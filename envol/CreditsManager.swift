import Foundation

class CreditsManager: ObservableObject {
    @Published var credits: Int = 0
    private var currentUserKey: String = ""

    init() {
        print("CreditsManager initialized (local mode)")
    }
    
    func setUser(email: String) {
        // Create a safe key from email (replace special characters)
        let userKey = email.replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "@", with: "_")
            .replacingOccurrences(of: "#", with: "_")
            .replacingOccurrences(of: "$", with: "_")
            .replacingOccurrences(of: "[", with: "_")
            .replacingOccurrences(of: "]", with: "_")
        currentUserKey = userKey
        // Load credits from UserDefaults
        credits = UserDefaults.standard.integer(forKey: "credits_\(currentUserKey)")
    }
    
    func addCredits(_ amount: Int) {
        guard !currentUserKey.isEmpty else {
            print("CreditsManager: No user key set, cannot add credits")
            return
        }
        let currentCredits = UserDefaults.standard.integer(forKey: "credits_\(currentUserKey)")
        let newCredits = currentCredits + amount
        UserDefaults.standard.set(newCredits, forKey: "credits_\(currentUserKey)")
        credits = newCredits
    }
    
    func subtractCredits(_ amount: Int) {
        guard !currentUserKey.isEmpty else {
            print("CreditsManager: No user key set, cannot subtract credits")
            return
        }
        let currentCredits = UserDefaults.standard.integer(forKey: "credits_\(currentUserKey)")
        let newCredits = max(0, currentCredits - amount)
        UserDefaults.standard.set(newCredits, forKey: "credits_\(currentUserKey)")
        credits = newCredits
    }
    
    deinit {
        // No cleanup needed for local storage
    }
}
