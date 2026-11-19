//
//  Constant.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-11-05.
//

import Foundation

enum Constant {
    // Global or General strings
    static let appName = "MyApp"
    
    enum AdMob {
        static let admobBannerID = "ca-app-pub-4176454856084667/7928618483"// // test ca-app-pub-3940256099942544/2934735716
        static let interstitialAdID = "ca-app-pub-4176454856084667/9412859030"// // test- ca-app-pub-3940256099942544/4411468910
        
    }
    
    // Grouping by feature or screen
    enum Onboarding {
        /// One page of the first-launch onboarding flow.
        struct Step {
            let icon: String
            let title: String
            let description: String
        }
        
        static let steps: [Step] = [
            Step(
                icon: "waveform",
                title: "Welcome to iSounds",
                description: "A little fun, whenever you need it. Dozens of funny sounds, all one tap away."
            ),
            Step(
                icon: "play.circle.fill",
                title: "Tap any sound to play it",
                description: "Browse the collection and tap a card to play. Tap it again to stop."
            ),
            Step(
                icon: "paintpalette.fill",
                title: "Make it yours",
                description: "Switch on dark mode and tweak your settings from the button in the top corner."
            )
        ]
        
        static let skip = "Skip"
        static let next = "Next"
        static let getStarted = "Get Started"
    }
    
//    enum Errors {
//        static let networkError = "Something went wrong. Please check your connection."
//        static let generic = "An unknown error occurred."
//    }
}
