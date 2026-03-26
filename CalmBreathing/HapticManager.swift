import UIKit

// MARK: - Haptic Manager
enum HapticManager {
    /// Soft pulse — inhale start
    static func inhale() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.6)
    }

    /// Medium pulse — hold start
    static func hold() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.4)
    }

    /// Gentle release — exhale start
    static func exhale() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.3)
    }

    /// Bell / session complete
    static func complete() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Session start
    static func start() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
