import SwiftUI
import AVFoundation

// MARK: - AI Breathing Coach

struct AIBreathingCoachView: View {

    @Environment(\.dismiss) private var dismiss

    private let moods = ["Stressed", "Anxious", "Can't Sleep", "Overwhelmed", "Sad", "Unfocused", "Tired", "Angry"]

    @State private var userInput    = ""
    @State private var fullResponse = ""
    @State private var exerciseName = ""
    @State private var script       = ""
    @State private var isGenerating = false
    @State private var showSession  = false
    @State private var errorText:   String?
    @State private var isPlaying    = false
    @State private var pulseScale:  CGFloat = 1.0

    private let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        ZStack {
            CalmBackground()
            if showSession {
                sessionView
            } else {
                inputView
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Input View

    private var inputView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Header
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 80, height: 80)
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }
                    Text("AI Breathing Coach")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Tell me how you feel and I'll create a personalized guided session just for you.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }

                // Quick mood grid
                VStack(alignment: .leading, spacing: 10) {
                    Text("How are you feeling?")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 10
                    ) {
                        ForEach(moods, id: \.self) { mood in
                            let selected = userInput == "I'm feeling \(mood.lowercased())"
                            Button {
                                userInput = "I'm feeling \(mood.lowercased())"
                            } label: {
                                Text(mood)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.calmDeep)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(selected ? 0.85 : 0.45))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.calmDeep.opacity(selected ? 0.3 : 0), lineWidth: 1.5)
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Custom text input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Or describe it in your own words:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.45))
                            .frame(minHeight: 80)

                        if userInput.isEmpty {
                            Text("e.g. \"I'm overwhelmed and can't stop thinking...\"")
                                .font(.system(size: 13))
                                .foregroundColor(.calmMid.opacity(0.65))
                                .padding(12)
                        }

                        TextEditor(text: $userInput)
                            .font(.system(size: 14))
                            .foregroundColor(.calmDeep)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                    }
                }
                .padding(.horizontal, 24)

                // Error
                if let err = errorText {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.25)))
                        .padding(.horizontal, 24)
                }

                // Generate button
                Button { Task { await generate() } } label: {
                    HStack(spacing: 10) {
                        if isGenerating {
                            ProgressView().tint(.calmDeep)
                            Text("Creating your session…")
                        } else {
                            Image(systemName: "sparkles")
                            Text("Generate My Session")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.calmDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.calmAccent))
                }
                .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty || isGenerating)
                .padding(.horizontal, 24)

                DisclaimerFooter()
                    .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Session View

    private var sessionView: some View {
        VStack(spacing: 0) {

            // Nav bar
            HStack {
                Button {
                    stopPlayback()
                    showSession = false
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("New Session")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.calmDeep)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Exercise badge
                    if !exerciseName.isEmpty {
                        Text(exerciseName)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.calmDeep)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.white.opacity(0.55)))
                    }

                    // Breathing circle animation
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 200, height: 200)
                            .scaleEffect(isPlaying ? pulseScale * 1.25 : 1.0)

                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 200, height: 200)
                            .scaleEffect(isPlaying ? pulseScale : 1.0)

                        Circle()
                            .fill(Color.white.opacity(0.22))
                            .frame(width: 200, height: 200)

                        Image(systemName: "lungs.fill")
                            .font(.system(size: 54))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .animation(
                        isPlaying
                            ? .easeInOut(duration: 4).repeatForever(autoreverses: true)
                            : .easeInOut(duration: 1),
                        value: isPlaying
                    )
                    .onAppear {
                        if isPlaying { pulseScale = 1.35 }
                    }
                    .onChange(of: isPlaying) { _, playing in
                        pulseScale = playing ? 1.35 : 1.0
                    }

                    // Play / Stop button
                    Button {
                        if isPlaying { stopPlayback() } else { startPlayback() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                .font(.system(size: 24))
                            Text(isPlaying ? "Stop" : "Play Session")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.calmDeep)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.calmAccent))
                    }

                    // Script card
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Your Guided Script", systemImage: "text.bubble.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)

                        Text(script)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.calmDeep)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.45))
                    )
                    .padding(.horizontal, 24)

                    DisclaimerFooter()
                        .padding(.bottom, 16)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Logic

    private func generate() async {
        let feeling = userInput.trimmingCharacters(in: .whitespaces)
        guard !feeling.isEmpty else { return }

        isGenerating = true
        errorText    = nil
        fullResponse = ""
        exerciseName = ""
        script       = ""

        do {
            for try await chunk in AIBreathingCoachService.stream(feeling) {
                await MainActor.run { fullResponse += chunk }
            }
            await MainActor.run {
                parseResponse(fullResponse)
                showSession = true
            }
        } catch {
            await MainActor.run { errorText = error.localizedDescription }
        }
        await MainActor.run { isGenerating = false }
    }

    private func parseResponse(_ text: String) {
        // Extract EXERCISE line
        if let range = text.range(of: "EXERCISE:") {
            let after = text[range.upperBound...]
            exerciseName = (after.components(separatedBy: "\n").first ?? "")
                .trimmingCharacters(in: .whitespaces)
        }
        // Extract SCRIPT section
        if let range = text.range(of: "SCRIPT:") {
            script = String(text[range.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            script = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func startPlayback() {
        guard !script.isEmpty else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}

        let utterance = AVSpeechUtterance(string: script)
        utterance.rate           = 0.40
        utterance.pitchMultiplier = 1.0
        utterance.volume         = 1.0
        utterance.voice          = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Nicky-compact")
            ?? AVSpeechSynthesisVoice(language: "en-US")

        synthesizer.speak(utterance)
        isPlaying = true
    }

    private func stopPlayback() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
    }
}
