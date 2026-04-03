import SwiftUI

// MARK: - Meditation Hub View
// Session tab root — lists all meditation features

struct MeditationHubView: View {
    @EnvironmentObject var premium: PremiumStore
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            CalmBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 6) {
                        AppLogoView(size: 64)
                            .padding(.top, 20)
                        Text("Meditation")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Guided sessions for mind & body")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.70))
                    }
                    .padding(.bottom, 24)

                    // Sessions
                    VStack(spacing: 10) {
                        MeditationHubRow(
                            icon: "timer",
                            title: "Start Meditation",
                            subtitle: "Countdown session",
                            destination: AnyView(MeditationTimerView()),
                            locked: false
                        )

                        MeditationHubRow(
                            icon: "sunrise.fill",
                            title: "Morning Meditation",
                            subtitle: "Start your day with clarity",
                            destination: AnyView(MorningMeditationView()),
                            locked: false
                        )

                        MeditationHubRow(
                            icon: "moon.stars.fill",
                            title: "Sleep Meditation",
                            subtitle: "Drift into deep restful sleep",
                            destination: AnyView(SleepMeditationView()),
                            locked: !premium.isPremium,
                            onLock: { showPaywall = true }
                        )

                        MeditationHubRow(
                            icon: "bell.fill",
                            title: "Silent Meditation",
                            subtitle: "Sit in stillness, guided by a bell",
                            destination: AnyView(MeditationTimerView(startSilent: true)),
                            locked: !premium.isPremium,
                            onLock: { showPaywall = true }
                        )

                        MeditationHubRow(
                            icon: "figure.mind.and.body",
                            title: "Body Scan",
                            subtitle: "Guided head-to-toe relaxation",
                            destination: AnyView(BodyScanView()),
                            locked: !premium.isPremium,
                            onLock: { showPaywall = true }
                        )

                        MeditationHubRow(
                            icon: "sparkles",
                            title: "Personalized Meditation",
                            subtitle: "A session tailored just for you",
                            destination: AnyView(PersonalizedMeditationView()),
                            locked: !premium.isPremium,
                            onLock: { showPaywall = true }
                        )

                        MeditationHubRow(
                            icon: "book.fill",
                            title: "Sleep Stories",
                            subtitle: "Calming narrated stories for sleep",
                            destination: AnyView(SleepStoriesView()),
                            locked: !premium.isPremium,
                            onLock: { showPaywall = true }
                        )

                        MeditationHubRow(
                            icon: "sparkles.rectangle.stack.fill",
                            title: "Deep Relax",
                            subtitle: "Immersive video relaxation",
                            destination: AnyView(DeepRelaxView()),
                            locked: !premium.isPremium,
                            onLock: { showPaywall = true }
                        )

                        MeditationHubRow(
                            icon: "drop.fill",
                            title: "Still Waters",
                            subtitle: "Guided calm meditation",
                            destination: AnyView(StillWatersView()),
                            locked: !premium.isPremium,
                            onLock: { showPaywall = true }
                        )
                    }
                    .padding(.horizontal, 20)

                    DisclaimerFooter()
                        .padding(.bottom, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall)
                .environmentObject(premium)
        }
    }
}

// MARK: - Row

private struct MeditationHubRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let destination: AnyView
    let locked: Bool
    var onLock: (() -> Void)? = nil

    private let brandPurple = Color(red: 0.541, green: 0.357, blue: 0.804)

    var body: some View {
        Group {
            if locked {
                Button { onLock?() } label: { rowContent }
                    .buttonStyle(.plain)
            } else {
                NavigationLink(destination: destination) { rowContent }
            }
        }
    }

    private var rowContent: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                    .shadow(color: brandPurple.opacity(0.15), radius: 4, x: 0, y: 2)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(locked ? brandPurple.opacity(0.35) : brandPurple)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(locked ? Color(red: 0.08, green: 0.12, blue: 0.28).opacity(0.45) : Color(red: 0.08, green: 0.12, blue: 0.28))
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.20, green: 0.28, blue: 0.50).opacity(0.50))
                    }
                }
                Text(locked ? "Premium" : subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(locked ? brandPurple.opacity(0.70) : Color(red: 0.20, green: 0.28, blue: 0.50).opacity(0.75))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 0.20, green: 0.28, blue: 0.50).opacity(0.45))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.85))
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
    }
}
