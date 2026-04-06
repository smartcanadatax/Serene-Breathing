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
                Color(red: 0.31, green: 0.44, blue: 0.77),
                Color(red: 0.30, green: 0.43, blue: 0.76),
                Color(red: 0.28, green: 0.41, blue: 0.74)
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
            .padding(.top, 20)
    }
}

// MARK: - Shiny Serene Title
struct SereneTitle: View {
    private let shinyGradient = LinearGradient(
        stops: [
            .init(color: Color(red: 1.00, green: 0.98, blue: 1.00), location: 0.0),
            .init(color: Color(red: 0.94, green: 0.90, blue: 0.99), location: 0.15),
            .init(color: Color(red: 0.78, green: 0.70, blue: 0.95), location: 0.40),
            .init(color: Color(red: 0.86, green: 0.80, blue: 0.97), location: 0.60),
            .init(color: Color(red: 0.94, green: 0.91, blue: 0.99), location: 0.82),
            .init(color: Color(red: 1.00, green: 0.98, blue: 1.00), location: 1.0),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        VStack(spacing: 2) {
            Text("Serene")
                .font(.custom("Georgia-BoldItalic", size: 36).leading(.tight))
                .foregroundStyle(shinyGradient)
            Text("BREATHING")
                .font(.system(size: 11, weight: .bold))
                .kerning(6)
                .foregroundStyle(shinyGradient)
        }
    }
}

// MARK: - Root View
struct ContentView: View {
    @AppStorage("hasAgreedToTerms")  private var hasAgreedToTerms  = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @EnvironmentObject var journal: JournalStore

    var body: some View {
        ZStack {
            if !hasAgreedToTerms {
                TermsGateView()
                    .transition(.identity)
            } else if !hasSeenOnboarding {
                OnboardingView()
                    .transition(.identity)
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
                        SoundsHubView()
                    }
                    .tabItem {
                        Label("Sounds", systemImage: "waveform")
                    }

                    NavigationStack {
                        MeditationHubView()
                    }
                    .tabItem {
                        Label("Session", systemImage: "figure.mind.and.body")
                    }

                    NavigationStack {
                        AICoachHubView()
                            .environmentObject(journal)
                    }
                    .tabItem {
                        Label("Serene", systemImage: "sparkles")
                    }
                }
                .tint(.white)
                .transition(.identity)
            }
        }
        .animation(nil, value: hasSeenOnboarding)
        .animation(nil, value: hasAgreedToTerms)
    }
}
