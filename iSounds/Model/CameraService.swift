//
//  CameraService.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-11-23.
//

import AVFoundation

/// Errors surfaced by the camera pipeline.
nonisolated enum CameraError: LocalizedError {
    case cameraUnavailable
    case cannotAddInput
    case cannotAddOutput
    case notRecording

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable: return "The camera is not available on this device."
        case .cannotAddInput: return "Unable to connect to the camera or microphone."
        case .cannotAddOutput: return "Unable to prepare video recording."
        case .notRecording: return "No recording is in progress."
        }
    }
}

/// Wraps an `AVCaptureSession` with a movie file output.
/// All session work is performed on a private serial queue, as recommended by AVFoundation.
nonisolated final class CameraService: NSObject, AVCaptureFileOutputRecordingDelegate, @unchecked Sendable {

    let session = AVCaptureSession()

    /// Called (on an arbitrary queue) once the movie file has actually started writing.
    var onRecordingStarted: (@Sendable () -> Void)?

    private let movieOutput = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "com.isounds.camera.session")
    private var videoInput: AVCaptureDeviceInput?
    private var isConfigured = false
    private var position: AVCaptureDevice.Position = .back
    private var finishContinuation: CheckedContinuation<URL, Error>?

    // MARK: - Permissions

    /// Requests camera and microphone access. Returns immediately if already decided.
    static func requestPermissions() async -> Bool {
        let video = await AVCaptureDevice.requestAccess(for: .video)
        let audio = await AVCaptureDevice.requestAccess(for: .audio)
        return video && audio
    }

    // MARK: - Session lifecycle

    /// Configures the session (once) and starts it running.
    func start() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async {
                do {
                    if !self.isConfigured {
                        try self.configureSession()
                        self.isConfigured = true
                    }
                    if !self.session.isRunning {
                        self.session.startRunning()
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    private func configureSession() throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        // The view model configures the audio session itself so the sound clip
        // keeps playing through the speaker while the microphone records.
        session.automaticallyConfiguresApplicationAudioSession = false
        session.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            throw CameraError.cameraUnavailable
        }
        let cameraInput = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(cameraInput) else { throw CameraError.cannotAddInput }
        session.addInput(cameraInput)
        videoInput = cameraInput

        if let microphone = AVCaptureDevice.default(for: .audio) {
            let microphoneInput = try AVCaptureDeviceInput(device: microphone)
            if session.canAddInput(microphoneInput) {
                session.addInput(microphoneInput)
            }
        }

        guard session.canAddOutput(movieOutput) else { throw CameraError.cannotAddOutput }
        session.addOutput(movieOutput)
        applyPortraitRotation()
    }

    /// Records in portrait orientation.
    private func applyPortraitRotation() {
        guard let connection = movieOutput.connection(with: .video) else { return }
        if connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }

    // MARK: - Camera switching

    /// Toggles between the back and front cameras and returns the new position.
    func switchCamera() async -> AVCaptureDevice.Position {
        await withCheckedContinuation { continuation in
            sessionQueue.async {
                let newPosition: AVCaptureDevice.Position = self.position == .back ? .front : .back
                guard let currentInput = self.videoInput,
                      let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                      let newInput = try? AVCaptureDeviceInput(device: device) else {
                    continuation.resume(returning: self.position)
                    return
                }

                self.session.beginConfiguration()
                self.session.removeInput(currentInput)
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.videoInput = newInput
                    self.position = newPosition
                } else {
                    // Restore the previous camera if the new one can't be added.
                    self.session.addInput(currentInput)
                }
                self.applyPortraitRotation()
                self.session.commitConfiguration()
                continuation.resume(returning: self.position)
            }
        }
    }

    // MARK: - Recording

    func startRecording() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("raw-\(UUID().uuidString)")
            .appendingPathExtension("mov")
        sessionQueue.async {
            guard !self.movieOutput.isRecording else { return }
            self.movieOutput.startRecording(to: url, recordingDelegate: self)
        }
    }

    func pauseRecording() {
        sessionQueue.async {
            if self.movieOutput.isRecording && !self.movieOutput.isRecordingPaused {
                self.movieOutput.pauseRecording()
            }
        }
    }

    func resumeRecording() {
        sessionQueue.async {
            if self.movieOutput.isRecordingPaused {
                self.movieOutput.resumeRecording()
            }
        }
    }

    /// Stops recording and returns the URL of the finished movie file.
    func stopRecording() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                guard self.movieOutput.isRecording else {
                    continuation.resume(throwing: CameraError.notRecording)
                    return
                }
                self.finishContinuation = continuation
                self.movieOutput.stopRecording()
            }
        }
    }

    // MARK: - AVCaptureFileOutputRecordingDelegate

    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        onRecordingStarted?()
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        // A recording can report an error yet still have finished writing a usable file.
        var succeeded = error == nil
        if let error = error as NSError?,
           let finished = error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool {
            succeeded = finished
        }

        sessionQueue.async {
            guard let continuation = self.finishContinuation else { return }
            self.finishContinuation = nil
            if succeeded {
                continuation.resume(returning: outputFileURL)
            } else {
                continuation.resume(throwing: error ?? CameraError.notRecording)
            }
        }
    }
}
