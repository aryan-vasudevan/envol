//
//  envolApp.swift
//  envol
//
//  Created by Aryan Vasudevan on 2025-07-19.
//

import SwiftUI
import Auth0
import FirebaseCore

@main
struct envolApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var creditsManager = CreditsManager()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(creditsManager)
                .onOpenURL { url in
                    print("onOpenURL called with: \(url)")
                    print("URL scheme: \(url.scheme ?? "nil")")
                    print("URL host: \(url.host ?? "nil")")
                    print("URL path: \(url.path)")
                    WebAuthentication.resume(with: url)
                }
        }
    }
}
