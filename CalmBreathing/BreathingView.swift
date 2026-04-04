import SwiftUI
import UIKit
import AVFoundation

// MARK: - Breathing Pattern
enum BreathingPattern: String, CaseIterable {
    case box    = "Box 4·4·4"
    case f478   = "4·7·8 Calm"
    case custom = "Custom"

    var description: String {
        switch self {
        case .box:    return "Stress relief"
        case .f478:   return "Calm anxiety & sleep"
        case .custom: return "Your own rhythm"
        }
    }

    var subtitle: String {
        switch self {
        case .box:    return "Inhale  ·  Hold  ·  Exhale"
        case .f478:   return "Inhale  ·  Long Hold  ·  Long Exhale"
        case .custom: return "Set your own durations below"
        }
    }

    func duration(for phase: BreathingView.Phase, custom: (inhale: Double, hold: Double, exhale: Double) = (4,4,4)) -> Double {
        switch (self, phase) {
        case (.box,    .inhale): return 4
        case (.box,    .hold):   return 4
        case (.box,    .exhale): return 4
        case (.f478,   .inhale): return 4
        case (.f478,   .hold):   return 7
        case (.f478,   .exhale): return 8
        case (.custom, .inhale): return custom.inhale
        case (.custom, .hold):   return custom.hold
        case (.custom, .exhale): return custom.exhale
        default:                 return 0
        }
    }

    func phaseTags(custom: (inhale: Double, hold: Double, exhale: Double) = (4,4,4)) -> [(name: String, dur: String, color: Color)] {
        let i = Int(self == .custom ? custom.inhale : (self == .f478 ? 4 : 4))
        let h = Int(self == .custom ? custom.hold   : (self == .f478 ? 7 : 4))
        let e = Int(self == .custom ? custom.exhale : (self == .f478 ? 8 : 4))
        return [("Inhale","\(i)s",.calmAccent),("Hold","\(h)s",.calmPurple),("Exhale","\(e)s",.calmTeal)]
    }
}

// MARK: - Breathing Exercise View
struct BreathingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var premium: PremiumStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showPaywall = false

    // Breathing phase state machine
    enum Phase {
        case ready, inhale, hold, exhale

        var label: String {
            switch self {
            case .ready:  return "Tap to Begin"
            case .inhale: return "Inhale"
            case .hold:   return "Hold"
            case .exhale: return "Exhale"
            }
        }

        var instruction: String {
            switch self {
            case .ready:  return "Breathe in through your nose"
            case .inhale: return "Breathe in slowly..."
            case .hold:   return "Hold your breath gently"
            case .exhale: return "Release slowly through your mouth"
            }
        }

        var circleColor: Color {
            switch self {
            case .ready, .inhale: return .calmAccent
            case .hold:           return .calmPurple
            case .exhale:         return .calmTeal
            }
        }

        var targetScale: CGFloat {
            switch self {
            case .ready:          return 0.82
            case .exhale:         return 0.48
            case .inhale, .hold:  return 1.0
            }
        }
    }

    @State private var sessionStartDate: Date = Date()
    @State private var selectedPattern: BreathingPattern = .box
    @State private var customInhale: Double = 4
    @State private var customHold:   Double = 4
    @State private var customExhale: Double = 4
    @State private var phase: Phase = .ready
    @State private var scale: CGFloat = 0.48
    @State private var animationDuration: Double = 1.0
    @State private var isRunning = false
    @State private var cycleCount = 0
    @State private var phaseTimer: Timer?
    @State private var countdown: Int = 4
    @State private var countdownTimer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var lastAudioPhase: Phase = .ready
    @State private var audioSyncTimer: Timer?
    private let speechSynth = AVSpeechSynthesizer()

    // Exact timestamps measured via silence detection
    private let boxCycleDuration:  TimeInterval = 15.672
    private let boxHoldStart:      TimeInterval = 5.476
    private let boxExhaleStart:    TimeInterval = 10.743

    private let f478CycleDuration: TimeInterval = 22.296
    private let f478HoldStart:     TimeInterval = 5.476
    private let f478ExhaleStart:   TimeInterval = 13.143

    var body: some View {
        ZStack {
            CalmBackground()

            VStack(spacing: 0) {
                // Nav header
                HStack {
                    Button {
                        stopBreathing()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                    if !premium.isPremium {
                        Button { showPaywall = true } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill").font(.system(size: 11))
                                Text("Premium").font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.calmDeep)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Capsule().fill(Color.calmAccent))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Header
                VStack(spacing: 6) {
                    AppLogoView(size: 52)
                        .padding(.top, 4)
                    Text("Need Calm Now?")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Breathe through it")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))

                    // Pattern picker pills
                    HStack(spacing: 8) {
                        ForEach(BreathingPattern.allCases, id: \.self) { p in
                            let isLocked = p != .box && !premium.isPremium
                            Button {
                                if !isRunning {
                                    if isLocked { showPaywall = true }
                                    else { selectedPattern = p }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(p.rawValue)
                                        .font(.system(size: 13, weight: selectedPattern == p ? .semibold : .medium))
                                        .foregroundColor(selectedPattern == p ? .calmDeep : (isLocked ? .white.opacity(0.45) : .white))
                                    if isLocked {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 9))
                                            .foregroundColor(.white.opacity(0.45))
                                    }
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .frame(minHeight: 40)
                                .contentShape(Rectangle())
                                .background(Capsule().fill(selectedPattern == p ? Color.white : Color.white.opacity(isLocked ? 0.06 : 0.12)))
                            }
                        }
                    }

                    Text(selectedPattern.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.70))

                    // Custom duration sliders
                    if selectedPattern == .custom && !isRunning {
                        VStack(spacing: 10) {
                            customSlider("Inhale", value: $customInhale, color: .calmAccent)
                            customSlider("Hold",   value: $customHold,   color: .calmPurple)
                            customSlider("Exhale", value: $customExhale, color: .calmTeal)
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                        .transition(.opacity)
                    }
                }
                .padding(.top, 12)

                Spacer()

                // Animated orb
                VStack(spacing: 16) {
                    LotusOrbView(isAnimating: isRunning)
                        .frame(width: 240, height: 240)
                        .scaleEffect(reduceMotion ? 1.0 : scale)
                        .animation(.easeInOut(duration: animationDuration), value: scale)
                        .accessibilityLabel(isRunning ? "\(phase.label), \(countdown) seconds" : "Tap to begin breathing exercise")

                    VStack(spacing: 6) {
                        if phase == .ready {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Text(phase.label)
                            .font(.system(size: 18, weight: .light, design: .rounded))
                            .foregroundColor(.white)
                        if isRunning {
                            Text("\(countdown)")
                                .font(.system(size: 42, weight: .light, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                                .monospacedDigit()
                            Text("Cycle \(cycleCount + 1)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.90))
                        }
                    }
                }
                .onTapGesture { if !isRunning { startBreathing() } }

                // Instruction text
                Text(phase.instruction)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 28)

                Spacer()

                // Controls
                HStack(spacing: 20) {
                    if isRunning {
                        Button(action: stopWithCompletion) {
                            Label("Stop", systemImage: "stop.fill")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 36)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(Color.white.opacity(0.12)))
                        }
                    } else {
                        Button(action: startBreathing) {
                            Label("Begin", systemImage: "play.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.calmDeep)
                                .padding(.horizontal, 44)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(Color.calmAccent))
                                .shadow(color: .calmAccent.opacity(0.35), radius: 10)
                        }
                    }
                }

                // Technique labels
                HStack(spacing: 32) {
                    ForEach(selectedPattern.phaseTags(custom: (customInhale, customHold, customExhale)), id: \.name) { tag in
                        phaseTag(tag.name, tag.dur, tag.color)
                    }
                }
                .padding(.top, 28)

                DisclaimerFooter()
                    .padding(.top, 10)
                    .padding(.bottom, 28)
            }
            .padding(.horizontal, 24)
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall).environmentObject(premium)
        }
        .onDisappear { stopBreathing() }
        .onReceive(NotificationCenter.default.publisher(for: .watchStopBreathing)) { _ in
            stopBreathing()
        }
    }

    // MARK: - Custom Slider Row
    private func customSlider(_ label: String, value: Binding<Double>, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
                .frame(width: 48, alignment: .leading)
            Slider(value: value, in: 2...12, step: 1)
                .tint(color)
            Text("\(Int(value.wrappedValue))s")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 28, alignment: .trailing)
        }
    }

    // MARK: - Phase Technique Label
    private func phaseTag(_ name: String, _ dur: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(dur)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(color)
            Text(name)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.92))
        }
    }

    // MARK: - Control Logic
    private func startBreathing() {
        isRunning = true
        cycleCount = 0
        sessionStartDate = Date()
        HapticManager.start()
        UIApplication.shared.isIdleTimerDisabled = true
        playBreathingAudio()
        if (selectedPattern == .box || selectedPattern == .f478), audioPlayer != nil {
            startAudioSync()
        } else {
            runPhase(.inhale)
        }
    }

    private func stopBreathing() {
        isRunning = false
        UIApplication.shared.isIdleTimerDisabled = false
        phaseTimer?.invalidate()
        countdownTimer?.invalidate()
        audioSyncTimer?.invalidate()
        phaseTimer = nil
        countdownTimer = nil
        audioSyncTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        speechSynth.stopSpeaking(at: .immediate)
        PhoneSession.shared.sendBreathingState(phase: "Ready", countdown: 0,
                                               phaseDuration: 0, pattern: "", isRunning: false)
        let elapsed = Date().timeIntervalSince(sessionStartDate)
        if elapsed >= 60 {
            HealthKitManager.shared.saveMindfulSession(startDate: sessionStartDate, endDate: Date())
        }
        animationDuration = 1.2
        scale = 0.48
        phase = .ready
    }

    // Syncs the visual phase to the audio position every 50ms so they never drift
    private func startAudioSync() {
        let cycleDur  = selectedPattern == .f478 ? f478CycleDuration  : boxCycleDuration
        let holdStart = selectedPattern == .f478 ? f478HoldStart      : boxHoldStart
        let exhaleStart = selectedPattern == .f478 ? f478ExhaleStart  : boxExhaleStart

        lastAudioPhase = .ready
        audioSyncTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            DispatchQueue.main.async {
                guard let player = audioPlayer, isRunning else { return }
                let t = player.currentTime.truncatingRemainder(dividingBy: cycleDur)

                let newPhase: Phase
                let patternInhale: Double = selectedPattern == .f478 ? 4 : 4
                let patternHold:   Double = selectedPattern == .f478 ? 7 : 4
                let patternExhale: Double = selectedPattern == .f478 ? 8 : 4

                if t < holdStart {
                    newPhase = .inhale
                    let progress = t / holdStart
                    countdown = max(0, Int(ceil(patternInhale * (1 - progress))))
                } else if t < exhaleStart {
                    newPhase = .hold
                    let progress = (t - holdStart) / (exhaleStart - holdStart)
                    countdown = max(0, Int(ceil(patternHold * (1 - progress))))
                } else {
                    newPhase = .exhale
                    let progress = (t - exhaleStart) / (cycleDur - exhaleStart)
                    countdown = max(0, Int(ceil(patternExhale * (1 - progress))))
                }

                if newPhase != lastAudioPhase {
                    let haptic = UIImpactFeedbackGenerator(style: newPhase == .exhale ? .light : .medium)
                    haptic.impactOccurred()
                    animationDuration = newPhase == .inhale ? patternInhale :
                                        newPhase == .hold   ? 0.2 : patternExhale
                    scale = newPhase.targetScale
                    // Exhale → Inhale transition = one full cycle completed
                    if newPhase == .inhale && lastAudioPhase == .exhale {
                        cycleCount += 1
                    }
                    phase = newPhase
                    lastAudioPhase = newPhase
                    let phaseDur: Double = newPhase == .inhale ? patternInhale :
                                          newPhase == .hold   ? patternHold   : patternExhale
                    PhoneSession.shared.sendBreathingState(phase: newPhase.label,
                                                          countdown: countdown,
                                                          phaseDuration: phaseDur,
                                                          pattern: selectedPattern.rawValue,
                                                          isRunning: true)
                }
            }
        }
    }

    private func playCompletionSpeech() {
        let utt = AVSpeechUtterance(string: "Well done. You have finished your breathing session.")
        utt.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Nicky-compact")
                   ?? AVSpeechSynthesisVoice(language: "en-US")
        utt.rate = 0.42
        utt.pitchMultiplier = 0.9
        utt.volume = 0.85
        speechSynth.speak(utt)
    }

    private func stopWithCompletion() {
        stopBreathing()
        playCompletionSpeech()
    }

    private func playBreathingAudio() {
        let filename: String
        switch selectedPattern {
        case .box:    filename = "box_breathing"
        case .f478:   filename = "breathing_478"
        case .custom: return   // no audio guide for custom
        }
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            print("⚠️ breathing audio not found in bundle: \(filename).mp3")
            return
        }
        print("✅ playing breathing audio: \(url)")
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1   // loop forever
            audioPlayer?.volume = 0.85
            audioPlayer?.play()
        } catch {
            // Audio unavailable — exercise continues silently
        }
    }

    private func runPhase(_ next: Phase) {
        guard isRunning else { return }

        // Haptic pulse on each phase change
        switch next {
        case .inhale: HapticManager.inhale()
        case .hold:   HapticManager.hold()
        case .exhale: HapticManager.exhale()
        case .ready:  break
        }

        // Speak phase cue for custom pattern
        if selectedPattern == .custom {
            let word: String
            switch next {
            case .inhale: word = "Inhale"
            case .hold:   word = "Hold"
            case .exhale: word = "Exhale"
            case .ready:  word = ""
            }
            if !word.isEmpty {
                let utt = AVSpeechUtterance(string: word)
                utt.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Nicky-compact")
                           ?? AVSpeechSynthesisVoice(language: "en-US")
                utt.rate = 0.42
                utt.pitchMultiplier = 0.9
                utt.volume = 0.85
                speechSynth.stopSpeaking(at: .immediate)
                speechSynth.speak(utt)
            }
        }

        let dur = selectedPattern.duration(for: next, custom: (customInhale, customHold, customExhale))
        phase = next
        countdown = Int(dur)
        PhoneSession.shared.sendBreathingState(phase: next.label,
                                               countdown: Int(dur),
                                               phaseDuration: dur,
                                               pattern: selectedPattern.rawValue,
                                               isRunning: true)

        // Animate the circle via .animation() modifier on the view
        switch next {
        case .inhale: animationDuration = dur
        case .exhale: animationDuration = dur
        case .hold:   animationDuration = 0.2
        case .ready:  animationDuration = 1.0
        }
        scale = next.targetScale

        // Countdown ticks every second
        countdownTimer?.invalidate()
        var ticks = Int(dur)
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            ticks -= 1
            countdown = max(0, ticks)
            if ticks <= 0 { t.invalidate() }
        }

        // Advance to next phase when duration expires
        phaseTimer?.invalidate()
        phaseTimer = Timer.scheduledTimer(withTimeInterval: dur, repeats: false) { _ in
            DispatchQueue.main.async {
                switch next {
                case .inhale:
                    self.runPhase(.hold)
                case .hold:
                    self.runPhase(.exhale)
                case .exhale:
                    self.cycleCount += 1
                    self.runPhase(.inhale)
                case .ready:
                    break
                }
            }
        }
    }
}

// MARK: - Breathing Hub
struct BreathingHubView: View {
    @EnvironmentObject var premium: PremiumStore
    @State private var showPaywall = false
    private let brandPurple = Color(red: 0.541, green: 0.357, blue: 0.804)

    var body: some View {
        ZStack {
            CalmBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    // Breathing Exercise
                    NavigationLink(destination: BreathingView()) {
                        HubRow(icon: "lungs.fill", title: "Breathing Exercise",
                               subtitle: "Box · 4-7-8 · Custom patterns", purple: brandPurple)
                    }

                    // Quick Relief
                    if premium.isPremium {
                        NavigationLink(destination: QuickReliefHubView()) {
                            HubRow(icon: "bolt.heart.fill", title: "Quick Relief",
                                   subtitle: "Stress · Anxiety · Focus · Pain Relief", purple: brandPurple)
                        }
                    } else {
                        Button { showPaywall = true } label: {
                            HubRow(icon: "bolt.heart.fill", title: "Quick Relief",
                                   subtitle: "Stress · Anxiety · Focus · Pain Relief", purple: brandPurple, locked: true)
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
        }
        .navigationTitle("Breathe")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPaywall) { PaywallView(isPresented: $showPaywall) }
    }
}

private struct HubRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let purple: Color
    var locked: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.white).frame(width: 50, height: 50)
                    .shadow(color: purple.opacity(0.15), radius: 4, x: 0, y: 2)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(locked ? purple.opacity(0.35) : purple)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(locked ? .calmDeep.opacity(0.45) : .calmDeep)
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.calmMid.opacity(0.50))
                    }
                }
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.calmMid.opacity(0.75))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.calmMid.opacity(0.45))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.85))
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
    }
}

