import SwiftUI

struct AICoachHubView: View {
    @EnvironmentObject var journal: JournalStore
    @EnvironmentObject var premium: PremiumStore
    @State private var showMood     = false
    @State private var showSleep    = false
    @State private var showCheckIn  = false
    @State private var showChat     = false

    var body: some View {
        ZStack {
            CalmBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer(minLength: 32)

                    // Header
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 80, height: 80)
                            Image(systemName: "sparkles")
                                .font(.system(size: 34))
                                .foregroundColor(.white)
                        }
                        Text("AI Coach")
                            .font(.system(size: 26, weight: .semibold, design: .rounded))
                            .foregroundColor(.calmDeep)
                        Text("Personalized sessions based on your real data — not just how you feel right now.")
                            .font(.system(size: 14))
                            .foregroundColor(.calmMid)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }

                    // ── Featured: Chat with Serene ──────────────────────
                    Button { showChat = true } label: {
                        FeaturedChatCard()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)

                    // Daily logging reminder
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Build Your Pattern", systemImage: "calendar.badge.clock")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.calmAccent)
                        Text("Use Daily Check-In for an instant AI insight every day. The more you log, the deeper Mood and Sleep Pattern Coaches can analyze your trends.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.12)))
                    .padding(.horizontal, 24)

                    // Daily Check-In card
                    Button { showCheckIn = true } label: {
                        AICoachCard(
                            icon: "sun.and.horizon.fill",
                            title: "Daily Check-In",
                            subtitle: "Log your mood and sleep, then get a personalized AI insight and session recommendation for your day.",
                            tag: "Mood · Sleep · Daily Insight"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)

                    // Mood Pattern Coach card
                    Button { showMood = true } label: {
                        AICoachCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Mood Pattern Coach",
                            subtitle: "Analyzes your last 7 days of mood data and creates a personalized breathing session for your patterns.",
                            tag: "Mood · Stress · Anxiety"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)

                    // Sleep Pattern Coach card
                    Button { showSleep = true } label: {
                        AICoachCard(
                            icon: "moon.zzz.fill",
                            title: "Sleep Pattern Coach",
                            subtitle: "Analyzes your last 7 nights of sleep data and generates a tailored wind-down session.",
                            tag: "Sleep · Rest · Recovery"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)

                    DisclaimerFooter().padding(.bottom, 80)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showMood) {
            MoodPatternCoachView().environmentObject(journal)
        }
        .fullScreenCover(isPresented: $showSleep) {
            SleepPatternCoachView().environmentObject(journal)
        }
        .fullScreenCover(isPresented: $showCheckIn) {
            DailyCheckInView().environmentObject(journal).environmentObject(premium)
        }
        .fullScreenCover(isPresented: $showChat) {
            CoachChatView().environmentObject(journal)
        }
    }
}

// MARK: - Featured Chat Card

private struct FeaturedChatCard: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.42, green: 0.22, blue: 0.78),
                            Color(red: 0.22, green: 0.42, blue: 0.90)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.20), lineWidth: 1)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        // Pulse ring
                        Circle()
                            .stroke(Color.white.opacity(0.30), lineWidth: 1.5)
                            .frame(width: 54, height: 54)
                            .scaleEffect(isPulsing ? 1.55 : 1.0)
                            .opacity(isPulsing ? 0 : 0.7)
                            .animation(
                                .easeOut(duration: 2.2).repeatForever(autoreverses: false),
                                value: isPulsing
                            )
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 54, height: 54)
                        Image(systemName: "sparkles")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .onAppear { isPulsing = true }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chat with Serene")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Text("AI · Chat · Wellness")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.70))
                    }
                    Spacer()
                }

                Text("Talk to your personal AI wellness coach anytime. Get breathing recommendations, mood support, and mindfulness guidance in real time.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.88))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Spacer()
                    Text("Start Chatting →")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.42, green: 0.22, blue: 0.78))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Color.white))
                }
            }
            .padding(18)
        }
        .shadow(color: Color(red: 0.42, green: 0.22, blue: 0.78).opacity(0.35), radius: 16, x: 0, y: 6)
    }
}

// MARK: - Coach Card

private struct AICoachCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let tag: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.calmDeep)
                    Text(tag)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.calmMid)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.calmMid.opacity(0.60))
            }

            Text(subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.calmMid)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.50))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.calmDeep.opacity(0.08), lineWidth: 1))
        )
    }
}
