import Foundation
import Auth0
import UIKit

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let domain = "dev-c3zpevnub2nb8x4v.ca.auth0.com"
    private let clientId = "LmJdLy5MAuRA2AWsUVBqrTo96Oq0RSUp"
    
    init() {
        // Don't check authentication status on init - let user manually login
        // This prevents the app from trying to start Auth0 web flow immediately
    }
    
    func login() {
        print("AuthManager.login() called")
        
        // Check if app is active before proceeding
        guard UIApplication.shared.applicationState == .active else {
            print("App not active, cannot start Auth0 login")
            errorMessage = "App not ready. Please try again."
            return
        }
        
        print("App is active, starting Auth0 login...")
        isLoading = true
        errorMessage = nil

        // Force reset Auth0 state completely
        let webAuth = Auth0.webAuth(clientId: clientId, domain: domain)
        
        print("Created webAuth instance, clearing session...")
        
        // First clear session
        webAuth.clearSession { _ in
            print("Session clear completed, starting login...")
            // Now start the login process
            webAuth
                .scope("openid profile email")
                .audience("https://\(self.domain)/userinfo")
                .start { result in
                    print("Auth0 login completed with result")
                    Task { @MainActor in
                        self.isLoading = false
                        switch result {
                        case .success(let credentials):
                            print("✅ Login successful! Access token: \(credentials.accessToken.prefix(20))...")
                            self.isAuthenticated = true
                        case .failure(let error):
                            print("❌ Login failed: \(error.localizedDescription)")
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
        }
    }
    
    func logout() {
        Auth0
            .webAuth(clientId: clientId, domain: domain)
            .clearSession { result in
                Task { @MainActor in
                    switch result {
                    case .success:
                        self.isAuthenticated = false
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
    }
    
    // Get user's display name
    var displayName: String {
        return "User"
    }
    
    // Get user's email
    var email: String {
        return ""
    }
    
    // Get user's profile picture URL
    var profilePictureURL: URL? {
        return nil
    }
} 