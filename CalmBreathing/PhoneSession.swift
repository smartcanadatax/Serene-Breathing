import WatchConnectivity

// MARK: - Phone-side WatchConnectivity handler
// Receives "toggleTimer" messages from the Watch companion app
// and broadcasts them as a local notification so MeditationTimerView
// can respond without any tight coupling.

class PhoneSession: NSObject, WCSessionDelegate {
    static let shared = PhoneSession()

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate after Watch switches (required for paired Watch switching)
        WCSession.default.activate()
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        guard let action = message["action"] as? String else { return }
        DispatchQueue.main.async {
            switch action {
            case "toggleTimer":
                NotificationCenter.default.post(name: .watchToggleTimer, object: nil)
            case "stopBreathing":
                NotificationCenter.default.post(name: .watchStopBreathing, object: nil)
            default:
                break
            }
        }
    }

    // MARK: - Outbound: send breathing state to Watch
    func sendBreathingState(phase: String, countdown: Int, phaseDuration: Double,
                            pattern: String, isRunning: Bool) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }
        let msg: [String: Any] = [
            "phase":         phase,
            "countdown":     countdown,
            "phaseDuration": phaseDuration,
            "pattern":       pattern,
            "isRunning":     isRunning
        ]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(msg, replyHandler: nil)
        } else {
            try? WCSession.default.updateApplicationContext(msg)
        }
    }
}

// MARK: - Notification names
extension Notification.Name {
    static let watchToggleTimer   = Notification.Name("watchToggleTimer")
    static let watchStopBreathing = Notification.Name("watchStopBreathing")
}
