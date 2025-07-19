import Foundation
import Auth0

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let domain = "dev-c3zpevnub2nb8x4v.ca.auth0.com"
    private let clientId = "O5NIMegeHfuFjhhlGtbqgcQo69Q7bIfz"
    
    init() {
        // Don't check authentication status on init - let user manually login
        // This prevents the app from trying to start Auth0 web flow immediately
    }
    
    func login() {
        isLoading = true
        errorMessage = nil

        // Force reset Auth0 state completely
        let webAuth = Auth0.webAuth(clientId: clientId, domain: domain)
        
        // First clear session
        webAuth.clearSession { _ in
            // Add a small delay to ensure the clear is processed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Clear session again to be sure
                webAuth.clearSession { _ in
                    // Now start the login process
                    webAuth
                        .scope("openid profile email")
                        .audience("https://\(self.domain)/userinfo")
                        .start { result in
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