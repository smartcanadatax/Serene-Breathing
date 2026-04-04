import Foundation

// MARK: - Chat Message Model

enum SuggestedFeature: String, CaseIterable {
    case boxBreathing       = "Box Breathing"
    case breathing478       = "4-7-8 Breathing"
    case morningMeditation  = "Morning Meditation"
    case sleepMeditation    = "Sleep Meditation"
    case bodyScan           = "Body Scan"
    case quickRelief        = "Quick Relief"
    case dailyPractice      = "Daily Practice"

    var icon: String {
        switch self {
        case .boxBreathing, .breathing478: return "lungs.fill"
        case .morningMeditation:           return "sunrise.fill"
        case .sleepMeditation:             return "moon.stars.fill"
        case .bodyScan:                    return "figure.mind.and.body"
        case .quickRelief:                 return "bolt.heart.fill"
        case .dailyPractice:               return "calendar.badge.clock"
        }
    }

    var keywords: [String] {
        switch self {
        case .boxBreathing:      return ["box breathing", "box breath"]
        case .breathing478:      return ["4-7-8", "4–7–8", "478"]
        case .morningMeditation: return ["morning meditation"]
        case .sleepMeditation:   return ["sleep meditation"]
        case .bodyScan:          return ["body scan"]
        case .quickRelief:       return ["quick relief", "stress relief", "anxiety relief"]
        case .dailyPractice:     return ["daily practice", "daily breathing"]
        }
    }
}

struct CoachChatMessage: Identifiable {
    let id = UUID()
    let role: String        // "user" or "assistant"
    var content: String
    var isStreaming: Bool = false
    var suggestedFeatures: [SuggestedFeature] = []

    init(role: String, content: String, isStreaming: Bool = false) {
        self.role = role
        self.content = content
        self.isStreaming = isStreaming
    }

    mutating func detectFeatures() {
        guard role == "assistant", !content.isEmpty else { return }
        let lower = content.lowercased()
        suggestedFeatures = SuggestedFeature.allCases.filter { feature in
            feature.keywords.contains { lower.contains($0) }
        }
    }
}

// MARK: - Coach Chat Service (full conversation history)

struct CoachChatService {
    private static let apiKey = DailyCheckInService.apiKey
    private static let model  = "llama-3.3-70b-versatile"

    private static let systemPrompt = """
    You are Serene, a warm and friendly AI wellness coach inside a meditation and breathing app. The user may be happy, neutral, or going through a tough time — do not assume they are stressed. Respond naturally to whatever mood they express. If they're doing well, celebrate that. If they need support, offer it gently. Keep responses concise (2–4 sentences). When relevant, mention breathing or mindfulness techniques (Box Breathing, 4-7-8 Breathing, Body Scan, Morning Meditation, Sleep Meditation). Never give medical advice — always recommend professional help for serious concerns.
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
