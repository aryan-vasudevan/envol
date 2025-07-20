import Foundation
import FirebaseDatabase

class CreditsManager: ObservableObject {
    @Published var credits: Int = 0
    @Published var bestScore: Int = 0
    @Published var bestRank: String = "Bronze"
    private var currentUserKey: String = ""
    private var databaseRef: DatabaseReference?
    private var userCreditsRef: DatabaseReference?

    init() {
        print("CreditsManager initialized (Firebase mode)")
        databaseRef = Database.database().reference()
    }
    
    func setUser(email: String) {
        // Validate email is not empty
        guard !email.isEmpty else {
            print("CreditsManager: Empty email provided, clearing user data")
            currentUserKey = ""
            userCreditsRef = nil
            credits = 0
            return
        }
        
        // Create a safe key from email (replace special characters)
        let userKey = email.replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "@", with: "_")
            .replacingOccurrences(of: "#", with: "_")
            .replacingOccurrences(of: "$", with: "_")
            .replacingOccurrences(of: "[", with: "_")
            .replacingOccurrences(of: "]", with: "_")
        
        // Additional validation for Firebase path
        guard !userKey.isEmpty && userKey.count > 0 else {
            print("CreditsManager: Invalid user key generated from email")
            currentUserKey = ""
            userCreditsRef = nil
            credits = 0
            return
        }
        
        currentUserKey = userKey
        
        // Set up Firebase reference for this user
        userCreditsRef = databaseRef?.child("users").child(currentUserKey)
        
        // Load credits from Firebase
        loadCreditsFromFirebase()
    }
    
    private func loadCreditsFromFirebase() {
        guard let userCreditsRef = userCreditsRef else {
            print("CreditsManager: No Firebase reference available")
            return
        }
        
        // Load credits
        userCreditsRef.child("credits").observe(.value) { snapshot in
            if let creditsValue = snapshot.value as? Int {
                DispatchQueue.main.async {
                    self.credits = creditsValue
                    print("CreditsManager: Loaded \(creditsValue) credits from Firebase for user \(self.currentUserKey)")
                }
            } else {
                // User doesn't exist yet, initialize with 0 credits
                DispatchQueue.main.async {
                    self.credits = 0
                    print("CreditsManager: New user \(self.currentUserKey), initializing with 0 credits")
                }
            }
        }
        
        // Load best score
        userCreditsRef.child("bestScore").observe(.value) { snapshot in
            if let scoreValue = snapshot.value as? Int {
                DispatchQueue.main.async {
                    self.bestScore = scoreValue
                    print("CreditsManager: Loaded best score \(scoreValue) from Firebase for user \(self.currentUserKey)")
                }
            } else {
                // User doesn't exist yet, initialize with 0 score
                DispatchQueue.main.async {
                    self.bestScore = 0
                    print("CreditsManager: New user \(self.currentUserKey), initializing with 0 best score")
                }
            }
        }
        
        // Load best rank
        userCreditsRef.child("bestRank").observe(.value) { snapshot in
            if let rankValue = snapshot.value as? String {
                DispatchQueue.main.async {
                    self.bestRank = rankValue
                    print("CreditsManager: Loaded best rank \(rankValue) from Firebase for user \(self.currentUserKey)")
                }
            } else {
                // User doesn't exist yet, initialize with Bronze rank
                DispatchQueue.main.async {
                    self.bestRank = "Bronze"
                    print("CreditsManager: New user \(self.currentUserKey), initializing with Bronze rank")
                }
            }
        }
    }
    
    func addCredits(_ amount: Int) {
        guard !currentUserKey.isEmpty, let userCreditsRef = userCreditsRef else {
            print("CreditsManager: No user key set or Firebase reference, cannot add credits")
            return
        }
        
        let newCredits = credits + amount
        userCreditsRef.child("credits").setValue(newCredits) { error, _ in
            if let error = error {
                print("CreditsManager: Error adding credits: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.credits = newCredits
                    print("CreditsManager: Added \(amount) credits, new total: \(newCredits)")
                }
            }
        }
    }
    
    func subtractCredits(_ amount: Int) {
        guard !currentUserKey.isEmpty, let userCreditsRef = userCreditsRef else {
            print("CreditsManager: No user key set or Firebase reference, cannot subtract credits")
            return
        }
        
        let newCredits = max(0, credits - amount)
        userCreditsRef.child("credits").setValue(newCredits) { error, _ in
            if let error = error {
                print("CreditsManager: Error subtracting credits: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.credits = newCredits
                    print("CreditsManager: Subtracted \(amount) credits, new total: \(newCredits)")
                }
            }
        }
    }
    
    func updateBestScore(_ newScore: Int, rank: String) {
        guard !currentUserKey.isEmpty, let userCreditsRef = userCreditsRef else {
            print("CreditsManager: No user key set or Firebase reference, cannot update best score")
            return
        }
        
        // Only update if the new score is higher
        if newScore > bestScore {
            let updates: [String: Any] = [
                "bestScore": newScore,
                "bestRank": rank
            ]
            
            userCreditsRef.updateChildValues(updates) { error, _ in
                if let error = error {
                    print("CreditsManager: Error updating best score: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.bestScore = newScore
                        self.bestRank = rank
                        print("CreditsManager: Updated best score to \(newScore) with rank \(rank)")
                    }
                }
            }
        }
    }
    
    deinit {
        // Remove Firebase observers
        userCreditsRef?.removeAllObservers()
    }
}
