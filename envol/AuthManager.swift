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
        print("Demo Auth0 login called")
        isLoading = true
        errorMessage = nil

        let webAuth = Auth0.webAuth(clientId: clientId, domain: domain)
        webAuth
            .scope("openid profile email")
            .audience("https://\(self.domain)/userinfo")
            .start { result in
                print("Auth0 login completed with result (demo mode)")
                Task { @MainActor in
                    self.isLoading = false
                    // Always succeed, no matter what
                    self.isAuthenticated = true
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