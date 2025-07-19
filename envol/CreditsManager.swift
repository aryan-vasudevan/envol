import Foundation
import FirebaseDatabase

class CreditsManager: ObservableObject {
    @Published var credits: Int = 0
    private var ref: DatabaseReference!

    init() {
        ref = Database.database().reference()
        print("CreditsManager initialized. Database ref: \(String(describing: ref))")
        observeCredits()
    }

    func observeCredits() {
        print("Setting up observer at /users/aryan/credits")
        ref.child("users/aryan/credits").observe(.value) { snapshot in
            print("Received snapshot: \(snapshot)")
            print("Snapshot value: \(String(describing: snapshot.value))")
            if let value = snapshot.value as? Int {
                print("Parsed credits as Int: \(value)")
                DispatchQueue.main.async {
                    self.credits = value
                }
            } else if let valueStr = snapshot.value as? String, let value = Int(valueStr) {
                print("Parsed credits as String->Int: \(value)")
                DispatchQueue.main.async {
                    self.credits = value
                }
            } else {
                print("Could not parse credits value from snapshot.")
            }
        }
    }

    func addCredits(_ amount: Int) {
        let creditsRef = ref.child("users/aryan/credits")
        creditsRef.runTransactionBlock { currentData in
            var value = currentData.value as? Int ?? 0
            value += amount
            print("addCredits: current value \(currentData.value ?? "nil"), adding \(amount), new value \(value)")
            currentData.value = value
            return TransactionResult.success(withValue: currentData)
        }
    }
    
    func subtractCredits(_ amount: Int) {
        let creditsRef = ref.child("users/aryan/credits")
        creditsRef.runTransactionBlock { currentData in
            var value = currentData.value as? Int ?? 0
            value = max(0, value - amount) // Ensure credits don't go below 0
            print("subtractCredits: current value \(currentData.value ?? "nil"), subtracting \(amount), new value \(value)")
            currentData.value = value
            return TransactionResult.success(withValue: currentData)
        }
    }
}
