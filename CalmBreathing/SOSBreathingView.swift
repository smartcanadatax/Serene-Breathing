import SwiftUI
import UIKit
import AVFoundation

// MARK: - SOS Breathing View

struct SOSBreathingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showDisclaimer = true
    @State private var phase: SOSPhase = .inhale
    @State private var countdown = 4
    @State private var cycleCount = 0
    @State private var isRunning = false
    @State private var scale: CGFloat = 0.6
    @State private var phaseTimer: Timer?
    @State private var countdownTimer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioSyncTimer: Timer?
    @State private var visualCountdownTimer: Timer?
    @State private var lastPhaseIdx      = -1
    @State private var showCompletion    = false
    @State private var completionPlayer: AVAudioPlayer?

    private let totalCycles = 6

    // Timestamps measured from sos_breathing.mp3
    private let audioCycleDuration: TimeInterval = 22.344
    private let audioPhases: [(phase: SOSPhase, start: TimeInterval, scale: CGFloat)] = [
        (.inhale, 0.0,    1.0),
        (.hold,   6.028,  1.0),
        (.exhale, 13.693, 0.72),
    ]


    var body: some View {
        ZStack {
            CalmBackground()

            if showDisclaimer {
                disclaimerView
            } else {
                breathingView
            }

            if showCompletion {
                completionOverlay
                    .transition(.opacity)
            }
        }
        .onDisappear { stopAll() }
    }

    // MARK: - Disclaimer

    private var disclaimerView: some View {
        VStack(spacing: 28) {
            Spacer()

            Image("meditation_bg_night")
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))

            VStack(spacing: 10) {
                Text("Quick Calm")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("A 2-minute breathing exercise to help you feel calmer right now.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.80))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Disclaimer box
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow.opacity(0.85))
                    Text("IMPORTANT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.yellow.opacity(0.85))
                        .tracking(1.2)
                }
                Text("This exercise is for relaxation and stress relief only. It is not a medical treatment and is not intended for emergencies.\n\nRespiratory, cardiac, or any other health condition patients should consult a doctor before practising breathing exercises.\n\nIf you are experiencing a medical emergency, severe chest pain, difficulty breathing, or thoughts of self-harm, please call emergency services (911) immediately.\n\nNot a substitute for professional medical or mental health care.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.20), lineWidth: 1))
            )
            .padding(.horizontal, 8)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    withAnimation { showDisclaimer = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { startBreathing() }
                } label: {
                    Text("I understand — Begin")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.calmDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color.calmAccent).shadow(color: .calmAccent.opacity(0.35), radius: 10))
                }

                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.50))
                }
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Breathing Screen

    private var breathingView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated logo
            VStack(spacing: 12) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .saturation(0.5)
                    .brightness(0.25)
                    .frame(width: 240, height: 240)
                    .scaleEffect(reduceMotion ? 1.0 : scale)
                    .opacity(reduceMotion ? 0.90 : (0.55 + Double(scale) * 0.45))
                    .animation(reduceMotion ? nil : .easeInOut(duration: Double(phase.duration)), value: scale)

                VStack(spacing: 4) {
                    Text(phase.label)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                    Text("\(countdown)")
                        .font(.system(size: 38, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.90))
                        .monospacedDigit()
                }
            }
            .padding(.bottom, 40)

            Text("Cycle \(cycleCount + 1) of \(totalCycles)")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.45))
                .padding(.bottom, 8)

            Text("Breathe with the circle")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.55))

            Spacer()

            Button { stopAll(); dismiss() } label: {
                Text("End Session")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.calmDeep)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color(red: 0.87, green: 0.89, blue: 0.96)))
            }
            .padding(.bottom, 48)
        }
    }

    // MARK: - Logic

    private func startBreathing() {
        isRunning = true
        UIApplication.shared.isIdleTimerDisabled = true
        playAudio()
        startAudioSync()
    }

    private func startAudioSync() {
        lastPhaseIdx = -1

        audioSyncTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            DispatchQueue.main.async {
                guard let player = audioPlayer, isRunning else { return }
                let t = player.currentTime.truncatingRemainder(dividingBy: audioCycleDuration)
                let phaseIdx = audioPhases.lastIndex(where: { t >= $0.start }) ?? 0

                // Update phase visual when phase changes
                if phaseIdx != lastPhaseIdx {
                    let ap = audioPhases[phaseIdx]
                    phase = ap.phase
                    switch ap.phase {
                    case .inhale: HapticManager.inhale()
                    case .hold:   HapticManager.hold()
                    case .exhale: HapticManager.exhale()
                    }
                    withAnimation(.easeInOut(duration: 1.0)) { scale = ap.scale }

                    // Last phase wrapping back to first = one full cycle completed
                    if phaseIdx == 0 && lastPhaseIdx == audioPhases.count - 1 {
                        cycleCount += 1
                        if cycleCount >= totalCycles {
                            stopAll()
                            HapticManager.complete()
                            playCompletionAudio()
                            withAnimation(.easeIn(duration: 0.5)) { showCompletion = true }
                            return
                        }
                    }
                    lastPhaseIdx = phaseIdx
                }

                // Derive countdown from audio position
                let phaseStart = audioPhases[phaseIdx].start
                let phaseEnd = phaseIdx + 1 < audioPhases.count
                    ? audioPhases[phaseIdx + 1].start : audioCycleDuration
                let phaseDur = phaseEnd - phaseStart
                let progress = (t - phaseStart) / phaseDur
                countdown = max(0, Int(ceil(4.0 * (1.0 - progress))))
            }
        }
    }

    private func runPhase(_ p: SOSPhase) {
        phase = p
        countdown = p.duration

        withAnimation(.easeInOut(duration: Double(p.duration))) {
            switch p {
            case .inhale: scale = 1.0
            case .hold:   scale = 1.0   // stay expanded
            case .exhale: scale = 0.72  // shrink but keep text inside
            }
        }

        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                countdown -= 1
            }
        }

        phaseTimer?.invalidate()
        phaseTimer = Timer.scheduledTimer(withTimeInterval: Double(p.duration), repeats: false) { _ in
            DispatchQueue.main.async {
                countdownTimer?.invalidate()
                let next = p.next
                if p == .exhale {
                    cycleCount += 1
                    if cycleCount >= totalCycles {
                        stopAll()
                        withAnimation(.easeIn(duration: 0.5)) { showCompletion = true }
                        return
                    }
                }
                runPhase(next)
            }
        }
    }

    // MARK: - Completion Overlay

    private var completionOverlay: some View {
        ZStack {
            CalmBackground()

            VStack(spacing: 22) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 48, weight: .regular))
                    .foregroundColor(Color(red: 0.75, green: 0.92, blue: 1.00))

                Text("Well Done")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("You completed 6 calming breaths.\nYour nervous system has begun to settle.\nCarry this calm with you.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 28)

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.calmDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color(red: 0.75, green: 0.92, blue: 1.00)))
                }
                .padding(.horizontal, 40)
                .padding(.top, 4)
            }
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

    private func stopAll() {
        phaseTimer?.invalidate()
        countdownTimer?.invalidate()
        phaseTimer = nil
        countdownTimer = nil
        audioSyncTimer?.invalidate()
        visualCountdownTimer?.invalidate()
        audioSyncTimer = nil
        visualCountdownTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        isRunning = false
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func playAudio() {
        guard let url = Bundle.main.url(forResource: "sos_breathing", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 0.85
            audioPlayer?.play()
        } catch {}
    }

}

// MARK: - Phase

private enum SOSPhase: Equatable {
    case inhale, hold, exhale

    var label: String {
        switch self {
        case .inhale: return "Breathe In"
        case .hold:   return "Hold"
        case .exhale: return "Breathe Out"
        }
    }

    var duration: Int { 4 }

    var color: Color {
        switch self {
        case .inhale: return Color(red: 0.75, green: 0.92, blue: 1.00)
        case .hold:   return Color(red: 0.55, green: 0.82, blue: 1.00)
        case .exhale: return Color(red: 0.30, green: 0.88, blue: 0.98)
        }
    }

    var next: SOSPhase {
        switch self {
        case .inhale: return .hold
        case .hold:   return .exhale
        case .exhale: return .inhale
        }
    }
}
