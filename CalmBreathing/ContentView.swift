import SwiftUI

// MARK: - App Colour Palette
extension Color {
    /// Dark navy — primary text
    static let calmDeep   = Color(red: 0.08, green: 0.12, blue: 0.28)
    /// Medium navy — secondary text
    static let calmMid    = Color(red: 0.20, green: 0.28, blue: 0.50)
    /// Brand purple — icons, accents, highlights
    static let calmAccent = Color(red: 0.541, green: 0.357, blue: 0.804)
    /// Mid brand purple — secondary accent
    static let calmPurple = Color(red: 0.647, green: 0.427, blue: 0.788)
    /// Soft purple — exhale phase
    static let calmTeal   = Color(red: 0.796, green: 0.659, blue: 0.902)
}

// MARK: - Shared Background
struct CalmBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.46, green: 0.64, blue: 0.92),
                Color(red: 0.36, green: 0.54, blue: 0.86),
                Color(red: 0.28, green: 0.46, blue: 0.80)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Shared Disclaimer Footer
struct DisclaimerFooter: View {
    var body: some View {
        Text("For relaxation & wellness purposes only. Not a substitute for medical or mental health advice. Respiratory, cardiac, or any other health condition patients should consult a doctor before practising breathing exercises.")
            .font(.system(size: 10, weight: .light))
            .foregroundColor(.white.opacity(0.72))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)
            .padding(.vertical, 10)
    }
}

// MARK: - Root View
struct ContentView: View {
    @AppStorage("hasAgreedToTerms")  private var hasAgreedToTerms  = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @EnvironmentObject var journal: JournalStore

    var body: some View {
        Group {
            if !hasAgreedToTerms {
                TermsGateView()
            } else if !hasSeenOnboarding {
                OnboardingView()
            } else {
                TabView {
                    NavigationStack {
                        HomeView()
                    }
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                    NavigationStack {
                        BreathingHubView()
                    }
                    .tabItem {
                        Label("Breathe", systemImage: "lungs.fill")
                    }

                    NavigationStack {
                        RelaxingSoundsView()
                    }
                    .tabItem {
                        Label("Sounds", systemImage: "waveform")
                    }

                    NavigationStack {
                        MeditationHubView()
                    }
                    .tabItem {
                        Label("Session", systemImage: "moon.stars.fill")
                    }

                    NavigationStack {
                        AICoachHubView()
                            .environmentObject(journal)
                    }
                    .tabItem {
                        Label("AI Coach", systemImage: "sparkles")
                    }
                }
                .tint(.white)
            }
        }
        .transaction { $0.animation = nil }
    }
}
