//
//  RecorderView.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-11-23.
//

import SwiftUI
import AVFoundation

/// Full-screen camera with controls for the sound clip and the video recording.
struct RecorderView: View {
    @Bindable var viewModel: RecordingViewModel
    let onClose: () -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if viewModel.permissionDenied {
                permissionView
            } else {
                CameraPreview(session: viewModel.camera.session)
                    .ignoresSafeArea()

                VStack {
                    topBar
                    Spacer()
                    if viewModel.recordingState == .finishing {
                        finishingBadge
                    }
                    bottomControls
                }
                .padding()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .statusBarHidden()
        .task {
            await viewModel.prepareCamera()
        }
        .onDisappear {
            viewModel.suspend()
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            CircleIconButton(systemName: "xmark", accessibilityLabel: "Close", action: onClose)
                .disabled(viewModel.recordingState == .finishing)

            Spacer()

            timerBadge

            Spacer()

            // Loop / single-play toggle
            CircleIconButton(
                systemName: viewModel.isLooping ? "repeat" : "repeat.1",
                accessibilityLabel: viewModel.isLooping ? Constant.RecordShare.loop : Constant.RecordShare.playOnce,
                isHighlighted: viewModel.isLooping
            ) {
                viewModel.isLooping.toggle()
            }

            CircleIconButton(systemName: "arrow.triangle.2.circlepath.camera", accessibilityLabel: "Flip camera") {
                Task { await viewModel.flipCamera() }
            }
            .disabled(viewModel.recordingState != .idle)
            .opacity(viewModel.recordingState == .idle ? 1 : 0.4)
        }
    }

    private var timerBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(viewModel.recordingState == .recording ? Color.red : Color.white.opacity(0.6))
                .frame(width: 8, height: 8)
            Text(viewModel.recordingState == .paused ? "PAUSED" : formatted(viewModel.elapsed))
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(.ultraThinMaterial))
        .opacity(viewModel.isRecordingActive ? 1 : 0)
    }

    private var finishingBadge: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(.white)
            Text(Constant.RecordShare.creatingVideo)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(.ultraThinMaterial))
        .padding(.bottom, 12)
    }

    // MARK: - Bottom controls

    private var bottomControls: some View {
        HStack(alignment: .top) {
            // Sound clip play / pause
            ControlButton(
                systemName: viewModel.isClipPlaying ? "pause.fill" : "play.fill",
                title: viewModel.sound.name,
                accessibilityLabel: viewModel.isClipPlaying ? "Pause sound" : "Play sound",
                action: viewModel.toggleClip
            )
            .frame(maxWidth: .infinity)

            recordButton
                .frame(maxWidth: .infinity)

            // Video pause / resume
            ControlButton(
                systemName: viewModel.recordingState == .paused ? "video.fill" : "pause.fill",
                title: viewModel.recordingState == .paused ? "Resume" : "Pause",
                accessibilityLabel: viewModel.recordingState == .paused ? "Resume video" : "Pause video",
                action: viewModel.togglePause
            )
            .frame(maxWidth: .infinity)
            .opacity(viewModel.isRecordingActive ? 1 : 0)
            .disabled(!viewModel.isRecordingActive)
        }
        .disabled(viewModel.recordingState == .finishing)
        .padding(.bottom, 8)
    }

    private var recordButton: some View {
        let isActive = viewModel.isRecordingActive
        return Button {
            if isActive {
                Task { await viewModel.stopRecording() }
            } else {
                viewModel.startRecording()
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 78, height: 78)
                RoundedRectangle(cornerRadius: isActive ? 8 : 32, style: .continuous)
                    .fill(Color.red)
                    .frame(width: isActive ? 30 : 64, height: isActive ? 30 : 64)
            }
            .animation(.spring(duration: 0.3), value: isActive)
        }
        .disabled(!viewModel.isCameraReady)
        .accessibilityLabel(isActive ? "Stop recording" : "Start recording")
    }

    // MARK: - Permission

    private var permissionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 48))
                .foregroundColor(Color("AppAccent"))
            Text(Constant.RecordShare.permissionTitle)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text(Constant.RecordShare.permissionMessage)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            Button(Constant.RecordShare.openSettings) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color("AppAccent")))

            Button("Close", action: onClose)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(32)
    }

    private func formatted(_ time: TimeInterval) -> String {
        let total = Int(time)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

// MARK: - Components

/// Small round translucent button used in the recorder top bar.
private struct CircleIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    var isHighlighted = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.headline)
                .foregroundColor(isHighlighted ? Color("AppAccent") : .white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(.ultraThinMaterial))
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Round control with a caption, used for the sound and video pause buttons.
private struct ControlButton: View {
    let systemName: String
    let title: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemName)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(.ultraThinMaterial))
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Hosts an `AVCaptureVideoPreviewLayer` for the live camera feed.
private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer? { layer as? AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.previewLayer?.session = session
        view.previewLayer?.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}
