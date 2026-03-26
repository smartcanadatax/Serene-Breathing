import SwiftUI
import AVFoundation
import UIKit

// MARK: - Body Scan Meditation View
struct BodyScanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var journal: JournalStore
    @State private var postMoodLogged = false

    private let prompts: [(text: String, duration: Double)] = [
        ("Find a comfortable position. Close your eyes and take three slow, deep breaths.", 17),
        ("Bring your attention to the top of your head. Notice any tension. Let it soften.", 17),
        ("Move your awareness to your forehead and eyes. Allow them to relax completely.", 17),
        ("Relax your jaw, your cheeks, your lips. Let your face become completely soft.", 17),
        ("Bring attention to your neck and shoulders. With each exhale, let the tension release.", 17),
        ("Notice your chest and your heart area. Feel it rise and fall with each breath.", 16),
        ("Move to your upper arms, then your forearms, then your hands. Let them grow heavy.", 17),
        ("Bring awareness to your belly. Feel it expand on the inhale, relax on the exhale.", 17),
        ("Move your attention to your lower back. Breathe into any areas of tightness.", 16),
        ("Notice your hips and the weight of your body. Allow yourself to sink deeper.", 16),
        ("Bring awareness to your thighs, your knees, your calves. Feel them completely relax.", 17),
        ("Move attention to your feet and toes. Let go of any tension held there.", 16),
        ("Now feel your whole body at once — relaxed, heavy, and completely at peace.", 16),
        ("Rest here for a moment. You are safe. You are calm. You are exactly where you need to be.", 18),
        ("When you're ready, take a deep breath, gently wiggle your fingers and toes, and open your eyes.", 6),
    ]

    @State private var currentIndex = 0
    @State private var isRunning = false
    @State private var isDone = false
    @State private var syncTimer: Timer?
    @State private var progress: Double = 0
    @State private var audioPlayer: AVAudioPlayer?

    private var totalDuration: Double { prompts.map(\.duration).reduce(0, +) }
    private var currentPrompt: String { prompts[min(currentIndex, prompts.count - 1)].text }

    // Cumulative end-timestamps scaled to actual audio duration, proportioned by character count
    // (character count matches Polly's speech timing far better than arbitrary duration values)
    private var promptTimestamps: [Double] {
        guard let dur = audioPlayer?.duration, dur > 0 else { return [] }
        let totalChars = Double(prompts.reduce(0) { $0 + $1.text.count })
        var stamps: [Double] = []
        var sum = 0.0
        for p in prompts {
            sum += (Double(p.text.count) / totalChars) * dur
            stamps.append(sum)
        }
        return stamps
    }

    var body: some View {
        ZStack {
            CalmBackground()

            if !isRunning && !isDone {
                ScrollView(showsIndicators: false) {
                    introView
                        .padding(.horizontal, 28)
                        .padding(.vertical, 20)
                }
            } else {
                VStack { Spacer(); activeView; Spacer() }
                    .padding(.horizontal, 28)
            }

            if isDone {
                bodyScanCompletionOverlay
                    .transition(.opacity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    stopScan()
                    audioPlayer?.stop()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Body Scan")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .onDisappear {
            stopScan()
            audioPlayer?.stop()
        }
    }

    // MARK: - Intro
    private var introView: some View {
        VStack(spacing: 28) {
            LotusOrbView()
                .frame(width: 120, height: 120)

            VStack(spacing: 12) {
                Text("Body Scan Meditation")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text("A gentle \(Int(totalDuration / 60))-minute guided journey through your body, releasing tension from head to toe.")
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
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white.opacity(0.88))
                    .lineSpacing(4)

                Text("Regular practice is linked to reduced stress, better sleep, and a greater sense of calm. It is one of the most widely studied mindfulness exercises in clinical research.")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white.opacity(0.88))
                    .lineSpacing(4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1))
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

            Button {
                startScan()
            } label: {
                Label("Begin Body Scan", systemImage: "play.fill")
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
            // Overall progress ring
            LotusOrbView(isAnimating: isRunning)
                .frame(width: 240, height: 240)

            Text("\(currentIndex + 1) of \(prompts.count)")
                .font(.system(size: 13, weight: .regular))
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
                    .foregroundColor(.white.opacity(0.60))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }
        }
    }

    // MARK: - Completion Overlay
    private var bodyScanCompletionOverlay: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundColor(.calmAccent)

                Text("Session Complete")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("Well done. Take a moment to notice how relaxed your body feels.")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(.white.opacity(0.80))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 32)

                VStack(spacing: 8) {
                    if !postMoodLogged {
                        Text("How do you feel now?")
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(.white.opacity(0.65))
                        HStack(spacing: 14) {
                            ForEach([1,2,3,5,6], id: \.self) { level in
                                Button {
                                    journal.addMoodEntry(MoodEntry(mood: level, source: "post-session"))
                                    withAnimation { postMoodLogged = true }
                                } label: {
                                    Text(level.moodEmoji).font(.system(size: 28))
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
        isRunning = true
        currentIndex = 0
        progress = 0
        UIApplication.shared.isIdleTimerDisabled = true
        playBodyScanAudio()
        startSyncTimer()
    }

    private func playBodyScanAudio() {
        guard let url = Bundle.main.url(forResource: "body_scan", withExtension: "mp3", subdirectory: "Audio"),
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

                // Detect natural end of audio
                if !player.isPlaying && time > 1 {
                    self.isRunning = false
                    self.isDone = true
                    UIApplication.shared.isIdleTimerDisabled = false
                    self.syncTimer?.invalidate()
                    self.syncTimer = nil
                }
            }
        }
    }

    private func stopScan() {
        syncTimer?.invalidate()
        syncTimer = nil
        isRunning = false
        UIApplication.shared.isIdleTimerDisabled = false
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
