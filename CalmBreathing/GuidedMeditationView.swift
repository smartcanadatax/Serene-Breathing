import SwiftUI
import AVFoundation
import AVKit
import UIKit

// MARK: - Session Controller
@MainActor
class MeditationSession: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var displayText: String  = "Welcome"
    @Published var phase: String        = "Opening"
    @Published var progress: Double     = 0
    @Published var breathScale: CGFloat = 0.85
    @Published var isComplete           = false

    private var voicePlayer: AVAudioPlayer?
    private var steps:       [MeditationStep] = []
    private var sessionTimer: Timer?
    private var breathTimer:  Timer?
    private var elapsed       = 0
    private var totalSeconds  = 0
    private var stepIndex     = 0
    private var breathingIn   = true

    func start(minutes: Int, soundPlayer: SoundPlayer) {
        totalSeconds = minutes * 60
        steps        = MeditationScripts.steps(for: minutes)
        elapsed      = 0
        stepIndex    = 0
        progress     = 0
        isComplete   = false
        UIApplication.shared.isIdleTimerDisabled = true

        soundPlayer.playMeditationMusic()

        startBreathing()
        deliver(steps[0])

        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    func stop(soundPlayer: SoundPlayer) {
        sessionTimer?.invalidate()
        breathTimer?.invalidate()
        voicePlayer?.stop()
        voicePlayer = nil
        soundPlayer.stopMeditationMusic()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func tick() {
        elapsed  += 1
        progress  = min(1, Double(elapsed) / Double(totalSeconds))

        let next = stepIndex + 1
        if next < steps.count, elapsed >= steps[next].timeOffset {
            stepIndex = next
            deliver(steps[next])
        }

        if elapsed >= totalSeconds { complete() }
    }

    private func deliver(_ step: MeditationStep) {
        displayText = step.displayText
        phase       = step.phase.rawValue
        voicePlayer?.stop()

        // Play the pre-recorded Shelley audio file bundled in the app
        guard let url = Bundle.main.url(forResource: step.audioFile,
                                        withExtension: "m4a",
                                        subdirectory: "Audio"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }

        player.delegate = self
        player.volume   = 1.0
        player.prepareToPlay()
        player.play()
        voicePlayer = player
    }

    private func startBreathing() {
        // Toggle every 4.5 s to create a smooth 9-second breath cycle
        breathTimer = Timer.scheduledTimer(withTimeInterval: 4.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.breathingIn = !self.breathingIn
                withAnimation(.easeInOut(duration: 4.2)) {
                    self.breathScale = self.breathingIn ? 1.18 : 0.82
                }
            }
        }
    }

    private func complete() {
        sessionTimer?.invalidate()
        breathTimer?.invalidate()
        voicePlayer?.stop()
        voicePlayer = nil
        isComplete = true
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

// MARK: - Guided Meditation Tab
struct GuidedMeditationView: View {
    @EnvironmentObject var soundPlayer: SoundPlayer
    @StateObject private var session = MeditationSession()

    @State private var selectedMinutes  = 10
    @State private var isActive         = false
    @State private var showVoiceBanner  = false

    private let options = [10, 20, 30]

    /// true when no premium or enhanced voice is installed — voice will sound robotic
    private var needsBetterVoice: Bool {
        let all = AVSpeechSynthesisVoice.speechVoices()
        return !all.contains { $0.language.hasPrefix("en-") &&
            ($0.quality == .premium || $0.quality == .enhanced) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CalmBackground()

                if isActive {
                    ActiveSessionView(session: session, onEnd: endSession)
                        .environmentObject(soundPlayer)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 1.04)),
                            removal:   .opacity))
                } else {
                    pickerView
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.55), value: isActive)
            .navigationBarHidden(true)
            .onAppear { showVoiceBanner = needsBetterVoice }
            // Voice quality banner
            .overlay(alignment: .top) {
                if showVoiceBanner && !isActive {
                    voiceBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: showVoiceBanner)
            .onDisappear {
                if isActive { endSession() }
            }
        }
    }

    // MARK: - Voice Banner
    private var voiceBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform.badge.exclamationmark")
                .font(.system(size: 15))
                .foregroundColor(.calmAccent)

            VStack(alignment: .leading, spacing: 2) {
                Text("Download a natural voice")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                Text("Go to Settings → Accessibility → Spoken Content → Voices → English → Ava → Download")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.calmDeep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.calmAccent))
            }

            Button { withAnimation { showVoiceBanner = false } } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.calmAccent.opacity(0.25), lineWidth: 1))
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Session Picker
    private var pickerView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Aria — real AI photo with breathing animation
            AriaPortrait(idle: true)
                .frame(height: 280)

            // Guide name + tagline
            VStack(spacing: 6) {
                Text("Aria")
                    .font(.system(size: 30, weight: .regular, design: .rounded))
                    .foregroundColor(.white)
                Text("Your Personal Meditation Guide")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.calmAccent.opacity(0.7))
            }
            .padding(.top, 12)

            Spacer()

            // Duration selector
            VStack(spacing: 14) {
                Text("Choose Session Length")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.90))
                    .tracking(1.5)

                HStack(spacing: 14) {
                    ForEach(options, id: \.self) { mins in
                        Button {
                            selectedMinutes = mins
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(mins)")
                                    .font(.system(size: 26, weight: .regular, design: .rounded))
                                    .foregroundColor(selectedMinutes == mins ? .calmDeep : .white)
                                Text("min")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(selectedMinutes == mins ? .calmDeep : .white.opacity(0.55))
                            }
                            .frame(width: 88, height: 72)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(selectedMinutes == mins
                                          ? Color.calmAccent
                                          : Color.white.opacity(0.09))
                                    .shadow(color: selectedMinutes == mins
                                            ? Color.calmAccent.opacity(0.4) : .clear,
                                            radius: 12)
                            )
                        }
                    }
                }

                // Session description
                Text(sessionDescription)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 4)
            }

            // Start button
            Button(action: startSession) {
                HStack(spacing: 8) {
                    Text("Begin Meditation")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.calmAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Capsule().fill(Color.white).shadow(color: .black.opacity(0.10), radius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)

            Text("Voice guided · Ambient sound · Bell at close")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.85))
                .padding(.top, 14)

            DisclaimerFooter()
                .padding(.bottom, 36)
        }
        .padding(.horizontal, 24)
    }

    private var sessionDescription: String {
        switch selectedMinutes {
        case 10: return "Perfect for a quick reset. Body relaxation, breath awareness & stillness."
        case 20: return "A fuller practice. Includes body scan, open awareness & gentle visualisation."
        case 30: return "Deep immersion. Complete body scan, visualisation & loving kindness."
        default: return ""
        }
    }

    private func startSession() {
        isActive = true
        session.start(minutes: selectedMinutes, soundPlayer: soundPlayer)
    }

    private func endSession() {
        session.stop(soundPlayer: soundPlayer)
        isActive = false
    }
}

// MARK: - Active Session View
struct ActiveSessionView: View {
    @ObservedObject var session: MeditationSession
    @EnvironmentObject var soundPlayer: SoundPlayer
    let onEnd: () -> Void

    @State private var showEndConfirm = false

    var body: some View {
        ZStack {
            // Real video background
            LoopingVideoPlayer()
                .ignoresSafeArea()
            // Subtle dark overlay so text stays readable
            Color.black.opacity(0.38).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: { showEndConfirm = true }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.15)))
                    }

                    Spacer()

                    Text(session.phase)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .tracking(1.5)

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.20), lineWidth: 2.5)
                            .frame(width: 36, height: 36)
                        Circle()
                            .trim(from: 0, to: CGFloat(session.progress))
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .frame(width: 36, height: 36)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: session.progress)
                        Text("\(Int(session.progress * 100))%")
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.08)).frame(height: 3)
                        Capsule()
                            .fill(Color.calmAccent.opacity(0.7))
                            .frame(width: geo.size.width * session.progress, height: 3)
                            .animation(.linear(duration: 1), value: session.progress)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }

            // Completion overlay
            if session.isComplete {
                completionView
                    .transition(.opacity)
                    .onAppear { soundPlayer.playBell() }
            }
        }
        .alert("End Session?", isPresented: $showEndConfirm) {
            Button("End", role: .destructive) { onEnd() }
            Button("Continue", role: .cancel) {}
        } message: {
            Text("Your progress will not be saved.")
        }
    }

    private var completionView: some View {
        ZStack {
            Color.black.opacity(0.70).ignoresSafeArea()

            VStack(spacing: 24) {
                // Glowing checkmark
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [.calmAccent.opacity(0.3), .clear],
                            center: .center, startRadius: 0, endRadius: 60))
                        .frame(width: 120, height: 120)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.calmAccent)
                }

                Text("Beautiful Work")
                    .font(.system(size: 30, weight: .regular, design: .rounded))
                    .foregroundColor(.white)

                Text("You have completed your meditation.\nTake a moment to simply rest in how you feel.\nYou deserve this peace.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)

                Button(action: onEnd) {
                    Text("Close")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(.calmDeep)
                        .padding(.horizontal, 52)
                        .padding(.vertical, 15)
                        .background(Capsule().fill(Color.calmAccent))
                        .shadow(color: .calmAccent.opacity(0.4), radius: 12)
                }
                .padding(.top, 4)
            }
            .padding(36)
        }
        .animation(.easeInOut(duration: 0.6), value: session.isComplete)
    }
}

// MARK: - Human Meditating Figure
// Skin palette
private let skinLight  = Color(red: 0.97, green: 0.89, blue: 0.82)
private let skinMid    = Color(red: 0.90, green: 0.77, blue: 0.67)
private let skinShadow = Color(red: 0.76, green: 0.62, blue: 0.52)
private let hairColor  = Color(red: 0.14, green: 0.09, blue: 0.06)

struct MeditatingFigure: View {
    let breathScale: CGFloat
    let idle: Bool

    @State private var idlePulse: CGFloat = 1.0

    var effectiveScale: CGFloat { idle ? idlePulse : breathScale }

    var body: some View {
        ZStack {
            // Floating light particles
            ForEach(0..<8, id: \.self) { FloatingParticle(index: $0) }

            // Aura rings
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .stroke(Color.calmAccent.opacity(max(0, 0.13 - Double(i) * 0.028)), lineWidth: 1)
                    .frame(width: 160 + CGFloat(i * 52), height: 160 + CGFloat(i * 52))
                    .scaleEffect(effectiveScale)
                    .animation(.easeInOut(duration: 4.2).delay(Double(i) * 0.15), value: effectiveScale)
            }

            // Soft glow behind figure
            Circle()
                .fill(RadialGradient(
                    colors: [.calmAccent.opacity(0.28), .calmPurple.opacity(0.14), .clear],
                    center: .center, startRadius: 0, endRadius: 95))
                .frame(width: 190, height: 190)
                .scaleEffect(effectiveScale)
                .animation(.easeInOut(duration: 4.5), value: effectiveScale)
                .blur(radius: 8)

            // Human body
            HumanMeditatorBody()
                .scaleEffect(effectiveScale * 0.90)
                .animation(.easeInOut(duration: 4.2), value: effectiveScale)
        }
        .onAppear {
            if idle {
                withAnimation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true)) {
                    idlePulse = 1.10
                }
            }
        }
    }
}

// MARK: - Human body assembly
struct HumanMeditatorBody: View {
    var body: some View {
        VStack(spacing: 0) {

            // ── HEAD ──
            ZStack {
                // Halo glow
                Ellipse()
                    .fill(RadialGradient(
                        colors: [.calmAccent.opacity(0.40), .clear],
                        center: .center, startRadius: 10, endRadius: 62))
                    .frame(width: 124, height: 124)
                    .blur(radius: 6)

                // Hair (behind face)
                Ellipse()
                    .fill(LinearGradient(colors: [hairColor, hairColor.opacity(0.7)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 74, height: 80)
                    .offset(y: 5)

                // Face
                Ellipse()
                    .fill(LinearGradient(colors: [skinLight, skinMid],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 64, height: 78)
                    .shadow(color: skinShadow.opacity(0.25), radius: 5, x: 2, y: 3)

                // Forehead shading
                Ellipse()
                    .fill(Color.black.opacity(0.035))
                    .frame(width: 58, height: 22)
                    .offset(y: -24)

                // Hair top / fringe
                HairFringe()
                    .offset(y: -35)

                // Eyebrows
                HStack(spacing: 24) {
                    EyebrowArc()
                    EyebrowArc().scaleEffect(x: -1, y: 1)
                }
                .offset(y: -17)

                // Closed eyes
                HStack(spacing: 18) {
                    ClosedEyelid()
                    ClosedEyelid()
                }
                .offset(y: -6)

                // Nose bridge + tip
                ZStack {
                    Ellipse()
                        .fill(skinShadow.opacity(0.28))
                        .frame(width: 11, height: 6)
                }
                .offset(y: 10)

                // Gentle smile
                GentleSmile()
                    .offset(y: 24)

                // Subtle cheek warmth
                HStack(spacing: 38) {
                    Ellipse()
                        .fill(Color(red: 0.94, green: 0.72, blue: 0.68).opacity(0.30))
                        .frame(width: 18, height: 10)
                    Ellipse()
                        .fill(Color(red: 0.94, green: 0.72, blue: 0.68).opacity(0.30))
                        .frame(width: 18, height: 10)
                }
                .offset(y: 6)
            }
            .frame(width: 90, height: 90)

            // ── NECK ──
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(LinearGradient(colors: [skinMid, skinLight], startPoint: .top, endPoint: .bottom))
                    .frame(width: 24, height: 16)
                // Collar
                Ellipse()
                    .fill(Color.white.opacity(0.65))
                    .frame(width: 36, height: 10)
                    .offset(y: 7)
            }

            // ── SHOULDERS + ROBE ──
            ZStack {
                // Robe body
                RoundedRectangle(cornerRadius: 24)
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.90), Color.calmAccent.opacity(0.38)],
                        startPoint: .top, endPoint: .bottom))
                    .frame(width: 98, height: 64)

                // Shoulder drape
                Ellipse()
                    .fill(Color.white.opacity(0.80))
                    .frame(width: 118, height: 34)
                    .offset(y: -17)
                    .shadow(color: .calmAccent.opacity(0.10), radius: 4)

                // Centre fold
                Rectangle()
                    .fill(Color.calmAccent.opacity(0.15))
                    .frame(width: 1.5, height: 42)

                // Dhyana mudra hands in lap
                DhyanaMudra()
                    .offset(y: 26)
            }
            .frame(width: 120, height: 70)

            // ── LOTUS LEGS ──
            ZStack {
                // Left leg
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.76), Color.calmAccent.opacity(0.28)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 90, height: 27)
                    .offset(x: -16, y: -4)
                    .rotationEffect(.degrees(-13))

                // Right leg
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.76), Color.calmAccent.opacity(0.28)],
                        startPoint: .topTrailing, endPoint: .bottomLeading))
                    .frame(width: 90, height: 27)
                    .offset(x: 16, y: -4)
                    .rotationEffect(.degrees(13))

                // Left foot (skin)
                Ellipse()
                    .fill(LinearGradient(colors: [skinLight, skinMid], startPoint: .top, endPoint: .bottom))
                    .frame(width: 28, height: 17)
                    .offset(x: 38, y: 6)

                // Right foot (skin)
                Ellipse()
                    .fill(LinearGradient(colors: [skinLight, skinMid], startPoint: .top, endPoint: .bottom))
                    .frame(width: 28, height: 17)
                    .offset(x: -38, y: 6)
            }
            .frame(width: 120, height: 46)
        }
        .shadow(color: .calmAccent.opacity(0.16), radius: 18)
    }
}

// MARK: - Face feature shapes

struct HairFringe: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(hairColor)
                .frame(width: 70, height: 20)
                .offset(y: 3)
            // Highlight on hair
            Capsule()
                .fill(Color(red: 0.32, green: 0.22, blue: 0.14).opacity(0.55))
                .frame(width: 28, height: 7)
                .offset(x: -10, y: -1)
        }
    }
}

struct EyebrowArc: View {
    var body: some View {
        BrowPath()
            .stroke(hairColor.opacity(0.85),
                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            .frame(width: 20, height: 6)
    }
}

struct BrowPath: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY * 0.6),
            control: CGPoint(x: rect.midX, y: 0))
        return p
    }
}

struct ClosedEyelid: View {
    var body: some View {
        ZStack {
            // Eyelid fill
            Capsule()
                .fill(skinMid)
                .frame(width: 22, height: 10)
            // Upper lash line
            Capsule()
                .fill(hairColor.opacity(0.90))
                .frame(width: 22, height: 2.5)
                .offset(y: -3.5)
            // Lower shadow
            Capsule()
                .fill(skinShadow.opacity(0.40))
                .frame(width: 20, height: 1.5)
                .offset(y: 4)
        }
    }
}

struct GentleSmile: View {
    var body: some View {
        SmilePath()
            .stroke(Color(red: 0.65, green: 0.45, blue: 0.40),
                    style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
            .frame(width: 24, height: 9)
    }
}

struct SmilePath: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 0))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: 0),
            control: CGPoint(x: rect.midX, y: rect.maxY))
        return p
    }
}

struct DhyanaMudra: View {
    var body: some View {
        ZStack {
            // Bottom hand
            Ellipse()
                .fill(LinearGradient(colors: [skinLight, skinMid],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 40, height: 19)
                .offset(y: 4)
            // Top hand
            Ellipse()
                .fill(LinearGradient(colors: [skinLight, skinMid],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 38, height: 17)
                .offset(y: -4)
            // Thumb tips touching (mudra circle)
            Circle()
                .fill(skinLight)
                .frame(width: 11, height: 11)
                .shadow(color: skinShadow.opacity(0.2), radius: 2)
        }
    }
}

// MARK: - Floating Particle
struct FloatingParticle: View {
    let index: Int
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 0

    private var xPos: CGFloat {
        let positions: [CGFloat] = [-90, -55, -30, 10, 35, 65, 90, 115]
        return positions[index % positions.count]
    }

    private var size: CGFloat { CGFloat([6, 5, 4, 6, 5, 4, 5, 4][index % 8]) }
    private var duration: Double { [4.5, 5.2, 6.0, 5.5, 4.8, 6.2, 5.0, 4.3][index % 8] }
    private var delay: Double { Double(index) * 0.7 }

    var body: some View {
        Circle()
            .fill(Color.calmAccent.opacity(0.55))
            .frame(width: size, height: size)
            .blur(radius: 1.5)
            .offset(x: xPos, y: 80 + offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    offsetY   = -200
                    opacity   = 0
                }
                withAnimation(.easeIn(duration: 0.6).delay(delay)) {
                    opacity = 0.7
                }
            }
    }
}

// MARK: - Starfield Background
struct StarfieldView: View {
    var body: some View {
        ZStack {
            CalmBackground()
            // Subtle stars
            ForEach(0..<40, id: \.self) { i in
                let x = CGFloat((i * 73 + 17) % 380)
                let y = CGFloat((i * 47 + 31) % 820)
                let s = CGFloat((i % 3) + 1) * 0.8
                Circle()
                    .fill(Color.white.opacity(Double((i % 4)) * 0.06 + 0.04))
                    .frame(width: s, height: s)
                    .position(x: x, y: y)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Aria Portrait (real AI photo)
struct AriaPortrait: View {
    var idle: Bool
    var breathScale: CGFloat = 1.0

    @State private var idlePulse: CGFloat = 1.0
    @State private var glowPulse: Double = 0.55

    private var scale: CGFloat { idle ? idlePulse : breathScale }

    var body: some View {
        ZStack {
            // Outer glow rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.calmAccent.opacity(0.22 - Double(i) * 0.06), .clear],
                            startPoint: .top, endPoint: .bottom),
                        lineWidth: 1.2)
                    .frame(width: 200 + CGFloat(i * 36), height: 200 + CGFloat(i * 36))
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: 4.2).delay(Double(i) * 0.2), value: scale)
            }

            // Radial glow behind photo
            Circle()
                .fill(RadialGradient(
                    colors: [Color.calmAccent.opacity(glowPulse), .calmPurple.opacity(0.18), .clear],
                    center: .center, startRadius: 0, endRadius: 110))
                .frame(width: 220, height: 220)
                .blur(radius: 18)
                .scaleEffect(scale)
                .animation(.easeInOut(duration: 4.5), value: scale)

            // Aria's photo — circular crop
            if UIImage(named: "AriaFace") != nil {
                Image("AriaFace")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 170, height: 170)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.55), Color.calmAccent.opacity(0.30)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2.5)
                    )
                    .shadow(color: Color.calmAccent.opacity(0.38), radius: 20, x: 0, y: 4)
                    .scaleEffect(scale * 0.96)
                    .animation(.easeInOut(duration: 4.2), value: scale)
            } else {
                // Fallback to drawn figure if image missing
                MeditatingFigure(breathScale: breathScale, idle: idle)
            }
        }
        .onAppear {
            if idle {
                withAnimation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true)) {
                    idlePulse = 1.08
                }
                withAnimation(.easeInOut(duration: 3.8).repeatForever(autoreverses: true)) {
                    glowPulse = 0.80
                }
            }
        }
    }
}

// MARK: - Looping Video Background
struct LoopingVideoPlayer: UIViewRepresentable {

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.backgroundColor = .black

        guard let url = Bundle.main.url(forResource: "meditation_bg", withExtension: "mp4") else {
            return view
        }

        let player = AVPlayer(url: url)
        player.isMuted = true
        player.allowsExternalPlayback = false

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main) { _ in
            player.seek(to: .zero)
            player.play()
        }

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(playerLayer)
        view.playerLayer = playerLayer   // stored so layoutSubviews can resize it

        player.play()
        context.coordinator.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {}

    class Coordinator {
        var player: AVPlayer?
        deinit {
            player?.pause()
            NotificationCenter.default.removeObserver(self)
        }
    }
}

/// UIView subclass that keeps AVPlayerLayer filling its bounds at all times
class PlayerUIView: UIView {
    var playerLayer: AVPlayerLayer?
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}

// MARK: - Ocean Background
struct OceanBackgroundView: View {
    @State private var waveOffset1: CGFloat = 0
    @State private var waveOffset2: CGFloat = 0
    @State private var waveOffset3: CGFloat = 0
    @State private var shimmerOpacity: Double = 0.08
    @State private var lightRayAngle: Double = -15

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Sky gradient — deep blue to horizon teal
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.05, blue: 0.22),
                        Color(red: 0.04, green: 0.14, blue: 0.38),
                        Color(red: 0.08, green: 0.30, blue: 0.55),
                        Color(red: 0.12, green: 0.48, blue: 0.62),
                        Color(red: 0.18, green: 0.58, blue: 0.60),
                    ],
                    startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

                // Sun / moon glow on horizon
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            Color(red: 0.95, green: 0.88, blue: 0.65).opacity(0.28),
                            Color(red: 0.72, green: 0.82, blue: 0.95).opacity(0.12),
                            .clear
                        ],
                        center: .center, startRadius: 0, endRadius: 120))
                    .frame(width: 280, height: 160)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.52)
                    .blur(radius: 22)

                // Light rays from horizon
                ForEach(0..<5, id: \.self) { i in
                    LightRay(angle: Double(i) * 18.0 - 36.0 + lightRayAngle)
                        .fill(Color.white.opacity(0.025))
                        .frame(width: geo.size.width * 1.4, height: geo.size.height * 0.55)
                        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.52)
                }

                // Ocean body — deep water gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.32, blue: 0.52).opacity(0.0),
                        Color(red: 0.05, green: 0.22, blue: 0.42).opacity(0.72),
                        Color(red: 0.02, green: 0.10, blue: 0.28),
                    ],
                    startPoint: .top, endPoint: .bottom)
                .frame(height: geo.size.height * 0.55)
                .position(x: geo.size.width * 0.5,
                          y: geo.size.height * 0.5 + geo.size.height * 0.275)
                .ignoresSafeArea()

                // Wave layer 1 — back / slow
                WaveShape(offset: waveOffset1, amplitude: 10, frequency: 0.012)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.18, green: 0.62, blue: 0.72).opacity(0.38), .clear],
                            startPoint: .top, endPoint: .bottom))
                    .frame(height: 90)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.52)

                // Wave layer 2 — mid
                WaveShape(offset: waveOffset2, amplitude: 13, frequency: 0.018)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.22, green: 0.70, blue: 0.80).opacity(0.28), .clear],
                            startPoint: .top, endPoint: .bottom))
                    .frame(height: 70)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.535)

                // Wave layer 3 — front / fast
                WaveShape(offset: waveOffset3, amplitude: 8, frequency: 0.022)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.14), .clear],
                            startPoint: .top, endPoint: .bottom))
                    .frame(height: 50)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.548)

                // Surface shimmer sparkles
                ForEach(0..<12, id: \.self) { i in
                    let sx = CGFloat((i * 71 + 23) % Int(geo.size.width))
                    let sy = geo.size.height * 0.50 + CGFloat((i * 37 + 11) % 80)
                    Circle()
                        .fill(Color.white.opacity(shimmerOpacity + Double(i % 3) * 0.04))
                        .frame(width: CGFloat(i % 3 + 1) * 1.5, height: CGFloat(i % 3 + 1) * 1.5)
                        .position(x: sx, y: sy)
                        .blur(radius: 0.8)
                }

                // Subtle vignette
                RadialGradient(
                    colors: [.clear, .black.opacity(0.42)],
                    center: .center, startRadius: geo.size.width * 0.35, endRadius: geo.size.width * 0.85)
                .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Slow wave animation
            withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) {
                waveOffset1 = 360
            }
            withAnimation(.linear(duration: 6.5).repeatForever(autoreverses: false)) {
                waveOffset2 = 360
            }
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                waveOffset3 = 360
            }
            withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
                shimmerOpacity = 0.22
            }
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                lightRayAngle = 15
            }
        }
    }
}

// MARK: - Wave Shape
struct WaveShape: Shape {
    var offset: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat

    var animatableData: CGFloat { get { offset } set { offset = newValue } }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))

        for x in stride(from: 0, through: rect.width, by: 2) {
            let angle = (x + offset) * frequency * .pi * 2
            let y = rect.midY + sin(angle) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Light Ray Shape
struct LightRay: Shape {
    var angle: Double  // degrees from vertical

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rad = angle * .pi / 180
        let origin = CGPoint(x: rect.midX, y: rect.midY)
        let spread: CGFloat = 30
        path.move(to: origin)
        path.addLine(to: CGPoint(
            x: origin.x + cos(rad - spread * .pi / 180) * rect.height,
            y: origin.y + sin(rad - spread * .pi / 180) * rect.height))
        path.addLine(to: CGPoint(
            x: origin.x + cos(rad + spread * .pi / 180) * rect.height,
            y: origin.y + sin(rad + spread * .pi / 180) * rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Wave Dot (speaking indicator)
struct WaveDot: View {
    let delay: Double
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.35

    var body: some View {
        Circle()
            .fill(Color.white.opacity(opacity))
            .frame(width: 5, height: 5)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.7)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    scale   = 1.0
                    opacity = 0.85
                }
            }
    }
}
