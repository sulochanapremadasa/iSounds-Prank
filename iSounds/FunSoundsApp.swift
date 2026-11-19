//
//  iSoundsApp.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-10-26.
//

import SwiftUI
import GoogleMobileAds

@main
struct FunSoundsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Initialize the Google Mobile Ads SDK
        MobileAds.shared.start(completionHandler: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task {
                            await ProManager.shared.updatePurchasedStatus()
                        }
                    }
                }
        }
    }
}
