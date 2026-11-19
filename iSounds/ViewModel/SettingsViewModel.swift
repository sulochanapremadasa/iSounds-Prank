//
//  SettingsViewModel.swift
//  iSounds
//
//  Created by Sulochana Premadasa on 2026-10-26.
//

import Foundation
import Combine
import SwiftUI

class SettingsViewModel: ObservableObject{
    
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    @Published var showContactPopup: Bool = false
    
    let appName: String = "iSound"
    let contactEmail: String = "support@aplivox.com"
    let emailSubject: String = "iSounds - Feedback"
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    func openMailApp() {

//        if let url = URL(string: "mailto:\(contactEmail)") {
//            UIApplication.shared.open(url)
//        }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = contactEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: emailSubject)
        ]
        if let emailURL = components.url {
            if UIApplication.shared.canOpenURL(emailURL) {
                UIApplication.shared.open(emailURL)
            }
        }
        showContactPopup = false
    }
}
