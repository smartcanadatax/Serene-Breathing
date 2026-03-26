import SwiftUI
import WatchKit
import WatchConnectivity
import Combine

struct ContentView: View {
    @StateObject private var session = WatchSession()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 6) {
                Text(session.isRunning ? session.pattern : "Serene Breathing")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .lineLimit(1)

                Spacer()

                ZStack {
                    Circle()
                        .fill(session.phaseColor.opacity(0.20))
                        .frame(width: 88, height: 88)
                        .scaleEffect(session.circleScale)
                        .animation(.easeInOut(duration: session.animDuration), value: session.circleScale)

                    Circle()
                        .stroke(session.phaseColor, lineWidth: 2.5)
                        .frame(width: 88, height: 88)
                        .scaleEffect(session.circleScale)
                        .animation(.easeInOut(duration: session.animDuration), value: session.circleScale)

                    VStack(spacing: 1) {
                        Text(session.phase)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)

                        if session.isRunning && session.countdown > 0 {
                            Text("\(session.countdown)")
                                .font(.system(size: 22, weight: .ultraLight, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                                .monospacedDigit()
                        } else if !session.isRunning {
                            Image(systemName: "lungs.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }

                Spacer()

                Button {
                    session.sendStop()
                } label: {
                    ZStack {
                        Circle()
                            .fill(session.isRunning ? Color.white.opacity(0.15) : session.phaseColor.opacity(0.3))
                            .frame(width: 44, height: 44)
                        Image(systemName: session.isRunning ? "stop.fill" : "play.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!session.isReachable && !session.isRunning)

                if !session.isReachable && !session.isRunning {
                    Text("Open iPhone app")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
    }
}

class WatchSession: NSObject, ObservableObject, WCSessionDelegate {
    @Published var phase: String = "Ready"
    @Published var countdown: Int = 0
    @Published var pattern: String = ""
    @Published var isRunning: Bool = false
    @Published var phaseColor: Color = Color(red: 0.4, green: 0.8, blue: 0.9)
    @Published var circleScale: CGFloat = 0.65
    @Published var animDuration: Double = 1.0
    @Published var isReachable: Bool = false

    private let wc = WCSession.default
    private var countdownTimer: Timer?

    override init() {
        super.init()
        wc.delegate = self
        wc.activate()
    }

    func sendStop() {
        guard wc.isReachable else { return }
        let action = isRunning ? "stopBreathing" : "startBreathing"
        wc.sendMessage(["action": action], replyHandler: nil)
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { self.applyState(message) }
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async { self.applyState(applicationContext) }
    }

    // MARK: - State

    private func applyState(_ msg: [String: Any]) {
        guard let newPhase = msg["phase"] as? String,
              let newIsRunning = msg["isRunning"] as? Bool else { return }

        let newCountdown   = msg["countdown"] as? Int    ?? 0
        let phaseDuration  = msg["phaseDuration"] as? Double ?? Double(max(newCountdown, 1))
        let newPattern     = msg["pattern"] as? String   ?? ""

        let phaseChanged = newPhase != phase || newIsRunning != isRunning

        pattern   = newPattern
        isRunning = newIsRunning

        guard newIsRunning else {
            stopCountdown()
            phase     = "Ready"
            countdown = 0
            animDuration = 1.0
            withAnimation(.easeInOut(duration: 1.0)) {
                circleScale = 0.65
                phaseColor  = Color(red: 0.4, green: 0.8, blue: 0.9)
            }
            return
        }

        if phaseChanged {
            WKInterfaceDevice.current().play(newPhase == "Exhale" ? .directionDown : .directionUp)

            let (color, scale, dur): (Color, CGFloat, Double) = {
                switch newPhase {
                case "Inhale": return (Color(red: 0.4, green: 0.8, blue: 0.9), 1.0,  phaseDuration)
                case "Hold":   return (Color(red: 0.6, green: 0.4, blue: 0.9), 1.0,  0.2)
                case "Exhale": return (Color(red: 0.3, green: 0.8, blue: 0.7), 0.48, phaseDuration)
                default:       return (Color(red: 0.4, green: 0.8, blue: 0.9), 0.65, 1.0)
                }
            }()

            animDuration = dur
            phase        = newPhase
            countdown    = newCountdown

            withAnimation(.easeInOut(duration: dur)) {
                circleScale = scale
                phaseColor  = color
            }

            startCountdown(from: newCountdown)
        } else {
            countdown = newCountdown
        }
    }

    private func startCountdown(from value: Int) {
        stopCountdown()
        guard value > 0 else { return }
        var ticks = value
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            ticks -= 1
            DispatchQueue.main.async { self?.countdown = max(0, ticks) }
            if ticks <= 0 { t.invalidate() }
        }
    }

    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
}
