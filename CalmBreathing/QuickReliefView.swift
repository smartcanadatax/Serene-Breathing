import SwiftUI
import AVFoundation
import UIKit

// MARK: - Exercise Config

struct QuickReliefExercise: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let icon: String
    let science: String
    let color: Color
    let phases: [ReliefPhase]
    let cycles: Int

    var totalSeconds: Int { phases.reduce(0) { $0 + $1.duration } * cycles }
}

struct ReliefPhase {
    let label: String
    let duration: Int
    let targetScale: CGFloat
}

// MARK: - Presets

extension QuickReliefExercise {
    static let all: [QuickReliefExercise] = [
        QuickReliefExercise(
            name: "Stress Relief",
            subtitle: "Physiological Sigh",
            icon: "wind",
            science: "Stanford research — fastest known technique to lower stress in real time.",
            color: Color(red: 0.541, green: 0.357, blue: 0.804),
            phases: [
                ReliefPhase(label: "Inhale",  duration: 2, targetScale: 1.15),
                ReliefPhase(label: "Sniff",   duration: 1, targetScale: 1.30),
                ReliefPhase(label: "Exhale",  duration: 7, targetScale: 0.68),
            ],
            cycles: 6
        ),
        QuickReliefExercise(
            name: "Anxiety Relief",
            subtitle: "Resonance Breathing",
            icon: "waveform.path",
            science: "HeartMath research — syncs heart rate and breath to reduce anxiety.",
            color: Color(red: 0.541, green: 0.357, blue: 0.804),
            phases: [
                ReliefPhase(label: "Inhale",  duration: 5, targetScale: 1.30),
                ReliefPhase(label: "Exhale",  duration: 5, targetScale: 0.68),
            ],
            cycles: 6
        ),
        QuickReliefExercise(
            name: "Focus Boost",
            subtitle: "Box Breathing",
            icon: "square",
            science: "Used by Navy SEALs — proven to sharpen focus and calm under pressure.",
            color: Color(red: 0.541, green: 0.357, blue: 0.804),
            phases: [
                ReliefPhase(label: "Inhale",  duration: 4, targetScale: 1.30),
                ReliefPhase(label: "Hold",    duration: 4, targetScale: 1.30),
                ReliefPhase(label: "Exhale",  duration: 4, targetScale: 0.68),
                ReliefPhase(label: "Hold",    duration: 4, targetScale: 0.68),
            ],
            cycles: 4
        ),
        QuickReliefExercise(
            name: "Calm Down",
            subtitle: "Extended Exhale",
            icon: "arrow.down.circle",
            science: "Activates the vagus nerve — releases emotional tension and lowers heart rate.",
            color: Color(red: 0.541, green: 0.357, blue: 0.804),
            phases: [
                ReliefPhase(label: "Inhale",  duration: 4, targetScale: 1.30),
                ReliefPhase(label: "Exhale",  duration: 8, targetScale: 0.68),
            ],
            cycles: 5
        ),
        QuickReliefExercise(
            name: "Pain Relief",
            subtitle: "Slow Deep Breathing",
            icon: "heart.circle",
            science: "Clinical research — reduces cortisol and calms the nervous system.",
            color: Color(red: 0.541, green: 0.357, blue: 0.804),
            phases: [
                ReliefPhase(label: "Inhale",  duration: 6, targetScale: 1.30),
                ReliefPhase(label: "Hold",    duration: 2, targetScale: 1.30),
                ReliefPhase(label: "Exhale",  duration: 6, targetScale: 0.68),
            ],
            cycles: 4
        ),
        QuickReliefExercise(
            name: "Quick Reset",
            subtitle: "Micro Breathing",
            icon: "bolt.circle",
            science: "A 30-second reset — clears mental fog and re-centres you in under a minute.",
            color: Color(red: 0.541, green: 0.357, blue: 0.804),
            phases: [
                ReliefPhase(label: "Inhale",  duration: 4, targetScale: 1.30),
                ReliefPhase(label: "Exhale",  duration: 6, targetScale: 0.68),
            ],
            cycles: 3
        ),
    ]
}

// MARK: - View

struct QuickReliefView: View {
    let exercise: QuickReliefExercise
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var journal: JournalStore

    private let purple = Color(red: 0.541, green: 0.357, blue: 0.804)

    @State private var isRunning     = false
    @State private var isDone        = false
    @State private var phaseIndex    = 0
    @State private var countdown     = 0
    @State private var cycleCount    = 0
    @State private var scale: CGFloat = 1.0
    @State private var phaseTimer:     Timer?
    @State private var countdownTimer: Timer?
    @State private var audioPlayer:    AVAudioPlayer?
    @State private var audioSyncTimer: Timer?
    @State private var selectedMusic:  BgMusicOption = breathingMusicOptions[0]
    @State private var bgPlayer:       AVAudioPlayer?
    @State private var completionPlayer: AVAudioPlayer?

    // Audio phase map — keyed by exercise name, values are (cycleDuration, [(label, startTime, targetScale)])
    private let audioPhaseMap: [String: (cycleDuration: Double, phases: [(label: String, start: Double, scale: CGFloat)])] = [
        "Stress Relief": (12.936, [
            ("Inhale", 0.356, 1.15),
            ("Sniff",  3.465, 1.30),
            ("Exhale", 5.619, 0.68),
        ]),
        "Anxiety Relief": (10.944, [
            ("Inhale", 0.3,  1.30),
            ("Exhale", 5.0,  0.68),
        ]),
        "Pain Relief": (15.408, [
            ("Inhale", 0.3,  1.30),
            ("Hold",   6.3,  1.30),
            ("Exhale", 8.6,  0.68),
        ]),
        "Calm Down": (10.944, [
            ("Inhale", 0.3,  1.30),
            ("Exhale", 4.5,  0.68),
        ]),
        "Focus Boost": (18.288, [
            ("Inhale", 0.3,  1.30),
            ("Hold",   4.5,  1.30),
            ("Exhale", 8.5,  0.68),
            ("Hold",   12.7, 0.68),
        ]),
    ]
    @State private var postMoodLogged  = false
    @State private var sessionStart    = Date()

    private var currentPhase: ReliefPhase {
        exercise.phases[min(phaseIndex, exercise.phases.count - 1)]
    }

    var body: some View {
        ZStack {
            CalmBackground()
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

            // Nav bar
            if !isDone {
                VStack {
                    HStack {
                        Button {
                            stopSession()
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        Spacer()
                        Text(exercise.name)
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
        .onDisappear { stopSession() }
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(spacing: 28) {
            LotusOrbView(isAnimating: false)
                .frame(width: 120, height: 120)

            VStack(spacing: 8) {
                Text(exercise.subtitle)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(exercise.totalSeconds >= 60 ? "\(exercise.totalSeconds / 60) minute" : "\(exercise.totalSeconds) seconds") · \(exercise.cycles) cycles")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.60))
            }

            // Phase guide
            VStack(spacing: 10) {
                ForEach(Array(exercise.phases.enumerated()), id: \.offset) { _, phase in
                    HStack(spacing: 14) {
                        Text(phase.label)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(purple)
                            .frame(width: 60, alignment: .leading)
                        Text("\(phase.duration)s")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.80))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.06)))
                }
            }

            // Science note
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle")
                    .font(.system(size: 13))
                    .foregroundColor(purple.opacity(0.80))
                Text(exercise.science)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.65))
                    .lineSpacing(3)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))

            Text("For relaxation and wellness purposes only. Not a substitute for medical advice.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.45))
                .multilineTextAlignment(.center)

            // Music selector
            HStack(spacing: 12) {
                Image(systemName: "music.note")
                    .font(.system(size: 14))
                    .foregroundColor(purple)
                    .frame(width: 20)
                Text("Music")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                Picker("", selection: $selectedMusic) {
                    ForEach(breathingMusicOptions, id: \.filename) { opt in
                        Text(opt.name).tag(opt)
                    }
                }
                .pickerStyle(.menu)
                .tint(purple)
                .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))

            Button { startSession() } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Begin · \(exercise.totalSeconds >= 60 ? "\(exercise.totalSeconds / 60) min" : "\(exercise.totalSeconds) sec")")
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(purple).shadow(color: purple.opacity(0.40), radius: 12))
            }
        }
    }

    // MARK: - Active

    private var activeView: some View {
        VStack(spacing: 32) {
            // Breathing logo
            VStack(spacing: 16) {
                LotusOrbView(isAnimating: isRunning)
                    .frame(width: 180, height: 180)
                    .scaleEffect(scale)

                VStack(spacing: 6) {
                    Text(currentPhase.label)
                        .font(.system(size: 22, weight: .light, design: .rounded))
                        .foregroundColor(.white)
                        .id(phaseIndex)
                        .transition(.opacity)

                    Text("\(countdown)")
                        .font(.system(size: 44, weight: .thin, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText(countsDown: true))
                }
            }

            // Cycle progress dots
            HStack(spacing: 8) {
                ForEach(0..<exercise.cycles, id: \.self) { i in
                    Circle()
                        .fill(i < cycleCount ? purple : Color.white.opacity(0.20))
                        .frame(width: 7, height: 7)
                }
            }

            Button(action: stopSession) {
                Text("End Session")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.55))
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

            Text("Well Done")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            Text("You completed \(exercise.totalSeconds >= 60 ? "\(exercise.totalSeconds / 60) minute" : "\(exercise.totalSeconds) seconds") of \(exercise.subtitle).")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.85))
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
                            .foregroundColor(purple)
                        Text("Mood saved")
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
            }

            Button {
                isDone = false
                cycleCount = 0
                phaseIndex = 0
                scale = 1.0
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Capsule().fill(purple))
            }
        }
    }

    // MARK: - Logic

    private func startSession() {
        isRunning    = true
        cycleCount   = 0
        phaseIndex   = 0
        sessionStart = Date()
        UIApplication.shared.isIdleTimerDisabled = true
        startBgMusic()
        if playVoiceAudio() {
            startAudioSync()
        } else {
            runPhase(0)
        }
    }

    // Returns true if voice audio loaded successfully
    @discardableResult
    private func playVoiceAudio() -> Bool {
        let filename: String
        switch exercise.name {
        case "Stress Relief":  filename = "stress_relief_breathing"
        case "Anxiety Relief": filename = "anxiety_relief_breathing"
        case "Focus Boost":    filename = "focus_boost_breathing"
        case "Calm Down":      filename = "calm_down_breathing"
        case "Pain Relief":    filename = "pain_relief_breathing"
        default: return false
        }
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3", subdirectory: "Audio"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return false }
        player.numberOfLoops = exercise.name == "Stress Relief" ? 0 : -1
        player.volume = 0.85
        player.prepareToPlay()
        player.play()
        audioPlayer = player
        return true
    }

    private func startAudioSync() {
        guard let map = audioPhaseMap[exercise.name] else { return }
        let cycleDur = map.cycleDuration
        let phases   = map.phases
        var lastPhaseIdx = -1
        var lastCyclePos = 0.0
        var localCycle   = 0

        audioSyncTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            DispatchQueue.main.async {
                guard let player = self.audioPlayer, self.isRunning else { return }

                let t        = player.currentTime
                let cyclePos = t.truncatingRemainder(dividingBy: cycleDur)

                // Detect cycle wrap-around (works for both looping and non-looping audio)
                if cyclePos < lastCyclePos - cycleDur * 0.5 {
                    localCycle += 1
                    self.cycleCount = min(localCycle, self.exercise.cycles)
                }
                lastCyclePos = cyclePos

                let phaseIdx  = phases.lastIndex(where: { cyclePos >= $0.start }) ?? 0
                let phaseEnd  = phaseIdx + 1 < phases.count ? phases[phaseIdx + 1].start : cycleDur
                if phaseIdx != lastPhaseIdx {
                    let p        = phases[phaseIdx]
                    let phaseDur = phaseEnd - p.start
                    self.phaseIndex = phaseIdx
                    withAnimation(.easeInOut(duration: phaseDur)) { self.scale = p.scale }
                    HapticManager.breathe(phase: p.label)
                    lastPhaseIdx = phaseIdx
                }
                self.countdown = max(0, Int(ceil(phaseEnd - cyclePos)))
            }
        }

        // Schedule completion after exact total duration
        let totalDuration = cycleDur * Double(exercise.cycles)
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            guard self.isRunning else { return }
            self.finishSession()
        }
    }

    private func runPhase(_ idx: Int) {
        let phase = exercise.phases[idx]
        phaseIndex = idx
        countdown  = phase.duration
        withAnimation(.easeInOut(duration: Double(phase.duration))) {
            scale = phase.targetScale
        }
        HapticManager.breathe(phase: phase.label)

        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async { self.countdown -= 1 }
        }

        phaseTimer?.invalidate()
        phaseTimer = Timer.scheduledTimer(withTimeInterval: Double(phase.duration), repeats: false) { _ in
            DispatchQueue.main.async {
                self.countdownTimer?.invalidate()
                let nextPhase = idx + 1
                if nextPhase >= self.exercise.phases.count {
                    self.cycleCount += 1
                    if self.cycleCount >= self.exercise.cycles {
                        self.finishSession()
                    } else {
                        self.runPhase(0)
                    }
                } else {
                    self.runPhase(nextPhase)
                }
            }
        }
    }

    private func finishSession() {
        stopTimers()
        withAnimation { scale = 1.0 }
        isDone    = true
        isRunning = false
        UIApplication.shared.isIdleTimerDisabled = false
        HapticManager.complete()
        playCompletionAudio()
        let elapsed = Date().timeIntervalSince(sessionStart)
        if elapsed >= 60 {
            HealthKitManager.shared.saveMindfulSession(startDate: sessionStart, endDate: Date())
        }
    }

    private func playCompletionAudio() {
        guard let url = Bundle.main.url(forResource: "breathing_complete", withExtension: "mp3", subdirectory: "Audio"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.numberOfLoops = 0
        player.volume = 0.85
        player.prepareToPlay()
        player.play()
        completionPlayer = player
    }

    private func stopSession() {
        stopTimers()
        isRunning = false
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func stopTimers() {
        phaseTimer?.invalidate()
        countdownTimer?.invalidate()
        audioSyncTimer?.invalidate()
        phaseTimer     = nil
        countdownTimer = nil
        audioSyncTimer = nil
        audioPlayer?.stop()
        audioPlayer      = nil
        bgPlayer?.stop()
        bgPlayer         = nil
        completionPlayer?.stop()
        completionPlayer = nil
    }

    private func startBgMusic() {
        let name: String
        if selectedMusic.filename.isEmpty {
            // Default: per-exercise track
            switch exercise.name {
            case "Stress Relief":  name = "spiritual_yoga"
            case "Anxiety Relief": name = "quietphase-yoga-ambient-485882"
            case "Focus Boost":    name = "focus_meditation"
            case "Calm Down":      name = "zen_water"
            default:               name = "deep_relaxation"
            }
        } else {
            name = selectedMusic.filename
        }
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Audio"),
              let bg = try? AVAudioPlayer(contentsOf: url) else { return }
        bg.numberOfLoops = -1
        bg.volume = 0.05
        bg.prepareToPlay()
        bg.play()
        bgPlayer = bg
    }
}

// MARK: - Haptic helper

private extension HapticManager {
    static func breathe(phase: String) {
        switch phase {
        case "Inhale": inhale()
        case "Exhale": exhale()
        case "Hold":   hold()
        default: break
        }
    }
}
