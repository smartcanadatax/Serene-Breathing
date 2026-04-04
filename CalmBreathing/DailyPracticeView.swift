import SwiftUI
import UIKit
import AVFoundation

// MARK: - Data Model

struct DailyPractice {
    let theme: String
    let intention: String
    let quote: String
    let author: String
    let patternName: String
    let patternDescription: String
    let inhale: Int
    let holdIn: Int
    let exhale: Int
    let holdOut: Int
    let cycles: Int
    let reflection: String
    let accentColor: Color
}

private struct BreathStep {
    let label: String
    let duration: Int
    let targetScale: CGFloat
}

// MARK: - Practice Pool (30 days, rotates annually)

private let practicePool: [DailyPractice] = [
    DailyPractice(
        theme: "Clarity", intention: "Today I see what matters and let the rest fade.",
        quote: "The ability to simplify means to eliminate the unnecessary so that the necessary may speak.",
        author: "Hans Hofmann",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "Notice the stillness in your mind. Carry this clarity into your first task today.",
        accentColor: Color(red: 0.55, green: 0.85, blue: 1.00)),

    DailyPractice(
        theme: "Courage", intention: "Today I take one small step toward what scares me.",
        quote: "Courage is not the absence of fear, but taking action in spite of it.",
        author: "Mark Twain",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — used by Navy SEALs under pressure",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "Feel the steadiness you just created. You are more capable than you think.",
        accentColor: Color(red: 1.00, green: 0.78, blue: 0.40)),

    DailyPractice(
        theme: "Rest", intention: "Today I give myself permission to slow down.",
        quote: "Almost everything will work again if you unplug it for a few minutes — including you.",
        author: "Anne Lamott",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "Your body knows how to rest. Trust it. Let the pace of this breath stay with you.",
        accentColor: Color(red: 0.70, green: 0.60, blue: 1.00)),

    DailyPractice(
        theme: "Renewal", intention: "Today I begin again, no matter what happened before.",
        quote: "Every morning we are born again. What we do today matters most.",
        author: "Buddha",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "Feel the fresh energy moving through you. This day is entirely new.",
        accentColor: Color(red: 1.00, green: 0.85, blue: 0.50)),

    DailyPractice(
        theme: "Gratitude", intention: "Today I notice what I have taken for granted.",
        quote: "Gratitude turns what we have into enough.",
        author: "Aesop",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "Bring to mind one thing you are genuinely grateful for right now. Hold it.",
        accentColor: Color(red: 1.00, green: 0.65, blue: 0.65)),

    DailyPractice(
        theme: "Stillness", intention: "Today I find silence before I speak.",
        quote: "In the midst of movement and chaos, keep stillness inside of you.",
        author: "Deepak Chopra",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "The world will be loud today. You now have a quiet place inside you.",
        accentColor: Color(red: 0.55, green: 0.80, blue: 0.70)),

    DailyPractice(
        theme: "Strength", intention: "Today I remember how much I have already overcome.",
        quote: "You have power over your mind — not outside events. Realise this, and you will find strength.",
        author: "Marcus Aurelius",
        patternName: "Box Breathing", patternDescription: "Structured rhythm builds mental resilience",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "You have survived every difficult day so far. That is your proof.",
        accentColor: Color(red: 1.00, green: 0.60, blue: 0.40)),

    DailyPractice(
        theme: "Release", intention: "Today I let go of something I have been holding too tightly.",
        quote: "Some of us think holding on makes us strong, but sometimes it is letting go.",
        author: "Herman Hesse",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 7, exhale: 8, holdOut: 0, cycles: 4,
        reflection: "Notice what just loosened in your chest. You do not have to carry everything.",
        accentColor: Color(red: 0.60, green: 0.75, blue: 1.00)),

    DailyPractice(
        theme: "Presence", intention: "Today I give my full attention to one thing at a time.",
        quote: "The present moment is the only moment available to us.",
        author: "Thich Nhat Hanh",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "You are here. Right now. That is enough.",
        accentColor: Color(red: 0.70, green: 0.90, blue: 0.80)),

    DailyPractice(
        theme: "Joy", intention: "Today I make room for something that makes me smile.",
        quote: "Joy is not in things; it is in us.",
        author: "Richard Wagner",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "Joy is a choice you can make at any moment. You just practised making it.",
        accentColor: Color(red: 1.00, green: 0.85, blue: 0.40)),

    DailyPractice(
        theme: "Patience", intention: "Today I trust that things are unfolding at exactly the right pace.",
        quote: "Patience is not the ability to wait, but how you act while you're waiting.",
        author: "Joyce Meyer",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "Some things cannot be rushed. Your breath just reminded you of that.",
        accentColor: Color(red: 0.85, green: 0.75, blue: 1.00)),

    DailyPractice(
        theme: "Balance", intention: "Today I notice when I am off-centre and gently return.",
        quote: "Happiness is not a matter of intensity but of balance, order, rhythm and harmony.",
        author: "Thomas Merton",
        patternName: "Box Breathing", patternDescription: "Four equal sides create perfect internal equilibrium",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "Balance is not a destination — it is a continuous small adjustment. You just practised it.",
        accentColor: Color(red: 0.55, green: 0.85, blue: 0.85)),

    DailyPractice(
        theme: "Compassion", intention: "Today I am as kind to myself as I would be to a good friend.",
        quote: "You yourself, as much as anybody in the entire universe, deserve your love.",
        author: "Buddha",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "Place your hand on your heart if it feels right. You are doing better than you know.",
        accentColor: Color(red: 1.00, green: 0.65, blue: 0.75)),

    DailyPractice(
        theme: "Trust", intention: "Today I trust myself to handle whatever comes.",
        quote: "As soon as you trust yourself, you will know how to live.",
        author: "Johann Wolfgang von Goethe",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "You have navigated every difficult moment in your life so far. Trust that record.",
        accentColor: Color(red: 0.80, green: 0.80, blue: 0.60)),

    DailyPractice(
        theme: "Resilience", intention: "Today I bend without breaking.",
        quote: "Rock bottom became the solid foundation on which I rebuilt my life.",
        author: "J.K. Rowling",
        patternName: "Box Breathing", patternDescription: "Holding through discomfort builds mental toughness",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "You are not fragile. This breath was a small act of strength.",
        accentColor: Color(red: 1.00, green: 0.55, blue: 0.45)),

    DailyPractice(
        theme: "Focus", intention: "Today I do one thing well rather than many things hurriedly.",
        quote: "The sun's rays do not burn until brought to a focus.",
        author: "Alexander Graham Bell",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "Your mind is clear. Pick your one most important task and begin.",
        accentColor: Color(red: 0.50, green: 0.80, blue: 1.00)),

    DailyPractice(
        theme: "Peace", intention: "Today I choose my response instead of reacting.",
        quote: "Peace is not the absence of conflict, but the ability to handle it by peaceful means.",
        author: "Ronald Reagan",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 7, exhale: 8, holdOut: 0, cycles: 4,
        reflection: "Between any event and your response, there is a space. You just practised living in it.",
        accentColor: Color(red: 0.70, green: 0.85, blue: 0.75)),

    DailyPractice(
        theme: "Acceptance", intention: "Today I make peace with what I cannot change.",
        quote: "Grant me the serenity to accept the things I cannot change.",
        author: "Reinhold Niebuhr",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "Resistance to what is creates more pain than what is. You just practised releasing it.",
        accentColor: Color(red: 0.75, green: 0.70, blue: 0.90)),

    DailyPractice(
        theme: "Growth", intention: "Today I am comfortable being a beginner at something.",
        quote: "The only way to grow is to be willing to be bad at something for a while.",
        author: "Ray Dalio",
        patternName: "Box Breathing", patternDescription: "Structured challenge builds capacity over time",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "Growth is not linear. Today's discomfort is tomorrow's strength.",
        accentColor: Color(red: 0.55, green: 0.90, blue: 0.65)),

    DailyPractice(
        theme: "Openness", intention: "Today I approach one situation with curiosity instead of judgement.",
        quote: "The mind that opens to a new idea never returns to its original size.",
        author: "Albert Einstein",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "What if today's challenge is actually an opportunity you haven't seen yet?",
        accentColor: Color(red: 0.80, green: 0.90, blue: 1.00)),

    DailyPractice(
        theme: "Grounding", intention: "Today I return to my body when my mind wanders.",
        quote: "You are a human being, not a human doing.",
        author: "Kurt Vonnegut",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "Feel your feet on the floor. Your body is here, steady, real. Come back to it often.",
        accentColor: Color(red: 0.70, green: 0.80, blue: 0.60)),

    DailyPractice(
        theme: "Energy", intention: "Today I protect my energy by saying no to what drains me.",
        quote: "Energy is contagious — positive and negative alike.",
        author: "Alex Elle",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "Notice the aliveness in your body. That is worth protecting today.",
        accentColor: Color(red: 1.00, green: 0.80, blue: 0.30)),

    DailyPractice(
        theme: "Calm", intention: "Today I remember that calm is a skill, not a feeling.",
        quote: "Nothing can disturb your peace of mind unless you allow it to.",
        author: "Roy T. Bennett",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 7, exhale: 8, holdOut: 0, cycles: 4,
        reflection: "You just changed your physiology with your breath. You can do this anywhere, anytime.",
        accentColor: Color(red: 0.60, green: 0.80, blue: 1.00)),

    DailyPractice(
        theme: "Forgiveness", intention: "Today I release one resentment I have been carrying.",
        quote: "Forgiveness is giving up the hope that the past could have been any different.",
        author: "Oprah Winfrey",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 7, exhale: 8, holdOut: 0, cycles: 4,
        reflection: "Letting go is not excusing. It is freeing yourself from what weighs you down.",
        accentColor: Color(red: 1.00, green: 0.75, blue: 0.70)),

    DailyPractice(
        theme: "Confidence", intention: "Today I act from values, not from fear of judgement.",
        quote: "Confidence is not 'they will like me.' It is 'I'll be fine if they don't.'",
        author: "Christina Grimmie",
        patternName: "Box Breathing", patternDescription: "Stabilises the nervous system before any challenge",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "You are enough, exactly as you are, right now in this moment.",
        accentColor: Color(red: 0.90, green: 0.70, blue: 0.40)),

    DailyPractice(
        theme: "Surrender", intention: "Today I trust that not everything needs my control.",
        quote: "Tension is who you think you should be. Relaxation is who you are.",
        author: "Chinese Proverb",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "Some things are not yours to fix. Notice what you can release today.",
        accentColor: Color(red: 0.75, green: 0.80, blue: 0.95)),

    DailyPractice(
        theme: "Vitality", intention: "Today I notice what truly makes me feel alive.",
        quote: "The secret of genius is to carry the spirit of the child into old age.",
        author: "Aldous Huxley",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "Life is happening right now. Not after the meeting. Not after the weekend. Now.",
        accentColor: Color(red: 1.00, green: 0.65, blue: 0.45)),

    DailyPractice(
        theme: "Simplicity", intention: "Today I remove one unnecessary complication from my day.",
        quote: "Life is really simple, but we insist on making it complicated.",
        author: "Confucius",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "What one thing can you remove today that would make everything feel lighter?",
        accentColor: Color(red: 0.75, green: 0.90, blue: 0.80)),

    DailyPractice(
        theme: "Wonder", intention: "Today I notice one thing I have never truly looked at before.",
        quote: "The world is full of magic things, patiently waiting for our senses to grow sharper.",
        author: "W.B. Yeats",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "Somewhere today, something small is extraordinary. You just need to look for it.",
        accentColor: Color(red: 0.85, green: 0.75, blue: 1.00)),

    DailyPractice(
        theme: "Intention", intention: "Today I do nothing by accident.",
        quote: "Our intention creates our reality.",
        author: "Wayne Dyer",
        patternName: "Box Breathing", patternDescription: "Four-sided rhythm for a purposeful, structured day",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "What is your one word for today? Hold it. Let it guide your next decision.",
        accentColor: Color(red: 0.55, green: 0.80, blue: 1.00)),

    DailyPractice(
        theme: "Kindness", intention: "Today I do one small kind thing for someone, including myself.",
        quote: "No act of kindness, no matter how small, is ever wasted.",
        author: "Aesop",
        patternName: "Box Breathing", patternDescription: "Equal counts on all four sides — calms and centres the mind",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4,
        reflection: "Kindness costs nothing and changes everything. Start with how you speak to yourself.",
        accentColor: Color(red: 1.00, green: 0.70, blue: 0.80)),
]

// MARK: - Today Resolver

enum DailyPracticeData {
    static var today: DailyPractice {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return practicePool[(day - 1) % practicePool.count]
    }
}

// MARK: - Main View

struct DailyPracticeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let practice = DailyPracticeData.today

    private enum Screen { case intro, breathing }
    @State private var screen: Screen = .intro
    @State private var showCompletion = false

    // Breathing state
    @State private var stepIndex    = 0
    @State private var countdown    = 0
    @State private var cycleCount   = 0
    @State private var scale: CGFloat = 0.6
    @State private var phaseTimer: Timer?
    @State private var countdownTimer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioSyncTimer: Timer?
    @State private var lastPhaseIdx   = -1
    @State private var visualCountdownTimer: Timer?
    private let completionSynth = AVSpeechSynthesizer()

    // Audio phase triggers (when the voice cue fires)
    private let audioCycleDuration: TimeInterval = 27.984
    private let audioPhases: [(label: String, start: TimeInterval, targetScale: CGFloat)] = [
        ("Breathe In",  0.0,    1.0),
        ("Hold",        6.028,  1.0),
        ("Breathe Out", 13.693, 0.72),
        ("Hold",        23.365, 0.72),
    ]

    private var steps: [BreathStep] {
        var s: [BreathStep] = []
        s.append(BreathStep(label: "Breathe In",  duration: practice.inhale,  targetScale: 1.0))
        if practice.holdIn  > 0 { s.append(BreathStep(label: "Hold",         duration: practice.holdIn,  targetScale: 1.0)) }
        s.append(BreathStep(label: "Breathe Out", duration: practice.exhale,  targetScale: 0.72))
        if practice.holdOut > 0 { s.append(BreathStep(label: "Hold",         duration: practice.holdOut, targetScale: 0.72)) }
        return s
    }

    var body: some View {
        ZStack {
            CalmBackground()

            switch screen {
            case .intro:     introView
            case .breathing: breathingView
            }

            if showCompletion {
                dailyCompletionOverlay
                    .transition(.opacity)
            }

            // Custom nav bar — works in both NavigationLink and fullScreenCover contexts
            if !showCompletion {
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
                        Text("Daily Practice")
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
        .onDisappear { stopTimers() }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { note in
            guard let info = note.userInfo,
                  let typeVal = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeVal) else { return }
            switch type {
            case .began:
                audioPlayer?.pause()
            case .ended:
                let opts = (info[AVAudioSessionInterruptionOptionKey] as? UInt)
                    .map { AVAudioSession.InterruptionOptions(rawValue: $0) } ?? []
                if opts.contains(.shouldResume) {
                    try? AVAudioSession.sharedInstance().setActive(true)
                    audioPlayer?.play()
                }
            @unknown default: break
            }
        }
    }

    // MARK: - Intro

    private var introView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Theme hero
                VStack(spacing: 10) {
                    Text("TODAY'S THEME")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(practice.accentColor.opacity(0.85))
                        .tracking(2)
                        .padding(.top, 32)

                    Text(practice.theme)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(practice.intention)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.90))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(practice.accentColor.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 20)
                            .stroke(practice.accentColor.opacity(0.25), lineWidth: 1))
                )
                .padding(.horizontal, 24)
                .padding(.top, 76)

                // Quote
                VStack(spacing: 10) {
                    Text("\u{201C}\(practice.quote)\u{201D}")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                    Text("— \(practice.author)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(practice.accentColor.opacity(0.80))
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)

                // Breathing pattern info
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "wind")
                            .font(.system(size: 14))
                            .foregroundColor(practice.accentColor)
                        Text(practice.patternName)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Text(practice.patternDescription)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.70))
                        .multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        patternBadge(label: "Inhale", value: practice.inhale)
                        if practice.holdIn > 0  { patternBadge(label: "Hold",    value: practice.holdIn) }
                        patternBadge(label: "Exhale", value: practice.exhale)
                        if practice.holdOut > 0 { patternBadge(label: "Hold",    value: practice.holdOut) }
                    }
                    .padding(.top, 4)

                    Text("\(practice.cycles) cycles · ~\(cycleDurationMinutes()) min")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.50))
                }
                .padding(18)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.07))
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1))
                )
                .padding(.horizontal, 24)
                .padding(.top, 22)

                Text("For relaxation and wellness purposes only. Not a substitute for medical or mental health advice. Respiratory, cardiac, or any other health condition patients should consult a doctor before practising breathing exercises.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 18)

                // Begin button
                Button {
                    withAnimation(.easeInOut(duration: 0.4)) { screen = .breathing }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { startBreathing() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "wind")
                        Text("Begin Today's Practice")
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.08, green: 0.18, blue: 0.40))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(practice.accentColor).shadow(color: practice.accentColor.opacity(0.35), radius: 12))
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Breathing

    private var breathingView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Theme label
            Text(practice.theme.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(practice.accentColor.opacity(0.75))
                .tracking(2)
                .padding(.bottom, 24)

            // Animated logo
            VStack(spacing: 12) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .saturation(0.5)
                    .brightness(0.25)
                    .frame(width: 240, height: 240)
                    .scaleEffect(reduceMotion ? 1.0 : scale)
                    .opacity(reduceMotion ? 0.90 : (0.55 + Double(scale) * 0.45))
                    .animation(reduceMotion ? nil : .easeInOut(duration: Double(currentStep.duration)), value: scale)

                VStack(spacing: 4) {
                    Text(currentStep.label)
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                    Text("\(countdown)")
                        .font(.system(size: 42, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.90))
                        .monospacedDigit()
                }
            }
            .padding(.bottom, 36)

            Text("Cycle \(cycleCount + 1) of \(practice.cycles)")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.45))
                .padding(.bottom, 6)

            Text("Breathe with the circle")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.50))

            Spacer()

            Button {
                stopTimers()
                withAnimation(.easeIn(duration: 0.5)) { showCompletion = true }
            } label: {
                Text("Skip to Reflection")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.white.opacity(0.07)))
            }
            .padding(.bottom, 48)
        }
    }

    // MARK: - Completion Overlay

    private var dailyCompletionOverlay: some View {
        ZStack {
            CalmBackground()

            VStack(spacing: 20) {
                // Theme badge
                Text(practice.theme.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(practice.accentColor)
                    .tracking(2)

                // Checkmark in accent color
                ZStack {
                    Circle()
                        .fill(practice.accentColor.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .regular))
                        .foregroundColor(practice.accentColor)
                }

                Text("Well Done")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                // Day's reflection — unique per day
                Text(practice.reflection)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 8)

                // Day's quote attribution
                Text("— \(practice.author)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(practice.accentColor.opacity(0.75))
                    .padding(.top, 2)

                Button { dismiss() } label: {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.08, green: 0.18, blue: 0.40))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(practice.accentColor))
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Helpers

    private var currentStep: BreathStep {
        steps[min(stepIndex, steps.count - 1)]
    }

    private func patternBadge(label: String, value: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(practice.accentColor)
            Text(label)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.white.opacity(0.55))
        }
    }

    private func cycleDurationMinutes() -> Int {
        let cycleSeconds = practice.inhale + practice.holdIn + practice.exhale + practice.holdOut
        let total = cycleSeconds * practice.cycles
        return max(1, Int((Double(total) / 60).rounded()))
    }

    // MARK: - Logic

    private func startBreathing() {
        UIApplication.shared.isIdleTimerDisabled = true
        playAudio()
        startAudioSync()
    }

    // Watches audio position — when a new voice cue fires, triggers a fresh 4-second visual countdown
    private func startAudioSync() {
        lastPhaseIdx = -1

        audioSyncTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            DispatchQueue.main.async {
                guard let player = audioPlayer else { return }
                let t = player.currentTime.truncatingRemainder(dividingBy: audioCycleDuration)
                let phaseIdx = audioPhases.lastIndex(where: { t >= $0.start }) ?? 0

                // Update phase visual when phase changes
                if phaseIdx != lastPhaseIdx {
                    let ap = audioPhases[phaseIdx]
                    if let idx = steps.firstIndex(where: { $0.label == ap.label }) { stepIndex = idx }
                    switch ap.label {
                    case "Inhale": HapticManager.inhale()
                    case "Hold":   HapticManager.hold()
                    default:       HapticManager.exhale()
                    }
                    withAnimation(.easeInOut(duration: 1.0)) { scale = ap.targetScale }

                    // Last phase wrapping back to first = one full cycle completed
                    if phaseIdx == 0 && lastPhaseIdx == audioPhases.count - 1 {
                        cycleCount += 1
                        if cycleCount >= practice.cycles {
                            stopTimers()
                            HapticManager.complete()
                            playCompletionSpeech()
                            withAnimation(.easeIn(duration: 0.5)) { showCompletion = true }
                            return
                        }
                    }
                    lastPhaseIdx = phaseIdx
                }

                // Derive countdown from audio position
                let phaseStart = audioPhases[phaseIdx].start
                let phaseEnd = phaseIdx + 1 < audioPhases.count
                    ? audioPhases[phaseIdx + 1].start : audioCycleDuration
                let phaseDur = phaseEnd - phaseStart
                let progress = (t - phaseStart) / phaseDur
                countdown = max(0, Int(ceil(4.0 * (1.0 - progress))))
            }
        }
    }


    private func playAudio() {
        guard let url = Bundle.main.url(forResource: "daily_breathing", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 0.85
            audioPlayer?.play()
        } catch {}
    }

    private func runStep(_ idx: Int) {
        guard idx < steps.count else { return }
        let step = steps[idx]
        stepIndex = idx
        countdown  = step.duration

        withAnimation(.easeInOut(duration: Double(step.duration))) {
            scale = step.targetScale
        }

        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async { self.countdown -= 1 }
        }

        phaseTimer?.invalidate()
        phaseTimer = Timer.scheduledTimer(withTimeInterval: Double(step.duration), repeats: false) { _ in
            DispatchQueue.main.async {
                self.countdownTimer?.invalidate()
                let next = idx + 1
                if next >= self.steps.count {
                    self.cycleCount += 1
                    if self.cycleCount >= self.practice.cycles {
                        self.stopTimers()
                        self.playCompletionSpeech()
                        withAnimation(.easeIn(duration: 0.5)) { self.showCompletion = true }
                        return
                    }
                    self.runStep(0)
                } else {
                    self.runStep(next)
                }
            }
        }
    }

    private func playCompletionSpeech() {
        let utt = AVSpeechUtterance(string: "Well done. You have finished your breathing session.")
        utt.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Nicky-compact")
                   ?? AVSpeechSynthesisVoice(language: "en-US")
        utt.rate = 0.42
        utt.pitchMultiplier = 0.9
        utt.volume = 0.85
        completionSynth.speak(utt)
    }

    private func stopTimers() {
        phaseTimer?.invalidate()
        countdownTimer?.invalidate()
        phaseTimer = nil
        countdownTimer = nil
        audioSyncTimer?.invalidate()
        visualCountdownTimer?.invalidate()
        audioSyncTimer = nil
        visualCountdownTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

// MARK: - Home Card (used in HomeView)

struct DailyPracticeCard: View {
    private let practice = DailyPracticeData.today

    var body: some View {
        NavigationLink(destination: DailyPracticeView()) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY'S PRACTICE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(red: 0.541, green: 0.357, blue: 0.804))
                        .tracking(1.5)
                    Text(practice.theme)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.10, green: 0.22, blue: 0.42))
                    Text(practice.intention)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 0.20, green: 0.35, blue: 0.55))
                        .lineSpacing(2)
                        .lineLimit(2)
                }
                Spacer()
                VStack(spacing: 4) {
                    LotusOrbView(isAnimating: true)
                        .frame(width: 52, height: 52)
                        .brightness(-0.25)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(red: 0.40, green: 0.48, blue: 0.65))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.87, green: 0.89, blue: 0.96))
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
