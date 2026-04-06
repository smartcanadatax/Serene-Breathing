import SwiftUI
import AVFoundation
import UIKit

// MARK: - Models

enum AmbientCategory: String, CaseIterable {
    case focus      = "Focus"
    case sleep      = "Sleep"
    case creativity = "Creativity"

    var icon: String {
        switch self {
        case .focus:      return "brain.head.profile"
        case .sleep:      return "moon.stars.fill"
        case .creativity: return "paintbrush.fill"
        }
    }
}

struct AmbientTrack: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let filename: String
    let category: AmbientCategory
}

let allAmbientTracks: [AmbientTrack] = [
    // Focus
    AmbientTrack(title: "Ambient Flow",      subtitle: "Steady concentration",  filename: "paulyudin-ambient-ambient-music-482398",                               category: .focus),

    // Sleep
    AmbientTrack(title: "Dreamscape",        subtitle: "Drift into deep sleep", filename: "mondamusic-dark-ambient-soundscape-dreamscape-2-487315",               category: .sleep),
    AmbientTrack(title: "Slow Drift",        subtitle: "Gentle sleep induction",filename: "quietphase-slow-ambient-490875",                                       category: .sleep),
    AmbientTrack(title: "Rain Piano",        subtitle: "Soft rain & piano",     filename: "clavier-music-relaxing-ambient-music-rain-354479",                     category: .sleep),
    AmbientTrack(title: "Mountain Night",    subtitle: "Peaceful wilderness",   filename: "the_mountain-ambient-nature-132350",                                   category: .sleep),
    AmbientTrack(title: "Calm Mountain",     subtitle: "Serene stillness",      filename: "the_mountain-calm-ambient-146122",                                     category: .sleep),
    AmbientTrack(title: "Very Deep Sleep",   subtitle: "Profound rest",         filename: "very_deep_sleep",                                                      category: .sleep),
    AmbientTrack(title: "C Major Dreams",    subtitle: "Meditation sleep music",filename: "sleep_c_major",                                                        category: .sleep),
    AmbientTrack(title: "Deep Sleep",        subtitle: "Background sleep waves",filename: "deep_sleep_bg",                                                        category: .sleep),
    AmbientTrack(title: "Sleep Drift",       subtitle: "Floating into rest",    filename: "sleep_deep_drift",                                                     category: .sleep),
    AmbientTrack(title: "Sleep Meditation",  subtitle: "Guided sleep tones",    filename: "sleep_meditation_bg",                                                  category: .sleep),
    AmbientTrack(title: "Blue Hour",         subtitle: "Rainy night calm",      filename: "sleep_blue_hour",                                                      category: .sleep),
    AmbientTrack(title: "Evening Relax",     subtitle: "Melt into sleep",       filename: "sleep_evening_relax",                                                  category: .sleep),

    // Creativity
    AmbientTrack(title: "Zen Garden",        subtitle: "Open your mind",        filename: "quietphase-ambient-zen-489706",                                        category: .creativity),
    AmbientTrack(title: "Calm Space",        subtitle: "Expansive creativity",  filename: "quietphase-ambient-calm-491578",                                       category: .creativity),
    AmbientTrack(title: "Meditation Bloom",  subtitle: "Inner inspiration",     filename: "quietphase-meditation-ambient-484356",                                 category: .creativity),
    AmbientTrack(title: "Yoga Flow",         subtitle: "Fluid and free",        filename: "quietphase-yoga-ambient-485882",                                       category: .creativity),
    AmbientTrack(title: "Peaceful Mind",     subtitle: "Clear creative space",  filename: "playstarz_music-ambient-meditation-486609",                            category: .creativity),
    AmbientTrack(title: "Mountain Calm",     subtitle: "Grounded & still",      filename: "the_mountain-yoga-meditation-165602",                                  category: .creativity),
    AmbientTrack(title: "Nature Soundscape", subtitle: "Immersive outdoors",    filename: "immersive_nature",                                                     category: .creativity),
    AmbientTrack(title: "Nature & Music",    subtitle: "Relax with nature",     filename: "relaxing_nature",                                                      category: .creativity),
    AmbientTrack(title: "Spiritual Music",   subtitle: "Sacred creative space", filename: "creativity_spiritual",                                                 category: .creativity),
    AmbientTrack(title: "Healing Sphere",    subtitle: "Open & expansive",      filename: "creativity_healing",                                                   category: .creativity),
    AmbientTrack(title: "River Zen",         subtitle: "Flowing inspiration",   filename: "creativity_river_zen",                                                 category: .creativity),
    AmbientTrack(title: "Dragon Meditation", subtitle: "Mystic calm",           filename: "dragon-studio-meditation-music-sound-bite-339735",                     category: .creativity),
    AmbientTrack(title: "Deep Calm",         subtitle: "Grounding texture",     filename: "gigidelaromusic-deep-calm-texture-short-450960",                       category: .creativity),
    AmbientTrack(title: "Sacred Chant",      subtitle: "Ancient resonance",     filename: "pankajsethjmt-chant-5-481438",                                         category: .creativity),
    AmbientTrack(title: "Peaceful Highlands",subtitle: "Open skies & calm",     filename: "prettysleepy-peaceful-highlands-by-prettysleepy-art-10733",            category: .creativity),
    AmbientTrack(title: "Light Ray",         subtitle: "Soft & luminous",       filename: "gigidelaromusic-peaceful-light-ray-short-450966",                      category: .creativity),
    AmbientTrack(title: "Soul Frequencies",  subtitle: "Ancient vibrations",    filename: "soul_frequencies-tibetan-bowls-498961",                                category: .creativity),
]

// MARK: - Player Engine

@MainActor
final class AmbientMusicEngine: NSObject, ObservableObject {
    @Published var currentTrack: AmbientTrack?
    @Published var isPlaying = false
    @Published var progress: Double = 0

    private var player: AVAudioPlayer?
    private var timer: Timer?

    func play(_ track: AmbientTrack) {
        if currentTrack?.id == track.id && isPlaying { pause(); return }
        stop()
        guard let url = Bundle.main.url(forResource: track.filename, withExtension: "mp3", subdirectory: "Audio"),
              let p = try? AVAudioPlayer(contentsOf: url) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        player = p
        player?.numberOfLoops = -1
        player?.prepareToPlay()
        player?.play()
        currentTrack = track
        isPlaying = true
        startTimer()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        timer?.invalidate()
    }

    func resume() {
        player?.play()
        isPlaying = true
        startTimer()
    }

    func stop() {
        player?.stop()
        player = nil
        timer?.invalidate()
        timer = nil
        isPlaying = false
        progress = 0
        currentTrack = nil
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let p = self.player, p.duration > 0 else { return }
                self.progress = p.currentTime / p.duration
            }
        }
    }
}

// MARK: - Main View

struct AmbientMusicView: View {
    @StateObject private var engine = AmbientMusicEngine()
    @State private var selectedCategory: AmbientCategory = .focus

    private var tracks: [AmbientTrack] {
        allAmbientTracks.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            CalmBackground()

            VStack(spacing: 0) {
                // Category picker
                Picker("", selection: $selectedCategory) {
                    ForEach(AmbientCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(tracks) { track in
                            TrackRow(track: track, engine: engine)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                DisclaimerFooter()
                    .padding(.bottom, engine.currentTrack != nil ? 100 : 32)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            // Mini player
            if engine.currentTrack != nil {
                MiniPlayer(engine: engine)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Ambient Music")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .onDisappear { engine.stop() }
        .animation(.easeInOut(duration: 0.3), value: engine.currentTrack?.id)
    }
}

// MARK: - Track Row

struct TrackRow: View {
    let track: AmbientTrack
    @ObservedObject var engine: AmbientMusicEngine

    private var isActive: Bool { engine.currentTrack?.id == track.id }
    private var isPlaying: Bool { isActive && engine.isPlaying }

    var body: some View {
        Button { engine.play(track) } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 46, height: 46)
                        .shadow(color: Color.black.opacity(0.08), radius: 4)
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.calmAccent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(track.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(isActive ? .calmAccent : .calmDeep)
                    Text(track.subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.calmMid)
                }

                Spacer()

                if isActive {
                    AmbientSoundWaveView(active: isPlaying)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isActive ? Color.calmAccent.opacity(0.10) : Color(red: 0.87, green: 0.89, blue: 0.96))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(isActive ? Color.calmAccent.opacity(0.40) : Color.clear, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mini Player

private struct MiniPlayer: View {
    @ObservedObject var engine: AmbientMusicEngine

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
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
                        .foregroundColor(.white.opacity(0.40))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(
            Color(red: 0.87, green: 0.89, blue: 0.96)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Sound Wave Animation

struct AmbientSoundWaveView: View {
    let active: Bool
    @State private var scales: [CGFloat] = [0.4, 0.7, 1.0, 0.7, 0.4]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                Capsule()
                    .fill(Color.calmAccent)
                    .frame(width: 3, height: 16 * scales[i])
                    .animation(
                        active ? .easeInOut(duration: 0.4 + Double(i) * 0.08).repeatForever(autoreverses: true) : .default,
                        value: scales[i]
                    )
            }
        }
        .onAppear { if active { animate() } }
        .onChange(of: active) { _, val in
            if val { animate() } else { scales = [0.4, 0.7, 1.0, 0.7, 0.4] }
        }
    }

    private func animate() {
        let targets: [CGFloat] = [1.0, 0.4, 0.7, 1.0, 0.5]
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                scales[i] = targets[i]
            }
        }
    }
}
