//
//  RecordedPreviewView.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-11-23.
//

import SwiftUI
import AVKit
import Photos

/// Plays back the finished video and offers sharing to the iSounds Prank Facebook page.
struct RecordedPreviewView: View {
    let videoURL: URL
    let onRetake: () -> Void
    let onDone: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var player = AVQueuePlayer()
    @State private var looper: AVPlayerLooper?
    @State private var isPreparingShare = false
    @State private var showShareReady = false
    @State private var shareError: String?

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            VStack(spacing: 16) {
                VideoPlayer(player: player)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    Button {
                        Task { await prepareFacebookShare() }
                    } label: {
                        HStack(spacing: 10) {
                            if isPreparingShare {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Text(Constant.RecordShare.share)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color("AppAccent")))
                    }
                    .disabled(isPreparingShare)

                    Text(Constant.RecordShare.shareHint)
                        .font(.footnote)
                        .foregroundColor(Color("AppSecondaryText"))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(Constant.RecordShare.retake, systemImage: "arrow.counterclockwise", action: onRetake)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(Constant.RecordShare.done, action: onDone)
                    .fontWeight(.semibold)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: videoURL))
            player.play()
        }
        .onDisappear {
            player.pause()
        }
        .alert(Constant.RecordShare.readyTitle, isPresented: $showShareReady) {
            Button(Constant.RecordShare.openFacebook) {
                player.pause()
                openFacebookPage()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(Constant.RecordShare.readyMessage)
        }
        .alert(
            "Couldn't Save Video",
            isPresented: Binding(
                get: { shareError != nil },
                set: { if !$0 { shareError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(shareError ?? "")
        }
    }

    // MARK: - Facebook sharing

    /// Saves the video to Photos and copies the caption, so the user can post them on the Facebook page.
    private func prepareFacebookShare() async {
        isPreparingShare = true
        defer { isPreparingShare = false }

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            shareError = Constant.RecordShare.photosPermissionMessage
            return
        }

        do {
            try await PHPhotoLibrary.shared().performChanges { [videoURL] in
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }
            UIPasteboard.general.string = Constant.RecordShare.caption
            showShareReady = true
        } catch {
            shareError = error.localizedDescription
        }
    }

    /// Opens the page via its web address; iOS routes it to the Facebook app when installed.
    private func openFacebookPage() {
        guard let pageURL = Constant.RecordShare.facebookPageURL else { return }
        openURL(pageURL)
    }
}
