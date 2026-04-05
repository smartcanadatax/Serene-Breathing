import SwiftUI

struct AICoachHubView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var journal: JournalStore
    @EnvironmentObject var premium: PremiumStore
    @State private var showMood     = false
    @State private var showSleep    = false
    @State private var showCheckIn  = false
    @State private var showChat     = false
    @State private var showPaywall  = false

    var body: some View {
        ZStack {
            CalmBackground()

            VStack(spacing: 0) {
                // Nav bar
                HStack {
                    if presentationMode.wrappedValue.isPresented {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.white.opacity(0.15)))
                        }
                    } else {
                        Color.clear.frame(width: 44, height: 44)
                    }
                    Spacer()
                    Text("Serene")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 20) {
                        Spacer(minLength: 8)

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
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.calmMid)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.87, green: 0.89, blue: 0.96)))
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

                    // ── What Serene Can Help With ───────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What Serene Can Help With")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)

                        VStack(spacing: 0) {
                            SereneFeatureRow(icon: "lungs.fill",                  label: "Box Breathing, 4-7-8, Custom Breathing",   section: "Breathe")
                            SereneFeatureRow(icon: "bolt.heart.fill",             label: "SOS Breathing, Quick Relief",               section: "Breathe")
                            SereneFeatureRow(icon: "calendar.badge.checkmark",    label: "Daily Practice",                            section: "Breathe")
                            SereneFeatureRow(icon: "brain.head.profile",          label: "Meditation Timer, Silent Meditation",       section: "Session")
                            SereneFeatureRow(icon: "sunrise.fill",                label: "Morning Meditation",                        section: "Session")
                            SereneFeatureRow(icon: "moon.stars.fill",             label: "Sleep Meditation, Sleep Stories",           section: "Session")
                            SereneFeatureRow(icon: "figure.mind.and.body",        label: "Body Scan, Still Waters, Deep Relax",       section: "Session")
                            SereneFeatureRow(icon: "wand.and.stars",              label: "Personalized Meditation",                   section: "Session")
                            SereneFeatureRow(icon: "waveform",                    label: "Relaxing Sounds, Ambient Music",            section: "Sounds")
                            SereneFeatureRow(icon: "book.fill",                   label: "AI Sleep Stories",                          section: "Sounds")
                        }
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color(red: 0.87, green: 0.89, blue: 0.96)))
                        .padding(.horizontal, 24)
                    }

                    DisclaimerFooter().padding(.bottom, 80)
                    }  // LazyVStack
                }  // ScrollView
            }  // VStack
        }  // ZStack
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
            CoachChatView().environmentObject(journal).environmentObject(premium)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall).environmentObject(premium)
        }
    }
}

// MARK: - Feature Row

private struct SereneFeatureRow: View {
    let icon: String
    let label: String
    let section: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(.calmAccent)
                .frame(width: 28)
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.calmDeep)
            Spacer()
            Text(section)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.calmMid)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(Divider().padding(.leading, 56), alignment: .bottom)
    }
}

// MARK: - Featured Chat Card

private struct FeaturedChatCard: View {

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.52, green: 0.30, blue: 0.80),
                            Color(red: 0.68, green: 0.44, blue: 0.80)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.20), lineWidth: 1)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    LotusOrbView(isAnimating: true)
                        .frame(width: 54, height: 54)
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
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.88))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Spacer()
                    Text("Start Chatting →")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.52, green: 0.30, blue: 0.80))
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
    var locked: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.87, green: 0.89, blue: 0.96))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(locked ? Color(red: 0.541, green: 0.357, blue: 0.804).opacity(0.40) : Color(red: 0.541, green: 0.357, blue: 0.804))
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
                Image(systemName: locked ? "lock.fill" : "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.calmMid.opacity(0.60))
            }

            Text(subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.calmMid)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.87, green: 0.89, blue: 0.96))
        )
    }
}
