import SwiftUI
import AVFoundation
import UIKit

// MARK: - Still Waters View
struct StillWatersView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var journal: JournalStore
    @State private var postMoodLogged = false

    private let prompts: [String] = [
        "Sit or lie down.",
        "Close your eyes.",
        "Take a breath in.",
        "And let it go.",
        "Imagine you are walking.",
        "Slowly.",
        "Along a quiet path.",
        "The air is soft around you.",
        "Cool and clean.",
        "With every step.",
        "You feel lighter.",
        "The path leads you forward.",
        "Gently.",
        "There is no hurry here.",
        "No destination.",
        "Just the path.",
        "And your footsteps.",
        "Up ahead.",
        "You see a clearing.",
        "You walk toward it.",
        "Slowly.",
        "As you step into the clearing.",
        "You see a still lake.",
        "Perfectly calm.",
        "The surface like glass.",
        "You sit down at the edge.",
        "The ground beneath you is soft.",
        "Warm.",
        "You look out at the water.",
        "Nothing moves.",
        "Everything is still.",
        "The sky above is open.",
        "Wide and clear.",
        "You breathe in the quiet.",
        "And breathe out.",
        "There is nothing here but peace.",
        "Let yourself feel it.",
        "The stillness of the water.",
        "The warmth beneath you.",
        "The clean air around you.",
        "All of it holding you.",
        "You are safe here.",
        "Completely safe.",
        "Let any tension you are carrying.",
        "Dissolve into the air.",
        "Watch it drift away.",
        "Like mist over the water.",
        "Gone.",
        "Now look at the lake again.",
        "See your reflection.",
        "Calm.",
        "Still.",
        "At peace.",
        "This is you.",
        "Beneath everything else.",
        "This is who you are.",
        "Breathe in slowly.",
        "And out.",
        "Stay by the lake.",
        "Let the stillness surround you.",
        "There is nowhere else to be.",
        "Just here.",
        "By this still water.",
        "In complete peace.",
        "When you are ready.",
        "Begin to feel the ground beneath you.",
        "The real ground.",
        "Your body here.",
        "In this room.",
        "Take a deeper breath.",
        "Wiggle your fingers.",
        "And your toes.",
        "One final breath in.",
        "Hold.",
        "And release.",
        "Open your eyes slowly.",
        "The lake is always there, whenever you need to return.",
    ]

    @State private var currentIndex = 0
    @State private var isRunning = false
    @State private var isDone = false
    @State private var syncTimer: Timer?
    @State private var progress: Double = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isInterrupted = false
    @State private var lastAudioTime: Double = 0

    private var currentPrompt: String { prompts[min(currentIndex, prompts.count - 1)] }

    private var promptTimestamps: [Double] {
        return [
              1.577,   7.893,  17.101,  24.250,  35.456,
             44.828,  54.308,  65.837,  76.811,  87.723,
             96.738, 108.138, 120.205, 131.383, 142.474,
            153.173, 164.186, 174.760, 184.053, 194.952,
            206.302, 217.638, 228.875, 239.838, 251.188,
            262.483, 274.072, 285.299, 296.509, 307.391,
            318.521, 329.910, 340.819, 352.055, 362.880,
            374.390, 385.562, 396.839, 407.981, 419.199,
            430.340, 441.372, 452.319, 464.259, 475.418,
            486.578, 498.106, 509.285, 520.624, 531.751,
            543.000, 544.335, 554.985, 565.693, 577.004,
            588.208, 599.284, 608.032, 618.928, 630.450,
            641.759, 652.361, 663.437, 674.545, 685.321,
            697.266, 708.094, 717.093, 726.009, 737.044,
            746.414, 753.605, 763.069, 770.247, 775.437,
            786.724, 796.105
        ]
    }

    var body: some View {
        ZStack {
            // Lake video background
            LoopingVideoView(resourceName: "still_waters_bg", ext: "mp4")
                .ignoresSafeArea()

            // Dark overlay for readability
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            if isDone {
                VStack { Spacer(); doneView; Spacer() }
                    .padding(.horizontal, 28)
            } else if !isRunning {
                ScrollView(showsIndicators: false) {
                    introView
                        .padding(.horizontal, 28)
                        .padding(.top, 72)
                        .padding(.bottom, 20)
                }
            } else {
                VStack { Spacer(); activeView; Spacer() }
                    .padding(.horizontal, 28)
            }

            // Small orb — bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    LotusOrbView(isAnimating: isRunning)
                        .frame(width: 80, height: 80)
                        .opacity(0.75)
                        .padding(.trailing, 24)
                        .padding(.bottom, 100)
                }
            }

            if !isDone {
                VStack {
                    HStack {
                        Button {
                            stopSession()
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        Spacer()
                        Text("Still Waters")
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
        }
        .navigationBarHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { n in
            handleInterruption(n)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            guard isInterrupted, isRunning else { return }
            isInterrupted = false
            try? AVAudioSession.sharedInstance().setActive(true)
            audioPlayer?.play()
        }
        .onDisappear {
            stopSession()
        }
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(spacing: 28) {
            VStack(spacing: 12) {
                Text("A 13-minute lake visualization to dissolve tension and find inner peace.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.90))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            VStack(spacing: 10) {
                infoRow(icon: "figure.mind.and.body", text: "Sit or lie down comfortably")
                infoRow(icon: "eye.slash.fill",       text: "Follow the visualization gently")
                infoRow(icon: "water.waves",          text: "Zen water sounds in background")
            }
            .padding(.horizontal, 8)

            Text("For relaxation and wellness purposes only. Not a substitute for medical or mental health advice.")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Button { startSession() } label: {
                Label("Begin Inner Calm", systemImage: "play.fill")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.calmDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Color.calmAccent).shadow(color: .calmAccent.opacity(0.35), radius: 12))
            }
        }
    }

    // MARK: - Active

    private var activeView: some View {
        VStack(spacing: 32) {
            Text("\(currentIndex + 1) of \(prompts.count)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.55))

            Text(currentPrompt)
                .font(.system(size: 22, weight: .regular, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 8)
                .id(currentIndex)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal:   .opacity.combined(with: .move(edge: .top))
                ))

            Button(action: stopSession) {
                Text("End Session")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.calmDeep)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color(red: 0.87, green: 0.89, blue: 0.96)))
            }
        }
    }

    // MARK: - Done

    private var doneView: some View {
        VStack(spacing: 24) {
            Text("Well Done")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text("You visited the still lake. Carry that quiet with you.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.90))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            VStack(spacing: 8) {
                if !postMoodLogged {
                    Text("How do you feel now?")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.65))
                    HStack(spacing: 4) {
                        ForEach([1,2,3,5,6], id: \.self) { level in
                            Button {
                                journal.addMoodEntry(MoodEntry(mood: level, source: "post-session"))
                                withAnimation { postMoodLogged = true }
                            } label: {
                                Text(level.moodEmoji)
                                    .font(.system(size: 28))
                                    .frame(minWidth: 44, minHeight: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.541, green: 0.357, blue: 0.804))
                        Text("Mood saved")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
            }

            Button {
                isDone = false
                currentIndex = 0
                progress = 0
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.calmDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Capsule().fill(Color.calmAccent))
            }
        }
    }

    // MARK: - Helpers

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.541, green: 0.357, blue: 0.804))
                .frame(width: 22)
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
        }
    }

    // MARK: - Logic

    private func startSession() {
        HapticManager.start()
        isRunning = true
        currentIndex = 0
        progress = 0
        UIApplication.shared.isIdleTimerDisabled = true
        playAudio()
        startSyncTimer()
    }

    private func playAudio() {
        guard let url = Bundle.main.url(forResource: "still_waters", withExtension: "mp3", subdirectory: "Audio"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        player.numberOfLoops = 0
        player.volume = 1.0
        player.prepareToPlay()
        audioPlayer = player
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            player.play()
        }
    }

    private func startSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                guard let player = self.audioPlayer else { return }
                let time = player.currentTime
                let dur  = player.duration
                self.progress = dur > 0 ? min(1.0, time / dur) : 0
                if player.isPlaying {
                    self.lastAudioTime = time
                    let stamps = self.promptTimestamps
                    if !stamps.isEmpty {
                        var idx = stamps.count - 1
                        for (i, ts) in stamps.enumerated() {
                            if time < ts { idx = i; break }
                        }
                        if idx != self.currentIndex {
                            withAnimation(.easeInOut(duration: 0.6)) { self.currentIndex = idx }
                        }
                    }
                }
                if !player.isPlaying && !self.isInterrupted && self.lastAudioTime > 1 {
                    self.isRunning = false
                    self.isDone = true
                    HapticManager.complete()
                    self.lastAudioTime = 0
                    self.syncTimer?.invalidate()
                    self.syncTimer = nil
                    UIApplication.shared.isIdleTimerDisabled = false
                }
            }
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        if type == .began {
            isInterrupted = true
            audioPlayer?.pause()
        } else if type == .ended {
            lastAudioTime = 0
            isInterrupted = false
            try? AVAudioSession.sharedInstance().setActive(true)
            audioPlayer?.play()
        }
    }

    private func stopSession() {
        syncTimer?.invalidate()
        syncTimer = nil
        isRunning = false
        isInterrupted = false
        lastAudioTime = 0
        UIApplication.shared.isIdleTimerDisabled = false
        if let player = audioPlayer {
            let steps = 20
            let interval = 2.0 / Double(steps)
            let startVol = player.volume
            var step = 0
            Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
                step += 1
                player.volume = max(0, startVol * (1.0 - Float(step) / Float(steps)))
                if step >= steps { t.invalidate(); player.stop() }
            }
        }
    }
}
