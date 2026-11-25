//
//  RecordIntroView.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-11-23.
//

import SwiftUI

/// Introduces the Record & Share feature and lets the user pick loop or single playback.
struct RecordIntroView: View {
    @Bindable var viewModel: RecordingViewModel
    let onStart: () -> Void
    let onClose: () -> Void

    @State private var animateHero = false

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    hero
                    featureList
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            startButton
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(Color("AppPrimaryText"))
                }
                .accessibilityLabel("Close")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { animateHero = true }
    }

    // MARK: - Sections

    private var hero: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color("AppAccent").opacity(0.12))
                    .frame(width: 150, height: 150)
                    .scaleEffect(animateHero ? 1.0 : 0.85)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: animateHero)
                Circle()
                    .fill(Color("AppAccent").opacity(0.22))
                    .frame(width: 110, height: 110)
                Image(systemName: "video.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(Color("AppAccent"))
                    .symbolEffect(.bounce, value: animateHero)
                Image(systemName: "waveform")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(Color("AppAccent")))
                    .offset(x: 38, y: 34)
            }
            .accessibilityHidden(true)

            Text(Constant.RecordShare.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color("AppPrimaryText"))

            Text(Constant.RecordShare.subtitle)
                .font(.subheadline)
                .foregroundColor(Color("AppSecondaryText"))
                .multilineTextAlignment(.center)

            Label(viewModel.sound.name, systemImage: "music.note")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color("AppAccent"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color("AppAccent").opacity(0.15)))

            // Keep the playback choice right next to the selected sound.
            playbackPicker
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private var featureList: some View {
        VStack(spacing: 12) {
            ForEach(Constant.RecordShare.features, id: \.title) { feature in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.title3)
                        .foregroundColor(Color("AppAccent"))
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color("AppAccent").opacity(0.15))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(feature.title)
                            .font(.headline)
                            .foregroundColor(Color("AppPrimaryText"))
                        Text(feature.description)
                            .font(.subheadline)
                            .foregroundColor(Color("AppSecondaryText"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color("CardBackground"))
                )
            }
        }
    }

    private var playbackPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Constant.RecordShare.playbackTitle.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("AppSecondaryText"))

            Picker(Constant.RecordShare.playbackTitle, selection: $viewModel.isLooping) {
                Label(Constant.RecordShare.playOnce, systemImage: "repeat.1").tag(false)
                Label(Constant.RecordShare.loop, systemImage: "repeat").tag(true)
            }
            .pickerStyle(.segmented)
        }
    }

    private var startButton: some View {
        Button {
            onStart()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "record.circle")
                Text(Constant.RecordShare.startRecording)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Capsule().fill(Color("AppAccent")))
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color("AppBackground"))
    }
}

#Preview {
    NavigationStack {
        RecordIntroView(
            viewModel: RecordingViewModel(
                sound: SoundItem(name: "Fart Loud", duration: "0:03", iconName: "waveform", filename: "fart-loud", fileExtension: "mp3", isFree: true)
            ),
            onStart: {},
            onClose: {}
        )
    }
}
