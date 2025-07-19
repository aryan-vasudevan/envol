import SwiftUI

struct ImageProcessorView: View {
    let beforeImage: UIImage
    let afterImage: UIImage
    
    @State private var isProcessing = false
    @State private var processingResult: ProcessingResult?
    @Environment(\.dismiss) private var dismiss
    
    enum ProcessingResult {
        case success(points: Int, message: String)
        case failure(message: String)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isProcessing {
                    processingView
                } else if let result = processingResult {
                    resultView(result)
                } else {
                    initialView
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Processing Cleanup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            startProcessing()
        }
    }
    
    private var initialView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Ready to Process")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("We'll analyze your before and after photos to verify the cleanup and award points.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                VStack {
                    Text("Before")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(uiImage: beforeImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipped()
                        .cornerRadius(8)
                }
                
                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack {
                    Text("After")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(uiImage: afterImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipped()
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Processing Images...")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Analyzing before and after photos with AI")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Simulated processing steps
            VStack(alignment: .leading, spacing: 10) {
                ProcessingStepView(
                    title: "Detecting trash in before image",
                    isCompleted: true
                )
                
                ProcessingStepView(
                    title: "Analyzing after image",
                    isCompleted: true
                )
                
                ProcessingStepView(
                    title: "Comparing images",
                    isCompleted: false
                )
                
                ProcessingStepView(
                    title: "Calculating points",
                    isCompleted: false
                )
            }
            .padding(.top)
        }
    }
    
    private func resultView(_ result: ProcessingResult) -> some View {
        VStack(spacing: 20) {
            switch result {
            case .success(let points, let message):
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Cleanup Verified!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("You earned \(points) points!")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Continue") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
                
            case .failure(let message):
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("Processing Failed")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Try Again") {
                    startProcessing()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
    }
    
    private func startProcessing() {
        isProcessing = true
        processingResult = nil
        
        // Simulate AI processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isProcessing = false
            
            // Simulate success (in real app, this would be based on AI analysis)
            let randomPoints = Int.random(in: 10...50)
            let messages = [
                "Great job cleaning up! The area looks much better.",
                "Excellent cleanup work! You've made a real difference.",
                "Outstanding! The community thanks you for your effort.",
                "Fantastic work! You've helped keep our community clean."
            ]
            
            processingResult = .success(
                points: randomPoints,
                message: messages.randomElement() ?? "Great job!"
            )
        }
    }
}

struct ProcessingStepView: View {
    let title: String
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)
                .font(.system(size: 16))
            
            Text(title)
                .font(.body)
                .foregroundColor(isCompleted ? .primary : .secondary)
            
            Spacer()
        }
    }
}

#Preview {
    let mockImage = UIImage(systemName: "photo") ?? UIImage()
    ImageProcessorView(
        beforeImage: mockImage,
        afterImage: mockImage
    )
} 