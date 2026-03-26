import Foundation

struct MoodPatternCoachService {

    static var apiKey: String = "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"
    private static let model = "llama-3.3-70b-versatile"

    private static let systemPrompt = """
    You are Serene, a compassionate AI wellness coach inside a meditation app. You analyze a user's real mood data over the past 7 days and suggest the most suitable existing guided session from the app — do not create new content or scripts. Focus only on mood patterns, emotional trends, and stress levels. Do not mention sleep.

    FORMAT YOUR RESPONSE EXACTLY LIKE THIS (no other text before or after):
    INSIGHT: [2 specific sentences about what the mood data shows — e.g. "You felt anxious 5 out of 7 days this week, with your lowest mood on weekdays." Be honest and data-driven. Do not mention sleep.]
    TECHNIQUE: [Name of the existing session to open in the app — one of: Morning Meditation, Body Scan, Breathing Exercise, Personalized Meditation, Relaxing Sounds]
    SCRIPT:
    [A warm 150-200 word message focused on mood and emotional wellbeing. Write as if speaking directly to the user. Start with what their mood data shows. Explain why this emotional pattern matters. Recommend the specific session by name and explain why it suits their current mood pattern. Tell them to open that session in the app. End with one encouraging sentence. No markdown, no bullet points, plain natural language only. Do not make medical claims. Do not mention sleep.]
    """

    static func stream(_ moodSummary: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
                        continuation.finish(throwing: MoodCoachError.apiError)
                        return
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let body: [String: Any] = [
                        "model": model,
                        "max_tokens": 800,
                        "stream": true,
                        "messages": [
                            ["role": "system", "content": systemPrompt],
                            ["role": "user",   "content": moodSummary]
                        ]
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        continuation.finish(throwing: MoodCoachError.apiError)
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

enum MoodCoachError: LocalizedError {
    case apiError
    var errorDescription: String? {
        "Could not reach the AI service. Check your internet connection and try again."
    }
}
