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

// MARK: - Sounds Hub
struct SoundsHubView: View {
    @EnvironmentObject var premium:     PremiumStore
    @EnvironmentObject var soundPlayer: SoundPlayer
    @EnvironmentObject var userPrefs:   UserPreferencesStore

    var body: some View {
        ZStack {
            CalmBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 6) {
                        AppLogoView(size: 64)
                            .padding(.top, 20)
                        Text("Sounds")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Relax, focus & drift off")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.70))
                    }
                    .padding(.bottom, 24)

                    VStack(spacing: 10) {
                        NavigationLink(destination: RelaxingSoundsView()
                            .environmentObject(soundPlayer)
                            .environmentObject(userPrefs)
                            .environmentObject(premium)
                        ) {
                            SoundsHubRow(icon: "waveform", title: "Sounds Library", subtitle: "Nature · Meditation · Sleep sounds")
                        }
                        NavigationLink(destination: AmbientMusicView()) {
                            SoundsHubRow(icon: "music.note", title: "Ambient Music", subtitle: "Focus · Sleep · Creativity playlists")
                        }
                    }
                    .padding(.horizontal, 20)

                    DisclaimerFooter()
                        .padding(.bottom, 16)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

private struct SoundsHubRow: View {
    let icon: String
    let title: String
    let subtitle: String
    private let brandPurple = Color(red: 0.541, green: 0.357, blue: 0.804)
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.white).frame(width: 50, height: 50)
                    .shadow(color: brandPurple.opacity(0.15), radius: 4, x: 0, y: 2)
                Image(systemName: icon).font(.system(size: 20)).foregroundColor(brandPurple)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundColor(.calmDeep)
                Text(subtitle).font(.system(size: 12, weight: .regular)).foregroundColor(.calmMid.opacity(0.70))
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(.calmMid.opacity(0.45))
        }
        .padding(.horizontal, 18).padding(.vertical, 15)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(red: 0.87, green: 0.89, blue: 0.96))
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2))
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
                        SoundsHubView()
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
