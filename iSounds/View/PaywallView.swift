//
//  PaywallView.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-11-04.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @StateObject private var proManager = ProManager.shared
    
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    
    /// Product ID of the plan the user already holds, when opened from Settings to change plans.
    private var currentProductID: String? {
        proManager.activePlan?.productID
    }
    
    /// Whether this paywall is being used to switch plans rather than to buy Pro for the first time.
    private var isChangingPlan: Bool {
        currentProductID != nil
    }
    
    /// Plans offered on this screen. Subscribers only switch between Monthly and Annual;
    /// Lifetime is hidden for them so a one-time purchase can't overlap a running subscription.
    private var displayedProducts: [Product] {
        guard isChangingPlan else { return proManager.products }
        return proManager.products.filter { !$0.id.contains("lifetime") }
    }
    
    /// The free trial attached to the currently selected plan, if the user can still claim it.
    private var selectedTrial: Product.SubscriptionOffer? {
        guard let product = selectedProduct else { return nil }
        return proManager.availableFreeTrial(for: product)
    }
    
    private var ctaTitle: String {
        if let trial = selectedTrial {
            return "Start \(trial.period.hyphenatedTitle) Free Trial"
        }
        return "Continue"
    }
    
    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24){
                    // Top Bar with Close Button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
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
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Header Branding & Icon
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color("AppAccent").opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Color("AppAccent"))
                        }
                        
                        Text(isChangingPlan ? "Change plan" : "iSounds Pro")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(isChangingPlan
                             ? "Switch between Monthly and Annual below. The change applies at your next renewal."
                             : "Unlock the full experience and support independent development.")
                            .font(.subheadline)
                            .foregroundColor(Color("AppSecondaryText"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Features List Card
                    VStack(alignment: .leading, spacing: 20) {
                        PaywallFeatureRow(
                            icon: "speaker.wave.3.fill",
                            title: "More sounds more pranks",
                            subtitle: "Enable all the funny sound clips."
                        )
                        
                        PaywallFeatureRow(
                            icon: "hand.raised.slash.fill",
                            title: "No ads",
                            subtitle: "Enjoy an uninterrupted, clean experience."
                        )
                        
//                        PaywallFeatureRow(
//                            icon: "magnifyingglass",
//                            title: "Search option",
//                            subtitle: "Quickly find any sound clip instantly."
//                        )
                        
                        PaywallFeatureRow(
                            icon: "heart.fill",
                            title: "Support indie developer",
                            subtitle: "Help fund future sound drops and app updates."
                        )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color("CardBackground"))
                    )
                    .padding(.horizontal)
                    
                    // 3. Subscription Options Selector
                    if proManager.isLoading{
                        ProgressView("Loading plans...")
                            .padding(.vertical, 30)
                    }else if displayedProducts.isEmpty {
                        VStack(spacing: 8) {
                            Text("Unable to load plans")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Button("Retry") {
                                Task { await proManager.loadProducts() }
                            }
                        }
                        .padding(.vertical, 20)
                    }else{
                        VStack(spacing: 12) {
                            ForEach(displayedProducts, id: \.id) { product in
                                ProductOptionCard(
                                    product: product,
                                    trial: proManager.availableFreeTrial(for: product),
                                    isSelected: selectedProduct?.id == product.id,
                                    isCurrent: product.id == currentProductID
                                ) {
                                    selectedProduct = product
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    // Error Banner
                    if let errorMessage = proManager.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // 4. Action CTA Button
                    
                    Button {
                        guard let product = selectedProduct else { return }
                        Task {
                            isPurchasing = true
                            let success = await proManager.purchase(product)
                            isPurchasing = false
                            if success {
                                dismiss()
                            }
                        }
                    } label: {
                        ZStack {
                            if isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text(ctaTitle)
                                    .font(.headline)
                                    .bold()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedProduct == nil ? Color.gray : Color("AppAccent"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(selectedProduct == nil || isPurchasing)
                    .padding(.horizontal)
                    
                    // Trial & renewal disclosure. Explains that the free period converts to a paid,
                    // auto-renewing subscription unless cancelled.
                    if let trial = selectedTrial,
                       let product = selectedProduct,
                       let subscription = product.subscription {
                        Text("\(trial.period.displayText) free, then \(product.displayPrice)\(subscription.subscriptionPeriod.perUnitSuffix). Auto-renews until cancelled. Cancel anytime in Settings.")
                            .font(.caption)
                            .foregroundColor(Color("AppSecondaryText"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    
                    // 5. Restore & Terms Legal Footer
                    HStack(spacing: 16) {
                        Button("Restore Purchases") {
                            Task {
                                isPurchasing = true
                                let restored = await proManager.restorePurchases()
                                isPurchasing = false
                                if restored {
                                    dismiss()
                                }
                            }
                        }
                        
//                        Text("•")
//                        
//                        Link("Terms of Service", destination: URL(string: "https://isounds.com/terms")!)
                        
                        Text("•")
                        
                        Link("Privacy Policy", destination: URL(string: "https://aplivox.com/privacy/isounds")!)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 20)
                    
                }
            }
        }
        .task {
            await proManager.loadProducts()
            guard selectedProduct == nil else { return }
            
            if let currentProductID {
                // Changing plans: pre-select the next step up from the current plan, never the current one.
                let products = displayedProducts
                let currentPrice = products.first(where: { $0.id == currentProductID })?.price
                selectedProduct = products.first(where: { product in
                    guard product.id != currentProductID, let currentPrice else { return false }
                    return product.price > currentPrice
                }) ?? products.first(where: { $0.id != currentProductID })
            } else {
                // Pre-select the Monthly plan, which carries the free trial, falling back to the first plan
                selectedProduct = proManager.products.first(where: { $0.id.contains("monthly") }) ?? proManager.products.first
            }
        }
    }
}

struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color("AppAccent").opacity(0.15))
                    .frame(width: 42, height: 42)
                
                Image(systemName: icon)
                    .foregroundColor(Color("AppAccent"))
                    .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color("AppSecondaryText"))
            }
            Spacer()
        }
    }
}

struct ProductOptionCard : View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    let product: Product
    /// Free trial the user can claim on this plan, or `nil` when there is none.
    let trial: Product.SubscriptionOffer?
    let isSelected: Bool
    /// Marks the plan the user already holds so it cannot be bought again.
    var isCurrent: Bool = false
    let onSelect:() -> Void
    
    var isAnnual: Bool {
        product.id.contains("annual")
    }
    
    /// Short badge shown next to the plan name, e.g. "CURRENT", "3 DAYS FREE" or the annual savings.
    private var badgeText: String? {
        if isCurrent {
            return "CURRENT"
        }
        if let trial {
            return "\(trial.period.displayText) FREE".uppercased()
        }
        if isAnnual {
            return "SAVE Almost 80%"
        }
        return nil
    }
    
    /// Plan description. When a trial is available it spells out the trial-then-price sequence.
    private var descriptionText: String {
        if let trial, let subscription = product.subscription {
            return "\(trial.period.displayText) free, then \(product.displayPrice)\(subscription.subscriptionPeriod.perUnitSuffix)"
        }
        return product.description
    }
    
    var body: some View {
        
        Button(action: onSelect) {
            HStack{
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                            .bold()
                            .foregroundColor(Color("AppPrimaryText"))
                        
                        if let badgeText {
                            Text(badgeText)
                                .font(.caption2)
                                .bold()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(isCurrent ? Color("AppSecondaryText") : Color("AppAccent"))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(descriptionText)
                        .font(.caption)
                        .foregroundColor(Color("AppSecondaryText"))
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .bold()
                        .foregroundColor(Color("AppPrimaryText"))
                    
                    if let subscription = product.subscription {
                        Text(subscription.subscriptionPeriod.unit == .year ? "/year" : "/month")
                            .font(.caption2)
                            .foregroundColor(Color("AppSecondaryText"))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color("CardBackground"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color("AppAccent") : Color.clear, lineWidth: 2)
            )
            .opacity(isCurrent ? 0.6 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isCurrent)
        
    }
}

#Preview {
    PaywallView()
}
