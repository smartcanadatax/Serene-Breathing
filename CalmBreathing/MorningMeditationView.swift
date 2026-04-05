import SwiftUI
import AVFoundation
import UIKit

struct MorningMeditationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var journal: JournalStore
    @State private var postMoodLogged = false

    private let prompts: [(text: String, duration: Double)] = [
        ("Good morning. Take a moment just for yourself before the day begins.", 16),
        ("Find a comfortable position. Sit tall, or lie down — whatever feels right.", 16),
        ("Close your eyes gently.", 10),
        ("Take a deep breath in through your nose.", 10),
        ("And exhale slowly through your mouth.", 10),
        ("Again. Breathe in — feel your chest and belly expand.", 10),
        ("And release — let everything go.", 10),
        ("One more. Breathe in deeply.", 8),
        ("And out. Completely.", 10),
        ("Bring your awareness to this moment.", 10),
        ("You woke up today. That alone is something.", 12),
        ("Today is a fresh start — untouched, full of possibility.", 12),
        ("Whatever happened yesterday does not follow you here.", 12),
        ("This morning, you begin again.", 12),
        ("Bring your attention to your body.", 8),
        ("Feel the weight of it — grounded, present, alive.", 12),
        ("Roll your shoulders back gently. Lift your chest slightly.", 12),
        ("This is the posture of someone ready to meet their day.", 12),
        ("Now set an intention for today. Just one word is enough.", 12),
        ("Perhaps it is calm. Perhaps it is focus. Perhaps it is kindness.", 14),
        ("Hold that word in your mind.", 10),
        ("Let it settle into your chest like a warm light.", 12),
        ("Carry it with you today.", 10),
        ("Take one final deep breath in.", 8),
        ("And exhale completely.", 8),
        ("Open your eyes when you are ready.", 10),
        ("Today is yours. Go gently.", 10),
    ]

    @State private var currentIndex = 0
    @State private var isRunning = false
    @State private var isDone = false
    @State private var syncTimer: Timer?
    @State private var progress: Double = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var bgPlayer: AVAudioPlayer?
    @State private var isInterrupted = false
    @State private var reachedNearEnd = false
    @State private var selectedBgMusic: BgMusicOption = BgMusicOption(name: "Serene", filename: "serene_mindfulness")
    @State private var showMusicPicker = false

    private var totalDuration: Double { prompts.map(\.duration).reduce(0, +) }
    private var currentPrompt: String { prompts[min(currentIndex, prompts.count - 1)].text }

    // Exact timestamps (seconds) from audio — each value is when the NEXT prompt begins
    private let promptTimestamps: [Double] = [
          9.62,  20.88,  27.48,  35.10,  41.80,
         50.44,  58.96,  65.88,  71.90,  79.48,
         87.54,  96.74, 104.92, 111.76, 116.72,
        125.26, 134.96, 142.04, 150.90, 162.34,
        167.98, 176.04, 181.84, 187.72, 192.56,
        198.68, 202.32,
    ]

    var body: some View {
        ZStack {
            CalmBackground()

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
                        Text("Morning Meditation")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Button { showMusicPicker = true } label: {
                            Image(systemName: "music.note")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { prepareBgMusic() }
        .onChange(of: selectedBgMusic) { _, _ in
            bgPlayer?.stop()
            bgPlayer = nil
            prepareBgMusic()
            if isRunning { bgPlayer?.play() }
        }
        .sheet(isPresented: $showMusicPicker) {
            MeditationMusicPickerSheet(selectedMusic: $selectedBgMusic)
        }
        .onDisappear {
            stopSession()
            audioPlayer?.stop()
            bgPlayer?.stop()
        }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { note in
            guard let info = note.userInfo,
                  let typeVal = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeVal) else { return }
            switch type {
            case .began:
                isInterrupted = true
                audioPlayer?.pause()
                bgPlayer?.pause()
            case .ended:
                isInterrupted = false
                let opts = (info[AVAudioSessionInterruptionOptionKey] as? UInt)
                    .map { AVAudioSession.InterruptionOptions(rawValue: $0) } ?? []
                if opts.contains(.shouldResume) {
                    try? AVAudioSession.sharedInstance().setActive(true)
                    audioPlayer?.play()
                    bgPlayer?.play()
                }
            @unknown default: break
            }
        }
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(spacing: 28) {
            VStack(spacing: 12) {
                Text("A \(Int(totalDuration / 60))-minute guided session to start your day with clarity and calm.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.90))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            VStack(spacing: 10) {
                infoRow(icon: "chair.lounge.fill",  text: "Sit comfortably or lie down")
                infoRow(icon: "eye.slash.fill",      text: "Close your eyes and follow each prompt")
                infoRow(icon: "sunrise.fill",        text: "Best used right after waking")
            }
            .padding(.horizontal, 8)

            Text("For relaxation and wellness purposes only. Not a substitute for medical or mental health advice. If you have any health conditions, consult a doctor before use.")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Button { startSession() } label: {
                HStack(spacing: 8) {
                    Text("Begin Morning Meditation")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.calmAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(Color.white).shadow(color: .black.opacity(0.10), radius: 12))
            }
        }
    }

    // MARK: - Active

    private var activeView: some View {
        VStack(spacing: 32) {
            LotusOrbView(isAnimating: isRunning)
                .frame(width: 240, height: 240)

            Text("\(currentIndex + 1) of \(prompts.count)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.55))

            Text(currentPrompt)
                .font(.system(size: 18, weight: .regular, design: .rounded))
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
                    .foregroundColor(.calmAccent)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color(red: 0.87, green: 0.89, blue: 0.96)).shadow(color: .black.opacity(0.08), radius: 8))
            }
        }
    }

    // MARK: - Done

    private var doneView: some View {
        VStack(spacing: 24) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 54, weight: .regular))
                .foregroundColor(.calmAccent)
            Text("Well Done")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text("You've set a powerful intention. Carry this calm with you today.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.90))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            VStack(spacing: 8) {
                if !postMoodLogged {
                    Text("How do you feel now?")
                        .font(.system(size: 13, weight: .regular))
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
                            .foregroundColor(.calmAccent)
                        Text("Mood saved")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
            }

            Button {
                dismiss()
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
                .foregroundColor(.calmAccent.opacity(0.80))
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
        reachedNearEnd = false
        UIApplication.shared.isIdleTimerDisabled = true
        playAudio()
        startBgMusic()
        startSyncTimer()
    }

    private func prepareBgMusic() {
        bgPlayer = makeBgPlayer(for: selectedBgMusic)
    }

    private func startBgMusic() {
        bgPlayer?.play()
    }

    private func playAudio() {
        guard let url = Bundle.main.url(forResource: "morning_meditation", withExtension: "mp3", subdirectory: "Audio"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        player.numberOfLoops = 0
        player.volume = 0.85
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
                if self.progress > 0.97 { self.reachedNearEnd = true }
                if !player.isPlaying && self.reachedNearEnd && !self.isInterrupted {
                    self.isRunning = false
                    self.isDone = true
                    self.syncTimer?.invalidate()
                    self.syncTimer = nil
                    UIApplication.shared.isIdleTimerDisabled = false
                    self.bgPlayer?.stop()
                    self.bgPlayer = nil
                }
            }
        }
    }

    private func stopSession() {
        syncTimer?.invalidate()
        syncTimer = nil
        isRunning = false
        UIApplication.shared.isIdleTimerDisabled = false
        bgPlayer?.stop()
        bgPlayer = nil
        prepareBgMusic()
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
