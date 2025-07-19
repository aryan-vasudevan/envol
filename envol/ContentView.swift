//
//  ContentView.swift
//  envol
//
//  Created by Aryan Vasudevan on 2025-07-19.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var authManager = AuthManager()
    @State private var showingCamera = false
    @State private var beforeImage: UIImage?
    @State private var afterImage: UIImage?
    @State private var currentStep: CleanupStep = .before
    @State private var showingImageProcessor = false
    
    enum CleanupStep {
        case before
        case after
    }
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                mainAppView
            } else {
                LoginView()
            }
        }
        .environmentObject(authManager)
    }
    
    private var mainAppView: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header with user info
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Welcome,")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(authManager.displayName)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            authManager.logout()
                        }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                    
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Clean Community")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Help keep our community clean with AI-powered trash detection")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Progress indicator
                HStack(spacing: 20) {
                    StepIndicator(
                        step: 1,
                        title: "Before",
                        isCompleted: beforeImage != nil,
                        isCurrent: currentStep == .before
                    )
                    
                    StepIndicator(
                        step: 2,
                        title: "After",
                        isCompleted: afterImage != nil,
                        isCurrent: currentStep == .after
                    )
                }
                .padding(.horizontal)
                
                // Image previews
                HStack(spacing: 20) {
                    ImagePreviewCard(
                        title: "Before",
                        image: beforeImage,
                        placeholder: "camera.fill"
                    )
                    
                    ImagePreviewCard(
                        title: "After",
                        image: afterImage,
                        placeholder: "camera.fill"
                    )
                }
                .padding(.horizontal)
                
                // Action buttons
                VStack(spacing: 15) {
                    if currentStep == .before {
                        Button(action: {
                            showingCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take Before Photo")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(!cameraManager.isCameraAvailable)
                    } else {
                        Button(action: {
                            showingCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take After Photo")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                        .disabled(!cameraManager.isCameraAvailable)
                    }
                    
                    if beforeImage != nil && afterImage != nil {
                        Button(action: {
                            showingImageProcessor = true
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Process Cleanup")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                        }
                    }
                    
                    if beforeImage != nil || afterImage != nil {
                        Button(action: {
                            resetWorkflow()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Reset")
                            }
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCamera) {
            if cameraManager.isCameraAvailable {
                CameraView(
                    cameraManager: cameraManager,
                    onImageCaptured: { image in
                        if currentStep == .before {
                            beforeImage = image
                            currentStep = .after
                        } else {
                            afterImage = image
                        }
                        showingCamera = false
                    }
                )
            } else {
                VStack {
                    Text("Camera Not Available")
                        .font(.title2)
                        .padding()
                    Text("Please run this app on a physical device with camera access.")
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Close") {
                        showingCamera = false
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingImageProcessor) {
            if let before = beforeImage, let after = afterImage {
                ImageProcessorView(
                    beforeImage: before,
                    afterImage: after
                )
            } else {
                VStack {
                    Text("Images Not Available")
                        .font(.title2)
                        .padding()
                    Button("Close") {
                        showingImageProcessor = false
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                cameraManager.checkCameraPermission()
            }
            #else
            cameraManager.checkCameraPermission()
            #endif
        }
    }
    
    private func resetWorkflow() {
        beforeImage = nil
        afterImage = nil
        currentStep = .before
    }
}

struct StepIndicator: View {
    let step: Int
    let title: String
    let isCompleted: Bool
    let isCurrent: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : (isCurrent ? Color.blue : Color.gray.opacity(0.3)))
                    .frame(width: 40, height: 40)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                } else {
                    Text("\(step)")
                        .foregroundColor(isCurrent ? .white : .gray)
                        .fontWeight(.bold)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(isCurrent ? .primary : .secondary)
        }
    }
}

struct ImagePreviewCard: View {
    let title: String
    let image: UIImage?
    let placeholder: String
    
    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 150)
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 150)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    Image(systemName: placeholder)
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ContentView()
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDisplayName("Clean Community App")
    }
}
#endif
