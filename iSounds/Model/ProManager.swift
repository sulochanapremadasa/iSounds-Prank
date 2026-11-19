//
//  ProManager.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-11-04.
//

import Foundation
import StoreKit
import Combine
import SwiftUI

@MainActor
final class ProManager: ObservableObject {

    static let shared = ProManager()
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?
    
    /// Whether the current App Store account can still claim the introductory offer, keyed by product ID.
    /// Only products that actually carry an introductory offer appear here.
    @Published private(set) var introOfferEligibility: [String: Bool] = [:]
    
    /// The Pro plan the user currently holds, with renewal details for the Settings screen.
    /// `nil` while the entitlement check is still running or when the user is not Pro.
    @Published private(set) var activePlan: ProPlan?
    
    @AppStorage("isProUser") var isProUser: Bool = false {
        didSet {
            objectWillChange.send()
        }
    }
    
    private let productIDs = [
        "com.sulo.iSounds.monthly",
        "com.sulo.iSounds.annual",
        "com.sulo.iSounds.lifetime"
    ]
    
    private var updatesTask: Task<Void, Never>? = nil
    private var statusUpdatesTask: Task<Void, Never>? = nil
    init() {
        // Start listening for asynchronous App Store transaction updates (e.g. renewals, refunds, family sharing)
        updatesTask = listenForTransactions()
        // Renewal-preference changes (e.g. the user cancels in the manage sheet) arrive here, not as transactions
        statusUpdatesTask = listenForSubscriptionStatusUpdates()
        
        Task {
            await updatePurchasedStatus()
        }
    }

    deinit {
        updatesTask?.cancel()
        statusUpdatesTask?.cancel()
    }
    
    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetchedProducts = try await Product.products(for: productIDs)
            self.products = fetchedProducts.sorted { $0.price < $1.price }
            await refreshIntroOfferEligibility()
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // MARK: - Introductory Offers
    
    /// Asks the App Store whether this account is still eligible for each subscription's introductory offer.
    /// Eligibility is per subscription group, so a user who already used the trial on any plan is not eligible again.
    private func refreshIntroOfferEligibility() async {
        var eligibility: [String: Bool] = [:]
        for product in products {
            guard let subscription = product.subscription,
                  subscription.introductoryOffer != nil else {
                continue
            }
            eligibility[product.id] = await subscription.isEligibleForIntroOffer
        }
        introOfferEligibility = eligibility
    }
    
    /// The free trial the user can claim for this product, or `nil` if the product has no
    /// free-trial introductory offer or the user is no longer eligible for it.
    func availableFreeTrial(for product: Product) -> Product.SubscriptionOffer? {
        guard let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial,
              introOfferEligibility[product.id] == true else {
            return nil
        }
        return offer
    }
    
    // MARK: - Purchase
    func purchase(_ product: Product) async -> Bool {
        errorMessage = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await updatePurchasedStatus()
                    return true
                case .unverified(_, let error):
                    errorMessage = "Verification failed: \(error.localizedDescription)"
                }
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
        return false
    }
    
    
    // MARK: - Restore Purchases
    func restorePurchases() async -> Bool {
        do {
            try await AppStore.sync()
            await updatePurchasedStatus()
            return isProUser
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
            return false
        }
    }

    
    // MARK: - Entitlement Verification
    func updatePurchasedStatus() async {
        var lifetimeTransaction: StoreKit.Transaction?
        var subscriptionTransaction: StoreKit.Transaction?

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            guard productIDs.contains(transaction.productID) else {
                continue
            }

            // If the transaction was revoked, the entitlement is no longer valid
            if transaction.revocationDate != nil {
                continue
            }

            if transaction.productType == .autoRenewable {
                subscriptionTransaction = transaction
            } else {
                lifetimeTransaction = transaction
            }
        }

        let plan = await makePlan(lifetime: lifetimeTransaction, subscription: subscriptionTransaction)
        if activePlan != plan {
            activePlan = plan
        }

        let hasActivePro = plan != nil
        if self.isProUser != hasActivePro {
            self.isProUser = hasActivePro
        }
    }
    
    /// Builds the plan summary shown in Settings. Lifetime wins if the user holds both, but the
    /// still-active subscription is kept so Settings can warn about it and offer the manage sheet.
    private func makePlan(lifetime: StoreKit.Transaction?, subscription: StoreKit.Transaction?) async -> ProPlan? {
        let activeSubscription = await makeSubscription(from: subscription)
        
        if let lifetime, let tier = ProPlan.Tier(productID: lifetime.productID) {
            return ProPlan(
                tier: tier,
                productID: lifetime.productID,
                expirationDate: nil,
                willAutoRenew: false,
                isInFreeTrial: false,
                isInGracePeriod: false,
                overlappingSubscription: activeSubscription
            )
        }
        
        guard let subscription, let activeSubscription else {
            return nil
        }
        
        return ProPlan(
            tier: activeSubscription.tier,
            productID: subscription.productID,
            expirationDate: activeSubscription.expirationDate,
            willAutoRenew: activeSubscription.willAutoRenew,
            isInFreeTrial: activeSubscription.isInFreeTrial,
            isInGracePeriod: activeSubscription.isInGracePeriod,
            overlappingSubscription: nil
        )
    }
    
    /// Reads renewal details for an auto-renewable transaction, or `nil` when there is none.
    private func makeSubscription(from transaction: StoreKit.Transaction?) async -> ProPlan.Subscription? {
        guard let transaction, let tier = ProPlan.Tier(productID: transaction.productID) else {
            return nil
        }
        
        // Renewal info tells us whether the user has already cancelled (willAutoRenew == false)
        // or is in a billing grace period, neither of which shows up on the transaction itself.
        var willAutoRenew = true
        var isInGracePeriod = false
        if let status = await transaction.subscriptionStatus,
           case .verified(let renewalInfo) = status.renewalInfo {
            willAutoRenew = renewalInfo.willAutoRenew
            isInGracePeriod = status.state == .inGracePeriod
        }
        
        let isInFreeTrial = transaction.offer?.type == .introductory
            && transaction.offer?.paymentMode == .freeTrial
        
        return ProPlan.Subscription(
            tier: tier,
            expirationDate: transaction.expirationDate,
            willAutoRenew: willAutoRenew,
            isInFreeTrial: isInFreeTrial,
            isInGracePeriod: isInGracePeriod
        )
    }
    
    
    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    
                }
                await self.updatePurchasedStatus()
            }
        }
    }
    
    // MARK: - Subscription Status Listener
    private func listenForSubscriptionStatusUpdates() -> Task<Void, Never> {
        Task {
            for await _ in Product.SubscriptionInfo.Status.updates {
                await self.updatePurchasedStatus()
            }
        }
    }
}

// MARK: - Pro Plan Summary

/// A snapshot of the Pro plan the user holds, derived from their current App Store entitlement.
struct ProPlan: Equatable {
    
    enum Tier: Equatable {
        case monthly
        case annual
        case lifetime
        
        /// Maps a store product ID to a tier using the same naming the paywall relies on.
        init?(productID: String) {
            if productID.contains("monthly") {
                self = .monthly
            } else if productID.contains("annual") {
                self = .annual
            } else if productID.contains("lifetime") {
                self = .lifetime
            } else {
                return nil
            }
        }
        
        var displayName: String {
            switch self {
            case .monthly: return "Monthly"
            case .annual: return "Annual"
            case .lifetime: return "Lifetime"
            }
        }
    }
    
    /// Renewal details for an auto-renewable plan.
    struct Subscription: Equatable {
        let tier: Tier
        let expirationDate: Date?
        let willAutoRenew: Bool
        let isInFreeTrial: Bool
        let isInGracePeriod: Bool
    }
    
    let tier: Tier
    /// Store product ID of the plan, used by the paywall to mark it as the current plan.
    let productID: String
    /// End of the current billing period. `nil` for the one-time Lifetime purchase.
    let expirationDate: Date?
    let willAutoRenew: Bool
    let isInFreeTrial: Bool
    let isInGracePeriod: Bool
    /// A Monthly/Annual subscription that is still active even though the user owns Lifetime.
    /// Apple keeps billing it until the user cancels, so Settings warns about it.
    let overlappingSubscription: Subscription?
    
    var isLifetime: Bool {
        tier == .lifetime
    }
    
    /// Apple's manage sheet only covers auto-renewable plans, so it is offered whenever one is active.
    var canManage: Bool {
        !isLifetime || overlappingSubscription != nil
    }
    
    /// Warning shown to Lifetime owners who still have a subscription running.
    var overlappingSubscriptionNotice: String? {
        guard let subscription = overlappingSubscription else { return nil }
        let name = subscription.tier.displayName
        guard let date = subscription.expirationDate?.formatted(date: .abbreviated, time: .omitted) else {
            return subscription.willAutoRenew
                ? "Your \(name) subscription still renews. Cancel it to avoid being charged."
                : "Your \(name) subscription is ending."
        }
        return subscription.willAutoRenew
            ? "Your \(name) subscription still renews on \(date). Cancel it to avoid being charged."
            : "Your \(name) subscription ends on \(date)."
    }
    
    /// One-line status shown beneath the plan name in Settings.
    var statusText: String {
        if isLifetime {
            return "Paid once, yours forever."
        }
        
        guard let expirationDate else {
            return willAutoRenew ? "Active." : "Auto-renew is off."
        }
        let date = expirationDate.formatted(date: .abbreviated, time: .omitted)
        
        if isInGracePeriod {
            return "Payment issue. Update your billing to keep Pro."
        }
        if isInFreeTrial {
            return willAutoRenew
                ? "Free trial. First payment on \(date)."
                : "Free trial ends \(date). Won't renew."
        }
        return willAutoRenew
            ? "Renews on \(date)."
            : "Expires on \(date). Won't renew."
    }
}

// MARK: - Subscription Period Formatting

extension Product.SubscriptionPeriod {
    
    /// Singular unit name, e.g. "day", "month".
    private var unitName: String {
        switch unit {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return "period"
        }
    }
    
    /// Human-readable length, e.g. "3 days", "1 month".
    var displayText: String {
        value == 1 ? "1 \(unitName)" : "\(value) \(unitName)s"
    }
    
    /// Title-style length for button labels, e.g. "3-Day" in "Start 3-Day Free Trial".
    var hyphenatedTitle: String {
        "\(value)-\(unitName.capitalized)"
    }
    
    /// Short per-period suffix, e.g. "/month", "/year".
    var perUnitSuffix: String {
        "/\(unitName)"
    }
}
