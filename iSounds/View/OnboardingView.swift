//
//  OnboardingView.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-11-10.
//

import SwiftUI

/// Three-step introduction shown once, on first launch. Completing or skipping it
/// sets `hasCompletedOnboarding`, which `ContentView` uses to switch to the sounds list.
struct OnboardingView: View {
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentPage: Int = 0
    
    private let steps = Constant.Onboarding.steps
    
    private var isLastPage: Bool {
        currentPage == steps.count - 1
    }
    
    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()
            
            // Soft decorative blobs behind the content for a modern feel
            OnboardingBackdrop(page: currentPage)
            
            VStack(spacing: 0) {
                // Skip button (hidden on the final page)
                HStack {
                    Spacer()
                    Button(Constant.Onboarding.skip) {
                        finish()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("AppSecondaryText"))
                    .opacity(isLastPage ? 0 : 1)
                    .disabled(isLastPage)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                // Swipeable pages
                TabView(selection: $currentPage) {
                    ForEach(steps.indices, id: \.self) { index in
                        OnboardingStepView(step: steps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(steps.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color("AppAccent") : Color("AppAccent").opacity(0.25))
                            .frame(width: index == currentPage ? 28 : 8, height: 8)
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentPage)
                .padding(.bottom, 28)
                
                // Primary action
                Button {
                    if isLastPage {
                        finish()
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            currentPage += 1
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(isLastPage ? Constant.Onboarding.getStarted : Constant.Onboarding.next)
                            .font(.headline)
                            .bold()
                        Image(systemName: isLastPage ? "checkmark" : "arrow.right")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("AppAccent"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color("AppAccent").opacity(0.35), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    private func finish() {
        withAnimation(.easeInOut(duration: 0.35)) {
            hasCompletedOnboarding = true
        }
    }
}

/// A single onboarding page: icon tile, title and a short description.
struct OnboardingStepView: View {
    let step: Constant.Onboarding.Step
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color("AppAccent"), Color("AppAccent").opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)
                    .shadow(color: Color("AppAccent").opacity(0.35), radius: 24, x: 0, y: 12)
                
                Image(systemName: step.icon)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 14) {
                Text(step.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AppPrimaryText"))
                    .multilineTextAlignment(.center)
                
                Text(step.description)
                    .font(.body)
                    .foregroundColor(Color("AppSecondaryText"))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
    }
}

/// Blurred accent circles that drift slightly as the user moves between pages.
private struct OnboardingBackdrop: View {
    let page: Int
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                Circle()
                    .fill(Color("AppAccent").opacity(0.18))
                    .frame(width: size.width * 0.9)
                    .blur(radius: 60)
                    .offset(x: -size.width * 0.35 + CGFloat(page) * 30, y: -size.height * 0.3)
                
                Circle()
                    .fill(Color("AppAccent").opacity(0.12))
                    .frame(width: size.width * 0.7)
                    .blur(radius: 50)
                    .offset(x: size.width * 0.4 - CGFloat(page) * 30, y: size.height * 0.25)
            }
            .animation(.easeInOut(duration: 0.6), value: page)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    OnboardingView()
}
