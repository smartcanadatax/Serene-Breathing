import SwiftUI

struct LaunchAnimationView: View {
    let onFinished: () -> Void

    // Orb state
    @State private var orbAlpha:    Double  = 0
    @State private var orbScale:    CGFloat = 0.2
    @State private var pulseScale:  CGFloat = 1.0
    @State private var glowOpacity: Double  = 0
    @State private var glowRadius:  CGFloat = 8

    // Satellites
    @State private var satelliteAlpha:  Double  = 0
    @State private var satelliteOffset: CGFloat = 1   // 1 = at start, 0 = merged
    @State private var satelliteScale:  CGFloat = 1.0

    // Text
    @State private var titleAlpha:  Double  = 0
    @State private var titleY:      CGFloat = 18
    @State private var titleBlur:   CGFloat = 10
    @State private var titleScale:  CGFloat = 0.4
    @State private var subAlpha:    Double  = 0
    @State private var subY:        CGFloat = 12

    // Screen
    @State private var screenAlpha: Double = 1

    private let purple = Color(red: 0.541, green: 0.357, blue: 0.804)

    private func positions(radius: Double) -> [CGSize] {
        let count = 24
        return (0..<count).map { i in
            let angle = Double(i) * 2 * .pi / Double(count)
            return CGSize(width: radius * cos(angle), height: radius * sin(angle))
        }
    }

    var body: some View {
        GeometryReader { geo in
            let radius = Double(min(geo.size.width, geo.size.height)) * 0.42
            let pos    = positions(radius: radius)

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.28, green: 0.55, blue: 0.82),
                        Color(red: 0.16, green: 0.40, blue: 0.72),
                        Color(red: 0.08, green: 0.26, blue: 0.62)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()

                // Absorption glow
                Circle()
                    .fill(RadialGradient(
                        colors: [purple.opacity(0.55), purple.opacity(0.08), .clear],
                        center: .center, startRadius: 0, endRadius: 120
                    ))
                    .frame(width: 280, height: 280)
                    .blur(radius: glowRadius)
                    .opacity(glowOpacity)
                    .scaleEffect(pulseScale)

                // Satellite orbs
                ForEach(Array(pos.enumerated()), id: \.offset) { i, p in
                    OrbParticle(index: i, purple: purple)
                        .offset(
                            x: p.width  * satelliteOffset,
                            y: p.height * satelliteOffset
                        )
                        .scaleEffect(satelliteScale)
                        .opacity(satelliteAlpha * (1.0 - (1.0 - satelliteOffset) * 0.5))
                }

                // Main orb — sits exactly at ZStack center so satellites merge to its middle
                LotusOrbView(isAnimating: false)
                    .frame(width: 138, height: 138)
                    .scaleEffect(orbScale * pulseScale)
                    .opacity(orbAlpha)

            // Text — offset below the orb
            VStack(spacing: 6) {
                Text("Serene")
                    .font(.system(size: 42, weight: .bold, design: .serif))
                    .italic()
                    .foregroundColor(Color(red: 0.88, green: 0.74, blue: 1.0))
                    .opacity(titleAlpha)
                    .offset(y: titleY)
                    .blur(radius: titleBlur)
                    .scaleEffect(titleScale)

                Text("B R E A T H I N G")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.88, green: 0.74, blue: 1.0).opacity(0.80))
                    .tracking(4)
                    .opacity(subAlpha)
                    .offset(y: subY)
                }
                .offset(y: 120)
            }
            .opacity(screenAlpha)
            .onAppear { run() }
        }
    }

    private func run() {
        // 1 — main orb appears
        withAnimation(.easeOut(duration: 0.42)) {
            orbAlpha = 1
            orbScale = 1.0
        }

        // 2 — satellites appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            withAnimation(.easeOut(duration: 0.30)) {
                satelliteAlpha = 1
            }
        }

        // 3 — satellites slowly fly to center
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
            withAnimation(.easeInOut(duration: 1.80)) {
                satelliteOffset = 0
                satelliteScale  = 0.01
                satelliteAlpha  = 0
            }
        }

        // 4 — absorption pulse (starts just after merge completes at 0.72+1.80=2.52)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.62) {
            withAnimation(.easeOut(duration: 0.20)) {
                pulseScale  = 1.32
                glowOpacity = 1
                glowRadius  = 36
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.82) {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.55)) {
                pulseScale  = 1.0
                glowRadius  = 10
                glowOpacity = 0.30
            }
        }

        // 5 — "Serene" bounces in
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.12) {
            withAnimation(.spring(response: 0.50, dampingFraction: 0.32)) {
                titleScale = 1.0
                titleY     = 0
            }
            withAnimation(.easeOut(duration: 0.35)) {
                titleAlpha = 1
                titleBlur  = 0
            }
        }

        // 6 — "BREATHING" fades up
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.48) {
            withAnimation(.easeOut(duration: 0.48)) {
                subAlpha = 1
                subY     = 0
            }
        }

        // 7 — hold then fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.60) {
            withAnimation(.easeIn(duration: 0.52)) {
                screenAlpha = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.12) {
            onFinished()
        }
    }
}

// MARK: - Particle

private struct OrbParticle: View {
    let index: Int
    let purple: Color
    @State private var twinkle = false

    private let cores: [CGFloat] = [9, 12, 8, 14, 10, 11, 8, 13]
    private let halos: [CGFloat] = [28, 34, 24, 38, 28, 32, 22, 36]

    var body: some View {
        let core = cores[index % cores.count]
        let halo = halos[index % halos.count]

        ZStack {
            // Halo glow
            Circle()
                .fill(purple.opacity(0.28))
                .frame(width: halo, height: halo)
                .blur(radius: 5)
                .scaleEffect(twinkle ? 1.35 : 1.0)

            // Bright core
            Circle()
                .fill(RadialGradient(
                    colors: [.white.opacity(0.95), purple, purple.opacity(0.0)],
                    center: .center, startRadius: 0, endRadius: core * 0.55
                ))
                .frame(width: core, height: core)
                .scaleEffect(twinkle ? 0.78 : 1.0)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.35 + Double(index % 5) * 0.08)
                .repeatForever(autoreverses: true)
                .delay(Double(index % 6) * 0.10)
            ) { twinkle = true }
        }
    }
}
