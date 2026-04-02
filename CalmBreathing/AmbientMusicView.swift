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
    AmbientTrack(title: "Cinematic Focus",   subtitle: "Deep concentration",    filename: "yevhenastafiev-cinematic-ambient-481810",                              category: .focus),
    AmbientTrack(title: "Inspiring Flow",    subtitle: "Creative momentum",     filename: "the_mountain-ambient-inspiring-music-141464",                          category: .focus),
    AmbientTrack(title: "Deep Space",        subtitle: "Limitless focus",       filename: "monume-space-ambient-498030",                                          category: .focus),
    AmbientTrack(title: "Ambient Flow",      subtitle: "Steady concentration",  filename: "paulyudin-ambient-ambient-music-482398",                               category: .focus),
    AmbientTrack(title: "Cinematic Depth",   subtitle: "Emotional clarity",     filename: "desifreemusic-emotional-ambient-piece-with-slow-cinematic-textures-370144", category: .focus),

    // Sleep
    AmbientTrack(title: "Dreamscape",        subtitle: "Drift into deep sleep", filename: "mondamusic-dark-ambient-soundscape-dreamscape-2-487315",               category: .sleep),
    AmbientTrack(title: "Slow Drift",        subtitle: "Gentle sleep induction",filename: "quietphase-slow-ambient-490875",                                       category: .sleep),
    AmbientTrack(title: "Rain Piano",        subtitle: "Soft rain & piano",     filename: "clavier-music-relaxing-ambient-music-rain-354479",                     category: .sleep),
    AmbientTrack(title: "Mountain Night",    subtitle: "Peaceful wilderness",   filename: "the_mountain-ambient-nature-132350",                                   category: .sleep),
    AmbientTrack(title: "Calm Mountain",     subtitle: "Serene stillness",      filename: "the_mountain-calm-ambient-146122",                                     category: .sleep),

    // Creativity
    AmbientTrack(title: "Zen Garden",        subtitle: "Open your mind",        filename: "quietphase-ambient-zen-489706",                                        category: .creativity),
    AmbientTrack(title: "Calm Space",        subtitle: "Expansive creativity",  filename: "quietphase-ambient-calm-491578",                                       category: .creativity),
    AmbientTrack(title: "Meditation Bloom",  subtitle: "Inner inspiration",     filename: "quietphase-meditation-ambient-484356",                                 category: .creativity),
    AmbientTrack(title: "Yoga Flow",         subtitle: "Fluid and free",        filename: "quietphase-yoga-ambient-485882",                                       category: .creativity),
    AmbientTrack(title: "Peaceful Mind",     subtitle: "Clear creative space",  filename: "playstarz_music-ambient-meditation-486609",                            category: .creativity),
    AmbientTrack(title: "Morning Yoga",      subtitle: "Energised & open",      filename: "the_mountain-yoga-meditation-165602",                                  category: .creativity),
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
        UIApplication.shared.isIdleTimerDisabled = true
        startTimer()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        timer?.invalidate()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func resume() {
        player?.play()
        isPlaying = true
        UIApplication.shared.isIdleTimerDisabled = true
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
        UIApplication.shared.isIdleTimerDisabled = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
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

private struct TrackRow: View {
    let track: AmbientTrack
    @ObservedObject var engine: AmbientMusicEngine

    private var isActive: Bool { engine.currentTrack?.id == track.id }
    private var isPlaying: Bool { isActive && engine.isPlaying }

    var body: some View {
        Button { engine.play(track) } label: {
            HStack(spacing: 14) {
                // Play indicator
                ZStack {
                    Circle()
                        .fill(isActive ? Color.calmAccent.opacity(0.20) : Color.white.opacity(0.08))
                        .frame(width: 46, height: 46)
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isActive ? .calmAccent : .white.opacity(0.70))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(track.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(isActive ? .calmAccent : .white)
                    Text(track.subtitle)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.white.opacity(0.60))
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
                    .fill(isActive ? Color.calmAccent.opacity(0.10) : Color.white.opacity(0.07))
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
                        .foregroundColor(.white)
                    Text(engine.currentTrack?.subtitle ?? "")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.white.opacity(0.60))
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
            Color(red: 0.10, green: 0.22, blue: 0.45)
                .opacity(0.97)
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
