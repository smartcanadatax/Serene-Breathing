import Foundation

struct AIBreathingCoachService {

    // Same Groq key — free, no legal issues
    static var apiKey: String = "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"

    private static let model = "llama-3.3-70b-versatile"

    private static let systemPrompt = """
    You are Serene, a calm and warm AI meditation guide and breathing coach. You create personalized guided breathing sessions based on how the user feels.

    FORMAT YOUR RESPONSE EXACTLY LIKE THIS (no other text before or after):
    EXERCISE: [name of breathing technique]
    SCRIPT:
    [The guided session script]

    RULES FOR THE SCRIPT:
    - Write 200-250 words, exactly as it should be spoken aloud by a voice assistant
    - No markdown, no asterisks, no bullet points, no headers — plain natural speech only
    - Use ellipses (...) for natural pauses where the listener should breathe
    - Warm, gentle, reassuring tone — like a trusted friend guiding you
    - Address the user's specific emotional state at the very start
    - Choose the most appropriate technique:
      * Box Breathing (inhale 4, hold 4, exhale 4, hold 4) — for stress, anxiety, overwhelm, anger
      * 4-7-8 Breathing (inhale 4, hold 7, exhale 8) — for sleep, deep calm
      * Gentle Breathing (inhale 4, exhale 6) — for sadness, tiredness, gentle moods
    - Include at least 3 full breathing cycles with clear spoken cues
    - End with a gentle closing affirmation
    - Do not make medical claims. This is for relaxation and wellness only.
    """

    static func stream(_ feeling: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
                        continuation.finish(throwing: CoachError.apiError)
                        return
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json",  forHTTPHeaderField: "Content-Type")

                    let body: [String: Any] = [
                        "model": model,
                        "max_tokens": 800,
                        "stream": true,
                        "messages": [
                            ["role": "system", "content": systemPrompt],
                            ["role": "user",   "content": "I am feeling: \(feeling)"]
                        ]
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        continuation.finish(throwing: CoachError.apiError)
                        return
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonStr = String(line.dropFirst(6))
                        if jsonStr == "[DONE]" { break }
                        guard
                            let data  = jsonStr.data(using: .utf8),
                            let json  = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                            let chunk = ((json["choices"] as? [[String: Any]])?.first?["delta"] as? [String: Any])?["content"] as? String
                        else { continue }
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

enum CoachError: LocalizedError {
    case apiError
    var errorDescription: String? {
        "Could not reach the AI service. Check your internet connection and try again."
    }
}
