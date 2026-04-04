import SwiftUI
import AVFoundation
import UIKit

// MARK: - Audio file map (add entries as you record each mood)
private let personalizedMeditationAudioFiles: [MeditationMood: String] = [
    .stressed:   "meditation_stressed_3min",
    .anxious:    "meditation_stressed_3min",
    .cantSleep:  "meditation_cantsleep_3min",
    .overwhelmed:"meditation_overwhelmed_3min",
    .sad:        "meditation_sad_3min",
    .unfocused:  "meditation_unfocused_3min",
    .tired:      "meditation_tired_3min",
    .lonely:     "meditation_lonely_3min",
]

// MARK: - Playback Engine

@MainActor
final class PersonalizedMeditationEngine: NSObject, ObservableObject {
    @Published var isPlaying  = false
    @Published var isFinished = false
    @Published var progress: Double = 0

    // For pre-recorded audio
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?

    // For TTS fallback
    private let synthesizer = AVSpeechSynthesizer()
    private var sentences: [ScriptSentence] = []
    private var utteranceMap: [ObjectIdentifier: UUID] = [:]
    private var totalCount = 0
    private var completedCount = 0
    private var usingTTS = false

    // Not used in audio-file mode but kept for UI compatibility
    @Published var currentSentenceID: UUID? = nil

    private var interruptionObserver: NSObjectProtocol?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func start(mood: MeditationMood, sentences: [ScriptSentence]) {
        stop()
        configureAudioSession()
        startInterruptionObserver()

        if let filename = personalizedMeditationAudioFiles[mood],
           let url = Bundle.main.url(forResource: filename, withExtension: "mp3", subdirectory: "Audio"),
           let player = try? AVAudioPlayer(contentsOf: url) {
            // Pre-recorded file
            usingTTS    = false
            audioPlayer = player
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            isPlaying = true
            UIApplication.shared.isIdleTimerDisabled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.audioPlayer?.play()
                self.startProgressTimer(duration: player.duration)
            }
        } else {
            // TTS fallback
            usingTTS        = true
            self.sentences  = sentences
            totalCount      = sentences.count
            completedCount  = 0
            progress        = 0
            isFinished      = false
            speakAll()
            isPlaying = true
        }
    }

    func stop() {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
            interruptionObserver = nil
        }
        audioPlayer?.stop()
        audioPlayer = nil
        progressTimer?.invalidate()
        progressTimer = nil
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying  = false
        isFinished = false
        currentSentenceID = nil
        utteranceMap.removeAll()
        UIApplication.shared.isIdleTimerDisabled = false
        restoreAudioSession()
    }

    func markFinished() {
        progressTimer?.invalidate()
        progressTimer = nil
        isPlaying  = false
        isFinished = true
        currentSentenceID = nil
        restoreAudioSession()
    }

    // MARK: Private — audio file

    private func startProgressTimer(duration: TimeInterval) {
        progress = 0
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let player = self.audioPlayer else { return }
                self.progress = player.duration > 0 ? player.currentTime / player.duration : 0
            }
        }
    }

    // MARK: Private — TTS fallback

    private func speakAll() {
        utteranceMap.removeAll()
        for sentence in sentences {
            let utt = AVSpeechUtterance(string: sentence.text)
            utt.voice              = preferredVoice()
            utt.rate               = 0.42
            utt.pitchMultiplier    = 0.95
            utt.preUtteranceDelay  = sentence.pauseAfter * 0.3
            utt.postUtteranceDelay = sentence.pauseAfter
            utteranceMap[ObjectIdentifier(utt)] = sentence.id
            synthesizer.speak(utt)
        }
    }

    private func preferredVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
        if let v = voices.first(where: { $0.name.lowercased().contains("ava") && $0.quality == .premium }) { return v }
        if let v = voices.first(where: { $0.name.lowercased().contains("ava") }) { return v }
        if let v = voices.first(where: { $0.quality == .premium })  { return v }
        if let v = voices.first(where: { $0.quality == .enhanced }) { return v }
        return voices.first
    }

    private func startInterruptionObserver() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self,
                  let info = note.userInfo,
                  let typeVal = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeVal) else { return }
            switch type {
            case .began:
                self.audioPlayer?.pause()
                self.isPlaying = false
            case .ended:
                let opts = (info[AVAudioSessionInterruptionOptionKey] as? UInt)
                    .map { AVAudioSession.InterruptionOptions(rawValue: $0) } ?? []
                if opts.contains(.shouldResume) {
                    try? AVAudioSession.sharedInstance().setActive(true)
                    self.audioPlayer?.play()
                    self.isPlaying = true
                }
            @unknown default: break
            }
        }
    }

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func restoreAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - AVAudioPlayerDelegate

extension PersonalizedMeditationEngine: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard flag else { return }   // interrupted — do not trigger completion
        Task { @MainActor in
            self.progress = 1.0
            self.markFinished()
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate (TTS fallback)

extension PersonalizedMeditationEngine: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didStart utterance: AVSpeechUtterance) {
        let key = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            self?.currentSentenceID = self?.utteranceMap[key]
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard let self, self.usingTTS else { return }
            self.completedCount += 1
            self.progress = Double(self.completedCount) / Double(max(self.totalCount, 1))
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {}
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause  utterance: AVSpeechUtterance) {}
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       willSpeakRangeOfSpeechString characterRange: NSRange,
                                       utterance: AVSpeechUtterance) {}
}

// MARK: - Setup View

struct PersonalizedMeditationView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CalmBackground()

            ScrollView {
                VStack(spacing: 28) {

                    Color.clear.frame(height: 60)

                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 32, weight: .regular))
                            .foregroundColor(.calmAccent)
                        Text("Tell us how you feel — we'll guide you from there.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.72))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    // Mood picker — tap any card to begin immediately
                    VStack(alignment: .leading, spacing: 12) {
                        Text("HOW ARE YOU FEELING?")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.55))
                            .padding(.leading, 4)
                        Text("Tap your mood to begin")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.45))
                            .padding(.leading, 4)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(MeditationMood.allCases) { mood in
                                NavigationLink {
                                    let sections = PersonalizedMeditationGenerator.generate(mood: mood, length: .short)
                                    PersonalizedMeditationPlayerView(mood: mood, sentences: sections.flatMap { $0.sentences })
                                } label: {
                                    MoodCard(mood: mood, isSelected: false)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Disclaimer
                    Text("For relaxation purposes only. Not a substitute for medical or mental health advice. If you have any health conditions, consult a doctor before use.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
            // Fixed header overlay
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                    Text("Personalized Meditation")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Mood Card

private struct MoodCard: View {
    let mood: MeditationMood
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: mood.icon)
                .font(.system(size: 32))
                .foregroundColor(.calmAccent)
            Text(mood.rawValue)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.calmDeep)
            Text(mood.tagline)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.calmMid.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.calmAccent.opacity(0.18) : Color(red: 0.87, green: 0.89, blue: 0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color.calmAccent.opacity(0.6) : Color.clear, lineWidth: 1.5)
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}


// MARK: - Player View

struct PersonalizedMeditationPlayerView: View {
    let mood: MeditationMood
    let sentences: [ScriptSentence]

    @StateObject private var engine = PersonalizedMeditationEngine()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var journal: JournalStore

    @State private var showCompletion = false
    @State private var orbPulse = false
    @State private var hasStarted = false

    private var currentText: String {
        hasStarted ? mood.openingText : "Tap play to begin"
    }

    var body: some View {
        ZStack {
            CalmBackground()

            VStack(spacing: 0) {
                Spacer()

                // Pulse ring
                ZStack {
                    Circle()
                        .fill(Color.calmAccent.opacity(0.12))
                        .frame(width: orbPulse ? 200 : 180, height: orbPulse ? 200 : 180)
                        .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: orbPulse)

                    LotusOrbView(isAnimating: engine.isPlaying)
                        .frame(width: 150, height: 150)

                    // Mood icon badge
                    Image(systemName: mood.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().fill(Color.calmAccent.opacity(0.85)))
                        .offset(x: 56, y: 56)
                }
                .padding(.bottom, 36)

                // Sentence display
                Text(currentText)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.90))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 32)
                    .frame(minHeight: 80, alignment: .top)
                    .animation(.easeInOut(duration: 0.8), value: hasStarted)

                Spacer()

                VStack(spacing: 20) {
                    ProgressRing(progress: engine.progress)
                        .frame(width: 64, height: 64)
                    PMWaveDots(active: engine.isPlaying)
                }
                .padding(.bottom, 40)

                // Controls
                HStack(spacing: 48) {
                    Color.clear.frame(width: 36, height: 36)

                    Button {
                        if engine.isPlaying {
                            engine.stop()
                            hasStarted = false
                            orbPulse   = false
                        } else {
                            engine.start(mood: mood, sentences: sentences)
                            hasStarted = true
                            orbPulse   = true
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 72, height: 72)
                                .shadow(color: Color.black.opacity(0.15), radius: 14)
                            Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.calmAccent)
                        }
                    }

                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.bottom, 48)
            }
            .opacity(showCompletion ? 0 : 1)

            // Fixed title header
            VStack {
                HStack {
                    Button {
                        engine.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                    Text(mood.rawValue)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                Spacer()
            }
            .opacity(showCompletion ? 0 : 1)

            if showCompletion {
                CompletionOverlay(mood: mood, onDone: { dismiss() }, onMoodLogged: { level in
                    journal.addMoodEntry(MoodEntry(mood: level, source: "post-session"))
                })
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: engine.progress) { _, newValue in
            if newValue >= 1.0 && hasStarted {
                engine.markFinished()
                orbPulse = false
                HapticManager.complete()
                withAnimation(.easeIn(duration: 0.6)) {
                    showCompletion = true
                }
            }
        }
        .onDisappear {
            engine.stop()
        }
    }
}

// MARK: - Progress Ring

private struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.calmAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)
            Text("\(Int(progress * 100))%")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
        }
    }
}

// MARK: - Wave Dots

private struct PMWaveDot: View {
    let active: Bool
    let delay: Double
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Circle()
            .fill(Color.calmAccent.opacity(0.70))
            .frame(width: 6, height: 6)
            .scaleEffect(scale)
            .onAppear { animate() }
            .onChange(of: active) { _, _ in animate() }
    }

    private func animate() {
        guard active else { scale = 1.0; return }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(delay)) {
            scale = 1.5
        }
    }
}

private struct PMWaveDots: View {
    let active: Bool

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<5, id: \.self) { i in
                PMWaveDot(active: active, delay: Double(i) * 0.1)
            }
        }
    }
}

// MARK: - Completion Overlay

private struct CompletionOverlay: View {
    let mood: MeditationMood
    let onDone: () -> Void
    var onMoodLogged: ((Int) -> Void)? = nil
    @State private var moodLogged = false

    private var message: String {
        switch mood {
        case .anxious:     return "You made it through. The tension has softened. Well done."
        case .stressed:    return "You gave yourself the gift of stillness. Carry that calm forward."
        case .sad:         return "You showed up for yourself today. That takes courage."
        case .tired:       return "Rest is not weakness — it is wisdom. Sleep well."
        case .cantSleep:   return "Your body knows how to rest. Let it drift when it's ready."
        case .unfocused:   return "Clarity begins with pausing. You've planted that seed."
        case .overwhelmed: return "You found stillness inside the storm. That takes strength."
        case .lonely:      return "You showed up for yourself. That is an act of love."
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .regular))
                    .foregroundColor(.calmAccent)

                Text("Well Done")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text(message)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.80))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 32)

                // Post-session mood check
                VStack(spacing: 8) {
                    if !moodLogged {
                        Text("How do you feel now?")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.65))
                        HStack(spacing: 14) {
                            ForEach([1,2,3,5,6], id: \.self) { level in
                                Button {
                                    onMoodLogged?(level)
                                    withAnimation { moodLogged = true }
                                } label: {
                                    Text(level.moodEmoji)
                                        .font(.system(size: 28))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.calmAccent)
                            Text("Mood saved")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.white.opacity(0.65))
                        }
                        .transition(.opacity)
                    }
                }

                Button {
                    onDone()
                } label: {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.calmDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color(red: 0.87, green: 0.89, blue: 0.96)))
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
        }
    }
}
