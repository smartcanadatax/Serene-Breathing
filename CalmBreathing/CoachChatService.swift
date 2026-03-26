import Foundation

// MARK: - Chat Message Model

struct CoachChatMessage: Identifiable {
    let id = UUID()
    let role: String        // "user" or "assistant"
    var content: String
    var isStreaming: Bool = false

    init(role: String, content: String, isStreaming: Bool = false) {
        self.role = role
        self.content = content
        self.isStreaming = isStreaming
    }
}

// MARK: - Coach Chat Service (full conversation history)

struct CoachChatService {
    private static let apiKey = DailyCheckInService.apiKey
    private static let model  = "llama-3.3-70b-versatile"

    private static let systemPrompt = """
    You are Serene, a warm, calm, and compassionate AI wellness coach inside a meditation and breathing app. Help users with stress, anxiety, sleep, breathing, and general wellbeing. Keep responses concise (2–4 sentences), warm, and actionable. When relevant, mention specific breathing exercises or mindfulness techniques available in the app (Box Breathing, 4-7-8 Breathing, Body Scan, Morning Meditation, Sleep Meditation). Never give medical advice — always recommend professional help for serious concerns.
    """

    static func stream(messages: [CoachChatMessage]) -> AsyncThrowingStream<String, Error> {
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

                    var apiMessages: [[String: Any]] = [["role": "system", "content": systemPrompt]]
                    apiMessages += messages.map { ["role": $0.role, "content": $0.content] }

                    let body: [String: Any] = [
                        "model": model, "max_tokens": 200, "stream": true,
                        "messages": apiMessages
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
