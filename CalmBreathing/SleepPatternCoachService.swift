import Foundation

struct SleepPatternCoachService {

    static var apiKey: String = GroqConfig.apiKey
    private static let model = "llama-3.3-70b-versatile"

    private static let systemPrompt = """
    You are Serene, a compassionate AI sleep coach inside a meditation app. You analyze a user's real sleep data over the past 7 days and suggest the most suitable existing guided session from the app — do not create new content or scripts.

    FORMAT YOUR RESPONSE EXACTLY LIKE THIS (no other text before or after):
    INSIGHT: [2 specific sentences about what the sleep data shows — e.g. "Your average sleep was 5.4 hours this week, with quality dropping to 2/5 on 4 nights." Be honest and data-driven.]
    TECHNIQUE: [Name of the existing session to open in the app — one of: Sleep Meditation, Body Scan, Breathing Exercise, Relaxing Sounds, Sleep Stories]
    SCRIPT:
    [A warm 150-200 word message about sleep improvement. Write as if speaking directly to the user. Start with what their sleep data shows. Explain why this pattern affects their wellbeing. Recommend the specific session by name and explain why it suits their sleep pattern. Tell them to open that session in the app tonight. End with one encouraging sentence. No markdown, no bullet points, plain natural language only. Do not make medical claims.]
    """

    static func stream(_ sleepSummary: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
                        continuation.finish(throwing: SleepCoachError.apiError)
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
                            ["role": "user",   "content": sleepSummary]
                        ]
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        continuation.finish(throwing: SleepCoachError.apiError)
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

enum SleepCoachError: LocalizedError {
    case apiError
    var errorDescription: String? {
        "Could not reach the AI service. Check your internet connection and try again."
    }
}
