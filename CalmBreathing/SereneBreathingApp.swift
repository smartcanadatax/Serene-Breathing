import SwiftUI

@main
struct SereneBreathingApp: App {
    // Shared sound player injected as environment object throughout the app
    @StateObject private var soundPlayer   = SoundPlayer()
    @StateObject private var userPrefs     = UserPreferencesStore()
    @StateObject private var journal       = JournalStore()
    @StateObject private var premium       = PremiumStore()
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("hasAgreedToTerms") private var hasAgreedToTerms = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasRequestedHealth") private var hasRequestedHealth = false
    @State private var showLaunch = true
    @State private var showHealthPermission = false

    init() {
        _ = PhoneSession.shared   // activate WatchConnectivity on launch
        // TODO: Remove before submitting — testing only
        // premium.forceUnlock()

        // Liquid glass tab bar
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.22)
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.30)
        // Selected item
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.02, green: 0.08, blue: 0.28, alpha: 1)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0.04, green: 0.14, blue: 0.36, alpha: 1),
            .font: UIFont.systemFont(ofSize: 10, weight: .bold)
        ]
        // Unselected item
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(red: 0.04, green: 0.14, blue: 0.36, alpha: 0.35)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0.04, green: 0.14, blue: 0.36, alpha: 0.45),
            .font: UIFont.systemFont(ofSize: 10, weight: .regular)
        ]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor(red: 0.04, green: 0.14, blue: 0.36, alpha: 1)
    }

    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasAgreedToTerms {
                    ContentView()
                        .environmentObject(soundPlayer)
                        .environmentObject(userPrefs)
                        .environmentObject(journal)
                        .environmentObject(premium)
                        .preferredColorScheme(darkMode ? .dark : .light)
                } else {
                    TermsGateView()
                        .preferredColorScheme(darkMode ? .dark : .light)
                }

                if showLaunch {
                    LaunchAnimationView {
                        showLaunch = false
                        // Show Health permission after onboarding is done
                        if hasAgreedToTerms && hasSeenOnboarding && !hasRequestedHealth {
                            showHealthPermission = true
                        }
                    }
                }
            }
            .onChange(of: hasSeenOnboarding) { _, newValue in
                if newValue && hasAgreedToTerms && !hasRequestedHealth {
                    showHealthPermission = true
                }
            }
            .fullScreenCover(isPresented: $showHealthPermission) {
                HealthPermissionView {
                    // Allow tapped — request system permission
                    hasRequestedHealth = true
                    showHealthPermission = false
                    HealthKitManager.shared.requestAuthorization { _ in }
                } onSkip: {
                    hasRequestedHealth = true
                    showHealthPermission = false
                }
            }
        }
    }
}
