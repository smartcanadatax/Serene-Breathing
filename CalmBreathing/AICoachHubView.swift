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

                    // Daily Check-in card — goes FIRST, before Mood Pattern Coach
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

                    // Chat with Serene card
                    Button { showChat = true } label: {
                        AICoachCard(
                            icon: "bubble.left.and.bubble.right.fill",
                            title: "Chat with Serene",
                            subtitle: "Have a real conversation with your AI wellness coach. Ask anything about stress, sleep, or breathing.",
                            tag: "Chat · Wellness · Breathing Tips"
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
