import SwiftUI
import AVFoundation
import UIKit

// MARK: - Body Scan Meditation View
struct BodyScanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var journal: JournalStore
    @State private var postMoodLogged = false

    private let prompts: [String] = [
        "Find a comfortable position, either lying down or seated. Allow your eyes to close gently. Take a moment to arrive here, fully present.",
        "Take a deep breath in through your nose. And slowly release it through your mouth.",
        "Once more, breathe in. And let it all go. One more time, breathe in slowly. And breathe out completely.",
        "We are going to gently move attention through the body. There is nothing to fix or change. Simply notice. Simply be aware.",
        "Bring your awareness to the top of your head. Notice any sensations there — warmth, tingling, or stillness. Whatever you feel is perfectly fine.",
        "Now move your attention down to your forehead. Let the muscles of your forehead soften and smooth. Your eyebrows. Your temples. Completely relaxed.",
        "Your eyes. Let them rest softly in their sockets. Your cheeks. Your jaw. Allow the jaw to drop slightly. No need to hold it tight.",
        "Your lips. Your tongue. Let everything in your face be completely still.",
        "Now bring awareness to your neck. Notice any tension here and simply breathe into it. With each exhale, let the neck soften a little more.",
        "Move your attention to your shoulders. So much tension lives here. Let them drop. Let them fall. Heavier with every breath out.",
        "Your upper arms. Your elbows. Your forearms. Your wrists. Your hands. Each finger. Heavy. Warm. Completely relaxed.",
        "Now bring your attention to your chest. Feel it rise gently with each inhale, and fall with each exhale. No effort needed. Just breathing. Your upper back, your shoulder blades — let them widen and soften.",
        "Bring awareness to your belly. Notice it rising. And falling. Rising. Falling. Your lower back — if there is any tightness, breathe into it gently. With each exhale, let it soften.",
        "Move your attention down to your hips. Your pelvis. Your tailbone. Heavy and supported. Your upper legs, your thighs. Your knees, your shins, your calves. Your ankles, your heels. The soles of your feet. Each toe, one by one. Completely still. Completely at rest.",
        "Now take a moment to feel your whole body at once — from the top of your head to the tips of your toes. One connected, relaxed, living body. You are exactly where you need to be. At peace. At rest. Whole. Take one final deep breath in. And release everything. When you are ready, gently return.",
    ]

    @State private var currentIndex = 0
    @State private var isRunning = false
    @State private var isDone = false
    @State private var sessionStartDate = Date()
    @State private var syncTimer: Timer?
    @State private var progress: Double = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var bgPlayer: AVAudioPlayer?
    @State private var isInterrupted = false
    @State private var reachedNearEnd = false
    @AppStorage("preferredBgMusicFilename") private var preferredBgMusicFilename: String = "serene_mindfulness"
    @State private var selectedBgMusic: BgMusicOption = BgMusicOption(name: "Serene", filename: "serene_mindfulness")
    @State private var showMusicPicker = false

    private var totalDuration: Double { audioPlayer?.duration ?? 501 }
    private var currentPrompt: String { prompts[min(currentIndex, prompts.count - 1)] }

    // Exact timestamps (seconds) from audio — each value is when the NEXT prompt begins speaking
    private let promptTimestamps: [Double] = [
        17.86,  33.60,  66.76,  84.56, 106.92,
       133.04, 157.84, 171.72, 195.84, 220.16,
       252.24, 298.98, 346.58, 423.28, 501.48,
    ]

    var body: some View {
        ZStack {
            CalmBackground()

            if !isRunning && !isDone {
                ScrollView(showsIndicators: false) {
                    introView
                        .padding(.horizontal, 28)
                        .padding(.top, 72)
                        .padding(.bottom, 20)
                }
            } else if isRunning {
                VStack { Spacer(); activeView; Spacer() }
                    .padding(.horizontal, 28)
            }

            if isDone {
                bodyScanCompletionOverlay
                    .transition(.opacity)
            }

            // Back button + title header (always visible, hidden only during completion)
            if !isDone {
                VStack {
                    HStack {
                        Button {
                            stopScan()
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
                        Text("Body Scan")
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
        .onAppear {
            selectedBgMusic = meditationMusicOptions.first { $0.filename == preferredBgMusicFilename } ?? BgMusicOption(name: "Serene", filename: "serene_mindfulness")
            prepareBgMusic()
        }
        .onChange(of: selectedBgMusic) { _, _ in
            preferredBgMusicFilename = selectedBgMusic.filename
            bgPlayer?.stop()
            bgPlayer = nil
            prepareBgMusic()
            if isRunning { bgPlayer?.play() }
        }
        .sheet(isPresented: $showMusicPicker) {
            MeditationMusicPickerSheet(selectedMusic: $selectedBgMusic)
        }
        .onDisappear {
            stopScan()
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
                Text("A gentle 8-minute guided journey through your body, releasing tension from head to toe.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.90))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // What is Body Scan?
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.calmAccent)
                    Text("WHAT IS A BODY SCAN?")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.calmAccent)
                        .tracking(1.1)
                }

                Text("A body scan is a mindfulness technique where you move your attention slowly through each part of your body — from head to toe. By noticing sensations without judgement, you release built-up tension, quiet a busy mind, and reconnect with the present moment.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.calmMid)
                    .lineSpacing(4)

                Text("Regular practice is linked to reduced stress, better sleep, and a greater sense of calm. It is one of the most widely studied mindfulness exercises in clinical research.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.calmMid)
                    .lineSpacing(4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.87, green: 0.89, blue: 0.96))
            )

            VStack(spacing: 10) {
                infoRow(icon: "bed.double.fill",   text: "Lie down or sit comfortably")
                infoRow(icon: "eye.slash.fill",     text: "Close your eyes and follow each prompt")
                infoRow(icon: "moon.fill",          text: "Best used before sleep or to unwind")
            }
            .padding(.horizontal, 8)

            // Disclaimer
            Text("For relaxation purposes only. Not a substitute for medical or mental health treatment. If you have any health conditions, consult a doctor before use.")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.top, 20)

            Button {
                startScan()
            } label: {
                HStack(spacing: 8) {
                    Text("Begin Body Scan")
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

            // Current prompt
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

            Button(action: stopScan) {
                Text("End Session")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.calmAccent)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color(red: 0.87, green: 0.89, blue: 0.96)).shadow(color: .black.opacity(0.08), radius: 8))
            }
        }
    }

    // MARK: - Completion Overlay
    private var bodyScanCompletionOverlay: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .regular))
                    .foregroundColor(.calmAccent)

                Text("Well Done")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("You completed your Body Scan Meditation. Take a moment to notice how relaxed your body feels.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.80))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 32)

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
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.calmDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color.calmAccent))
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
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
    private func startScan() {
        HapticManager.start()
        isRunning = true
        sessionStartDate = Date()
        currentIndex = 0
        progress = 0
        reachedNearEnd = false
        UIApplication.shared.isIdleTimerDisabled = true
        playBodyScanAudio()
        startBgMusic()
        startSyncTimer()
    }

    private func prepareBgMusic() {
        bgPlayer = makeBgPlayer(for: selectedBgMusic)
    }

    private func startBgMusic() {
        bgPlayer?.play()
    }

    private func playBodyScanAudio() {
        guard let url = Bundle.main.url(forResource: "body_scan_v2", withExtension: "mp3", subdirectory: "Audio"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.numberOfLoops = 0
        player.volume = 0.85
        player.prepareToPlay()
        audioPlayer = player
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            player.play()
        }
    }

    // Single timer drives both progress ring and prompt index from audio position
    private func startSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                guard let player = self.audioPlayer else { return }
                let time = player.currentTime
                let dur  = player.duration

                // Update progress ring
                self.progress = dur > 0 ? min(1.0, time / dur) : 0

                // Advance prompt based on current audio position
                if player.isPlaying {
                    let stamps = self.promptTimestamps
                    if !stamps.isEmpty {
                        var idx = stamps.count - 1
                        for (i, ts) in stamps.enumerated() {
                            if time < ts { idx = i; break }
                        }
                        if idx != self.currentIndex {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                self.currentIndex = idx
                            }
                        }
                    }
                }

                // Track near-completion so reset of currentTime doesn't fool us
                if self.progress > 0.97 { self.reachedNearEnd = true }

                // Detect natural end of audio
                if !player.isPlaying && self.reachedNearEnd && !self.isInterrupted {
                    self.isRunning = false
                    self.isDone = true
                    HapticManager.complete()
                    UIApplication.shared.isIdleTimerDisabled = false
                    HealthKitManager.shared.saveMindfulSession(startDate: self.sessionStartDate, endDate: Date())
                    self.syncTimer?.invalidate()
                    self.syncTimer = nil
                    self.bgPlayer?.stop()
                    self.bgPlayer = nil
                }
            }
        }
    }

    private func stopScan() {
        syncTimer?.invalidate()
        syncTimer = nil
        isRunning = false
        UIApplication.shared.isIdleTimerDisabled = false
        bgPlayer?.stop()
        bgPlayer = nil
        prepareBgMusic()
        // Fade out audio
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
