import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack {
            // Starry background
            StarryBackground()
            
            NavigationView {
                VStack(spacing: 50) {
                    Spacer()
                    
                    // Header
                    VStack(spacing: 30) {
                        // App icon
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                        }
                        
                        // App name
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Text("envol")
                                    .font(.system(size: 36, weight: .bold, design: .default))
                                    .foregroundColor(.white)
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.green)
                            }
                            
                            Text("Join the movement to keep our community clean through exciting gameplay")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    
                    Spacer()
                    
                    // Login Button
                    VStack(spacing: 25) {
                        if authManager.isLoading {
                            VStack(spacing: 15) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .green))
                                Text("Signing in...")
                                    .font(.system(size: 18, weight: .medium, design: .default))
                                    .foregroundColor(.gray)
                            }
                        } else {
                            Button(action: {
                                // Add a longer delay to ensure window is fully active
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    // Double-check app is active before login
                                    if UIApplication.shared.applicationState == .active {
                                        authManager.login()
                                    } else {
                                        print("App not active, retrying...")
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            authManager.login()
                                        }
                                    }
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 20, weight: .medium, design: .default))
                                    Text("Sign In / Sign Up")
                                        .font(.system(size: 18, weight: .semibold, design: .default))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .padding(.horizontal, 40)
                            
                            Text("Sign in with Auth0 to get started")
                                .font(.system(size: 14, weight: .medium, design: .default))
                                .foregroundColor(.gray)
                        }
                        
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium, design: .default))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                    
                    // Footer
                    VStack(spacing: 12) {
                        Text("By signing in, you agree to our")
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 5) {
                            Button("Terms of Service") {
                                // TODO: Show terms
                            }
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .foregroundColor(.blue)
                            
                            Text("and")
                                .font(.system(size: 12, weight: .medium, design: .default))
                                .foregroundColor(.gray)
                            
                            Button("Privacy Policy") {
                                // TODO: Show privacy policy
                            }
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.bottom, 30)
                }
                .navigationBarHidden(true)
            }
        }
    }
}



#Preview {
    LoginView()
} 