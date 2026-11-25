//
//  SoundItem.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-10-26.
//

import Foundation

struct SoundItem: Identifiable {
    let id = UUID()
    let name: String
    let duration: String       // Only duration remains
    let iconName: String
    let filename: String
    let fileExtension: String
    let isFree : Bool
}

extension SoundItem {
    /// Location of the audio file in the bundle: the "Sounds" folder first, then the bundle root.
    var fileURL: URL? {
        Bundle.main.url(forResource: filename, withExtension: fileExtension, subdirectory: "Sounds")
            ?? Bundle.main.url(forResource: filename, withExtension: fileExtension)
    }
}
