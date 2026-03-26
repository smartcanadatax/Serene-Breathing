import SwiftUI
import UserNotifications

// MARK: - Onboarding View
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "circle.fill",
            iconColor: Color(red: 0.55, green: 0.20, blue: 0.80),
            title: "Welcome to\nSerene Breathing",
            body: "Your daily companion for calm, focus, and better sleep. Just a few minutes a day can transform how you feel.",
            buttonLabel: "Next"
        ),
        OnboardingPage(
            icon: "lungs.fill",
            iconColor: Color(red: 0.55, green: 0.82, blue: 1.00),
            title: "Breathe, Meditate\n& Relax",
            body: "Guided breathing patterns, ambient sounds, and meditation timers — everything you need in one peaceful place.",
            buttonLabel: "Next"
        ),
        OnboardingPage(
            icon: "flame.fill",
            iconColor: Color(red: 1.0, green: 0.60, blue: 0.25),
            title: "Build a\nDaily Habit",
            body: "Track your meditation streak, earn badges, and watch your wellbeing improve day by day.",
            buttonLabel: "Next"
        ),
        OnboardingPage(
            icon: "bell.badge.fill",
            iconColor: Color(red: 0.75, green: 0.92, blue: 1.00),
            title: "Stay on Track",
            body: "Get a gentle daily reminder to meditate — only if you want one. You're always in control.",
            buttonLabel: "Get Started"
        ),
    ]

    var body: some View {
        ZStack {
            CalmBackground()

            VStack(spacing: 0) {
                Spacer()

                // Page icon
                ZStack {
                    if page == 0 {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 240, height: 240)
                        Image(systemName: pages[page].icon)
                            .font(.system(size: 108, weight: .ultraLight))
                            .foregroundColor(pages[page].iconColor)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: page)
                .padding(.bottom, 36)

                // Text
                VStack(spacing: 16) {
                    Text(pages[page].title)
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.3), value: page)

                    Text(pages[page].body)
                        .font(.system(size: 16, weight: .light, design: .rounded))
                        .foregroundColor(.white.opacity(0.90))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 36)
                        .animation(.easeInOut(duration: 0.3), value: page)
                }

                Spacer()

                // Dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Color.white : Color.white.opacity(0.30))
                            .frame(width: i == page ? 20 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: page)
                    }
                }
                .padding(.bottom, 32)

                // Button
                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        // Last page — ask for notification permission then finish
                        requestNotificationPermission {
                            hasSeenOnboarding = true
                        }
                    }
                } label: {
                    Text(pages[page].buttonLabel)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.calmDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color.calmAccent))
                        .shadow(color: .calmAccent.opacity(0.35), radius: 12)
                }
                .padding(.horizontal, 32)

                // Skip
                if page < pages.count - 1 {
                    Button("Skip") {
                        hasSeenOnboarding = true
                    }
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white.opacity(0.60))
                    .padding(.top, 16)
                }

                Spacer().frame(height: 48)
            }
            .padding(.horizontal, 24)
        }
    }

    private func requestNotificationPermission(completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            DispatchQueue.main.async { completion() }
        }
    }
}

private struct OnboardingPage {
    let icon:        String
    let iconColor:   Color
    let title:       String
    let body:        String
    let buttonLabel: String
}
