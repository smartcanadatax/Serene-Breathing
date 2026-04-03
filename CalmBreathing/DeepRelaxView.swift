import SwiftUI
import AVFoundation
import AVKit
import UIKit

// MARK: - Looping Video Background
struct LoopingVideoView: UIViewRepresentable {
    let resourceName: String
    let ext: String

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: ext, subdirectory: "Audio") else { return view }
        let player = AVPlayer(url: url)
        player.isMuted = true
        player.actionAtItemEnd = .none
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        player.play()
        context.coordinator.player = player
        context.coordinator.playerLayer = layer
        let token = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in player.seek(to: .zero); player.play() }
        context.coordinator.loopToken = token
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.playerLayer?.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var player: AVPlayer?
        var playerLayer: AVPlayerLayer?
        var loopToken: NSObjectProtocol?
        deinit {
            player?.pause()
            if let token = loopToken {
                NotificationCenter.default.removeObserver(token)
            }
        }
    }
}

// MARK: - Deep Relax View
struct DeepRelaxView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var journal: JournalStore
    @State private var postMoodLogged = false

    private let prompts: [String] = [
        "Sit comfortably.",
        "Close your eyes.",
        "Take a natural breath in.",
        "And let it go.",
        "Don't try to control it.",
        "Just breathe.",
        "Notice the breath coming in.",
        "Cool at the tip of your nose.",
        "Moving into your chest.",
        "And leaving slowly.",
        "Just that.",
        "Breathe in.",
        "And out.",
        "If your mind wanders.",
        "That is okay.",
        "Simply notice.",
        "And return to your breath.",
        "In.",
        "Out.",
        "The breath is always here.",
        "Steady.",
        "Reliable.",
        "Always returning.",
        "Just like you.",
        "Breathe in.",
        "And out.",
        "Notice the pause between the inhale.",
        "And the exhale.",
        "That stillness.",
        "Rest there for a moment.",
        "Breathe in.",
        "Pause.",
        "And out.",
        "Your mind will wander again.",
        "It always does.",
        "That is not failure.",
        "That is the practice.",
        "Notice.",
        "And return.",
        "Back to the breath.",
        "In.",
        "Out.",
        "In.",
        "Out.",
        "Nothing to achieve here.",
        "No destination.",
        "Just this breath.",
        "And then the next.",
        "In.",
        "Out.",
        "In.",
        "Out.",
        "You are here.",
        "Awake.",
        "Present.",
        "Breathing.",
        "When you are ready.",
        "Take a slightly deeper breath.",
        "Feel yourself returning.",
        "Wiggle your fingers.",
        "And your toes.",
        "One final breath in.",
        "Hold.",
        "And release.",
        "Open your eyes slowly.",
        "The breath will always be there.",
        "Whenever you need to come home.",
    ]

    @State private var currentIndex = 0
    @State private var isRunning = false
    @State private var isDone = false
    @State private var syncTimer: Timer?
    @State private var progress: Double = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isInterrupted = false
    @State private var lastAudioTime: Double = 0

    private var currentPrompt: String { prompts[min(currentIndex, prompts.count - 1)] }

    private var promptTimestamps: [Double] {
        return [
              1.417,   6.805,  14.606,  21.750,  31.133,
             40.031,  51.476,  61.162,  70.730,  81.821,
             92.485, 103.131, 111.887, 123.053, 130.153,
            139.286, 146.788, 158.093, 159.256, 170.608,
            181.965, 183.469, 194.480, 205.350, 215.993,
            224.749, 236.489, 245.522, 256.325, 267.536,
            278.206, 287.521, 293.524, 305.022, 314.209,
            323.436, 332.630, 343.970, 351.068, 361.972,
            373.170, 374.330, 385.502, 386.670, 397.902,
            408.993, 419.754, 430.799, 441.994, 443.154,
            454.325, 455.494, 466.148, 477.432, 478.730,
            490.017, 500.834, 510.520, 520.047, 529.277,
            536.471, 545.936, 553.107, 558.301, 569.591,
            577.373, 585.336
        ]
    }

    var body: some View {
        ZStack {
            // Ocean video background
            LoopingVideoView(resourceName: "deep_relax_bg", ext: "mp4")
                .ignoresSafeArea()

            // Dark overlay for readability
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            if isDone {
                VStack { Spacer(); doneView; Spacer() }
                    .padding(.horizontal, 28)
            } else if !isRunning {
                ScrollView(showsIndicators: false) {
                    introView
                        .padding(.horizontal, 28)
                        .padding(.top, 72)
                        .padding(.bottom, 20)
                }
            } else {
                VStack { Spacer(); activeView; Spacer() }
                    .padding(.horizontal, 28)
            }

            // Small orb — bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    LotusOrbView(isAnimating: isRunning)
                        .frame(width: 80, height: 80)
                        .opacity(0.75)
                        .padding(.trailing, 24)
                        .padding(.bottom, 100)
                }
            }

            if !isDone {
                VStack {
                    HStack {
                        Button {
                            stopSession()
                            audioPlayer?.stop()
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        Spacer()
                        Text("Deep Relax")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Color.clear.frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { n in
            handleInterruption(n)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            guard isInterrupted, isRunning else { return }
            isInterrupted = false
            try? AVAudioSession.sharedInstance().setActive(true)
            audioPlayer?.play()
        }
        .onDisappear {
            stopSession()
            audioPlayer?.stop()
        }
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(spacing: 28) {
            VStack(spacing: 12) {
                Text("A 10-minute session to anchor your attention and find stillness.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.90))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            VStack(spacing: 10) {
                infoRow(icon: "chair.lounge.fill",  text: "Sit comfortably or lie down")
                infoRow(icon: "eye.slash.fill",      text: "Follow the breath, not the thoughts")
                infoRow(icon: "waveform",            text: "Ocean sounds in background")
            }
            .padding(.horizontal, 8)

            Text("For relaxation and wellness purposes only. Not a substitute for medical or mental health advice.")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Button { startSession() } label: {
                Label("Begin Deep Relax", systemImage: "play.fill")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.calmDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Color.calmAccent).shadow(color: .calmAccent.opacity(0.35), radius: 12))
            }
        }
    }

    // MARK: - Active

    private var activeView: some View {
        VStack(spacing: 32) {
            Text("\(currentIndex + 1) of \(prompts.count)")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.55))

            Text(currentPrompt)
                .font(.system(size: 22, weight: .light, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 8)
                .id(currentIndex)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal:   .opacity.combined(with: .move(edge: .top))
                ))

            Button(action: stopSession) {
                Text("End Session")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.60))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }
        }
    }

    // MARK: - Done

    private var doneView: some View {
        VStack(spacing: 24) {
            Text("Well Done")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text("You returned to your breath. That is the whole practice.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.90))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            VStack(spacing: 8) {
                if !postMoodLogged {
                    Text("How do you feel now?")
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(.white.opacity(0.65))
                    HStack(spacing: 4) {
                        ForEach([1,2,3,5,6], id: \.self) { level in
                            Button {
                                journal.addMoodEntry(MoodEntry(mood: level, source: "post-session"))
                                withAnimation { postMoodLogged = true }
                            } label: {
                                Text(level.moodEmoji)
                                    .font(.system(size: 28))
                                    .frame(minWidth: 44, minHeight: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.541, green: 0.357, blue: 0.804))
                        Text("Mood saved")
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
            }

            Button {
                isDone = false
                currentIndex = 0
                progress = 0
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.calmDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Capsule().fill(Color.calmAccent))
            }
        }
    }

    // MARK: - Helpers

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.541, green: 0.357, blue: 0.804))
                .frame(width: 22)
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
        }
    }

    // MARK: - Logic

    private func startSession() {
        isRunning = true
        currentIndex = 0
        progress = 0
        UIApplication.shared.isIdleTimerDisabled = true
        playAudio()
        startSyncTimer()
    }

    private func playAudio() {
        guard let url = Bundle.main.url(forResource: "deep_relax", withExtension: "mp3", subdirectory: "Audio"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        player.numberOfLoops = 0
        player.volume = 1.0
        player.prepareToPlay()
        audioPlayer = player
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            player.play()
        }
    }

    private func startSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                guard let player = self.audioPlayer else { return }
                let time = player.currentTime
                let dur  = player.duration
                self.progress = dur > 0 ? min(1.0, time / dur) : 0
                if player.isPlaying {
                    self.lastAudioTime = time
                    let stamps = self.promptTimestamps
                    if !stamps.isEmpty {
                        var idx = stamps.count - 1
                        for (i, ts) in stamps.enumerated() {
                            if time < ts { idx = i; break }
                        }
                        if idx != self.currentIndex {
                            withAnimation(.easeInOut(duration: 0.6)) { self.currentIndex = idx }
                        }
                    }
                }
                if !player.isPlaying && !self.isInterrupted && self.lastAudioTime > 1 {
                    self.isRunning = false
                    self.isDone = true
                    self.lastAudioTime = 0
                    self.syncTimer?.invalidate()
                    self.syncTimer = nil
                    UIApplication.shared.isIdleTimerDisabled = false
                }
            }
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        if type == .began {
            isInterrupted = true
            audioPlayer?.pause()
        } else if type == .ended {
            lastAudioTime = 0
            isInterrupted = false
            try? AVAudioSession.sharedInstance().setActive(true)
            audioPlayer?.play()
        }
    }

    private func stopSession() {
        syncTimer?.invalidate()
        syncTimer = nil
        isRunning = false
        isInterrupted = false
        lastAudioTime = 0
        UIApplication.shared.isIdleTimerDisabled = false
        if let player = audioPlayer {
            let steps = 20
            let interval = 2.0 / Double(steps)
            let startVol = player.volume
            var step = 0
            Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
                step += 1
                player.volume = max(0, startVol * (1.0 - Float(step) / Float(steps)))
                if step >= steps { t.invalidate(); player.stop() }
            }
        }
    }
}
