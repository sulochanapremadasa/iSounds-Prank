//
//  ContentView.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-10-26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode : Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        
        Group {
            if hasCompletedOnboarding {
                SoundsListView()
                    .navigationViewStyle(.stack)
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: hasCompletedOnboarding)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .tint(Color("AppAccent"))

    }
}

#Preview {
    ContentView()
}
