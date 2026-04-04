import SwiftUI

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
                    // Header
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

                    // Rows
                    VStack(spacing: 10) {
                        NavigationLink(destination: RelaxingSoundsView()
                            .environmentObject(soundPlayer)
                            .environmentObject(userPrefs)
                            .environmentObject(premium)
                        ) {
                            SoundsHubRow(
                                icon: "waveform",
                                title: "Sounds Library",
                                subtitle: "Nature · Meditation · Sleep sounds"
                            )
                        }

                        NavigationLink(destination: AmbientMusicView()) {
                            SoundsHubRow(
                                icon: "music.note",
                                title: "Ambient Music",
                                subtitle: "Focus · Sleep · Creativity playlists"
                            )
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

// MARK: - Row

private struct SoundsHubRow: View {
    let icon: String
    let title: String
    let subtitle: String

    private let brandPurple = Color(red: 0.541, green: 0.357, blue: 0.804)

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                    .shadow(color: brandPurple.opacity(0.15), radius: 4, x: 0, y: 2)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(brandPurple)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.28))
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(red: 0.20, green: 0.28, blue: 0.50).opacity(0.75))
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
