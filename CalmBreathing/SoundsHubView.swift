import SwiftUI

// MARK: - Sounds Hub (combined Library + Ambient in one page)

struct SoundsHubView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var premium:     PremiumStore
    @EnvironmentObject var soundPlayer: SoundPlayer
    @EnvironmentObject var userPrefs:   UserPreferencesStore
    @StateObject private var ambientEngine = AmbientMusicEngine()

    @State private var topTab: Int = 0
    @State private var showPaywall = false

    var body: some View {
        ZStack(alignment: .bottom) {
            CalmBackground()

            VStack(spacing: 0) {
                // Nav bar
                HStack {
                    if presentationMode.wrappedValue.isPresented {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                    } else {
                        Color.clear.frame(width: 44, height: 44)
                    }
                    Spacer()
                    Text("Sounds")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    SleepTimerButton()
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.25)))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 14)

                // Sounds / Ambient pill toggle
                HStack(spacing: 0) {
                    ForEach([("Sounds", 0), ("Ambient", 1)], id: \.1) { label, idx in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { topTab = idx }
                        } label: {
                            Text(label)
                                .font(.system(size: 15, weight: topTab == idx ? .semibold : .regular, design: .rounded))
                                .foregroundColor(topTab == idx ? .calmDeep : .white.opacity(0.75))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(topTab == idx ? Color.white : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 13).fill(Color.white.opacity(0.15)))
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Grid content
                if topTab == 0 {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(SoundPlayer.SoundType.allCases) { sound in
                                SoundGridCard(sound: sound)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        DisclaimerFooter()
                            .padding(.bottom, soundPlayer.playing != nil ? 100 : 32)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(allAmbientTracks) { track in
                                AmbientGridCard(track: track, engine: ambientEngine)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        DisclaimerFooter()
                            .padding(.bottom, ambientEngine.currentTrack != nil ? 100 : 32)
                    }
                    .animation(.easeInOut(duration: 0.3), value: ambientEngine.currentTrack?.id)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            // Mini players
            if topTab == 0, soundPlayer.playing != nil {
                SoundMiniPlayer()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if topTab == 1, ambientEngine.currentTrack != nil {
                AmbientMiniPlayer(engine: ambientEngine)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.25), value: topTab)
        .onDisappear { ambientEngine.stop() }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall).environmentObject(premium)
        }
    }

}

// MARK: - Sound Grid Card

private struct SoundGridCard: View {
    @EnvironmentObject var soundPlayer: SoundPlayer
    @EnvironmentObject var userPrefs:   UserPreferencesStore
    @EnvironmentObject var premium:     PremiumStore
    let sound: SoundPlayer.SoundType

    @State private var showPaywall = false

    private var isActive: Bool { soundPlayer.playing == sound }
    private var isLocked: Bool { !sound.isFree && !premium.isPremium }
    private var isFav:    Bool { userPrefs.isFavorite(sound) }
    private let brandPurple = Color(red: 0.541, green: 0.357, blue: 0.804)

    var body: some View {
        Button {
            if isLocked { showPaywall = true }
            else if isActive { soundPlayer.stop() }
            else { soundPlayer.play(sound); userPrefs.recordUsed(sound) }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(isActive ? brandPurple.opacity(0.15) : brandPurple.opacity(0.08))
                            .frame(width: 40, height: 40)
                        Image(systemName: isLocked ? "lock.fill" : (isActive ? "pause.fill" : "play.fill"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isLocked ? brandPurple.opacity(0.35) : brandPurple)
                    }
                    Spacer()
                    if isActive {
                        AmbientSoundWaveView(active: true)
                            .frame(width: 24)
                            .padding(.top, 12)
                    } else if !isLocked {
                        Button {
                            userPrefs.toggleFavorite(sound)
                        } label: {
                            Image(systemName: isFav ? "heart.fill" : "heart")
                                .font(.system(size: 13))
                                .foregroundColor(isFav ? Color(red: 1.0, green: 0.40, blue: 0.55) : brandPurple.opacity(0.30))
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(sound.rawValue)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(isLocked ? .calmDeep.opacity(0.40) : .calmDeep)
                        .lineLimit(1)
                    Text(isLocked ? "Premium" : sound.subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(isLocked ? brandPurple.opacity(0.50) : .calmMid)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isActive ? brandPurple.opacity(0.12) : Color(red: 0.87, green: 0.89, blue: 0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isActive ? brandPurple.opacity(0.40) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall).environmentObject(premium)
        }
    }
}

// MARK: - Ambient Grid Card

private struct AmbientGridCard: View {
    let track: AmbientTrack
    @ObservedObject var engine: AmbientMusicEngine

    private var isActive:  Bool { engine.currentTrack?.id == track.id }
    private var isPlaying: Bool { isActive && engine.isPlaying }
    private let brandPurple = Color(red: 0.541, green: 0.357, blue: 0.804)

    var body: some View {
        Button { engine.play(track) } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(isActive ? brandPurple.opacity(0.15) : brandPurple.opacity(0.08))
                            .frame(width: 40, height: 40)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(brandPurple)
                    }
                    Spacer()
                    if isActive {
                        AmbientSoundWaveView(active: isPlaying)
                            .frame(width: 24)
                            .padding(.top, 12)
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(track.title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.calmDeep)
                        .lineLimit(1)
                    Text(track.subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.calmMid)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isActive ? brandPurple.opacity(0.12) : Color(red: 0.87, green: 0.89, blue: 0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isActive ? brandPurple.opacity(0.40) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ambient Mini Player (inline, no nav dependency)

private struct AmbientMiniPlayer: View {
    @ObservedObject var engine: AmbientMusicEngine

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.white.opacity(0.10)).frame(height: 2)
                    Rectangle()
                        .fill(Color.calmAccent)
                        .frame(width: geo.size.width * CGFloat(engine.progress), height: 2)
                        .animation(.linear(duration: 0.5), value: engine.progress)
                }
            }
            .frame(height: 2)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(engine.currentTrack?.title ?? "")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.calmDeep)
                    Text(engine.currentTrack?.subtitle ?? "")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.calmMid)
                }
                Spacer()
                Button {
                    if engine.isPlaying { engine.pause() } else { engine.resume() }
                } label: {
                    Image(systemName: engine.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.calmAccent)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                Button { engine.stop() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color(red: 0.541, green: 0.357, blue: 0.804).opacity(0.50))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color.white.opacity(0.92).ignoresSafeArea(edges: .bottom))
    }
}
