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
    
    enum RecordShare {
        /// One highlight row on the Record & Share intro screen.
        struct Feature {
            let icon: String
            let title: String
            let description: String
        }
        
        static let title = "Record & Share"
        static let subtitle = "Turn any sound into a hilarious video moment."
        static let pageName = "iSounds Prank"
        static let hashtag = "#iSoundsPrank"
        static let facebookPageURLString = "https://www.facebook.com/profile.php?id=61596999114500"
        static var facebookPageURL: URL? { URL(string: facebookPageURLString) }
        
        static let features: [Feature] = [
            Feature(
                icon: "video.fill",
                title: "Record your reaction",
                description: "Film yourself or your friends with the back or front camera."
            ),
            Feature(
                icon: "waveform",
                title: "Sound plays while you film",
                description: "The clip plays out loud and is mixed into your video in crystal-clear quality."
            ),
            Feature(
                icon: "pause.circle.fill",
                title: "You're in control",
                description: "Tap play to start the sound whenever you're ready. Pause or stop the video and the sound stops with it."
            ),
            Feature(
                icon: "hand.thumbsup.fill",
                title: "Share & get featured",
                description: "Share your video with \(hashtag) — the best ones get featured on the \(pageName) Facebook page!"
            )
        ]
        
        static let playbackTitle = "Sound playback"
        static let playOnce = "Play once"
        static let loop = "Loop"
        static let startRecording = "Start Recording"
        static let share = "Share on \(pageName)"
        static let shareHint = "Your video will be saved to Photos and the caption copied, then the \(pageName) Facebook page opens so you can post it."
        static let readyTitle = "Ready to Share!"
        static let readyMessage = "Your video is saved to Photos and the caption is copied. On the \(pageName) page, tap to create a post, add your video, and paste the caption."
        static let openFacebook = "Open Facebook"
        static let photosPermissionMessage = "Allow iSounds to add videos to Photos in Settings so you can share them on Facebook."
        static let retake = "Retake"
        static let done = "Done"
        static let creatingVideo = "Creating your video…"
        static let permissionTitle = "Camera & Microphone Access Needed"
        static let permissionMessage = "Allow camera and microphone access in Settings to record videos with your sounds."
        static let openSettings = "Open Settings"
        
        static var caption: String {
            "Made with iSounds 🎬🔊 \(hashtag)\n\(facebookPageURLString)"
        }
    }
    
//    enum Errors {
//        static let networkError = "Something went wrong. Please check your connection."
//        static let generic = "An unknown error occurred."
//    }
}
