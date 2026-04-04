import SwiftUI

// MARK: - Sounds Hub (combined Library + Ambient in one page)

struct SoundsHubView: View {
    @EnvironmentObject var premium:     PremiumStore
    @EnvironmentObject var soundPlayer: SoundPlayer
    @EnvironmentObject var userPrefs:   UserPreferencesStore
    @StateObject private var ambientEngine = AmbientMusicEngine()

    @State private var topTab: Int = 0                          // 0 = Library, 1 = Music
    @State private var soundCategory: SoundLibraryCategory = .nature
    @State private var ambientCategory: AmbientCategory = .focus
    @State private var showPaywall = false

    private var libraryTracks: [SoundPlayer.SoundType] {
        SoundPlayer.SoundType.allCases.filter { $0.libraryCategory == soundCategory }
    }
    private var ambientTracks: [AmbientTrack] {
        allAmbientTracks.filter { $0.category == ambientCategory }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            CalmBackground()

            VStack(spacing: 0) {
                // Nav bar
                HStack {
                    Color.clear.frame(width: 36, height: 36)
                    Spacer()
                    Text("Sounds")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 10) {
                        SleepTimerButton()
                    }
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.25)))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 10)

                // Single row: top tabs + sub-category chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Library / Music toggle chips
                        chipButton("Sounds", selected: topTab == 0) { topTab = 0 }
                        chipButton("Ambient", selected: topTab == 1) { topTab = 1 }

                        Rectangle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 1, height: 20)
                            .padding(.horizontal, 2)

                        // Sub-category chips
                        if topTab == 0 {
                            ForEach(SoundLibraryCategory.allCases, id: \.self) { cat in
                                chipButton(cat.rawValue, selected: soundCategory == cat) { soundCategory = cat }
                            }
                        } else {
                            ForEach(AmbientCategory.allCases, id: \.self) { cat in
                                chipButton(cat.rawValue, selected: ambientCategory == cat) { ambientCategory = cat }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                }

                if topTab == 0 {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 8) {
                            ForEach(libraryTracks) { sound in
                                SoundLibraryRow(sound: sound)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 2)
                        DisclaimerFooter()
                            .padding(.bottom, soundPlayer.playing != nil ? 100 : 32)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 8) {
                            ForEach(ambientTracks) { track in
                                TrackRow(track: track, engine: ambientEngine)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 2)
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

    // MARK: - Chip Button
    private func chipButton(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: selected ? .semibold : .regular, design: .rounded))
                .foregroundColor(selected ? .calmDeep : .white.opacity(0.80))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(selected ? Color.white : Color.white.opacity(0.15)))
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
                }
                Button { engine.stop() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color(red: 0.541, green: 0.357, blue: 0.804).opacity(0.50))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color.white.opacity(0.92).ignoresSafeArea(edges: .bottom))
    }
}
