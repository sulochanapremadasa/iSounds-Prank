//
//  SoundsListView.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-10-26.
//

import SwiftUI

struct SoundsListView: View {
    
    @StateObject private var viewModel = SoundsViewModel()
    @State private var showSettings = false
    @ObservedObject private var proManager = ProManager.shared
    @StateObject private var interstitial = AdMobInterstitialAd()
    
    @State private var showPaywall = false
    
    var body: some View {
        NavigationView{
            ZStack{
                Color("AppBackground")
                    .ignoresSafeArea()
                
                ScrollView{
                    
                    VStack (alignment: .leading, spacing: 20){
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "waveform")
                                    Text("iSound")
                                }
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color("AppAccent"))
                                
                                Text("Sounds")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("AppPrimaryText"))
                                
                                Text("A little fun, whenever you need it.")
                                    .font(.subheadline)
                                    .foregroundColor(Color("AppSecondaryText"))
                            }
                            
                            Spacer()
                            
                            // Settings Button (Placed at the blue star location)
                            Button(action: {
                                showSettings = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color("CardBackground"))
                                        .frame(width: 44, height: 44)
                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.headline)
                                        .foregroundColor(Color("AppAccent"))
                                }
                            }
                            .padding(.top, 4)
                        }
                        .padding(.horizontal)
                        
                        
                        HStack {
                            Text("SOUNDS COLLECTION")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("AppSecondaryText"))
                            Spacer()
                            Text("\(viewModel.filteredSounds.count) sounds")
                                .font(.caption)
                                .foregroundColor(Color("AppSecondaryText"))
                        }
                        .padding(.horizontal)
                        

                        VStack(spacing: 12) {
                            if viewModel.filteredSounds.isEmpty {
                                VStack(spacing: 8) {
                                    Spacer()
                                    Image(systemName: "magnifyingglass")
                                        .font(.largeTitle)
                                        .foregroundColor(Color("AppSecondaryText"))
                                    Text(viewModel.sounds.isEmpty ? "No sound files found in 'Sounds' folder." : "No sounds match your search.")
                                        .font(.subheadline)
                                        .foregroundColor(Color("AppSecondaryText"))
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                            } else {
                                ForEach(viewModel.filteredSounds) { sound in
                                    
                                    let isAccessible = sound.isFree || proManager.isProUser
                                    
                                    SoundRowView(
                                        sound: sound,
                                        isPlaying: viewModel.currentlyPlayingID == sound.id,
                                        isLocked: !isAccessible
                                    ) {
                                        if isAccessible {
                                            viewModel.togglePlay(for: sound)
                                        } else {
                                            showPaywall = true
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                    }
                    .padding(.vertical)
                }
                
               
            }
            
            .searchable(text: $viewModel.searchText, prompt: "Search sounds...") // Native iOS search bar
            .navigationBarHidden(true) // Hides default nav bar header since you have a custom title
            .safeAreaInset(edge: .bottom) {
                if !proManager.isProUser {
                    AdMobBannerView(adUnitID: Constant.AdMob.admobBannerID)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color("AppBackground"))
                }
            }
            .fullScreenCover(isPresented: $showSettings) {
                NavigationView {
                    SettingsView()
                }
                .tint(Color("AppAccent"))
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear {
                if !proManager.isProUser {
                    interstitial.load()
                }
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                // Calculate if content height minus the top offset matches the visible bounds
                let contentHeight = geometry.contentSize.height
                let visibleHeight = geometry.containerSize.height
                let offsetY = geometry.contentOffset.y
                
                // Returns true if the user scrolled to the absolute bottom (with a small threshold)
                return (offsetY + visibleHeight) >= (contentHeight - 100)
            } action: { oldValue, newValue in
                // Trigger your function only when the bottom state changes to true
                if newValue && !proManager.isProUser {
                    interstitial.present()
                }
            }
        }
    }
}

struct SoundRowView: View {
    let sound: SoundItem
    let isPlaying: Bool
    let isLocked: Bool
    let onPlayTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color("AppAccent").opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: sound.iconName)
                    .font(.title3)
                    .foregroundColor(isLocked ? Color("AppAccent").opacity(0.50) : Color("AppAccent"))
            }

            VStack(alignment: .leading, spacing: 4) {
//                HStack(spacing: 6) {
//                    Text(sound.name)
//                        .font(.headline)
//                        .fontWeight(.bold)
//                        .foregroundColor(Color("AppPrimaryText"))
//                    
//                    if isLocked {
//                        Image(systemName: "lock.fill")
//                            .font(.caption2)
//                            .foregroundColor(Color("AppSecondaryText"))
//                    }
//                }
                Text(sound.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isLocked ? Color("AppPrimaryText").opacity(0.50) : Color("AppPrimaryText"))
                // Displays ONLY duration now
                Text(sound.duration)
                    .font(.subheadline)
                    .foregroundColor(isLocked ? Color("AppSecondaryText").opacity(0.80) : Color("AppSecondaryText"))
            }

            Spacer()

            Button(action: onPlayTapped) {
                ZStack {
                    Circle()
                        .fill(isLocked ? Color("AppSecondaryText").opacity(0.15) : Color("AppAccent").opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: isLocked ? "lock.fill" : (isPlaying ? "pause.fill" : "play.fill"))
                        .foregroundColor(isLocked ? Color("AppSecondaryText") : Color("AppAccent"))
                        .font(.body)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color("CardBackground")) // Adapts automatically to Light/Dark mode
        )
    }
}

#Preview {
    SoundsListView()
}
