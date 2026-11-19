//
//  SettingsView.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-10-26.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var proManager = ProManager.shared
    
    @StateObject private var interstitial = AdMobInterstitialAd()
    
    @State private var showPaywall = false
    @State private var showManageSubscriptions = false
    
    var body: some View {
            ZStack {
                Color("AppBackground")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Scrollable so taller content (e.g. the Pro plan card) never gets clipped.
                    GeometryReader { geometry in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                    
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Image(systemName: "waveform")
                                            Text(viewModel.appName)
                                        }
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color("AppAccent"))
                            
                                        Text("Settings")
                                            .font(.largeTitle)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color("AppPrimaryText"))
                                
                                
                            
                                        Text("Make yourself comfortable.")
                                            .font(.subheadline)
                                            .foregroundColor(Color("AppSecondaryText"))
                                    }
                        
                                    Spacer()
                        
                                    // Close (X) Button
                                    Button(action: {
                                        dismiss()
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color("CardBackground"))
                                                .frame(width: 44, height: 44)
                                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                
                                            Image(systemName: "xmark")
                                                .font(.headline)
                                                .foregroundColor(Color("AppSecondaryText"))
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                                .padding(.horizontal)

                                // Appearance Section
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("APPEARANCE")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color("AppSecondaryText"))
                                        .padding(.horizontal)

                                    HStack {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color("AppAccent").opacity(0.15))
                                                .frame(width: 40, height: 40)

                                            Image(systemName: "moon.fill")
                                                .foregroundColor(Color("AppAccent"))
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Dark mode")
                                                .font(.headline)
                                                .foregroundColor(Color("AppPrimaryText"))
                                            Text("A darker look for quieter nights.")
                                                .font(.caption)
                                                .foregroundColor(Color("AppSecondaryText"))
                                        }

                                        Spacer()

                                        Toggle("", isOn: $viewModel.isDarkMode)
                                            .labelsHidden()
                                            .tint(Color("AppAccent"))
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(Color("CardBackground"))
                                    )
                                    .padding(.horizontal)
                                }

                                // Support Section
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("HERE TO HELP")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color("AppSecondaryText"))
                                        .padding(.horizontal)

                                    Button(action: {
                                        withAnimation(.spring()) {
                                            viewModel.showContactPopup = true
                                        }
                                    }) {
                                        HStack {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color("AppAccent").opacity(0.15))
                                                    .frame(width: 40, height: 40)

                                                Image(systemName: "envelope.fill")
                                                    .foregroundColor(Color("AppAccent"))
                                            }

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Contact us")
                                                    .font(.headline)
                                                    .foregroundColor(Color("AppPrimaryText"))
                                                Text("We'd love to hear from you.")
                                                    .font(.caption)
                                                    .foregroundColor(Color("AppSecondaryText"))
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.subheadline)
                                                .foregroundColor(Color("AppSecondaryText"))
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .fill(Color("CardBackground"))
                                        )
                                        .padding(.horizontal)
                                    }
                                }
                                if proManager.isProUser {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("YOUR PLAN")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color("AppSecondaryText"))
                                            .padding(.horizontal)
                            
                                        ProPlanCard(
                                            plan: proManager.activePlan,
                                            onChangePlan: { showPaywall = true },
                                            onManage: { showManageSubscriptions = true }
                                        )
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("ADVANCE")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color("AppSecondaryText"))
                                            .padding(.horizontal)
                            
                                        Button(action: {
                                            showPaywall = true
                                        }) {
                                            HStack {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color("AppAccent").opacity(0.15))
                                                        .frame(width: 40, height: 40)
                                        
                                                    Image(systemName: "star.fill")
                                                        .foregroundColor(Color("AppAccent"))
                                                }
                                    
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Upgrade to Pro")
                                                        .font(.headline)
                                                        .foregroundColor(.primary)
                                                    Text("Unlock all sounds & remove ads")
                                                        .font(.caption)
                                                        .foregroundColor(Color("AppSecondaryText"))
                                                }
                                    
                                                Spacer()
                                    
                                                Image(systemName: "chevron.right")
                                                    .font(.subheadline)
                                                    .foregroundColor(Color("AppSecondaryText"))
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                    .fill(Color("CardBackground"))
                                            )
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                    

                                Spacer()

                                // App Version Footer
                                VStack(spacing: 8) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color("AppAccent").opacity(0.15))
                                            .frame(width: 36, height: 36)
                            
                                        Image(systemName: "waveform")
                                            .font(.subheadline)
                                            .foregroundColor(Color("AppAccent"))
                                    }

                                    Text(viewModel.appName)
                                        .font(.headline)
                                        .foregroundColor(Color("AppSecondaryText"))

                                    Text("Version \(viewModel.appVersion)")
                                        .font(.caption)
                                        .foregroundColor(Color("AppSecondaryText"))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 20)
                            }
                            .padding(.top)
                            // Fill at least the visible height so the Spacer still pushes the footer down.
                            .frame(minHeight: geometry.size.height)
                        }
                    }

                    if !proManager.isProUser {
                        AdMobBannerView(adUnitID: Constant.AdMob.admobBannerID)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                }
                
                

                // Popup Overlay
                if viewModel.showContactPopup {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation { viewModel.showContactPopup = false }
                        }

                    ContactPopupView(viewModel: viewModel)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
            .onChange(of: showManageSubscriptions) { _, isPresented in
                // Re-check the entitlement once the sheet closes so a plan change or
                // cancellation made there is reflected right away.
                if !isPresented {
                    Task { await proManager.updatePurchasedStatus() }
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .onAppear {
                if !proManager.isProUser {
                    interstitial.load()
                }
            }

        }
}

/// Card shown in Settings once the user is Pro: plan name, renewal status, an in-app
/// "Change plan" path (the only way to reach Lifetime) and, while an auto-renewable plan
/// is active, a shortcut to Apple's manage-subscriptions sheet.
struct ProPlanCard: View {
    /// `nil` while the entitlement check is still running.
    let plan: ProPlan?
    let onChangePlan: () -> Void
    let onManage: () -> Void
    
    private var titleText: String {
        guard let plan else { return "iSounds Pro" }
        return "iSounds Pro · \(plan.tier.displayName)"
    }
    
    private var statusText: String {
        plan?.statusText ?? "Checking your plan…"
    }
    
    private var badgeText: String {
        plan?.isInFreeTrial == true ? "TRIAL" : "PRO"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("AppAccent").opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "crown.fill")
                        .foregroundColor(Color("AppAccent"))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(titleText)
                        .font(.headline)
                        .foregroundColor(Color("AppPrimaryText"))
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(Color("AppSecondaryText"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Text(badgeText)
                    .font(.caption2)
                    .bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color("AppAccent"))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding()
            
            if let notice = plan?.overlappingSubscriptionNotice {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(notice)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(.orange)
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            
            // Lifetime owners with no subscription left have nothing to change or manage.
            if let plan, !(plan.isLifetime && !plan.canManage) {
                Divider()
                    .padding(.horizontal)
                
                if !plan.isLifetime {
                    ProPlanActionRow(icon: "arrow.left.arrow.right", title: "Change plan", action: onChangePlan)
                }
                
                if plan.canManage {
                    if !plan.isLifetime {
                        Divider()
                            .padding(.leading, 52)
                    }
                    ProPlanActionRow(icon: "creditcard.fill", title: "Manage Subscription", action: onManage)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
}

/// One tappable action row at the bottom of the Pro plan card.
struct ProPlanActionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(Color("AppAccent"))
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("AppAccent"))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(Color("AppSecondaryText"))
            }
            .padding()
        }
    }
}

struct ContactPopupView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject private var proManager = ProManager.shared

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color("AppAccent").opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: "envelope.fill")
                    .font(.title2)
                    .foregroundColor(Color("AppAccent"))
            }
            .padding(.top, 10)

            VStack(spacing: 8) {
                Text("Let’s talk")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Questions, feedback, or just want to say hello?\nSend us a note and we’ll get back to you.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color("AppSecondaryText"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 12) {
                Button(action: {
                    viewModel.openMailApp()
                }) {
                    Text("Email \(viewModel.contactEmail)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color("AppAccent"))
                        )
                }

                Button(action: {
                    withAnimation { viewModel.showContactPopup = false }
                }) {
                    Text("Maybe later")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("AppSecondaryText"))
                }
            }
            .padding(.top, 4)

            if !proManager.isProUser {
                AdMobBannerView(adUnitID: Constant.AdMob.admobBannerID)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            
        }
        .padding(24)
        .frame(width: 330)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color("CardBackground"))
        )
        .overlay(
            Button(action: {
                withAnimation { viewModel.showContactPopup = false }
            }) {
                Image(systemName: "xmark")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("AppSecondaryText"))
                    .padding(12)
            },
            alignment: .topTrailing
        )
        .shadow(color: Color.black.opacity(0.2), radius: 25, x: 0, y: 10)
    }
}

#Preview {
    SettingsView()
}

#Preview("Pro plan card") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()
        ScrollView {
            VStack(spacing: 16) {
                ProPlanCard(
                    plan: ProPlan(tier: .monthly, productID: "com.sulo.iSounds.monthly", expirationDate: .now.addingTimeInterval(86_400 * 3), willAutoRenew: true, isInFreeTrial: true, isInGracePeriod: false, overlappingSubscription: nil),
                    onChangePlan: {},
                    onManage: {}
                )
                ProPlanCard(
                    plan: ProPlan(tier: .annual, productID: "com.sulo.iSounds.annual", expirationDate: .now.addingTimeInterval(86_400 * 200), willAutoRenew: false, isInFreeTrial: false, isInGracePeriod: false, overlappingSubscription: nil),
                    onChangePlan: {},
                    onManage: {}
                )
                ProPlanCard(
                    plan: ProPlan(tier: .lifetime, productID: "com.sulo.iSounds.lifetime", expirationDate: nil, willAutoRenew: false, isInFreeTrial: false, isInGracePeriod: false, overlappingSubscription: nil),
                    onChangePlan: {},
                    onManage: {}
                )
                ProPlanCard(
                    plan: ProPlan(
                        tier: .lifetime,
                        productID: "com.sulo.iSounds.lifetime",
                        expirationDate: nil,
                        willAutoRenew: false,
                        isInFreeTrial: false,
                        isInGracePeriod: false,
                        overlappingSubscription: .init(tier: .monthly, expirationDate: .now.addingTimeInterval(86_400 * 20), willAutoRenew: true, isInFreeTrial: false, isInGracePeriod: false)
                    ),
                    onChangePlan: {},
                    onManage: {}
                )
                ProPlanCard(plan: nil, onChangePlan: {}, onManage: {})
            }
            .padding(.vertical)
        }
    }
}
