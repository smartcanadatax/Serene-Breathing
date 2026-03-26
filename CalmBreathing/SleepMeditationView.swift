import SwiftUI
import AVFoundation
import UIKit

struct SleepMeditationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var journal: JournalStore
    @State private var postMoodLogged = false

    private let prompts: [(text: String, duration: Double)] = [
        ("The day is done. You have done enough.", 12),
        ("Whatever is unfinished can wait until tomorrow.", 12),
        ("Right now, there is only this.", 12),
        ("Lie down and let your body sink into the surface beneath you.", 14),
        ("Feel the weight of your head, your shoulders, your back — all supported.", 14),
        ("You don't need to hold anything up right now.", 12),
        ("Take a slow breath in through your nose.", 10),
        ("And breathe out through your mouth — long and slow.", 12),
        ("Again. Breathe in.", 8),
        ("And out. Even slower this time.", 12),
        ("With every exhale, feel yourself sinking a little deeper.", 14),
        ("Bring your attention to the top of your head. Let it soften.", 14),
        ("Your forehead. Your eyes. Your jaw.", 10),
        ("Let every muscle in your face go completely slack.", 12),
        ("Your neck. Your shoulders. Let them melt.", 12),
        ("Your arms. Your hands. Your fingers. Heavy and still.", 12),
        ("Your chest rises and falls with each breath. Slowly. Naturally.", 14),
        ("Your belly. Your lower back. Breathe into any tightness and let it go.", 14),
        ("Your legs. Your feet. Your toes. Completely relaxed.", 12),
        ("Your whole body is now at rest. Heavy. Warm. Safe.", 14),
        ("There is nothing to solve tonight.", 12),
        ("Nothing to worry about. Nothing to plan.", 12),
        ("Just this breath. And the next.", 12),
        ("You are safe. You are loved. You are at peace.", 14),
        ("Let sleep come now.", 10),
    ]

    @State private var currentIndex = 0
    @State private var isRunning = false
    @State private var isDone = false
    @State private var syncTimer: Timer?
    @State private var progress: Double = 0
    @State private var audioPlayer: AVAudioPlayer?

    private var totalDuration: Double { prompts.map(\.duration).reduce(0, +) }
    private var currentPrompt: String { prompts[min(currentIndex, prompts.count - 1)].text }

    private var promptTimestamps: [Double] {
        guard let dur = audioPlayer?.duration, dur > 0 else { return [] }
        // Exact timestamps extracted from audio silence detection
        let scale = dur / 265.872
        let raw: [Double] = [
             8.32,  16.44,  24.63,  34.51,  46.12,
            53.43,  60.52,  71.49,  79.19,  89.91,
           101.21, 111.70, 123.02, 133.23, 144.81,
           160.14, 174.81, 190.12, 203.46, 219.14,
           225.98, 236.91, 247.37, 261.20, 265.87
        ]
        return raw.map { $0 * scale }
    }

    var body: some View {
        ZStack {
            // Darker background for sleep
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.10, blue: 0.28),
                    Color(red: 0.08, green: 0.15, blue: 0.38),
                    Color(red: 0.10, green: 0.20, blue: 0.45),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
                        Text("Sleep Meditation")
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
        .onDisappear {
            stopSession()
            audioPlayer?.stop()
        }
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(spacing: 28) {
            LotusOrbView()
                .frame(width: 120, height: 120)

            VStack(spacing: 12) {
                Text("Sleep Meditation")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text("A \(Int(totalDuration / 60))-minute guided session to release the day and drift into deep, restful sleep.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.90))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            VStack(spacing: 10) {
                infoRow(icon: "bed.double.fill",  text: "Lie down in bed")
                infoRow(icon: "eye.slash.fill",    text: "Close your eyes and follow each prompt")
                infoRow(icon: "moon.fill",         text: "Best used right before sleep")
            }
            .padding(.horizontal, 8)

            Text("For relaxation and wellness purposes only. Not a substitute for medical or mental health advice. If you have any health conditions, consult a doctor before use.")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Button { startSession() } label: {
                Label("Begin Sleep Meditation", systemImage: "moon.fill")
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
            LotusOrbView(isAnimating: isRunning)
                .frame(width: 240, height: 240)

            Text("\(currentIndex + 1) of \(prompts.count)")
                .font(.system(size: 13, weight: .regular))
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
            LotusOrbView(isAnimating: false)
                .frame(width: 100, height: 100)
            Text("Sleep Well")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text("You have let go of the day. Rest deeply and wake up restored.")
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
                            .foregroundColor(.calmAccent)
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
        UIApplication.shared.isIdleTimerDisabled = true
        playAudio()
        startSyncTimer()
    }

    private func playAudio() {
        guard let url = Bundle.main.url(forResource: "sleep_meditation", withExtension: "mp3", subdirectory: "Audio"),
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
                if !player.isPlaying && time > 1 {
                    self.isRunning = false
                    self.isDone = true
                    self.syncTimer?.invalidate()
                    self.syncTimer = nil
                    UIApplication.shared.isIdleTimerDisabled = false
                }
            }
        }
    }

    private func stopSession() {
        syncTimer?.invalidate()
        syncTimer = nil
        isRunning = false
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
