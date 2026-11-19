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
