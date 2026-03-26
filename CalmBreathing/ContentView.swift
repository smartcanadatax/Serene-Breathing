import SwiftUI

// MARK: - App Colour Palette
extension Color {
    /// Dark navy — primary text & button labels
    static let calmDeep   = Color(red: 0.04, green: 0.14, blue: 0.36)
    /// Medium navy — secondary text
    static let calmMid    = Color(red: 0.10, green: 0.30, blue: 0.60)
    /// Light ice blue — accent highlights & buttons
    static let calmAccent = Color(red: 0.75, green: 0.92, blue: 1.00)
    /// Soft periwinkle — secondary accent
    static let calmPurple = Color(red: 0.55, green: 0.82, blue: 1.00)
    /// Cyan — exhale phase
    static let calmTeal   = Color(red: 0.30, green: 0.88, blue: 0.98)
}

// MARK: - Shared Background
struct CalmBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.48, green: 0.80, blue: 0.98),
                Color(red: 0.30, green: 0.64, blue: 0.92),
                Color(red: 0.15, green: 0.48, blue: 0.84)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
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
                        BreathingView()
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
                        MeditationTimerView()
                    }
                    .tabItem {
                        Label("Timer", systemImage: "timer")
                    }

                    NavigationStack {
                        AICoachHubView()
                            .environmentObject(journal)
                    }
                    .tabItem {
                        Label("AI Coach", systemImage: "sparkles")
                    }

                    NavigationStack {
                        ProgressTabView()
                    }
                    .tabItem {
                        Label("Progress", systemImage: "chart.bar.fill")
                    }
                }
                .tint(.white)
            }
        }
        .transaction { $0.animation = nil }
    }
}
