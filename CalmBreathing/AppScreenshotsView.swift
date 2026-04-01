import SwiftUI

// MARK: - App Screenshots View
// Run on iPhone 13 Pro Max Simulator, navigate to each page and screenshot (Cmd+S)

struct AppScreenshotsView: View {
    @State private var page = 0
    private let total = 6

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $page) {
                ScreenshotSlide1().tag(0)
                ScreenshotSlide2().tag(1)
                ScreenshotSlide3().tag(2)
                ScreenshotSlide4().tag(3)
                ScreenshotSlide5().tag(4)
                ScreenshotSlide6().tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Dot indicator
            HStack(spacing: 8) {
                ForEach(0..<total, id: \.self) { i in
                    Circle()
                        .fill(i == page ? Color.white : Color.white.opacity(0.35))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 36)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Shared Helpers

private struct ScreenshotBg: View {
    var colors: [Color] = [
        Color(red: 0.42, green: 0.72, blue: 0.95),
        Color(red: 0.28, green: 0.58, blue: 0.88),
        Color(red: 0.18, green: 0.45, blue: 0.80)
    ]
    var body: some View {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}

private struct Headline: View {
    let top: String
    let bottom: String
    var body: some View {
        VStack(spacing: 6) {
            Text(top)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
            Text(bottom)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.62, green: 0.88, blue: 1.00))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(.horizontal, 28)
    }
}

private struct SubHeadline: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 17, weight: .regular, design: .rounded))
            .foregroundColor(.white.opacity(0.75))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 36)
    }
}

private struct MockCard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(spacing: 0) { content() }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.10))
                    .overlay(RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1))
            )
            .padding(.horizontal, 28)
    }
}

// MARK: - Slide 1: Home / Overview

private struct ScreenshotSlide1: View {
    var body: some View {
        ZStack {
            ScreenshotBg()
            VStack(spacing: 0) {
                Spacer(minLength: 72)
                Headline(top: "Your daily calm,", bottom: "all in one place")
                Spacer(minLength: 12)
                SubHeadline(text: "Breathe · Meditate · Sleep · Relax")
                Spacer(minLength: 40)

                // Mock feature grid
                VStack(spacing: 10) {
                    MockFeatureTile(icon: "lungs.fill",         label: "Breathing",  color: Color(red: 0.40, green: 0.80, blue: 0.95))
                    MockFeatureTile(icon: "brain.head.profile", label: "Meditate",   color: Color(red: 0.62, green: 0.48, blue: 0.92))
                    MockFeatureTile(icon: "waveform",           label: "Sounds",     color: Color(red: 0.35, green: 0.78, blue: 0.65))
                    MockFeatureTile(icon: "sparkles",           label: "AI Coach",   color: Color(red: 0.90, green: 0.65, blue: 0.95))
                    MockFeatureTile(icon: "moon.stars.fill",    label: "Sleep",      color: Color(red: 0.45, green: 0.60, blue: 0.98))
                    MockFeatureTile(icon: "chart.bar.fill",     label: "Progress",   color: Color(red: 1.00, green: 0.72, blue: 0.30))
                }
                .padding(.horizontal, 28)

                Spacer()

                // Badge row
                HStack(spacing: 16) {
                    BadgePill(text: "No login")
                    BadgePill(text: "No ads")
                    BadgePill(text: "Private")
                }
                .padding(.bottom, 60)
            }
        }
    }
}

private struct MockFeatureTile: View {
    let icon: String
    let label: String
    let color: Color
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.20)).frame(width: 46, height: 46)
                Image(systemName: icon).font(.system(size: 20)).foregroundColor(color)
            }
            Text(label)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.09))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.12), lineWidth: 1)))
        .frame(maxWidth: .infinity)
    }
}

private struct BadgePill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white.opacity(0.85))
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color.white.opacity(0.12)))
    }
}

// MARK: - Slide 2: Breathing

private struct ScreenshotSlide2: View {
    @State private var animating = false
    var body: some View {
        ZStack {
            ScreenshotBg()
            VStack(spacing: 0) {
                Spacer(minLength: 72)
                Headline(top: "Breathe away", bottom: "stress in minutes")
                Spacer(minLength: 10)
                SubHeadline(text: "Box · 4-7-8 · Custom patterns\nguided step by step")
                Spacer(minLength: 48)

                // App logo with pulse
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(0.08 - Double(i) * 0.02))
                            .frame(width: CGFloat(160 + i * 40), height: CGFloat(160 + i * 40))
                            .scaleEffect(animating ? 1.10 : 1.0)
                            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true).delay(Double(i) * 0.3), value: animating)
                    }
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 130, height: 130)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 6)
                }
                .onAppear { animating = true }

                Spacer(minLength: 40)

                // Pattern pills
                HStack(spacing: 10) {
                    ForEach(["Box", "4-7-8", "Custom"], id: \.self) { p in
                        Text(p)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(Capsule().fill(Color.white.opacity(0.14)))
                    }
                }

                Spacer()

                Text("Reduce anxiety · Lower heart rate · Improve focus")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .padding(.bottom, 60)
            }
        }
    }
}

// MARK: - Slide 3: AI Coach

private struct ScreenshotSlide3: View {
    var body: some View {
        ZStack {
            ScreenshotBg()
            VStack(spacing: 0) {
                Spacer(minLength: 72)
                Headline(top: "Your personal", bottom: "AI wellness coach")
                Spacer(minLength: 10)
                SubHeadline(text: "Powered by AI · Learns your patterns\nGives real personalized guidance")
                Spacer(minLength: 36)

                // Chat bubbles mock
                VStack(alignment: .leading, spacing: 14) {
                    ChatBubble(text: "I've been feeling really stressed and can't sleep well.", isUser: true)
                    ChatBubble(text: "I understand. Based on your recent sleep patterns, I recommend starting with a 4-7-8 breathing session tonight. It will calm your nervous system within minutes. 🌙", isUser: false)
                    ChatBubble(text: "Your mood has improved 40% over the last 7 days. Keep it up! ✨", isUser: false)
                }
                .padding(.horizontal, 28)

                Spacer(minLength: 32)

                // Feature tags
                HStack(spacing: 10) {
                    ForEach(["Mood Coach", "Sleep Coach", "Daily Insight"], id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(red: 0.80, green: 0.68, blue: 1.00))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color(red: 0.62, green: 0.48, blue: 0.92).opacity(0.22)))
                    }
                }

                Spacer()
                    .frame(height: 60)
            }
        }
    }
}

private struct ChatBubble: View {
    let text: String
    let isUser: Bool
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white)
                .lineSpacing(3)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isUser
                              ? Color(red: 0.62, green: 0.48, blue: 0.92).opacity(0.45)
                              : Color.white.opacity(0.12))
                )
            if !isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Slide 4: Sounds

private struct ScreenshotSlide4: View {
    var body: some View {
        ZStack {
            ScreenshotBg()
            VStack(spacing: 0) {
                Spacer(minLength: 72)
                Headline(top: "Fall asleep to", bottom: "nature sounds")
                Spacer(minLength: 10)
                SubHeadline(text: "Ocean · Forest · Rain · Meditation\nSleep timer built in")
                Spacer(minLength: 40)

                // Sound rows mock
                VStack(spacing: 10) {
                    ForEach([
                        ("🌊", "Ocean Waves",    "Gentle coastal waves"),
                        ("🌲", "Forest",         "Birds and rustling leaves"),
                        ("🌧️", "Rain & Thunder", "Deep sleep rainfall"),
                        ("🌙", "Sleep Meditation","Soft ambient tones"),
                        ("🧘", "Zen Water",       "Flowing water healing"),
                    ], id: \.0) { item in
                        MockSoundRow(emoji: item.0, title: item.1, subtitle: item.2)
                    }
                }
                .padding(.horizontal, 28)

                Spacer()

                // Mini player mock
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ocean Waves")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Now playing · Sleep timer: 30m")
                            .font(.system(size: 11, weight: .light))
                            .foregroundColor(.white.opacity(0.60))
                    }
                    Spacer()
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.40))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color(red: 0.18, green: 0.45, blue: 0.80).opacity(0.97))
                .padding(.bottom, 0)
            }
        }
    }
}

private struct MockSoundRow: View {
    let emoji: String
    let title: String
    let subtitle: String
    var body: some View {
        HStack(spacing: 14) {
            Text(emoji).font(.system(size: 22))
                .frame(width: 46, height: 46)
                .background(Circle().fill(Color.white.opacity(0.10)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(.white)
                Text(subtitle).font(.system(size: 12, weight: .light)).foregroundColor(.white.opacity(0.60))
            }
            Spacer()
            Image(systemName: "play.fill").font(.system(size: 14)).foregroundColor(.white.opacity(0.50))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.10), lineWidth: 1)))
    }
}

// MARK: - Slide 5: Meditation

private struct ScreenshotSlide5: View {
    @State private var animating = false
    var body: some View {
        ZStack {
            ScreenshotBg()
            VStack(spacing: 0) {
                Spacer(minLength: 72)
                Headline(top: "Guided meditations", bottom: "for every moment")
                Spacer(minLength: 10)
                SubHeadline(text: "Morning · Sleep · Body Scan\nPersonalized sessions just for you")
                Spacer(minLength: 40)

                // Lotus orb mock
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color(red: 0.62, green: 0.88, blue: 1.00).opacity(0.12 - Double(i) * 0.03), lineWidth: 1)
                            .frame(width: CGFloat(160 + i * 36), height: CGFloat(160 + i * 36))
                            .scaleEffect(animating ? 1.08 : 1.0)
                            .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(Double(i) * 0.4), value: animating)
                    }
                    Circle()
                        .fill(LinearGradient(colors: [
                            Color(red: 0.30, green: 0.60, blue: 0.95),
                            Color(red: 0.18, green: 0.40, blue: 0.80)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 140, height: 140)
                    Text("🪷").font(.system(size: 52))
                }
                .onAppear { animating = true }

                Spacer(minLength: 32)

                // Session types
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        MockSessionPill(icon: "sun.horizon.fill",         label: "Morning",    color: Color(red: 1.00, green: 0.80, blue: 0.40))
                        MockSessionPill(icon: "moon.stars.fill",      label: "Sleep",      color: Color(red: 0.45, green: 0.60, blue: 0.98))
                    }
                    HStack(spacing: 10) {
                        MockSessionPill(icon: "figure.mind.and.body", label: "Body Scan",  color: Color(red: 0.40, green: 0.80, blue: 0.75))
                        MockSessionPill(icon: "sparkles",             label: "Personalized", color: Color(red: 0.80, green: 0.65, blue: 1.00))
                    }
                }
                .padding(.horizontal, 28)

                Spacer()
                    .frame(height: 60)
            }
        }
    }
}

private struct MockSessionPill: View {
    let icon: String
    let label: String
    let color: Color
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
            Text(label).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(color.opacity(0.14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.28), lineWidth: 1)))
    }
}

// MARK: - Slide 6: Progress & Streaks

private struct ScreenshotSlide6: View {
    var body: some View {
        ZStack {
            ScreenshotBg()
            VStack(spacing: 0) {
                Spacer(minLength: 72)
                Headline(top: "Build a habit", bottom: "that sticks")
                Spacer(minLength: 10)
                SubHeadline(text: "Track your mood, sleep & streaks\nSee your progress over time")
                Spacer(minLength: 36)

                // Stats cards
                HStack(spacing: 12) {
                    MockStatCard(value: "14", label: "Day Streak", icon: "flame.fill", color: Color(red: 1.00, green: 0.55, blue: 0.20))
                    MockStatCard(value: "32", label: "Sessions",   icon: "checkmark.seal.fill", color: Color(red: 0.40, green: 0.80, blue: 0.75))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 12)

                HStack(spacing: 12) {
                    MockStatCard(value: "7.2h", label: "Avg Sleep",  icon: "moon.fill",        color: Color(red: 0.45, green: 0.60, blue: 0.98))
                    MockStatCard(value: "😊",   label: "Avg Mood",   icon: "heart.fill",       color: Color(red: 1.00, green: 0.40, blue: 0.55))
                }
                .padding(.horizontal, 28)

                Spacer(minLength: 28)

                // Mood week mock
                MockCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This Week")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.60))
                            .padding(.top, 16)
                            .padding(.horizontal, 16)
                        HStack(spacing: 0) {
                            ForEach(0..<7, id: \.self) { i in
                                let days   = ["M","T","W","T","F","S","S"]
                                let emojis = ["😔","😐","🙂","😊","😊","😄","😊"]
                                VStack(spacing: 6) {
                                    Text(emojis[i]).font(.system(size: 22))
                                    Text(days[i]).font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.50))
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 16)
                    }
                }

                Spacer()
                    .frame(height: 60)
            }
        }
    }
}

private struct MockStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.60))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(color.opacity(0.14))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(color.opacity(0.25), lineWidth: 1)))
    }
}

