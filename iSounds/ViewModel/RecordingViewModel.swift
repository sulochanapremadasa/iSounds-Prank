//
//  RecordingViewModel.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-11-23.
//

import Foundation
import AVFoundation
import Observation

enum RecordingState {
    case idle
    case recording
    case paused
    case finishing
}

/// Drives the Record & Share flow: camera capture, sound clip playback,
/// and keeping both in sync so the clip can be merged into the final video.
@Observable
final class RecordingViewModel: NSObject, AVAudioPlayerDelegate {

    let sound: SoundItem
    let camera = CameraService()

    /// Whether the clip repeats or plays a single time.
    var isLooping = false {
        didSet { loopingChanged(from: oldValue) }
    }
    private(set) var isClipPlaying = false
    private(set) var recordingState: RecordingState = .idle
    private(set) var elapsed: TimeInterval = 0
    private(set) var cameraPosition: AVCaptureDevice.Position = .back
    private(set) var isCameraReady = false
    private(set) var permissionDenied = false
    var errorMessage: String?
    /// Set once the final video is ready; the flow navigates to the preview.
    var finishedVideoURL: URL?

    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var segments: [ClipSegment] = []
    @ObservationIgnored private var openSegment: (videoStart: Double, clipStart: Double)?
    @ObservationIgnored private var accumulatedTime: TimeInterval = 0
    @ObservationIgnored private var resumedAt: Date?
    @ObservationIgnored private var timerTask: Task<Void, Never>?

    init(sound: SoundItem) {
        self.sound = sound
        super.init()
        camera.onRecordingStarted = { [weak self] in
            guard let self else { return }
            Task { @MainActor in self.recordingDidStart() }
        }
    }

    var isRecordingActive: Bool {
        recordingState == .recording || recordingState == .paused
    }

    /// Time recorded into the video so far, excluding paused periods.
    private var recordedTime: TimeInterval {
        accumulatedTime + (resumedAt.map { Date().timeIntervalSince($0) } ?? 0)
    }

    // MARK: - Setup

    func prepareCamera() async {
        guard await CameraService.requestPermissions() else {
            permissionDenied = true
            return
        }
        permissionDenied = false
        configureAudioSession()
        preparePlayerIfNeeded()
        do {
            try await camera.start()
            isCameraReady = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Stops the camera and sound when leaving the recording screen.
    func suspend() {
        if isRecordingActive {
            Task { await stopRecording(discard: true) }
        }
        stopClip()
        camera.stop()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            print("Audio session setup failed: \(error.localizedDescription)")
        }
    }

    private func preparePlayerIfNeeded() {
        guard player == nil, let url = sound.fileURL else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.numberOfLoops = isLooping ? -1 : 0
            player.prepareToPlay()
            self.player = player
        } catch {
            errorMessage = "Could not load \(sound.name)."
        }
    }

    // MARK: - Camera

    func flipCamera() async {
        guard recordingState == .idle else { return }
        cameraPosition = await camera.switchCamera()
    }

    // MARK: - Sound clip

    func toggleClip() {
        isClipPlaying ? pauseClip() : playClip()
    }

    private func playClip() {
        guard let player else { return }
        player.play()
        isClipPlaying = true
        if recordingState == .recording && resumedAt != nil {
            openSegmentNow()
        }
    }

    private func pauseClip() {
        closeSegmentNow()
        player?.pause()
        isClipPlaying = false
    }

    private func stopClip() {
        closeSegmentNow()
        player?.stop()
        player?.currentTime = 0
        isClipPlaying = false
    }

    private func loopingChanged(from oldValue: Bool) {
        player?.numberOfLoops = isLooping ? -1 : 0
        // Split the timeline so each segment knows whether it looped.
        if openSegment != nil {
            closeSegmentNow(looping: oldValue)
            openSegmentNow()
        }
    }

    // MARK: - Clip timeline

    private func openSegmentNow() {
        guard openSegment == nil, let player else { return }
        openSegment = (videoStart: recordedTime, clipStart: player.currentTime)
    }

    private func closeSegmentNow(looping: Bool? = nil) {
        guard let open = openSegment else { return }
        openSegment = nil
        let duration = recordedTime - open.videoStart
        guard duration > 0.02 else { return }
        segments.append(ClipSegment(
            videoStart: open.videoStart,
            clipStart: open.clipStart,
            duration: duration,
            isLooping: looping ?? isLooping
        ))
    }

    // MARK: - Recording

    func startRecording() {
        guard recordingState == .idle, isCameraReady else { return }
        segments = []
        openSegment = nil
        accumulatedTime = 0
        resumedAt = nil
        elapsed = 0
        recordingState = .recording
        camera.startRecording()
    }

    /// Called once the movie file is actually being written, so clip timing lines up with video time zero.
    /// The clip is not started automatically; the user taps the sound button to play it.
    private func recordingDidStart() {
        guard recordingState == .recording, resumedAt == nil else { return }
        resumedAt = Date()
        startTimer()
        if isClipPlaying {
            openSegmentNow()
        }
    }

    func togglePause() {
        switch recordingState {
        case .recording: pauseRecording()
        case .paused: resumeRecording()
        default: break
        }
    }

    private func pauseRecording() {
        guard recordingState == .recording else { return }
        // Pausing the video always pauses the sound clip too.
        if isClipPlaying {
            pauseClip()
        }
        accumulatedTime = recordedTime
        resumedAt = nil
        camera.pauseRecording()
        recordingState = .paused
    }

    private func resumeRecording() {
        guard recordingState == .paused else { return }
        camera.resumeRecording()
        recordingState = .recording
        resumedAt = Date()
        // The clip stays paused until the user taps play again.
        if isClipPlaying {
            openSegmentNow()
        }
    }

    /// Stops recording (and the sound clip), then builds the final video.
    func stopRecording(discard: Bool = false) async {
        guard isRecordingActive else { return }
        // Stopping the video always stops the sound clip too.
        stopClip()
        accumulatedTime = recordedTime
        resumedAt = nil
        stopTimer()
        recordingState = .finishing

        do {
            let rawURL = try await camera.stopRecording()
            if discard {
                try? FileManager.default.removeItem(at: rawURL)
            } else if let clipURL = sound.fileURL, !segments.isEmpty {
                finishedVideoURL = try await VideoComposer.compose(videoURL: rawURL, clipURL: clipURL, segments: segments)
            } else {
                finishedVideoURL = rawURL
            }
        } catch {
            if !discard {
                errorMessage = error.localizedDescription
            }
        }
        recordingState = .idle
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard let self else { return }
                self.elapsed = self.recordedTime
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        elapsed = recordedTime
    }

    // MARK: - AVAudioPlayerDelegate

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            // A single-play clip reached its end.
            self.closeSegmentNow()
            self.isClipPlaying = false
        }
    }
}
