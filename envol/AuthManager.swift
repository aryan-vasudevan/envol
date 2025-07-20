import Foundation
import Auth0
import UIKit
import FirebaseDatabase

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var profilePictureURL: URL?
    
    private let domain = "dev-c3zpevnub2nb8x4v.ca.auth0.com"
    private let clientId = "LmJdLy5MAuRA2AWsUVBqrTo96Oq0RSUp"
    private let databaseRef = Database.database().reference()
    
    init() {
        // Don't check authentication status on init - let user manually login
        // This prevents the app from trying to start Auth0 web flow immediately
    }
    
    func login() {
        print("Auth0 login called")
        isLoading = true
        errorMessage = nil

        let webAuth = Auth0.webAuth(clientId: clientId, domain: domain)
        webAuth
            .scope("openid profile email")
            .audience("https://\(self.domain)/userinfo")
            .start { result in
                Task { @MainActor in
                    self.isLoading = false
                    
                    switch result {
                    case .success(let credentials):
                        // Get user profile
                        Auth0
                            .authentication(clientId: self.clientId, domain: self.domain)
                            .userInfo(withAccessToken: credentials.accessToken)
                            .start { profileResult in
                                Task { @MainActor in
                                    switch profileResult {
                                    case .success(let profile):
                                        self.isAuthenticated = true
                                        self.displayName = profile.name ?? profile.nickname ?? "User"
                                        self.email = profile.email ?? ""
                                        if let pictureURL = profile.picture {
                                            self.profilePictureURL = pictureURL
                                        }
                                        print("Auth0 login successful for user: \(self.displayName) (\(self.email))")
                                        // Initialize user in database
                                        self.initializeUserInDatabase()
                                    case .failure(let error):
                                        self.errorMessage = "Failed to get user profile: \(error.localizedDescription)"
                                        print("Auth0 profile error: \(error)")
                                    }
                                }
                            }
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        print("Auth0 login error: \(error)")
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
                        self.displayName = ""
                        self.email = ""
                        self.profilePictureURL = nil
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
    }
    
    private func initializeUserInDatabase() {
        guard !email.isEmpty else {
            print("AuthManager: Cannot initialize user - email is empty")
            return
        }
        
        // Create a safe key from email (same as CreditsManager)
        let userKey = email.replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "@", with: "_")
            .replacingOccurrences(of: "#", with: "_")
            .replacingOccurrences(of: "$", with: "_")
            .replacingOccurrences(of: "[", with: "_")
            .replacingOccurrences(of: "]", with: "_")
        
        let userRef = databaseRef.child("users").child(userKey)
        
        // Check if user already exists
        userRef.observeSingleEvent(of: .value) { snapshot in
            if !snapshot.exists() {
                // User doesn't exist, create with default values
                let userData: [String: Any] = [
                    "credits": 0, // New users start with 0 credits
                    "bestScore": 0,
                    "bestRank": "Bronze",
                    "displayName": self.displayName,
                    "email": self.email,
                    "dateCreated": ServerValue.timestamp()
                ]
                
                userRef.setValue(userData) { error, _ in
                    if let error = error {
                        print("AuthManager: Error creating user in database: \(error.localizedDescription)")
                    } else {
                        print("AuthManager: Successfully created new user in database: \(self.email)")
                    }
                }
            } else {
                print("AuthManager: User already exists in database: \(self.email)")
            }
        }
    }
} 