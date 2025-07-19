import Foundation
import UIKit

enum GeminiAPI {
    static func validateCleanup(before: UIImage, after: UIImage) async -> String {
        guard let beforeData = before.jpegData(compressionQuality: 0.8),
              let afterData = after.jpegData(compressionQuality: 0.8) else {
            return "Failed to encode images."
        }
        let beforeBase64 = beforeData.base64EncodedString()
        let afterBase64 = afterData.base64EncodedString()
        let apiKey = Secrets.geminiApiKey
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)")!
        let prompt = "You are an AI judge for a community cleanup app. The first image ('before') should show visible trash on a background. The second image ('after') should show the same location, but the trash should be completely out of the frame. Only reply 'valid' if (1) the trash is entirely absent from the after image (not just moved, rotated, or partially visible), and (2) the background in the after image loosely matches the background of the before image (e.g., same setting, same objects  except for the trash, angle can vary a lot, no major changes except for the trash being gone). If either of these is not true, reply 'invalid'. Also, briefly explain your reasoning."
        let requestBody: [String: Any] = [
            "contents": [
                ["role": "user", "parts": [
                    ["text": prompt],
                    ["inline_data": ["mime_type": "image/jpeg", "data": beforeBase64]],
                    ["inline_data": ["mime_type": "image/jpeg", "data": afterBase64]]
                ]]
            ]
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                return text
            } else if let str = String(data: data, encoding: .utf8) {
                return "Gemini response: \(str)"
            } else {
                return "Failed to parse Gemini response."
            }
        } catch {
            return "Gemini API error: \(error.localizedDescription)"
        }
    }
} 