import SwiftUI
import AVFoundation
import UIKit

// MARK: - AI Sleep Story View

struct AISleepStoryView: View {

    private let themes = ["Enchanted Forest", "Ocean Voyage", "Mountain Cabin", "Starry Desert", "Rainy Garden", "Hidden Valley"]

    @State private var selectedTheme = "Enchanted Forest"
    @State private var fullResponse  = ""
    @State private var storyTitle    = ""
    @State private var storyText     = ""
    @State private var isGenerating  = false
    @State private var showStory     = false
    @State private var errorText:    String?
    @State private var isPlaying     = false

    private let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        ZStack {
            CalmBackground()

            if showStory {
                storyView
            } else {
                inputView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("AI Sleep Story")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Input View

    private var inputView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 28) {
                Spacer(minLength: 24)

                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.10))
                            .frame(width: 90, height: 90)
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.calmAccent)
                    }
                    Text("AI Sleep Story")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Choose a theme and AI will create a personalized calming story just for you.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.80))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Choose a theme:")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(themes, id: \.self) { theme in
                            let selected = selectedTheme == theme
                            Button { selectedTheme = theme } label: {
                                Text(theme)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.calmDeep)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(selected ? 0.85 : 0.35))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.calmAccent.opacity(selected ? 0.6 : 0), lineWidth: 1.5)
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                if let err = errorText {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.25)))
                        .padding(.horizontal, 24)
                }

                Button { Task { await generate() } } label: {
                    HStack(spacing: 10) {
                        if isGenerating {
                            ProgressView().tint(.calmDeep)
                            Text("Writing your story…")
                        } else {
                            Image(systemName: "sparkles")
                            Text("Generate Story")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.calmDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.calmAccent))
                }
                .disabled(isGenerating)
                .padding(.horizontal, 24)

                DisclaimerFooter()
                    .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Story View

    private var storyView: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    stopPlayback()
                    showStory = false
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("New Story")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.calmAccent)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 24) {
                    if !storyTitle.isEmpty {
                        Text(storyTitle)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    ZStack {
                        Circle().fill(Color.white.opacity(0.06)).frame(width: 120, height: 120)
                        Circle().fill(Color.white.opacity(0.10)).frame(width: 120, height: 120)
                            .scaleEffect(isPlaying ? 1.2 : 1.0)
                            .animation(isPlaying ? .easeInOut(duration: 3).repeatForever(autoreverses: true) : .easeInOut(duration: 1), value: isPlaying)
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.calmAccent.opacity(0.85))
                    }

                    Button {
                        if isPlaying { stopPlayback() } else { startPlayback() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                .font(.system(size: 22))
                            Text(isPlaying ? "Stop" : "Listen to Story")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.calmDeep)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.calmAccent))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Label("Your Sleep Story", systemImage: "book.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)

                        Text(storyText)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.10)))
                    .padding(.horizontal, 24)

                    DisclaimerFooter().padding(.bottom, 16)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Logic

    private func generate() async {
        isGenerating = true
        errorText    = nil
        fullResponse = ""
        storyTitle   = ""
        storyText    = ""

        do {
            for try await chunk in SleepStoriesService.stream(selectedTheme) {
                await MainActor.run { fullResponse += chunk }
            }
            await MainActor.run {
                parseResponse(fullResponse)
                showStory = true
            }
        } catch {
            await MainActor.run { errorText = error.localizedDescription }
        }
        await MainActor.run { isGenerating = false }
    }

    private func parseResponse(_ text: String) {
        if let range = text.range(of: "TITLE:") {
            let after = text[range.upperBound...]
            storyTitle = (after.components(separatedBy: "\n").first ?? "")
                .trimmingCharacters(in: .whitespaces)
        }
        if let range = text.range(of: "STORY:") {
            storyText = String(text[range.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            storyText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func startPlayback() {
        guard !storyText.isEmpty else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}

        let utterance = AVSpeechUtterance(string: storyText)
        utterance.rate            = 0.38
        utterance.pitchMultiplier = 0.95
        utterance.volume          = 1.0
        utterance.voice           = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Nicky-compact")
            ?? AVSpeechSynthesisVoice(language: "en-US")

        synthesizer.speak(utterance)
        isPlaying = true
    }

    private func stopPlayback() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
    }
}

// MARK: - Model

struct SleepStory: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let duration: String
    let filename: String
    let icon: String
}

private let stories: [SleepStory] = [
    SleepStory(
        title: "The Quiet Forest",
        subtitle: "A walk through ancient, peaceful woods",
        description: "Wander gently through a moonlit forest where the only sounds are your footsteps on soft earth and the distant call of an owl.",
        duration: "~10 min",
        filename: "sleep_story_1",
        icon: "leaf.fill"
    ),
    SleepStory(
        title: "The Mountain Cabin",
        subtitle: "Warmth and stillness at the end of the day",
        description: "Find yourself in a cosy cabin high in the mountains. A fire crackles softly, snow falls outside, and all is still.",
        duration: "~10 min",
        filename: "sleep_story_2",
        icon: "house.fill"
    ),
    SleepStory(
        title: "The Evening Shore",
        subtitle: "Waves, stars, and open sky",
        description: "Sit at the edge of a calm ocean as the last light fades. The tide is gentle, the stars are rising, and sleep comes naturally.",
        duration: "~10 min",
        filename: "sleep_story_3",
        icon: "water.waves"
    ),
]

// MARK: - Main View

struct SleepStoriesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStory: SleepStory? = nil

    var body: some View {
        ZStack {
            CalmBackground()

            if let story = selectedStory {
                StoryPlayerView(story: story) {
                    selectedStory = nil
                }
                .transition(.opacity)
            } else {
                storyListView
                    .transition(.opacity)
            }

            // Custom nav bar overlay
            VStack {
                HStack {
                    Button {
                        if selectedStory != nil { selectedStory = nil }
                        else { dismiss() }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                    Text(selectedStory?.title ?? "Sleep Stories")
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
        .animation(.easeInOut(duration: 0.4), value: selectedStory?.id)
    }

    // MARK: - Story List

    private var storyListView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.calmAccent)
                        .padding(.top, 60)

                    Text("Calming narrated stories to quiet your mind and guide you gently into sleep.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.80))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)

                // Story cards
                VStack(spacing: 14) {
                    ForEach(stories) { story in
                        Button { withAnimation { selectedStory = story } } label: {
                            StoryCard(story: story)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)

                Text("For relaxation and wellness purposes only. Not a substitute for medical or mental health advice. If you have any health conditions, consult a doctor before use.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 36)
            }
        }
    }
}

// MARK: - Story Card

private struct StoryCard: View {
    let story: SleepStory

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.calmAccent.opacity(0.15))
                        .frame(width: 72, height: 72)
                    Image(systemName: story.icon)
                        .font(.system(size: 30))
                        .foregroundColor(.calmAccent)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(story.title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.calmDeep)
                    Text(story.subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.calmMid)
                    Text(story.duration)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.calmAccent)
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 38))
                    .foregroundColor(.calmAccent)
            }

            Text(story.description)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.calmMid)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.87, green: 0.89, blue: 0.96))
        )
    }
}

// MARK: - Story Player

private struct StoryPlayerView: View {
    let story: SleepStory
    let onDone: () -> Void

    @State private var audioPlayer: AVAudioPlayer?
    @State private var bgPlayer: AVAudioPlayer?
    @State private var progress: Double = 0
    @State private var isDone = false
    @State private var syncTimer: Timer?
    @State private var hasStarted = false

    var body: some View {
        if isDone {
            doneView
        } else {
            playerView
        }
    }

    private var playerView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Progress orb
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 10)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        AngularGradient(colors: [.calmAccent, .calmPurple, .calmAccent], center: .center),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: progress)

                LotusOrbView(isAnimating: true)
                    .frame(width: 160, height: 160)

                Image(systemName: story.icon)
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 40)

            Text(story.description)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.70))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 36)
                .padding(.bottom, 16)

            Text("Close your eyes and listen")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.45))

            Spacer()

            Button {
                stopSession()
                onDone()
            } label: {
                Text("End Story")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.calmAccent)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color(red: 0.87, green: 0.89, blue: 0.96)).shadow(color: .black.opacity(0.08), radius: 8))
            }
            .padding(.bottom, 48)
        }
        .onAppear { startSession() }
        .onDisappear { stopSession() }
    }

    private var doneView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(red: 0.87, green: 0.89, blue: 0.96))
                    .frame(width: 100, height: 100)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.calmAccent)
            }

            Text("Sweet Dreams")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            Text("The story is over. Let sleep carry you the rest of the way.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            Spacer()

            Button { onDone() } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.calmDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Color(red: 0.87, green: 0.89, blue: 0.96)).shadow(color: .black.opacity(0.08), radius: 8))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Logic

    private func startBgMusic() {
        guard let url = Bundle.main.url(forResource: "deep_sleep_bg", withExtension: "mp3", subdirectory: "Audio"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.numberOfLoops = -1
        player.volume = 0.07
        player.prepareToPlay()
        bgPlayer = player
        player.play()
    }

    private func startSession() {
        guard let url = Bundle.main.url(forResource: story.filename, withExtension: "mp3", subdirectory: "Audio"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        player.volume = 0.90
        player.prepareToPlay()
        audioPlayer = player
        UIApplication.shared.isIdleTimerDisabled = true
        startBgMusic()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            player.play()
        }

        syncTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            DispatchQueue.main.async {
                guard let p = audioPlayer else { return }
                progress = p.duration > 0 ? min(1.0, p.currentTime / p.duration) : 0
                if p.isPlaying { hasStarted = true }
                if !p.isPlaying && hasStarted {
                    isDone = true
                    syncTimer?.invalidate()
                    syncTimer = nil
                    UIApplication.shared.isIdleTimerDisabled = false
                    bgPlayer?.stop()
                    bgPlayer = nil
                }
            }
        }
    }

    private func stopSession() {
        syncTimer?.invalidate()
        syncTimer = nil
        UIApplication.shared.isIdleTimerDisabled = false
        bgPlayer?.stop()
        bgPlayer = nil
        guard let player = audioPlayer else { return }
        let steps = 20
        let interval = 1.5 / Double(steps)
        let startVol = player.volume
        var step = 0
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            step += 1
            player.volume = max(0, startVol * (1.0 - Float(step) / Float(steps)))
            if step >= steps { t.invalidate(); player.stop() }
        }
    }
}
