//
//  AdMobBannerView.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-11-05.
//

import SwiftUI
import GoogleMobileAds

struct AdMobBannerView: UIViewRepresentable {
    let adUnitID: String
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        let scenes = UIApplication.shared.connectedScenes
        if let windowScene = scenes.first(where: { $0 is UIWindowScene }) as? UIWindowScene {
            banner.rootViewController = windowScene.windows.first?.rootViewController
        }
        banner.load(Request())
        return banner
    }
    func updateUIView(_ uiView: BannerView, context: Context) {}
}

//import SwiftUI
//import GoogleMobileAds
//
//struct AdMobBannerView: UIViewControllerRepresentable {
//    /// Use the test ad unit ID provided by Google for development.
//    /// Replace with your production Ad Unit ID from the AdMob console.
//    let adUnitID: String
//    
//    func makeUIViewController(context: Context) -> UIViewController {
//        let viewController = UIViewController()
//        let bannerView = BannerView()
//        
//        bannerView.adUnitID = adUnitID
//        bannerView.rootViewController = viewController
//        
//        // Add the bannerView to the view controller hierarchy
//        viewController.view.addSubview(bannerView)
//        
//        // Setup Auto Layout constraints to pin the ad to the edges
//        bannerView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            bannerView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
//            bannerView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
//            bannerView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
//            bannerView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor)
//        ])
//        
//        return viewController
//    }
//    
//    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
//        // Dynamically scale the banner size to match the frame width allocated by SwiftUI
//        guard let bannerView = uiViewController.view.subviews.first as? BannerView else { return }
//        
//        let frameWidth = uiViewController.view.frame.width
//        if frameWidth > 0 {
//            // Requests an adaptive banner size based on current layout width
//            bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(frameWidth)
//            bannerView.load(GADRequest())
//        }
//    }
//}
