import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 20) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Clean Community")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Join the movement to keep our community clean")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Login Button
                VStack(spacing: 20) {
                    if authManager.isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Signing in...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    } else {
                        Button(action: {
                            authManager.login()
                        }) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                Text("Sign In / Sign Up")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        Text("Sign in with Auth0 to get started")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Footer
                VStack(spacing: 10) {
                    Text("By signing in, you agree to our")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 5) {
                        Button("Terms of Service") {
                            // TODO: Show terms
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        
                        Text("and")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Privacy Policy") {
                            // TODO: Show privacy policy
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
        .environmentObject(authManager)
    }
}

#Preview {
    LoginView()
} 