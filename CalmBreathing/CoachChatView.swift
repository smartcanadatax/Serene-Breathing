import SwiftUI

// MARK: - Interactive AI Coach Chat

// MARK: - Crisis Keywords

// Self-harm keywords
private let crisisKeywords: [String] = [
    "suicide", "suicidal", "kill myself", "end my life", "want to die",
    "don't want to live", "dont want to live", "self-harm", "self harm",
    "hurt myself", "harm myself", "cutting myself", "overdose", "no reason to live"
]

private let crisisResponse = """
I'm really glad you reached out, and I want you to know you're not alone. \
What you're feeling matters deeply.

Please contact emergency services or a crisis support line in your country right away — trained people are available 24/7.

If you're in immediate danger, call your local emergency number now.

You can find crisis contacts for your country at: findahelpline.com

Serene is a wellness tool and cannot replace professional support. Please reach out — you deserve care.
"""

// Threat-toward-others keywords
private let threatKeywords: [String] = [
    // Kill / murder
    "kill him", "kill her", "kill them", "kill someone", "kill people",
    "going to kill", "want to kill", "murder", "gonna kill",
    // Physical violence
    "stab him", "stab her", "stab them", "stab someone",
    "shoot him", "shoot her", "shoot them", "shoot someone",
    "beat him", "beat her", "beat them", "beat up",
    "punch him", "punch her", "punch them",
    "strangle", "choke him", "choke her", "choke them",
    "attack someone", "attack him", "attack her", "going to attack",
    // Harm / hurt
    "want to hurt them", "want to hurt him", "want to hurt her",
    "going to hurt", "hurt them", "harm them",
    // Weapons / explosives
    "bomb", "blow up", "explosive",
    "poison him", "poison her", "poison them",
    // Other serious threats
    "burn them", "burn him", "burn her", "set fire to",
    "run them over", "run him over", "run her over",
    "kidnap", "torture", "rape",
    "make them suffer", "make him suffer", "make her suffer",
    "destroy them", "jump them",
    "make them pay", "going to get them"
]

private let threatResponse = """
I'm not able to help with thoughts of harming others.

If you're feeling intense anger, that's something a professional can help you work through safely.

For right now, try the Box Breathing session in the app — it can help bring your nervous system back to calm.

If there is any immediate danger, please contact your local emergency services.
"""

// MARK: - Monthly Message Limit

private let monthlyMessageLimit = 1000

private func currentMonthKey() -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM"
    return f.string(from: Date())
}

private func monthlyMessageCount() -> Int {
    let key = currentMonthKey()
    let storedKey = UserDefaults.standard.string(forKey: "chatMonthKey") ?? ""
    if storedKey != key {
        // New month — reset
        UserDefaults.standard.set(key, forKey: "chatMonthKey")
        UserDefaults.standard.set(0, forKey: "chatMessageCount")
        return 0
    }
    return UserDefaults.standard.integer(forKey: "chatMessageCount")
}

private func incrementMessageCount() {
    let current = UserDefaults.standard.integer(forKey: "chatMessageCount")
    UserDefaults.standard.set(current + 1, forKey: "chatMessageCount")
}

// MARK: - Chat View

struct CoachChatView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var journal: JournalStore
    @AppStorage("hasSeenChatDisclaimer") private var hasSeenDisclaimer = false

    @State private var messages: [CoachChatMessage] = [
        CoachChatMessage(role: "assistant",
                         content: "Hi! I'm Serene, your wellness coach. How are you doing today?")
    ]
    @State private var inputText    = ""
    @State private var isResponding = false
    @State private var showDisclaimer = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack {
            CalmBackground()

            VStack(spacing: 0) {

                // MARK: Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("Serene")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Text("AI Wellness Coach")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    Spacer()
                    // Balance the close button
                    Color.clear.frame(width: 32, height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Divider().background(Color.white.opacity(0.15))

                // MARK: Messages
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            ForEach(messages) { msg in
                                ChatBubble(message: msg)
                                    .id(msg.id)
                            }
                            if isResponding && (messages.last?.content.isEmpty ?? false) == false {
                                TypingIndicatorView()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: messages.last?.content) { _, _ in
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }

                // MARK: Input Bar
                HStack(spacing: 10) {
                    ZStack(alignment: .leading) {
                        if inputText.isEmpty {
                            Text("Message Serene…")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.45))
                                .padding(.horizontal, 14)
                                .allowsHitTesting(false)
                        }
                        TextField("", text: $inputText, axis: .vertical)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .tint(.white)
                            .lineLimit(1...4)
                            .focused($inputFocused)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                    }
                    .frame(minHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { inputFocused = true }

                    Button { sendMessage() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 34))
                            .foregroundColor(canSend ? .white : .white.opacity(0.28))
                    }
                    .disabled(!canSend)
                    .animation(.easeInOut(duration: 0.15), value: canSend)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.15))
            }
        }
        .onAppear {
            if !hasSeenDisclaimer { showDisclaimer = true }
        }
        .sheet(isPresented: $showDisclaimer) {
            ChatDisclaimerSheet {
                hasSeenDisclaimer = true
                showDisclaimer = false
            }
        }
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty && !isResponding
    }

    // MARK: - Send

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !isResponding else { return }
        inputText = ""
        inputFocused = false

        messages.append(CoachChatMessage(role: "user", content: text))

        // Monthly message limit check
        if monthlyMessageCount() >= monthlyMessageLimit {
            messages.append(CoachChatMessage(role: "assistant", content: "You've used all your Serene chat sessions for this month. Your access resets on the 1st of next month. In the meantime, your breathing and meditation sessions are always available."))
            return
        }
        incrementMessageCount()

        // Safety detection — never send to AI, always respond with hardcoded message
        let lower = text.lowercased()
        if crisisKeywords.contains(where: { lower.contains($0) }) {
            messages.append(CoachChatMessage(role: "assistant", content: crisisResponse))
            return
        }
        if threatKeywords.contains(where: { lower.contains($0) }) {
            messages.append(CoachChatMessage(role: "assistant", content: threatResponse))
            return
        }
        isResponding = true

        // Snapshot before appending placeholder
        let apiMessages = messages

        // Append streaming placeholder
        let placeholder = CoachChatMessage(role: "assistant", content: "", isStreaming: true)
        messages.append(placeholder)
        let targetID = placeholder.id

        Task {
            do {
                for try await chunk in CoachChatService.stream(messages: apiMessages) {
                    await MainActor.run {
                        if let idx = messages.firstIndex(where: { $0.id == targetID }) {
                            messages[idx].content += chunk
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    if let idx = messages.firstIndex(where: { $0.id == targetID }) {
                        messages[idx].content = "Sorry, I couldn't connect right now. Please try again."
                    }
                }
            }
            await MainActor.run {
                if let idx = messages.firstIndex(where: { $0.id == targetID }) {
                    messages[idx].isStreaming = false
                }
                isResponding = false
            }
        }
    }
}

// MARK: - Chat Bubble

private struct ChatBubble: View {
    let message: CoachChatMessage
    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 56) }

            if !isUser {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 30, height: 30)
                    Image(systemName: "sparkles")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                }
            }

            Group {
                if message.content.isEmpty && message.isStreaming {
                    TypingDotsView()
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                } else {
                    Text(message.content)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(isUser ? Color(red: 0.04, green: 0.14, blue: 0.36) : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isUser ? Color.white.opacity(0.90) : Color.white.opacity(0.16))
            )

            if !isUser { Spacer(minLength: 56) }
        }
    }
}

// MARK: - Typing Dots (inline, used inside streaming bubble)

private struct TypingDotsView: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.70))
                    .frame(width: 7, height: 7)
                    .scaleEffect(animate ? 1.2 : 0.7)
                    .animation(
                        .easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(Double(i) * 0.15),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

// MARK: - Chat Disclaimer Sheet

private struct ChatDisclaimerSheet: View {
    let onAccept: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.48, green: 0.80, blue: 0.98), Color(red: 0.15, green: 0.48, blue: 0.84)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle().fill(Color.white.opacity(0.20)).frame(width: 72, height: 72)
                    Image(systemName: "sparkles")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }

                VStack(spacing: 10) {
                    Text("Before you chat with Serene")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Serene is an AI wellness assistant — not a licensed therapist, counsellor, or medical professional.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                VStack(alignment: .leading, spacing: 12) {
                    disclaimerRow(icon: "exclamationmark.triangle.fill", color: Color(red: 1.0, green: 0.75, blue: 0.20),
                                  text: "Do not use this chat for medical, mental health, or emergency situations.")
                    disclaimerRow(icon: "phone.fill", color: Color(red: 0.45, green: 0.90, blue: 0.60),
                                  text: "If you are in crisis, call your local emergency number or find a crisis line at findahelpline.com.")
                    disclaimerRow(icon: "lock.fill", color: Color(red: 0.75, green: 0.92, blue: 1.00),
                                  text: "Conversations are processed by Groq (groq.com) and are not stored by Serene Breathing.")
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.12)))

                Spacer()

                Button(action: onAccept) {
                    Text("I understand — Start chatting")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.04, green: 0.14, blue: 0.36))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.92)))
                }

                Text("This disclaimer appears once.")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.50))
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 28)
        }
    }

    private func disclaimerRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Typing Indicator Row (standalone, shown while waiting for first token)

private struct TypingIndicatorView: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 30, height: 30)
                Image(systemName: "sparkles")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
            }
            TypingDotsView()
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.16)))
            Spacer(minLength: 56)
        }
    }
}
