import SwiftUI
import WatchKit
import WatchConnectivity
import Combine
import AVFoundation

// MARK: - Breathing Patterns
struct WatchBreathPattern {
    let name: String
    let inhale: Double
    let hold: Double   // 0 = skip hold phase
    let exhale: Double
}

private let watchPatterns: [WatchBreathPattern] = [
    WatchBreathPattern(name: "Box 4·4·4",  inhale: 4, hold: 4, exhale: 4),
    WatchBreathPattern(name: "4·7·8 Calm", inhale: 4, hold: 7, exhale: 8),
    WatchBreathPattern(name: "5·5 Relax",  inhale: 5, hold: 0, exhale: 5),
]

// MARK: - Phase
enum WatchPhase: String {
    case ready  = "Ready"
    case inhale = "Inhale"
    case hold   = "Hold"
    case exhale = "Exhale"

    var color: Color {
        switch self {
        case .ready, .inhale: return Color(red: 0.4, green: 0.8, blue: 0.9)
        case .hold:           return Color(red: 0.6, green: 0.4, blue: 0.9)
        case .exhale:         return Color(red: 0.3, green: 0.8, blue: 0.7)
        }
    }

    var targetScale: CGFloat {
        switch self {
        case .ready:          return 0.65
        case .inhale, .hold:  return 1.0
        case .exhale:         return 0.48
        }
    }
}

// MARK: - View Model
class WatchBreathingVM: NSObject, ObservableObject, WCSessionDelegate {
    @Published var phase: WatchPhase = .ready
    @Published var countdown: Int = 0
    @Published var isRunning: Bool = false
    @Published var phaseColor: Color = Color(red: 0.4, green: 0.8, blue: 0.9)
    @Published var circleScale: CGFloat = 0.65
    @Published var animDuration: Double = 1.0
    @Published var patternIndex: Int = 0
    @Published var cycleCount: Int = 0

    var currentPattern: WatchBreathPattern { watchPatterns[patternIndex] }

    private var phaseTimer: Timer?
    private var countdownTimer: Timer?
    private var bgPlayer: AVAudioPlayer?

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - Pattern Picker
    func nextPattern() {
        guard !isRunning else { return }
        patternIndex = (patternIndex + 1) % watchPatterns.count
    }

    // MARK: - Start / Stop
    func toggleBreathing() {
        if isRunning { stopBreathing() } else { startBreathing() }
    }

    private func startBreathing() {
        isRunning = true
        cycleCount = 0
        WKInterfaceDevice.current().play(.start)
        startBgMusic()
        runPhase(.inhale)
    }

    func stopBreathing() {
        isRunning = false
        phaseTimer?.invalidate()
        countdownTimer?.invalidate()
        phaseTimer = nil
        countdownTimer = nil
        phase = .ready
        countdown = 0
        cycleCount = 0
        animDuration = 1.0
        circleScale = 0.65
        phaseColor = Color(red: 0.4, green: 0.8, blue: 0.9)
        WKInterfaceDevice.current().play(.stop)
        bgPlayer?.stop()
        bgPlayer = nil
        sendToPhone(["action": "stopBreathing"])
    }

    // MARK: - Background Music
    private func startBgMusic() {
        let track: String
        switch patternIndex {
        case 1:  track = "peaceful_mind"
        case 2:  track = "zen_water"
        default: track = "serene_mindfulness"
        }
        let url = Bundle.main.url(forResource: track, withExtension: "mp3", subdirectory: "Audio")
            ?? Bundle.main.url(forResource: track, withExtension: "mp3")
        guard let url else { return }
        bgPlayer = try? AVAudioPlayer(contentsOf: url)
        bgPlayer?.numberOfLoops = -1
        bgPlayer?.volume = 0.4
        bgPlayer?.prepareToPlay()
        bgPlayer?.play()
    }

    // MARK: - Phase Engine (runs fully on watch)
    private func runPhase(_ next: WatchPhase) {
        guard isRunning else { return }

        let dur: Double
        switch next {
        case .inhale: dur = currentPattern.inhale
        case .hold:   dur = currentPattern.hold
        case .exhale: dur = currentPattern.exhale
        case .ready:  dur = 0
        }

        // Skip hold if duration is 0
        if next == .hold && dur == 0 {
            runPhase(.exhale)
            return
        }

        // Haptic feedback per phase
        switch next {
        case .inhale: WKInterfaceDevice.current().play(.directionUp)
        case .hold:   WKInterfaceDevice.current().play(.click)
        case .exhale: WKInterfaceDevice.current().play(.directionDown)
        case .ready:  break
        }

        phase      = next
        countdown  = Int(dur)
        animDuration = next == .hold ? 0.2 : dur
        circleScale  = next.targetScale
        phaseColor   = next.color

        // Countdown ticks every second
        countdownTimer?.invalidate()
        var ticks = Int(dur)
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            ticks -= 1
            DispatchQueue.main.async { self?.countdown = max(0, ticks) }
            if ticks <= 0 { t.invalidate() }
        }

        // Notify iPhone (best-effort, not required)
        sendToPhone([
            "phase": next.rawValue,
            "isRunning": true,
            "countdown": Int(dur),
            "phaseDuration": dur,
            "pattern": currentPattern.name
        ])

        // Advance to next phase
        phaseTimer?.invalidate()
        phaseTimer = Timer.scheduledTimer(withTimeInterval: dur, repeats: false) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                switch next {
                case .inhale: self.runPhase(.hold)
                case .hold:   self.runPhase(.exhale)
                case .exhale:
                    self.cycleCount += 1
                    self.runPhase(.inhale)
                case .ready:  break
                }
            }
        }
    }

    // MARK: - WatchConnectivity (optional sync)
    private func sendToPhone(_ msg: [String: Any]) {
        let wc = WCSession.default
        guard wc.activationState == .activated else { return }
        if wc.isReachable {
            wc.sendMessage(msg, replyHandler: nil)
        } else {
            try? wc.updateApplicationContext(msg.compactMapValues { $0 as AnyObject })
        }
    }

    // Receive stop signal from iPhone
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let action = message["action"] as? String, action == "stopBreathing" else { return }
        DispatchQueue.main.async { self.stopBreathing() }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {}
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
}

// MARK: - Content View
struct ContentView: View {
    @StateObject private var vm = WatchBreathingVM()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 6) {

                // Pattern selector — tap to cycle (hidden when running)
                if vm.isRunning {
                    Text(vm.currentPattern.name)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                } else {
                    Button(action: vm.nextPattern) {
                        HStack(spacing: 3) {
                            Text(vm.currentPattern.name)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                            Image(systemName: "chevron.right.2")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Animated breathing circle
                ZStack {
                    Circle()
                        .fill(vm.phaseColor.opacity(0.20))
                        .frame(width: 88, height: 88)
                        .scaleEffect(vm.circleScale)
                        .animation(.easeInOut(duration: vm.animDuration), value: vm.circleScale)

                    Circle()
                        .stroke(vm.phaseColor, lineWidth: 2.5)
                        .frame(width: 88, height: 88)
                        .scaleEffect(vm.circleScale)
                        .animation(.easeInOut(duration: vm.animDuration), value: vm.circleScale)

                    VStack(spacing: 1) {
                        Text(vm.phase.rawValue)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)

                        if vm.isRunning && vm.countdown > 0 {
                            Text("\(vm.countdown)")
                                .font(.system(size: 22, weight: .ultraLight, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                                .monospacedDigit()
                        } else if !vm.isRunning {
                            Image(systemName: "lungs.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }

                // Cycle counter
                if vm.isRunning {
                    Text("Cycle \(vm.cycleCount + 1)")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                }

                Spacer()

                // Play / Stop button — always enabled
                Button(action: vm.toggleBreathing) {
                    ZStack {
                        Circle()
                            .fill(vm.isRunning ? Color.white.opacity(0.15) : vm.phaseColor.opacity(0.3))
                            .frame(width: 44, height: 44)
                        Image(systemName: vm.isRunning ? "stop.fill" : "play.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
    }
}
