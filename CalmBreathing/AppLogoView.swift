import SwiftUI

// MARK: - Simplified Wave Logo
// Drop-in replacement for Image("AppLogo") — scales cleanly at any size.
// Usage: AppLogoView(size: 40)

struct AppLogoView: View {
    var size: CGFloat = 40

    private let borderColor  = Color(red: 0.50, green: 0.30, blue: 0.88)
    private let waveDeep     = Color(red: 0.42, green: 0.22, blue: 0.82)
    private let waveMid      = Color(red: 0.62, green: 0.45, blue: 0.95)
    private let wavLight     = Color(red: 0.78, green: 0.64, blue: 1.00)

    var body: some View {
        ZStack {
            // White background
            Circle()
                .fill(Color.white)

            // Bottom wave fill (deeper purple)
            WaveBottomShape(yFraction: 0.56, curvature: 0.13)
                .fill(waveDeep)
                .clipShape(Circle())

            // Top wave fill (lighter purple — creates layered look)
            WaveBottomShape(yFraction: 0.46, curvature: 0.11)
                .fill(waveMid.opacity(0.85))
                .clipShape(Circle())

            // Thin highlight wave line
            WaveStrokePath(yFraction: 0.44, curvature: 0.10)
                .stroke(wavLight.opacity(0.70), lineWidth: size * 0.025)
                .clipShape(Circle())

            // Circle border
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [wavLight, waveDeep],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: size * 0.055
                )
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Wave Fill Shape
// Fills everything below a sinusoidal wave at `yFraction` (0=top, 1=bottom).
private struct WaveBottomShape: Shape {
    var yFraction: CGFloat   // vertical midpoint of wave (0–1)
    var curvature: CGFloat   // amplitude as fraction of height

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let mid   = h * yFraction
        let amp   = h * curvature
        var p = Path()
        p.move(to: CGPoint(x: 0, y: mid + amp * 0.3))
        p.addCurve(
            to:       CGPoint(x: w,     y: mid - amp * 0.3),
            control1: CGPoint(x: w * 0.30, y: mid - amp),
            control2: CGPoint(x: w * 0.70, y: mid + amp)
        )
        p.addLine(to: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: 0, y: h))
        p.closeSubpath()
        return p
    }
}

// MARK: - Wave Stroke Path (highlight line only)
private struct WaveStrokePath: Shape {
    var yFraction: CGFloat
    var curvature: CGFloat

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let mid = h * yFraction
        let amp = h * curvature
        var p = Path()
        p.move(to: CGPoint(x: 0, y: mid + amp * 0.3))
        p.addCurve(
            to:       CGPoint(x: w,     y: mid - amp * 0.3),
            control1: CGPoint(x: w * 0.30, y: mid - amp),
            control2: CGPoint(x: w * 0.70, y: mid + amp)
        )
        return p
    }
}

#Preview {
    HStack(spacing: 20) {
        AppLogoView(size: 40)
        AppLogoView(size: 64)
        AppLogoView(size: 120)
    }
    .padding(40)
    .background(Color(red: 0.08, green: 0.12, blue: 0.28))
}
