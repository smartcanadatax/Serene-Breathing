import SwiftUI
import UserNotifications

// MARK: - Onboarding View
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("userGoal")          private var userGoal          = ""
    @State private var page = 0

    // Goal selection page is index 1
    private let goalPage = 1
    private let totalPages = 5  // 0: welcome, 1: goal, 2: breathe, 3: habit, 4: notifications

    private let goals: [(icon: String, label: String, value: String, color: Color)] = [
        ("moon.zzz.fill",         "Sleep Better",     "sleep",   Color(red: 0.30, green: 0.40, blue: 0.80)),
        ("brain.head.profile",    "Reduce Stress",    "stress",  Color(red: 0.55, green: 0.28, blue: 0.80)),
        ("scope",                 "Improve Focus",    "focus",   Color(red: 0.20, green: 0.60, blue: 0.90)),
        ("heart.fill",            "General Wellness", "wellness",Color(red: 0.90, green: 0.45, blue: 0.55)),
    ]

    private let pages: [OnboardingPage] = [
        OnboardingPage(icon: "circle.fill",     iconColor: Color(red: 0.55, green: 0.20, blue: 0.80),
                       title: "Welcome to\nSerene Breathing",
                       body: "Your daily companion for calm, focus, and better sleep. Just a few minutes a day can transform how you feel.",
                       buttonLabel: "Next"),
        OnboardingPage(icon: "",                iconColor: .clear,
                       title: "What's your\nmain goal?",
                       body: "We'll personalise your experience based on what matters most to you.",
                       buttonLabel: "Next"),
        OnboardingPage(icon: "lungs.fill",      iconColor: Color(red: 0.55, green: 0.82, blue: 1.00),
                       title: "Breathe, Meditate\n& Relax",
                       body: "Guided breathing patterns, ambient sounds, and meditation timers — everything you need in one peaceful place.",
                       buttonLabel: "Next"),
        OnboardingPage(icon: "flame.fill",      iconColor: Color(red: 1.0, green: 0.60, blue: 0.25),
                       title: "Build a\nDaily Habit",
                       body: "Track your meditation streak, earn badges, and watch your wellbeing improve day by day.",
                       buttonLabel: "Next"),
        OnboardingPage(icon: "bell.badge.fill", iconColor: Color(red: 0.75, green: 0.92, blue: 1.00),
                       title: "Stay on Track",
                       body: "Get a gentle daily reminder to meditate — only if you want one. You're always in control.",
                       buttonLabel: "Get Started"),
    ]

    var body: some View {
        ZStack {
            CalmBackground()

            VStack(spacing: 0) {
                Spacer()

                // MARK: Page Content
                if page == goalPage {
                    // Goal selection
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            Text(pages[page].title)
                                .font(.system(size: 30, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            Text(pages[page].body)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 24)
                        }

                        VStack(spacing: 12) {
                            ForEach(goals, id: \.value) { goal in
                                Button {
                                    withAnimation(.spring(response: 0.3)) { userGoal = goal.value }
                                } label: {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(goal.color.opacity(userGoal == goal.value ? 0.30 : 0.15))
                                                .frame(width: 46, height: 46)
                                            Image(systemName: goal.icon)
                                                .font(.system(size: 20))
                                                .foregroundColor(userGoal == goal.value ? goal.color : .white.opacity(0.70))
                                        }
                                        Text(goal.label)
                                            .font(.system(size: 16, weight: userGoal == goal.value ? .semibold : .regular, design: .rounded))
                                            .foregroundColor(.white)
                                        Spacer()
                                        if userGoal == goal.value {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.calmAccent)
                                                .font(.system(size: 20))
                                        }
                                    }
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(userGoal == goal.value ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
                                            .overlay(RoundedRectangle(cornerRadius: 16)
                                                .stroke(userGoal == goal.value ? Color.calmAccent.opacity(0.60) : Color.clear, lineWidth: 1.5))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                } else {
                    // Standard icon page
                    ZStack {
                        if page == 0 {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 200, height: 200)
                            Image(systemName: pages[page].icon)
                                .font(.system(size: 90, weight: .regular))
                                .foregroundColor(pages[page].iconColor)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: page)
                    .padding(.bottom, 36)

                    VStack(spacing: 16) {
                        Text(pages[page].title)
                            .font(.system(size: 30, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .animation(.easeInOut(duration: 0.3), value: page)

                        Text(pages[page].body)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.90))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 36)
                            .animation(.easeInOut(duration: 0.3), value: page)
                    }
                }

                Spacer()

                // MARK: Dots
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Color.white : Color.white.opacity(0.30))
                            .frame(width: i == page ? 20 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: page)
                    }
                }
                .padding(.bottom, 28)

                // MARK: Button
                Button {
                    if page < totalPages - 1 {
                        withAnimation { page += 1 }
                    } else {
                        requestNotificationPermission { hasSeenOnboarding = true }
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
                .disabled(page == goalPage && userGoal.isEmpty)
                .opacity(page == goalPage && userGoal.isEmpty ? 0.45 : 1)

                // Skip
                if page < totalPages - 1 {
                    Button("Skip") { hasSeenOnboarding = true }
                        .font(.system(size: 14, weight: .regular))
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
