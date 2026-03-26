import SwiftUI

// MARK: - Shared logo animation helper
private func logoImage(breathe: Bool, shouldAnimate: Bool, cycleDuration: Double) -> some View {
    Image("AppLogo")
        .resizable()
        .scaledToFit()
        .saturation(0.5)
        .brightness(0.25)
        .scaleEffect(breathe ? 1.22 : 1.0)
        .opacity(breathe ? 1.0 : 0.90)
        .drawingGroup()
        .animation(
            shouldAnimate ? .easeInOut(duration: cycleDuration).repeatForever(autoreverses: true) : .default,
            value: breathe
        )
}

// MARK: - Breathing Ring (shows inhale/exhale label)
struct BreathingRingView: View {
    var isAnimating: Bool = true
    @State private var breathe  = false
    @State private var inhaling = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let cycleDuration: Double = 4.5
    private var shouldAnimate: Bool { isAnimating && !reduceMotion }

    var body: some View {
        VStack(spacing: 4) {
            logoImage(breathe: breathe, shouldAnimate: shouldAnimate, cycleDuration: cycleDuration)
                .frame(width: 240, height: 240)
                .onAppear { breathe = shouldAnimate; if shouldAnimate { scheduleToggle() } }
                .onDisappear { breathe = false; inhaling = true }
                .onChange(of: isAnimating) { _, active in breathe = active && !reduceMotion }

            Text(inhaling ? "inhale" : "exhale")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.70))
                .transition(.opacity)
                .id(inhaling)
        }
    }

    private func scheduleToggle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + cycleDuration) {
            guard shouldAnimate else { return }
            withAnimation(.easeInOut(duration: 0.4)) { inhaling.toggle() }
            scheduleToggle()
        }
    }
}

// MARK: - Meditation Orb
struct MeditationOrbView: View {
    var isAnimating: Bool = true
    @State private var breathe = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let cycleDuration: Double = 4.5
    private var shouldAnimate: Bool { isAnimating && !reduceMotion }

    var body: some View {
        logoImage(breathe: breathe, shouldAnimate: shouldAnimate, cycleDuration: cycleDuration)
            .onAppear { breathe = shouldAnimate }
            .onDisappear { breathe = false }
            .onChange(of: isAnimating) { _, active in breathe = active && !reduceMotion }
    }
}

// MARK: - Lotus Orb
struct LotusOrbView: View {
    var isAnimating: Bool = true
    @State private var breathe = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let cycleDuration: Double = 4.5
    private var shouldAnimate: Bool { isAnimating && !reduceMotion }

    var body: some View {
        logoImage(breathe: breathe, shouldAnimate: shouldAnimate, cycleDuration: cycleDuration)
            .onAppear { breathe = shouldAnimate }
            .onDisappear { breathe = false }
            .onChange(of: isAnimating) { _, active in breathe = active && !reduceMotion }
    }
}

// MARK: - Body Scan Orb
struct BodyScanOrbView: View {
    var isAnimating: Bool = true
    @State private var breathe = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let cycleDuration: Double = 4.5
    private var shouldAnimate: Bool { isAnimating && !reduceMotion }

    var body: some View {
        logoImage(breathe: breathe, shouldAnimate: shouldAnimate, cycleDuration: cycleDuration)
            .onAppear { breathe = shouldAnimate }
            .onDisappear { breathe = false }
            .onChange(of: isAnimating) { _, active in breathe = active && !reduceMotion }
    }
}

// MARK: - Calm Timer Orb (unused — kept for reference)
struct CalmTimerOrbView: View {
    var isAnimating: Bool = true
    var body: some View { LotusOrbView(isAnimating: isAnimating) }
}
