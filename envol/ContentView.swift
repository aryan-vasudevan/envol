//
//  ContentView.swift
//  envol
//
//  Created by Aryan Vasudevan on 2025-07-19.
//

import SwiftUI
import AVFoundation

struct PendingPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                TabView(selection: $selectedTab) {
                    HomePage()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(0)
                    GamePage()
                        .tabItem {
                            Label("Game", systemImage: "gamecontroller.fill")
                        }
                        .tag(1)
                }
            } else {
                LoginView()
            }
        }
    }
}

struct HomePage: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var cameraManager = CameraManager()
    @State private var showingCamera = false
    @State private var beforeImage: UIImage?
    @State private var afterImage: UIImage?
    @State private var currentStep: CleanupStep = .before
    @State private var showingImageProcessor = false
    @State private var geminiValidationResult: String? = nil
    @State private var isProcessing: Bool = false
    @State private var validationHighlight: Color? = nil
    @State private var creditsMessage: String? = nil
    @State private var showCreditsMessage: Bool = false
    @State private var pendingImage: PendingPhoto? = nil
    @State private var geminiTrashCount: Int = 0
    
    enum CleanupStep {
        case before
        case after
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                welcomeCreditsBox
                exitButtonRow
                mainContent
                Spacer()
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Text("envol")
                        .font(.headline)
                        .fontWeight(.bold)
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                    Text("Home")
                        .font(.headline)
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            if cameraManager.isCameraAvailable {
                CameraView { image in
                    if currentStep == .before {
                        beforeImage = image
                        currentStep = .after
                    } else if currentStep == .after {
                        afterImage = image
                    }
                    showingCamera = false
                }
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

    private var welcomeCreditsBox: some View {
        HStack {
            Text("Welcome, Aryan!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Spacer()
            Text("Credits: 0.0")
                .font(.title3)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.8))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var exitButtonRow: some View {
        HStack {
            Spacer()
            Button(action: {
                authManager.logout()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.title2)
                        .foregroundColor(.red)
                    Text("Sign Out")
                        .font(.body)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal)
    }

    private var mainContent: some View {
        VStack(spacing: 30) {
            // Progress indicator
            HStack(spacing: 20) {
                StepIndicator(
                    step: 1,
                    title: "Before",
                    isCompleted: beforeImage != nil,
                    isCurrent: currentStep == .before
                )
                .foregroundColor(validationHighlight ?? .green)
                StepIndicator(
                    step: 2,
                    title: "After",
                    isCompleted: afterImage != nil,
                    isCurrent: currentStep == .after
                )
                .foregroundColor(validationHighlight ?? .green)
            }
            .padding(.horizontal)
            // Image previews
            HStack(spacing: 20) {
                ImagePreviewCard(
                    title: "Before",
                    image: beforeImage,
                    placeholder: "camera.fill"
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(validationHighlight ?? .clear, lineWidth: 4)
                )
                ImagePreviewCard(
                    title: "After",
                    image: afterImage,
                    placeholder: "camera.fill"
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(validationHighlight ?? .clear, lineWidth: 4)
                )
            }
            .padding(.horizontal)
            // Action buttons and workflow
            actionButtons
            // Spinner/result/credits logic as before...
            if beforeImage != nil && afterImage != nil {
                VStack(spacing: 16) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(.systemGray)))
                            .scaleEffect(2.0)
                        Text("Processing cleanup...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else if let result = geminiValidationResult {
                        Text(result)
                            .font(.headline)
                            .foregroundColor(validationHighlight ?? .primary)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background((validationHighlight ?? .clear).opacity(0.1))
                            .cornerRadius(12)
                            .transition(.opacity)
                    }
                }
                .padding()
                .onAppear {
                    if !isProcessing && geminiValidationResult == nil {
                        validateCleanupWithGemini()
                    }
                }
            } else {
                latestCleanupsBox
            }
            if let creditsMessage = creditsMessage, showCreditsMessage {
                Text(creditsMessage)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(validationHighlight ?? .primary)
                    .padding()
                    .background((validationHighlight ?? .clear).opacity(0.2))
                    .cornerRadius(16)
                    .transition(.opacity)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 15) {
            if beforeImage == nil {
                Button(action: {
                    currentStep = .before
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
                .disabled(isProcessing)
            } else if afterImage == nil {
                Button(action: {
                    currentStep = .after
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
                .disabled(isProcessing)
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
    }

    private var latestCleanupsBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Latest Cleanups")
                .font(.headline)
                .padding(.bottom, 2)
            // Placeholder for future Firebase-powered list
            ForEach(0..<3) { i in
                HStack {
                    Image(systemName: "person.crop.circle")
                        .foregroundColor(.green)
                    Text("User \(i+1) cleaned up trash!")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("Just now")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.8))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private func resetWorkflow() {
        beforeImage = nil
        afterImage = nil
        currentStep = .before
        geminiValidationResult = nil
        isProcessing = false
    }

    private func validateCleanupWithGemini() {
        guard let before = beforeImage, let after = afterImage else { return }
        isProcessing = true
        geminiValidationResult = nil
        validationHighlight = nil
        creditsMessage = nil
        showCreditsMessage = false
        geminiTrashCount = 0
        Task {
            let result = await GeminiAPI.validateCleanup(before: before, after: after)
            await MainActor.run {
                geminiValidationResult = result
                isProcessing = false
                let lower = result.lowercased()
                // Parse trash_count from Gemini response
                let trashCount = parseTrashCount(from: result)
                geminiTrashCount = trashCount
                if lower.contains("valid") && !lower.contains("invalid") && !(lower.contains("perspective") || lower.contains("angle") || lower.contains("view") || lower.contains("retake")) {
                    validationHighlight = .green
                    creditsMessage = "+\(geminiTrashCount) credits added"
                    showCreditsMessage = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            showCreditsMessage = false
                            resetWorkflow()
                            validationHighlight = nil
                        }
                    }
                } else if lower.contains("invalid") {
                    validationHighlight = .red
                    creditsMessage = "No credits added"
                    showCreditsMessage = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            showCreditsMessage = false
                            resetWorkflow()
                            validationHighlight = nil
                        }
                    }
                } else if lower.contains("perspective") || lower.contains("angle") || lower.contains("view") || lower.contains("retake") {
                    validationHighlight = .yellow
                    creditsMessage = "Please take a more accurate after image"
                    showCreditsMessage = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            showCreditsMessage = false
                            validationHighlight = nil
                            afterImage = nil
                            currentStep = .after
                        }
                    }
                } else {
                    validationHighlight = .primary
                    creditsMessage = nil
                    showCreditsMessage = false
                }
            }
        }
    }

    private func parseTrashCount(from response: String) -> Int {
        // Look for 'trash_count: X' in the response
        let pattern = "trash_count: \\d+"
        if let range = response.range(of: pattern, options: .regularExpression) {
            let match = String(response[range])
            if let count = Int(match.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") {
                return count
            }
        }
        return 0
    }
}

struct CleanupPage: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Upload Before & After Photos")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Take or select your before and after photos to earn credits!")
                    .font(.body)
                    .foregroundColor(.secondary)
                // TODO: Add photo upload UI and logic
                Spacer()
                Text("(Future) Trash metrics and Roboflow results will appear here.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .navigationTitle("Cleanup")
        }
    }
}

struct GamePage: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Game Coming Soon!")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Use your credits as currency in the upcoming game.")
                    .font(.body)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Text("envol")
                            .font(.headline)
                            .fontWeight(.bold)
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                        Text("Game")
                            .font(.headline)
                    }
                }
            }
        }
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
