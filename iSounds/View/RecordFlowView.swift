//
//  RecordFlowView.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-11-23.
//

import SwiftUI

/// Screens of the Record & Share flow after the intro.
enum RecordStep: Hashable {
    case recorder
    case preview(URL)
}

/// Hosts the Record & Share flow: Intro → Recorder → Preview.
struct RecordFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RecordingViewModel
    @State private var path: [RecordStep] = []

    init(sound: SoundItem) {
        _viewModel = State(initialValue: RecordingViewModel(sound: sound))
    }

    var body: some View {
        NavigationStack(path: $path) {
            RecordIntroView(
                viewModel: viewModel,
                onStart: { path.append(.recorder) },
                onClose: { dismiss() }
            )
            .navigationDestination(for: RecordStep.self) { step in
                switch step {
                case .recorder:
                    RecorderView(viewModel: viewModel, onClose: { dismiss() })
                case .preview(let url):
                    RecordedPreviewView(
                        videoURL: url,
                        onRetake: { path.removeLast() },
                        onDone: { dismiss() }
                    )
                }
            }
        }
        .tint(Color("AppAccent"))
        .onChange(of: viewModel.finishedVideoURL) { _, url in
            guard let url else { return }
            viewModel.finishedVideoURL = nil
            path.append(.preview(url))
        }
        .onDisappear {
            viewModel.suspend()
        }
    }
}
