//
//  ContentView.swift
//  envol
//
//  Created by Aryan Vasudevan on 2025-07-19.
//

import SwiftUI
import AVFoundation
import CoreMotion
import SceneKit
import UIKit

struct PendingPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct CleanupEntry: Identifiable {
    let id = UUID()
    let name: String
    let item: String
    let color: Color
    let timestamp: Date
}

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0
    @State private var isPlaying = false
    
    var body: some View {
        ZStack {
            // Starry background for all pages
            StarryBackground()
            
            Group {
                if authManager.isAuthenticated {
                    if isPlaying {
                        GamePage(isPlaying: $isPlaying)
                    } else {
                        TabView(selection: $selectedTab) {
                            HomePage()
                                .tabItem {
                                    Label("Home", systemImage: "house.fill")
                                }
                                .tag(0)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                            
                            MetricsPage()
                                .tabItem {
                                    Label("Metrics", systemImage: "chart.bar.fill")
                                }
                                .tag(1)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            
                            GamePage(isPlaying: $isPlaying)
                                .tabItem {
                                    Label("Game", systemImage: "gamecontroller.fill")
                                }
                                .tag(2)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            
                            // Sign out tab
                            SignOutTabView(selectedTab: $selectedTab)
                                .tabItem {
                                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                }
                                .tag(3)
                        }
                        .animation(.easeInOut(duration: 0.3), value: selectedTab)
                        .accentColor(.blue) // This will make the selected tab blue
                        .onAppear {
                            // Customize tab bar appearance
                            let appearance = UITabBarAppearance()
                            appearance.configureWithOpaqueBackground()
                            appearance.backgroundColor = UIColor.systemBackground
                            
                            // Set the default selected item color to blue
                            appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
                            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
                            
                            // Set the default unselected item color to gray
                            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
                            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
                            
                            UITabBar.appearance().standardAppearance = appearance
                            UITabBar.appearance().scrollEdgeAppearance = appearance
                            
                            // Start continuous monitoring to keep sign out tab red
                            startTabBarColorMonitoring()
                        }
                    }
                } else {
                    LoginView()
                }
            }
        }
    }
}

struct HomePage: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var creditsManager: CreditsManager
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
    
    // Latest cleanups data
    @State private var latestCleanups: [CleanupEntry] = []
    @State private var cleanupTimer: Timer?
    
    // Animation states
    @State private var animateHeader = false
    @State private var animateWelcomeBox = false
    @State private var animateStepIndicators = false
    @State private var animateImageCards = false
    @State private var animateButtons = false
    
    enum CleanupStep {
        case before
        case after
    }
    
    // Random data for cleanups
    private let randomNames = [
        "Lara", "Alex", "Jordan", "Sam", "Taylor", "Casey", "Riley", "Quinn",
        "Morgan", "Avery", "Blake", "Cameron", "Drew", "Emery", "Finley", "Gray"
    ]
    
    private let randomItems = [
        "some wrappers", "plastic bottles", "paper waste", "metal cans", "glass items",
        "food containers", "coffee cups", "takeout boxes", "soda cans", "water bottles",
        "snack bags", "candy wrappers", "straws", "utensils", "napkins", "receipts"
    ]
    
    private let randomColors: [Color] = [
        .green, .blue, .orange, .purple, .pink, .red, .yellow, .cyan, .mint, .indigo
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                envolHeader(title: "Home")
                    .opacity(animateHeader ? 1 : 0)
                    .offset(y: animateHeader ? 0 : -20)
                
                welcomeCreditsBox
                    .opacity(animateWelcomeBox ? 1 : 0)
                    .offset(y: animateWelcomeBox ? 0 : 20)
                    .scaleEffect(animateWelcomeBox ? 1 : 0.9)
                
                mainContent
                Spacer()
            }
            

            .padding()
            .background(Color.clear)
        }
        .background(Color.clear)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EmptyView() }
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
                        .font(.system(size: 20, weight: .semibold, design: .default))
                        .padding()
                    Text("Please run this app on a physical device with camera access.")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Close") {
                        showingCamera = false
                    }
                    .font(.system(size: 16, weight: .medium, design: .default))
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
                        .font(.system(size: 20, weight: .semibold, design: .default))
                        .padding()
                    Button("Close") {
                        showingImageProcessor = false
                    }
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .padding()
                }
            }
        }
        .onAppear {
            // Reset animation states
            animateHeader = false
            animateWelcomeBox = false
            animateStepIndicators = false
            animateImageCards = false
            animateButtons = false
            
            // Trigger animations with delays
            withAnimation(.easeOut(duration: 0.6)) {
                animateHeader = true
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateWelcomeBox = true
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                animateStepIndicators = true
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                animateImageCards = true
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
                animateButtons = true
            }
            
            // Setup user credits when page appears
            setupUserCredits()
            
            // Start the cleanup timer
            startCleanupTimer()
            
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                cameraManager.checkCameraPermission()
            }
            #else
            cameraManager.checkCameraPermission()
            #endif
        }
        .onDisappear {
            // Stop the cleanup timer when leaving the page
            stopCleanupTimer()
        }
        .onChange(of: authManager.isAuthenticated) { _ in
            setupUserCredits()
        }
    }

    private var welcomeCreditsBox: some View {
        HStack {
            Text("Welcome, \(authManager.displayName.isEmpty ? "User" : authManager.displayName)!")
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundColor(.primary)
            Spacer()
            Text("\(creditsManager.credits) 🍃")
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.8))
        .cornerRadius(16)
        .padding(.horizontal)
    }


    
    // Monitor authentication state and set up user in CreditsManager
    private func setupUserCredits() {
        if authManager.isAuthenticated && !authManager.email.isEmpty {
            creditsManager.setUser(email: authManager.email)
        }
    }
    
    // Helper function to format time ago
    private func timeAgoString(from date: Date) -> String {
        let timeInterval = Date().timeIntervalSince(date)
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
    
    // Add a new random cleanup entry
    private func addRandomCleanup() {
        let randomName = randomNames.randomElement() ?? "User"
        let randomItem = randomItems.randomElement() ?? "trash"
        let randomColor = randomColors.randomElement() ?? .green
        
        let newEntry = CleanupEntry(
            name: randomName,
            item: randomItem,
            color: randomColor,
            timestamp: Date()
        )
        
        withAnimation(.easeInOut(duration: 0.5)) {
            latestCleanups.insert(newEntry, at: 0)
            // Keep only the latest 5 entries
            if latestCleanups.count > 5 {
                latestCleanups = Array(latestCleanups.prefix(5))
            }
        }
    }
    
    // Start the cleanup timer
    private func startCleanupTimer() {
        cleanupTimer?.invalidate()
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 1...3), repeats: false) { _ in
            addRandomCleanup()
            // Schedule next update
            startCleanupTimer()
        }
    }
    
    // Stop the cleanup timer
    private func stopCleanupTimer() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }

    private var mainContent: some View {
        VStack(spacing: 24) {
            // Combined progress and photo capture box
            VStack(spacing: 20) {
                Text("Cleanup Workflow")
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundColor(.primary)
                
                // Progress indicators
                HStack(spacing: 20) {
                    StepIndicator(
                        step: 1,
                        title: "Before",
                        isCompleted: beforeImage != nil,
                        isCurrent: currentStep == .before
                    )
                    .foregroundColor(validationHighlight ?? .green)
                    .opacity(animateStepIndicators ? 1 : 0)
                    .offset(y: animateStepIndicators ? 0 : 30)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateStepIndicators)
                    
                    StepIndicator(
                        step: 2,
                        title: "After",
                        isCompleted: afterImage != nil,
                        isCurrent: currentStep == .after
                    )
                    .foregroundColor(validationHighlight ?? .green)
                    .opacity(animateStepIndicators ? 1 : 0)
                    .offset(y: animateStepIndicators ? 0 : 30)
                    .animation(.easeOut(duration: 0.6).delay(0.5), value: animateStepIndicators)
                }
                
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
                    .opacity(animateImageCards ? 1 : 0)
                    .offset(x: animateImageCards ? 0 : -50)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: animateImageCards)
                    
                    ImagePreviewCard(
                        title: "After",
                        image: afterImage,
                        placeholder: "camera.fill"
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(validationHighlight ?? .clear, lineWidth: 4)
                    )
                    .opacity(animateImageCards ? 1 : 0)
                    .offset(x: animateImageCards ? 0 : 50)
                    .animation(.easeOut(duration: 0.8).delay(0.7), value: animateImageCards)
                }
            }
            .padding()
            .background(Color(.systemGray6).opacity(0.8))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Action buttons box
            VStack(spacing: 16) {
                Text("Actions")
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundColor(.primary)
                
                actionButtons
                    .opacity(animateButtons ? 1 : 0)
                    .offset(y: animateButtons ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: animateButtons)
            }
            .padding()
            .background(Color(.systemGray6).opacity(0.8))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Spinner/result/credits logic as before...
            if beforeImage != nil && afterImage != nil {
                VStack(spacing: 16) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(.systemGray)))
                            .scaleEffect(2.0)
                        Text("Processing cleanup...")
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(.secondary)
                    } else if let result = geminiValidationResult {
                        Text(result)
                            .font(.system(size: 18, weight: .semibold, design: .default))
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
                    .opacity(animateButtons ? 1 : 0)
                    .offset(y: animateButtons ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(1.0), value: animateButtons)
                
                // Add bottom spacing to prevent overlap with tab bar
                Spacer(minLength: 20)
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
            
            if latestCleanups.isEmpty {
                // Show placeholder entries while loading
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
            } else {
                // Show dynamic entries
                ForEach(latestCleanups.prefix(3)) { entry in
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(entry.color)
                        Text("\(entry.name) cleaned up \(entry.item)!")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(timeAgoString(from: entry.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
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
                    creditsManager.addCredits(geminiTrashCount)
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

struct MetricsPage: View {
    @State private var animateCharts = false
    @State private var animateDonut = false
    
    // Animation states for page entry
    @State private var animateHeader = false
    @State private var animateStats = false
    @State private var animateWeeklyChart = false
    @State private var animateBreakdown = false
    @State private var animateActivity = false
    
    // Sample data
    private let weeklyData = [
        ("Mon", 12), ("Tue", 8), ("Wed", 15), ("Thu", 22), 
        ("Fri", 18), ("Sat", 25), ("Sun", 14)
    ]
    
    private let trashTypeData = [
        ("Plastic", 35, Color.blue),
        ("Paper", 28, Color.green),
        ("Metal", 20, Color.orange),
        ("Glass", 12, Color.purple),
        ("Other", 5, Color.red)
    ]
    
    private let totalCollections = 118
    private let weeklyGoal = 100
    
    // Leaderboard data
    private let leaderboardData = [
        ("Lara Chen", 142, false),
        ("Aryan Vasudevan", 118, true),  // Your name highlighted
        ("Alex Rodriguez", 95, false),
        ("Jordan Smith", 87, false),
        ("Sam Johnson", 76, false),
        ("Taylor Kim", 65, false),
        ("Casey Wong", 54, false),
        ("Riley Patel", 43, false)
    ]
    
    @State private var showAllFriends = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    envolHeader(title: "Metrics")
                        .opacity(animateHeader ? 1 : 0)
                        .offset(y: animateHeader ? 0 : -20)
                    
                    // Leaderboard
                    leaderboard
                        .frame(maxWidth: .infinity)
                    
                    // Header stats
                    headerStats
                        .frame(maxWidth: .infinity)
                    
                    // Weekly progress chart
                    weeklyProgressChart
                        .frame(maxWidth: .infinity)
                    
                    // Trash type breakdown
                    trashTypeBreakdown
                        .frame(maxWidth: .infinity)
                    
                    // Recent activity (shortened)
                    recentActivity
                        .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .background(Color.clear)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { EmptyView() }
            .onAppear {
                // Reset animation states
                animateHeader = false
                animateStats = false
                animateWeeklyChart = false
                animateBreakdown = false
                animateActivity = false
                animateCharts = false
                animateDonut = false
                
                // Trigger page entry animations with delays
                withAnimation(.easeOut(duration: 0.6)) {
                    animateHeader = true
                }
                
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    animateStats = true
                }
                
                withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                    animateWeeklyChart = true
                }
                
                withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                    animateBreakdown = true
                }
                
                withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
                    animateActivity = true
                }
                
                // Trigger chart animations with additional delays
                withAnimation(.easeOut(duration: 1.0).delay(1.0)) {
                    animateCharts = true
                }
                withAnimation(.easeOut(duration: 1.5).delay(1.3)) {
                    animateDonut = true
                }
            }
        }
    }
    
    private var headerStats: some View {
        VStack(spacing: 16) {
            // Total collections card
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Collections")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.secondary)
                    Text("\(totalCollections)")
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundColor(.primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text("This Week")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.secondary)
                    Text("\(weeklyData.map { $0.1 }.reduce(0, +))")
                        .font(.system(size: 24, weight: .semibold, design: .default))
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(.systemGray6).opacity(0.8))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Weekly goal progress
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Goal")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.secondary)
                    Text("\(weeklyData.map { $0.1 }.reduce(0, +))/\(weeklyGoal)")
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .foregroundColor(.primary)
                }
                Spacer()
                CircularProgressView(
                    progress: Double(weeklyData.map { $0.1 }.reduce(0, +)) / Double(weeklyGoal),
                    animate: animateDonut
                )
                .frame(width: 40, height: 40)
            }
            .padding()
            .background(Color(.systemGray6).opacity(0.8))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
    
    private var weeklyProgressChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Collections")
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(.primary)
            
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { index, data in
                    VStack(spacing: 8) {
                        // Animated bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.gradient)
                            .frame(width: 20, height: animateCharts ? CGFloat(data.1) * 2 : 5)
                            .animation(.easeOut(duration: 0.8).delay(Double(index) * 0.1), value: animateCharts)
                        
                        Text(data.0)
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.8))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var trashTypeBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trash Type Breakdown")
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                // Donut chart
                DonutChartView(data: trashTypeData, animate: animateDonut)
                    .frame(width: 120, height: 120)
                
                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(trashTypeData.enumerated()), id: \.offset) { index, data in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(data.2)
                                .frame(width: 12, height: 12)
                            Text(data.0)
                                .font(.system(size: 14, weight: .medium, design: .default))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(data.1)%")
                                .font(.system(size: 14, weight: .semibold, design: .default))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.8))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var leaderboard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Friends Leaderboard")
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAllFriends.toggle()
                    }
                }) {
                    Text(showAllFriends ? "Show Top 3" : "Show All")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.blue)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(Array((showAllFriends ? leaderboardData : Array(leaderboardData.prefix(3))).enumerated()), id: \.offset) { index, data in
                    HStack(spacing: 12) {
                        // Rank
                        Text("\(index + 1)")
                            .font(.system(size: 16, weight: .bold, design: .default))
                            .foregroundColor(data.2 ? .white : .secondary)
                            .frame(width: 24, alignment: .center)
                        
                        Spacer()
                        
                        // Score bar with name inside
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(data.2 ? Color.blue.gradient : Color.green.gradient)
                                .frame(width: animateCharts ? CGFloat(data.1) * 1.5 : 5, height: 32)
                                .animation(.easeOut(duration: 0.8).delay(Double(index) * 0.1), value: animateCharts)
                            
                            // Name inside the bar
                            Text(data.0)
                                .font(.system(size: 12, weight: .semibold, design: .default))
                                .foregroundColor(.white)
                                .padding(.leading, 12)
                                .lineLimit(1)
                        }
                        
                        // Score number
                        Text("\(data.1)")
                            .font(.system(size: 14, weight: .semibold, design: .default))
                            .foregroundColor(data.2 ? .blue : .secondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(data.2 ? Color.blue.opacity(0.3) : Color.clear)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.8))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Collected \(["plastic bottles", "paper waste", "metal cans"][index])")
                                .font(.system(size: 14, weight: .medium, design: .default))
                                .foregroundColor(.primary)
                            Text("\(["2 hours ago", "4 hours ago", "6 hours ago"][index])")
                                .font(.system(size: 12, weight: .medium, design: .default))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("+\([3, 2, 4][index]) 🍃")
                            .font(.system(size: 14, weight: .semibold, design: .default))
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.8))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let animate: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: animate ? progress : 0.1)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.0), value: animate)
        }
    }
}

struct DonutChartView: View {
    let data: [(String, Int, Color)]
    let animate: Bool
    
    var body: some View {
        ZStack {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                DonutSlice(
                    percentage: Double(item.1) / 100.0,
                    color: item.2,
                    startAngle: startAngle(for: index),
                    animate: animate
                )
            }
            
            // Center circle
            Circle()
                .fill(Color(.systemGray6).opacity(0.8))
                .frame(width: 60, height: 60)
            
            VStack {
                Text("Total")
                    .font(.system(size: 10, weight: .medium, design: .default))
                    .foregroundColor(.secondary)
                Text("\(data.map { $0.1 }.reduce(0, +))%")
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundColor(.primary)
            }
        }
    }
    
    private func startAngle(for index: Int) -> Double {
        let previousPercentages = data.prefix(index).map { Double($0.1) / 100.0 }
        return previousPercentages.reduce(0, +) * 360
    }
}

struct DonutSlice: View {
    let percentage: Double
    let color: Color
    let startAngle: Double
    let animate: Bool
    
    var body: some View {
        Path { path in
            let center = CGPoint(x: 60, y: 60)
            let radius: CGFloat = 50
            let endAngle = startAngle + (animate ? percentage * 360 : 0.1 * 360)
            
            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(startAngle),
                endAngle: .degrees(endAngle),
                clockwise: false
            )
            path.closeSubpath()
        }
        .fill(color)
        .animation(.easeOut(duration: 1.0).delay(0.3), value: animate)
    }
}

class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    @Published var roll: Double = 0.0

    init() {
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
            guard let motion = motion else { return }
            self?.roll = motion.attitude.roll
        }
    }
}

struct GamePage: View {
    @EnvironmentObject var creditsManager: CreditsManager
    @StateObject private var gameCoordinator = SlopeGameCoordinator()
    @Binding var isPlaying: Bool
    @State private var selectedPowerUp: PowerUp = .none
    @State private var showingInsufficientCredits = false
    
    // Animation states
    @State private var animateHeader = false
    @State private var animateTitle = false
    @State private var animateCredits = false
    @State private var animatePowerUps = false
    @State private var animateStartButton = false
    @State private var showingRanksInfo = false

    var body: some View {
        NavigationView {
            ZStack {
                if isPlaying {
                    ZStack {
                        SlopeGameSceneView(coordinator: gameCoordinator)
                            .edgesIgnoringSafeArea(.all)
                        VStack {
                            envolHeader(title: "Eco Run")
                                .opacity(animateHeader ? 1 : 0)
                                .offset(y: animateHeader ? 0 : -20)
                            
                            HStack {
                                Text("Score: \(gameCoordinator.score)")
                                    .font(.system(size: 18, weight: .semibold, design: .default))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(creditsManager.credits) 🍃")
                                    .font(.system(size: 18, weight: .semibold, design: .default))
                                    .foregroundColor(.green)
                            }
                            .padding()
                            
                            // Power-up status indicator
                            if gameCoordinator.selectedPowerUp != .none {
                                powerUpStatusView
                            }
                            
                            Spacer()
                        }
                        if gameCoordinator.showEndScreen {
                            VStack(spacing: 24) {
                                Text("Game Over")
                                    .font(.system(size: 32, weight: .bold, design: .default))
                                    .foregroundColor(.red)
                                Text("Score: \(gameCoordinator.score)")
                                    .font(.system(size: 20, weight: .semibold, design: .default))
                                    .foregroundColor(.white)
                                
                                // Show rank achieved
                                let achievedRank = GameRank.fromScore(gameCoordinator.score)
                                HStack(spacing: 12) {
                                    Image(systemName: achievedRank.medalIcon)
                                        .font(.system(size: 24, weight: .bold, design: .default))
                                        .foregroundColor(achievedRank.medalColor)
                                    Text("\(achievedRank.rawValue) Rank!")
                                        .font(.system(size: 18, weight: .semibold, design: .default))
                                        .foregroundColor(achievedRank.medalColor)
                                }
                                
                                Button(action: { 
                                    isPlaying = false 
                                }) {
                                    Text("Back to Menu")
                                        .font(.system(size: 16, weight: .medium, design: .default))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.black.opacity(0.85))
                            .cornerRadius(20)
                            .padding(.horizontal, 40)
                            .onAppear {
                                // Update best score immediately when game over screen appears
                                updatePlayerBestScore(gameCoordinator.score)
                            }
                        }
                    }
                } else {
                    // Start menu
                    ScrollView {
                        VStack(spacing: 32) {
                            envolHeader(title: "Eco Run")
                                .opacity(animateHeader ? 1 : 0)
                                .offset(y: animateHeader ? 0 : -20)
                        
                        // Credits and cost box
                        VStack(spacing: 12) {
                            HStack {
                                Text("Credits Available")
                                    .font(.system(size: 14, weight: .medium, design: .default))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Game Cost")
                                    .font(.system(size: 14, weight: .medium, design: .default))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("\(creditsManager.credits) 🍃")
                                    .font(.system(size: 24, weight: .semibold, design: .default))
                                    .foregroundColor(.green)
                                Spacer()
                                Text("\(selectedPowerUp.cost) 🍃")
                                    .font(.system(size: 20, weight: .semibold, design: .default))
                                    .foregroundColor(creditsManager.credits >= selectedPowerUp.cost ? .green : .red)
                            }
                            
                            if creditsManager.credits < selectedPowerUp.cost {
                                Text("Insufficient credits!")
                                    .font(.system(size: 12, weight: .medium, design: .default))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6).opacity(0.8))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .opacity(animateCredits ? 1 : 0)
                        .offset(y: animateCredits ? 0 : 20)
                        
                        // Power-up selection
                        VStack(spacing: 16) {
                            ForEach(PowerUp.allCases, id: \.self) { powerUp in
                                VStack(spacing: 0) {
                                    Button(action: {
                                        selectedPowerUp = powerUp
                                    }) {
                                        HStack {
                                            Image(systemName: powerUp.icon)
                                                .font(.system(size: 18, weight: .medium, design: .default))
                                            Text(powerUp.rawValue)
                                                .font(.system(size: 16, weight: .medium, design: .default))
                                            Spacer()
                                            Text("\(powerUp.cost) 🍃")
                                                .font(.system(size: 14, weight: .medium, design: .default))
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(selectedPowerUp == powerUp ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                    .padding(.horizontal)
                                    
                                    // Power-up description box
                                    if selectedPowerUp == powerUp {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(powerUpDescription(for: powerUp))
                                                .font(.system(size: 14, weight: .medium, design: .default))
                                                .foregroundColor(.gray)
                                                .multilineTextAlignment(.leading)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                        .padding(.top, 8)
                                    }
                                }
                            }
                        }
                        .opacity(animatePowerUps ? 1 : 0)
                        .offset(y: animatePowerUps ? 0 : 30)
                        
                        VStack(spacing: 16) {
                            Button(action: startGame) {
                                HStack {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 18, weight: .medium, design: .default))
                                    Text("Start Game")
                                        .font(.system(size: 18, weight: .semibold, design: .default))
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(creditsManager.credits >= selectedPowerUp.cost ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(creditsManager.credits < selectedPowerUp.cost)
                            .padding(.horizontal)
                            
                            // Player's Best Rank
                            playerBestRankView
                                .opacity(animateStartButton ? 1 : 0)
                                .offset(y: animateStartButton ? 0 : 30)
                                .animation(.easeOut(duration: 0.8).delay(1.0), value: animateStartButton)
                        }
                        .opacity(animateStartButton ? 1 : 0)
                        .offset(y: animateStartButton ? 0 : 30)
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                    .background(Color.clear)
                    }
                    .navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    .onAppear {
                        // Reset animation states
                        animateHeader = false
                        animateTitle = false
                        animateCredits = false
                        animatePowerUps = false
                        animateStartButton = false
                        
                        // Trigger animations with delays
                        withAnimation(.easeOut(duration: 0.6)) {
                            animateHeader = true
                        }
                        
                        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                            animateTitle = true
                        }
                        
                        withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                            animateCredits = true
                        }
                        
                        withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                            animatePowerUps = true
                        }
                        
                        withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
                            animateStartButton = true
                        }
                    }
                }
            }
        }
        .background(Color.clear)
        .onChange(of: isPlaying) { _ in
            checkGameEnd()
        }
        .sheet(isPresented: $showingRanksInfo) {
            ranksInfoView
        }
    }

    func startGame() {
        // Check if player has enough credits
        if creditsManager.credits >= selectedPowerUp.cost {
            // Deduct credits using database method
            creditsManager.subtractCredits(selectedPowerUp.cost)
            
            // Pass power-up to game coordinator
            gameCoordinator.selectedPowerUp = selectedPowerUp
            
            // Reset power-up selection to none for next game
            selectedPowerUp = .none
            
            // Start the game
            gameCoordinator.resetGame()
            
            // Power-up will be auto-initialized in the renderer
            print("DEBUG: Game started with power-up: \(self.gameCoordinator.selectedPowerUp.rawValue)")
            
            isPlaying = true
        } else {
            showingInsufficientCredits = true
        }
    }
    
    // Monitor game state changes to update best score
    private func checkGameEnd() {
        if !isPlaying && gameCoordinator.score > 0 {
            // Game has ended, update best score
            updatePlayerBestScore(gameCoordinator.score)
        }
    }

    func restartGame() {
        gameCoordinator.resetGame()
        isPlaying = false
    }
    
    func powerUpDescription(for powerUp: PowerUp) -> String {
        switch powerUp {
        case .none:
            return "No power-up selected. Play with basic settings."
        case .shield:
            return "Automatically activated. Tank 3 collisions with red obstacles before game over."
        case .slowMotion:
            return "Automatically activated. Speed increases every 100 points instead of 50."
        case .doublePoints:
            return "Automatically activated. Double the rate at which you gain points."
        }
    }
    
    func powerUpColor(for powerUp: PowerUp) -> Color {
        switch powerUp {
        case .none:
            return .gray
        case .shield:
            return .cyan
        case .slowMotion:
            return .orange
        case .doublePoints:
            return .yellow
        }
    }
    
    private var powerUpStatusView: some View {
        HStack {
            Image(systemName: gameCoordinator.selectedPowerUp.icon)
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundColor(powerUpColor(for: gameCoordinator.selectedPowerUp))
            Text(gameCoordinator.selectedPowerUp.rawValue)
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundColor(.white)
            
            // Shield hits indicator
            if gameCoordinator.selectedPowerUp == .shield {
                Spacer()
                shieldHitsIndicator
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.5))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private var shieldHitsIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                let remainingHits = 3 - (gameCoordinator.sceneCoordinator?.shieldHits ?? 0)
                Circle()
                    .fill(index < remainingHits ? Color.cyan : Color.gray)
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private var playerBestRankView: some View {
        VStack(spacing: 12) {
            Text("Your Best Rank")
                .font(.system(size: 16, weight: .semibold, design: .default))
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                // Medal
                let bestRank = GameRank(rawValue: creditsManager.bestRank) ?? .bronze
                ZStack {
                    Circle()
                        .fill(bestRank.medalColor)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: bestRank.medalIcon)
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(bestRank.rawValue)
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundColor(bestRank.medalColor)
                    
                    Text("Best Score: \(creditsManager.bestScore)")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Info icon
                Image(systemName: "info.circle")
                    .font(.system(size: 20, weight: .medium, design: .default))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.8))
        .cornerRadius(16)
        .padding(.horizontal)
        .onTapGesture {
            showingRanksInfo = true
        }
    }
    

    
    // Function to update player's best score and rank
    func updatePlayerBestScore(_ newScore: Int) {
        let newRank = GameRank.fromScore(newScore)
        creditsManager.updateBestScore(newScore, rank: newRank.rawValue)
    }
    
    private var ranksInfoView: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Rank System")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                
                Text("Progress through ranks by achieving higher scores!")
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(GameRank.allCases, id: \.self) { rank in
                            HStack(spacing: 16) {
                                // Medal
                                ZStack {
                                    Circle()
                                        .fill(rank.medalColor)
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: rank.medalIcon)
                                        .font(.system(size: 24, weight: .bold, design: .default))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(rank.rawValue)
                                        .font(.system(size: 18, weight: .bold, design: .default))
                                        .foregroundColor(rank.medalColor)
                                    
                                    Text(scoreRangeText(for: rank))
                                        .font(.system(size: 14, weight: .medium, design: .default))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Current rank indicator
                                if rank.rawValue == creditsManager.bestRank {
                                    Text("CURRENT")
                                        .font(.system(size: 12, weight: .bold, design: .default))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(rank.medalColor)
                                        .cornerRadius(8)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6).opacity(0.8))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingRanksInfo = false
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func scoreRangeText(for rank: GameRank) -> String {
        switch rank {
        case .bronze:
            return "0 - 499 points"
        case .silver:
            return "500 - 749 points"
        case .gold:
            return "750 - 999 points"
        case .platinum:
            return "1000 - 1299 points"
        case .diamond:
            return "1300 - 1599 points"
        case .champion:
            return "1600+ points"
        }
    }
}

enum GameRank: String, CaseIterable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
    case diamond = "Diamond"
    case champion = "Champion"
    
    static func fromScore(_ score: Int) -> GameRank {
        if score >= 1600 {
            return .champion
        } else if score >= 1300 {
            return .diamond
        } else if score >= 1000 {
            return .platinum
        } else if score >= 750 {
            return .gold
        } else if score >= 500 {
            return .silver
        } else {
            return .bronze
        }
    }
    
    var medalIcon: String {
        switch self {
        case .bronze: return "medal"
        case .silver: return "medal.fill"
        case .gold: return "crown.fill"
        case .platinum: return "crown"
        case .diamond: return "diamond.fill"
        case .champion: return "star.fill"
        }
    }
    
    var medalColor: Color {
        switch self {
        case .bronze: return .orange
        case .silver: return .gray
        case .gold: return .yellow
        case .platinum: return .blue
        case .diamond: return .purple
        case .champion: return .red
        }
    }
    
    var emoji: String {
        switch self {
        case .bronze: return "🥉"
        case .silver: return "🥈"
        case .gold: return "🥇"
        case .platinum: return "💎"
        case .diamond: return "💠"
        case .champion: return "🏆"
        }
    }
}

struct Obstacle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
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

struct NeonGridView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Vertical grid lines
                ForEach(0..<8) { i in
                    Path { path in
                        let x = geo.size.width * CGFloat(i) / 7.0
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    .stroke(Color.cyan, lineWidth: 2)
                    .shadow(color: .cyan, radius: 8)
                }
                // Horizontal grid lines
                ForEach(0..<12) { j in
                    Path { path in
                        let y = geo.size.height * CGFloat(j) / 11.0
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    .stroke(Color.cyan, lineWidth: 2)
                    .shadow(color: .cyan, radius: 8)
                }
            }
        }
        .opacity(0.5)
    }
}

// Starry background component
struct StarryBackground: View {
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.05, green: 0.05, blue: 0.15)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Stars
            GeometryReader { geometry in
                ForEach(0..<100, id: \.self) { _ in
                    Circle()
                        .fill(Color.white)
                        .frame(width: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .opacity(Double.random(in: 0.3...1.0))
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 2...4))
                                .repeatForever(autoreverses: true),
                            value: UUID()
                        )
                }
            }
        }
    }
}

@ViewBuilder
private func envolHeader(title: String) -> some View {
    HStack(spacing: 6) {
        Text("envolv")
            .font(.system(size: 18, weight: .bold, design: .default))
        Image(systemName: "leaf.fill")
            .foregroundColor(.green)
        Text(title)
            .font(.system(size: 18, weight: .semibold, design: .default))
    }
    .padding(.bottom, 4)
}



struct SignOutTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var creditsManager: CreditsManager
    @Binding var selectedTab: Int
    
    var body: some View {
        Color.clear
            .onAppear {
                // Trigger sign out when this tab is selected
                // Clear user data first
                creditsManager.setUser(email: "")
                // Then logout
                authManager.logout()
                // Reset to home tab after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedTab = 0
                }
            }
    }
}

// Helper function to find the tab bar
func findTabBar() -> UITabBar? {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first else {
        return nil
    }
    
    func findTabBar(in view: UIView) -> UITabBar? {
        if let tabBar = view as? UITabBar {
            return tabBar
        }
        
        for subview in view.subviews {
            if let tabBar = findTabBar(in: subview) {
                return tabBar
            }
        }
        
        return nil
    }
    
    return findTabBar(in: window)
}

// Function to continuously monitor and maintain tab bar colors
func startTabBarColorMonitoring() {
    // Initial setup
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        applySignOutTabColor()
    }
    
    // Set up a timer to continuously check and apply the color
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
        DispatchQueue.main.async {
            applySignOutTabColor()
        }
    }
}

// Function to apply red color to sign out tab
func applySignOutTabColor() {
    if let tabBar = findTabBar() {
        if let items = tabBar.items, items.count > 3 {
            // Set both normal and selected states to red for sign out tab
            items[3].setTitleTextAttributes([.foregroundColor: UIColor.systemRed], for: .normal)
            items[3].setTitleTextAttributes([.foregroundColor: UIColor.systemRed], for: .selected)
            
            // Also set the icon color to red
            items[3].image = items[3].image?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)
            items[3].selectedImage = items[3].selectedImage?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)
        }
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
