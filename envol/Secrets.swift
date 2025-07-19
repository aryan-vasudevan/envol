import Foundation

enum Secrets {
    static var geminiApiKey: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["GEMINI_API_KEY"] as? String else {
            fatalError("Missing GEMINI_API_KEY in Secrets.plist")
        }
        return key
    }
    // Add more secrets as needed
} 