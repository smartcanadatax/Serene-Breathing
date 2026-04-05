import Foundation

// MARK: - Chat Message Model

enum SuggestedFeature: String, CaseIterable {
    // Breathing
    case boxBreathing       = "Box Breathing"
    case breathing478       = "4-7-8 Breathing"
    case quickCalm          = "Quick Calm"
    // Meditation
    case morningMeditation  = "Morning Meditation"
    case sleepMeditation    = "Sleep Meditation"
    case bodyScan           = "Body Scan"
    case stillWaters        = "Still Waters"
    case deepRelax          = "Deep Relax"
    // Other
    case dailyPractice           = "Daily Practice"
    case sleepStories            = "Sleep Stories"
    case sounds                  = "Nature Sounds"
    case personalizedMeditation  = "Personalized Meditation"

    var icon: String {
        switch self {
        case .boxBreathing, .breathing478: return "lungs.fill"
        case .quickCalm:                   return "heart.circle.fill"
        case .morningMeditation:           return "sunrise.fill"
        case .sleepMeditation:             return "moon.stars.fill"
        case .bodyScan:                    return "figure.mind.and.body"
        case .stillWaters:                 return "water.waves"
        case .deepRelax:                   return "waveform.path.ecg"
        case .dailyPractice:               return "calendar.badge.clock"
        case .sleepStories:                return "book.fill"
        case .sounds:                      return "waveform"
        case .personalizedMeditation:      return "heart.text.square.fill"
        }
    }

    var keywords: [String] {
        switch self {
        case .boxBreathing:      return ["box breathing", "box breath", "stress relief", "calm down"]
        case .breathing478:      return ["4-7-8", "4–7–8", "478", "anxiety relief", "focus boost"]
        case .quickCalm:         return ["quick calm", "pain relief"]
        case .morningMeditation: return ["morning meditation"]
        case .sleepMeditation:   return ["sleep meditation"]
        case .bodyScan:          return ["body scan"]
        case .stillWaters:       return ["still waters"]
        case .deepRelax:         return ["deep relax"]
        case .dailyPractice:              return ["daily practice"]
        case .sleepStories:               return ["sleep stories", "sleep story"]
        case .sounds:                     return ["nature sounds"]
        case .personalizedMeditation:     return ["personalized meditation"]
        }
    }

    // Client-side emotion detection on the user's raw message
    static func suggestionsForEmotion(_ text: String) -> [SuggestedFeature] {
        let t = text.lowercased()
        var result: [SuggestedFeature] = []

        let sad       = ["sad", "unhappy", "depress", "lonely", "low", "hopeless", "miserable", "crying", "cry", "heartbroken", "down", "grief", "griev", "hurt", "empty"]
        let anxious   = ["anxious", "anxiety", "panic", "nervous", "worried", "worry", "overwhelm", "scared", "fear", "dread", "uneasy", "on edge", "restless mind", "racing thoughts", "racing mind"]
        let stressed  = ["stress", "tense", "tension", "pressure", "frustrated", "burnout", "burn out", "overwhelm", "too much", "so much on", "a lot on my mind"]
        let angry     = ["angry", "anger", "irritat", "annoy", "furious", "rage", "mad", "aggravat", "livid", "upset"]
        let sleep     = ["can't sleep", "cant sleep", "cannot sleep", "insomnia", "awake", "trouble sleeping", "falling asleep", "stay asleep", "sleep tonight", "mind won't stop", "can't rest", "cant rest"]
        let tired     = ["tired", "exhausted", "drained", "fatigued", "worn out", "no energy", "low energy", "burnout", "burn out", "sleepy", "depleted"]
        let unfocused = ["distract", "focus", "concentrat", "scatter", "brain fog", "unfocused", "can't think", "cant think", "mind wandering", "procrastinat"]
        let morning   = ["morning", "wake up", "woke up", "start the day", "just woke", "good morning", "early"]
        let good      = ["great", "amazing", "wonderful", "fantastic", "happy", "joyful", "excited", "feeling good", "doing well", "doing great"]
        let peace     = ["peace", "calm", "quiet", "stillness", "serene", "relax", "unwind", "decompress"]

        if sad.contains(where: { t.contains($0) })       { result += [.stillWaters, .bodyScan, .personalizedMeditation] }
        if anxious.contains(where: { t.contains($0) })   { result += [.quickCalm, .breathing478, .personalizedMeditation] }
        if stressed.contains(where: { t.contains($0) })  { result += [.boxBreathing, .breathing478, .personalizedMeditation] }
        if angry.contains(where: { t.contains($0) })     { result += [.boxBreathing, .bodyScan] }
        if sleep.contains(where: { t.contains($0) })     { result += [.sleepMeditation, .sleepStories, .breathing478] }
        if tired.contains(where: { t.contains($0) })     { result += [.deepRelax, .bodyScan] }
        if unfocused.contains(where: { t.contains($0) }) { result += [.boxBreathing, .dailyPractice] }
        if morning.contains(where: { t.contains($0) })   { result += [.morningMeditation, .dailyPractice] }
        if good.contains(where: { t.contains($0) })      { result += [.dailyPractice, .morningMeditation] }
        if peace.contains(where: { t.contains($0) })     { result += [.stillWaters, .deepRelax] }

        // Deduplicate while preserving order
        var seen = Set<SuggestedFeature>()
        return result.filter { seen.insert($0).inserted }
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

    mutating func mergeEmotionSuggestions(from userText: String) {
        let extra = SuggestedFeature.suggestionsForEmotion(userText)
        let existing = Set(suggestedFeatures)
        let merged = suggestedFeatures + extra.filter { !existing.contains($0) }
        suggestedFeatures = Array(merged.prefix(4))
    }
}

// MARK: - Coach Chat Service (full conversation history)

struct CoachChatService {
    private static let apiKey = DailyCheckInService.apiKey
    private static let model  = "llama-3.3-70b-versatile"

    private static let systemPrompt = """
    You are Serene, a warm and friendly AI wellness coach inside the Serene Breathing app. Keep responses short — 2 sentences of empathy MAX, then immediately recommend features.

    CRITICAL RULE: You MUST ALWAYS end every single response with "Try: [Feature Name]" or "Try: [Feature Name] or [Feature Name]" using the EXACT names below. The app reads your response to show tappable buttons. If you forget to include exact feature names, the buttons won't appear. Never skip this step.

    EXACT FEATURE NAMES (copy these precisely):
    Box Breathing | 4-7-8 Breathing | Quick Calm | Morning Meditation | Sleep Meditation | Body Scan | Still Waters | Deep Relax | Daily Practice | Sleep Stories | Nature Sounds | Personalized Meditation

    EMOTION → FEATURE RULE (strict — always follow):
    - Stressed, tense, pressure, frustrated, burnout → Box Breathing, 4-7-8 Breathing
    - Anxious, anxiety, nervous, worried, panic, overwhelmed → Quick Calm, 4-7-8 Breathing
    - Sad, low, down, depressed, lonely, unhappy → Still Waters, Body Scan
    - Angry, irritated, annoyed → Box Breathing, Body Scan
    - Can't sleep, insomnia, restless, trouble sleeping → Sleep Meditation, Sleep Stories, 4-7-8 Breathing
    - Tired, exhausted, drained, fatigued → Deep Relax, Body Scan
    - Unfocused, distracted, scattered, brain fog → Box Breathing, Daily Practice
    - Morning, just woke up, start the day → Morning Meditation, Daily Practice
    - Happy, great, good → Daily Practice, Morning Meditation
    - Calm, peaceful, relaxed → Still Waters, Deep Relax

    EXAMPLE RESPONSES:
    User: "I'm anxious" → "That anxious feeling is tough — you're not alone. Try: Quick Calm or 4-7-8 Breathing"
    User: "I'm stressed" → "Stress builds up fast. Let's reset your nervous system. Try: Box Breathing or 4-7-8 Breathing"
    User: "I can't sleep" → "Racing thoughts at night are exhausting. Try: Sleep Meditation or Sleep Stories"
    User: "I'm sad" → "I hear you — it's okay to feel this way. Try: Still Waters or Body Scan"

    Never give medical advice. Recommend professional help for serious concerns.
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
                        "model": model, "max_tokens": 300, "stream": true,
                        "temperature": 0.3,
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
