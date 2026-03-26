import Foundation

struct SleepStoriesService {

    static var apiKey: String = GroqConfig.apiKey

    private static let model = "llama-3.3-70b-versatile"

    private static let systemPrompt = """
    You are a gentle sleep story narrator. You write calming, immersive bedtime stories to help adults fall asleep.

    FORMAT YOUR RESPONSE EXACTLY LIKE THIS:
    TITLE: [story title]
    STORY:
    [the full story text]

    RULES FOR THE STORY:
    - Write 350-400 words, exactly as it should be spoken aloud
    - No markdown, no asterisks, no bullet points — plain natural prose only
    - Use a slow, peaceful narrative voice — like a bedtime story for adults
    - Use ellipses (...) for natural pauses
    - Rich sensory details: soft textures, gentle sounds, warm light, cool air
    - The story should gradually slow down and become more dream-like toward the end
    - Themes: nature, cozy places, gentle journeys, peaceful landscapes
    - Do NOT include anything exciting, tense, or stimulating
    - End with the character drifting into a deep, peaceful sleep
    """

    static func stream(_ theme: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
                        continuation.finish(throwing: StoryError.apiError)
                        return
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json",  forHTTPHeaderField: "Content-Type")

                    let body: [String: Any] = [
                        "model": model,
                        "max_tokens": 900,
                        "stream": true,
                        "messages": [
                            ["role": "system", "content": systemPrompt],
                            ["role": "user",   "content": "Create a sleep story with this theme: \(theme)"]
                        ]
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        continuation.finish(throwing: StoryError.apiError)
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

enum StoryError: LocalizedError {
    case apiError
    var errorDescription: String? {
        "Could not reach the AI service. Check your internet connection and try again."
    }
}
