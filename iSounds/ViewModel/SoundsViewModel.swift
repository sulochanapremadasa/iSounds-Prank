//
//  SoundsViewModel.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-10-26.
//

import Foundation
import AVFoundation
import Combine

class SoundsViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var sounds: [SoundItem] = []
    @Published var currentlyPlayingID: UUID? = nil
    @Published var searchText: String = ""
    
    private var player: AVAudioPlayer?
    
    var filteredSounds: [SoundItem] {
        if searchText.isEmpty {
            return sounds
        } else {
            return sounds.filter{ $0.name.localizedStandardContains(searchText) }
        }
    }

    override init() {
        super.init()
        loadSoundsFromBundle()
    }

    private func loadSoundsFromBundle() {
        var loadedSounds: [SoundItem] = []
        let fileExtensions = ["mp3", "m4a", "wav", "aac"]
        var discoveredUrls: [URL] = []

        // 1. Check inside the "Sounds" folder reference subdirectory
        for ext in fileExtensions {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Sounds") {
                discoveredUrls.append(contentsOf: urls)
            }
        }

        // 2. Fallback: Check the main bundle root
        if discoveredUrls.isEmpty {
            for ext in fileExtensions {
                if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                    discoveredUrls.append(contentsOf: urls)
                }
            }
        }

        // 3. Fallback: Search the resource path directly via FileManager if bundle lookups fail
        if discoveredUrls.isEmpty, let resourcePath = Bundle.main.resourcePath {
            let soundsFolderPath = (resourcePath as NSString).appendingPathComponent("Sounds")
            let fileManager = FileManager.default
            if let items = try? fileManager.contentsOfDirectory(atPath: soundsFolderPath) {
                for item in items {
                    let fullPath = (soundsFolderPath as NSString).appendingPathComponent(item)
                    let url = URL(fileURLWithPath: fullPath)
                    if fileExtensions.contains(url.pathExtension.lowercased()) {
                        discoveredUrls.append(url)
                    }
                }
            }
        }

        // Process found URLs into SoundItems
        for url in discoveredUrls {
            let filenameWithoutExtension = url.deletingPathExtension().lastPathComponent
            let fileExtension = url.pathExtension
            
            let isFreeClip = filenameWithoutExtension.lowercased().hasSuffix("-free")
            
            let cleanFilename = filenameWithoutExtension
                    .replacingOccurrences(of: "-free", with: "", options: .caseInsensitive)
            
            let readableName = cleanFilename
                .replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: "-", with: " ")
                .capitalized
            
            let durationString = getAudioDuration(url: url)
            
            let sound = SoundItem(
                name: readableName,
                duration: durationString,
                iconName: "waveform",
                filename: filenameWithoutExtension,
                fileExtension: fileExtension,
                isFree: isFreeClip
            )
            loadedSounds.append(sound)
        }

        self.sounds = loadedSounds.sorted { $0.name < $1.name }
    }

    private func getAudioDuration(url: URL) -> String {
        let asset = AVURLAsset(url: url)
        let durationSeconds = CMTimeGetSeconds(asset.duration)
        
        if durationSeconds.isNaN || durationSeconds.isInfinite {
            return "0:00"
        }
        
        let minutes = Int(durationSeconds) / 60
        let seconds = Int(durationSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func togglePlay(for item: SoundItem) {
        // If the same item is already playing, stop it and reset state
        if currentlyPlayingID == item.id {
            player?.stop()
            currentlyPlayingID = nil
            return
        }

        // Try finding the file in the Sounds folder subdirectory first, then root bundle
        guard let url = Bundle.main.url(forResource: item.filename, withExtension: item.fileExtension, subdirectory: "Sounds")
                ?? Bundle.main.url(forResource: item.filename, withExtension: item.fileExtension) else {
            print("Could not find audio file path for: \(item.filename).\(item.fileExtension)")
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self // Set delegate to track when playback finishes
            player?.play()
            currentlyPlayingID = item.id
        } catch {
            print("Playback failed: \(error.localizedDescription)")
        }
    }

    // MARK: - AVAudioPlayerDelegate
    
    // Automatically called by iOS when the audio clip finishes playing to the end
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.currentlyPlayingID = nil
        }
    }
}
