//
//  VideoComposer.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-11-23.
//

import AVFoundation

/// A stretch of the recorded video during which the sound clip was playing.
nonisolated struct ClipSegment: Sendable {
    /// Position in the recorded video (seconds) where the clip started playing.
    let videoStart: Double
    /// Position inside the sound clip (seconds) where playback started.
    let clipStart: Double
    /// How long the clip played for (seconds).
    let duration: Double
    /// Whether the clip was looping during this segment.
    let isLooping: Bool
}

nonisolated enum VideoComposerError: LocalizedError {
    case missingVideoTrack
    case exportUnavailable

    var errorDescription: String? {
        switch self {
        case .missingVideoTrack: return "The recorded video could not be read."
        case .exportUnavailable: return "Unable to create the final video."
        }
    }
}

/// Merges the clean sound clip into the recorded video at the times it was played.
nonisolated enum VideoComposer {

    private static let microphoneVolume: Float = 0.8
    private static let clipVolume: Float = 1.0

    static func compose(videoURL: URL, clipURL: URL, segments: [ClipSegment]) async throws -> URL {
        let videoAsset = AVURLAsset(url: videoURL)
        let clipAsset = AVURLAsset(url: clipURL)
        let composition = AVMutableComposition()

        // Video track
        let videoDuration = try await videoAsset.load(.duration)
        let videoSeconds = videoDuration.seconds
        let fullRange = CMTimeRange(start: .zero, duration: videoDuration)

        guard let sourceVideo = try await videoAsset.loadTracks(withMediaType: .video).first,
              let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw VideoComposerError.missingVideoTrack
        }
        try videoTrack.insertTimeRange(fullRange, of: sourceVideo, at: .zero)
        videoTrack.preferredTransform = try await sourceVideo.load(.preferredTransform)

        var mixParameters: [AVMutableAudioMixInputParameters] = []

        // Microphone track
        if let sourceMic = try await videoAsset.loadTracks(withMediaType: .audio).first,
           let micTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try micTrack.insertTimeRange(fullRange, of: sourceMic, at: .zero)
            let parameters = AVMutableAudioMixInputParameters(track: micTrack)
            parameters.setVolume(microphoneVolume, at: .zero)
            mixParameters.append(parameters)
        }

        // Sound clip track, placed at each recorded segment
        let clipSeconds = try await clipAsset.load(.duration).seconds
        if clipSeconds > 0.05,
           let sourceClip = try await clipAsset.loadTracks(withMediaType: .audio).first,
           let clipTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {

            var trackEnd = 0.0
            for segment in segments.sorted(by: { $0.videoStart < $1.videoStart }) {
                // Never overlap the previous piece; insertTimeRange would shift later audio.
                var videoTime = max(segment.videoStart, trackEnd)
                var clipTime = segment.clipStart + (videoTime - segment.videoStart)
                var remaining = segment.duration - (videoTime - segment.videoStart)

                // A looping clip may wrap around several times within a single segment.
                while remaining > 0.01 && videoTime < videoSeconds {
                    if segment.isLooping {
                        clipTime = clipTime.truncatingRemainder(dividingBy: clipSeconds)
                    }
                    let available = clipSeconds - clipTime
                    guard available > 0.01 else { break }

                    let piece = min(remaining, available, videoSeconds - videoTime)
                    try clipTrack.insertTimeRange(
                        CMTimeRange(start: time(clipTime), duration: time(piece)),
                        of: sourceClip,
                        at: time(videoTime)
                    )
                    videoTime += piece
                    clipTime += piece
                    remaining -= piece
                    trackEnd = videoTime
                }
            }

            let parameters = AVMutableAudioMixInputParameters(track: clipTrack)
            parameters.setVolume(clipVolume, at: .zero)
            mixParameters.append(parameters)
        }

        // Export
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw VideoComposerError.exportUnavailable
        }
        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = mixParameters
        exporter.audioMix = audioMix

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("iSounds-\(UUID().uuidString)")
            .appendingPathExtension("mp4")
        try await exporter.export(to: outputURL, as: .mp4)

        // The raw recording is no longer needed.
        try? FileManager.default.removeItem(at: videoURL)
        return outputURL
    }

    private static func time(_ seconds: Double) -> CMTime {
        CMTime(seconds: seconds, preferredTimescale: 600)
    }
}
