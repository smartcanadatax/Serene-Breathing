import Foundation

struct DailyCheckInService {

    static let apiKey = "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"
    private static let model = "llama-3.3-70b-versatile"

    private static let systemPrompt = """
    You are Serene, a compassionate AI wellness coach inside a meditation app. A user has just logged their mood and last night's sleep. Give them a brief, warm, personalized insight and recommend one session.

    FORMAT YOUR RESPONSE EXACTLY LIKE THIS (no other text):
    INSIGHT: [2 warm specific sentences about what their mood and sleep combination means. Be honest and caring. Example: "You slept 6 hours but feel anxious — your mind may need more stillness than your body right now. This pattern is common and manageable."]
    TECHNIQUE: [One of: Morning Meditation, Body Scan, 4-7-8 Breathing, Box Breathing, Personalized Meditation, Relaxing Sounds, Sleep Meditation]
    REASON: [One short sentence why this session suits them right now.]
    """

    static func stream(_ summary: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
                        continuation.finish(throwing: CheckInError.apiError); return
                    }
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    let body: [String: Any] = [
                        "model": model, "max_tokens": 300, "stream": true,
                        "messages": [
                            ["role": "system", "content": systemPrompt],
                            ["role": "user",   "content": summary]
                        ]
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        continuation.finish(throwing: CheckInError.apiError); return
                    }
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let s = String(line.dropFirst(6))
                        if s == "[DONE]" { break }
                        guard let data = s.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let chunk = ((json["choices"] as? [[String: Any]])?.first?["delta"] as? [String: Any])?["content"] as? String
                        else { continue }
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch { continuation.finish(throwing: error) }
            }
        }
    }
}

enum CheckInError: LocalizedError {
    case apiError
    var errorDescription: String? { "Could not reach the AI service. Check your connection and try again." }
}

// MARK: - Quick mood support message (fires automatically on stressed/anxious selection)
struct MoodCoachService {

    private static let apiKey = DailyCheckInService.apiKey
    private static let model  = "llama-3.3-70b-versatile"

    private static let systemPrompt = """
    You are Serene, a warm and compassionate AI wellness coach. A user just selected their mood. Send them a brief, caring 2-sentence support message. Be warm, human, and specific to their mood. Do not give advice or recommend sessions — just acknowledge and comfort. No formatting, no labels, just the message.
    """

    static func stream(mood: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
                        continuation.finish(throwing: CheckInError.apiError); return
                    }
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    let body: [String: Any] = [
                        "model": model, "max_tokens": 80, "stream": true,
                        "messages": [
                            ["role": "system", "content": systemPrompt],
                            ["role": "user",   "content": "The user selected their mood as: \(mood)"]
                        ]
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        continuation.finish(throwing: CheckInError.apiError); return
                    }
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let s = String(line.dropFirst(6))
                        if s == "[DONE]" { break }
                        guard let data = s.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let chunk = ((json["choices"] as? [[String: Any]])?.first?["delta"] as? [String: Any])?["content"] as? String
                        else { continue }
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch { continuation.finish(throwing: error) }
            }
        }
    }
}
