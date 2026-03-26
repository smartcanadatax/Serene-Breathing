import Foundation

// MARK: - Script Step
struct MeditationStep {
    let timeOffset: Int      // seconds from session start when this step triggers
    let displayText: String  // short text shown on screen
    let audioFile: String    // bundled .m4a filename (no extension) inside Audio/
    let spokenText: String   // displayed as caption; also fallback if audio missing
    let phase: SessionPhase

    enum SessionPhase: String {
        case opening        = "Opening"
        case breathing      = "Breathe"
        case bodyScan       = "Relax"
        case awareness      = "Awareness"
        case deepMeditation = "Be Still"
        case visualization  = "Visualise"
        case closing        = "Return"
    }
}

// MARK: - Scripts Library
enum MeditationScripts {

    static func steps(for minutes: Int) -> [MeditationStep] {
        switch minutes {
        case 10:  return ten
        case 20:  return twenty
        case 30:  return thirty
        default:  return ten
        }
    }

    // MARK: - 10-Minute
    static let ten: [MeditationStep] = [
        .init(timeOffset: 0,   displayText: "Welcome",           audioFile: "g10_00", spokenText: "Welcome. I'm Aria, your meditation guide.",                                   phase: .opening),
        .init(timeOffset: 22,  displayText: "Settle in",         audioFile: "g10_01", spokenText: "Take a moment to arrive here, fully.",                                        phase: .opening),
        .init(timeOffset: 48,  displayText: "Three deep breaths",audioFile: "g10_02", spokenText: "Let's begin with three cleansing breaths.",                                   phase: .breathing),
        .init(timeOffset: 105, displayText: "Natural breath",    audioFile: "g10_03", spokenText: "Allow your breathing to return to its own natural rhythm.",                   phase: .breathing),
        .init(timeOffset: 150, displayText: "Soften your face",  audioFile: "g10_04", spokenText: "Bring your awareness to your face. Soften your forehead.",                   phase: .bodyScan),
        .init(timeOffset: 200, displayText: "Release tension",   audioFile: "g10_05", spokenText: "Drop your shoulders away from your ears.",                                    phase: .bodyScan),
        .init(timeOffset: 245, displayText: "Ground yourself",   audioFile: "g10_06", spokenText: "Feel the weight of your body against the surface beneath you.",               phase: .bodyScan),
        .init(timeOffset: 290, displayText: "Anchor to breath",  audioFile: "g10_07", spokenText: "Return your full attention to your breath.",                                  phase: .awareness),
        .init(timeOffset: 345, displayText: "Watch thoughts",    audioFile: "g10_08", spokenText: "Thoughts may arise — and that is perfectly natural.",                         phase: .awareness),
        .init(timeOffset: 405, displayText: "Be still",          audioFile: "g10_09", spokenText: "Rest in this stillness.",                                                     phase: .deepMeditation),
        .init(timeOffset: 465, displayText: "Inner light",       audioFile: "g10_10", spokenText: "Imagine a warm, gentle light glowing softly at the centre of your chest.",    phase: .deepMeditation),
        .init(timeOffset: 520, displayText: "Simply breathe",    audioFile: "g10_11", spokenText: "Continue breathing. You are doing wonderfully.",                              phase: .deepMeditation),
        .init(timeOffset: 555, displayText: "Begin to return",   audioFile: "g10_12", spokenText: "Your session is gently coming to a close.",                                   phase: .closing),
        .init(timeOffset: 575, displayText: "Gently awaken",     audioFile: "g10_13", spokenText: "Wiggle your fingers. Wiggle your toes.",                                      phase: .closing),
        .init(timeOffset: 592, displayText: "Well done",         audioFile: "g10_14", spokenText: "You have completed your ten minute meditation. Well done.",                   phase: .closing),
    ]

    // MARK: - 20-Minute
    static let twenty: [MeditationStep] = [
        .init(timeOffset: 0,    displayText: "Welcome",           audioFile: "g20_00", spokenText: "Welcome. I'm Aria.",                                                          phase: .opening),
        .init(timeOffset: 22,   displayText: "Arrive here",       audioFile: "g20_01", spokenText: "Let the outside world fade into the background.",                             phase: .opening),
        .init(timeOffset: 50,   displayText: "Cleansing breath",  audioFile: "g20_02", spokenText: "Take a long, deep breath in through your nose.",                              phase: .breathing),
        .init(timeOffset: 115,  displayText: "Natural rhythm",    audioFile: "g20_03", spokenText: "Let your breath settle into its natural rhythm.",                              phase: .breathing),
        .init(timeOffset: 160,  displayText: "Relax your face",   audioFile: "g20_04", spokenText: "Scan your face for any tension.",                                             phase: .bodyScan),
        .init(timeOffset: 215,  displayText: "Shoulders & arms",  audioFile: "g20_05", spokenText: "Bring awareness to your neck and shoulders.",                                 phase: .bodyScan),
        .init(timeOffset: 265,  displayText: "Chest & belly",     audioFile: "g20_06", spokenText: "Notice your chest and belly softening with each exhale.",                     phase: .bodyScan),
        .init(timeOffset: 315,  displayText: "Lower body",        audioFile: "g20_07", spokenText: "Release tension in your lower back, your hips, and your legs.",               phase: .bodyScan),
        .init(timeOffset: 370,  displayText: "Breath awareness",  audioFile: "g20_08", spokenText: "Your entire body is now soft and heavy.",                                     phase: .awareness),
        .init(timeOffset: 440,  displayText: "Present moment",    audioFile: "g20_09", spokenText: "Every time a thought pulls you away, simply notice.",                         phase: .awareness),
        .init(timeOffset: 510,  displayText: "Expand awareness",  audioFile: "g20_10", spokenText: "Now gently expand your awareness beyond the breath.",                         phase: .awareness),
        .init(timeOffset: 570,  displayText: "Deep stillness",    audioFile: "g20_11", spokenText: "Rest now in pure awareness.",                                                 phase: .deepMeditation),
        .init(timeOffset: 660,  displayText: "You are peace",     audioFile: "g20_12", spokenText: "Underneath the noise of everyday life, there is a part of you always still.", phase: .deepMeditation),
        .init(timeOffset: 750,  displayText: "Visualise",         audioFile: "g20_13", spokenText: "Allow yourself to imagine a place of perfect peace.",                         phase: .visualization),
        .init(timeOffset: 845,  displayText: "Soak it in",        audioFile: "g20_14", spokenText: "Breathe in the peace of this place.",                                         phase: .visualization),
        .init(timeOffset: 930,  displayText: "Simply be",         audioFile: "g20_15", spokenText: "Continue breathing peacefully.",                                               phase: .deepMeditation),
        .init(timeOffset: 1050, displayText: "Gratitude",         audioFile: "g20_16", spokenText: "Bring to mind one thing you feel genuinely grateful for.",                    phase: .closing),
        .init(timeOffset: 1110, displayText: "Begin to return",   audioFile: "g20_17", spokenText: "Slowly deepen your breathing.",                                               phase: .closing),
        .init(timeOffset: 1155, displayText: "Gentle awakening",  audioFile: "g20_18", spokenText: "Wiggle your fingers and toes.",                                               phase: .closing),
        .init(timeOffset: 1185, displayText: "Well done",         audioFile: "g20_19", spokenText: "You have completed your twenty minute meditation. Well done.",                phase: .closing),
    ]

    // MARK: - 30-Minute
    static let thirty: [MeditationStep] = [
        .init(timeOffset: 0,    displayText: "Welcome",           audioFile: "g30_00", spokenText: "Welcome to your thirty minute guided meditation.",                             phase: .opening),
        .init(timeOffset: 28,   displayText: "Let go",            audioFile: "g30_01", spokenText: "Take a moment to consciously decide to let everything go.",                   phase: .opening),
        .init(timeOffset: 60,   displayText: "Set intention",     audioFile: "g30_02", spokenText: "Set a gentle intention for this session.",                                    phase: .opening),
        .init(timeOffset: 110,  displayText: "Cleansing breath",  audioFile: "g30_03", spokenText: "Take a long breath in, hold it gently at the top.",                          phase: .breathing),
        .init(timeOffset: 185,  displayText: "Natural rhythm",    audioFile: "g30_04", spokenText: "Let your breath settle into its natural, unhurried rhythm.",                  phase: .breathing),
        .init(timeOffset: 245,  displayText: "Top of head",       audioFile: "g30_05", spokenText: "Begin a slow body scan from the top of your head.",                           phase: .bodyScan),
        .init(timeOffset: 295,  displayText: "Face & jaw",        audioFile: "g30_06", spokenText: "Soften the skin around your eyes.",                                           phase: .bodyScan),
        .init(timeOffset: 345,  displayText: "Neck & shoulders",  audioFile: "g30_07", spokenText: "Bring awareness to your neck and throat.",                                    phase: .bodyScan),
        .init(timeOffset: 395,  displayText: "Arms & hands",      audioFile: "g30_08", spokenText: "Feel your upper arms grow heavy.",                                            phase: .bodyScan),
        .init(timeOffset: 445,  displayText: "Chest & heart",     audioFile: "g30_09", spokenText: "Bring a gentle awareness to your chest.",                                     phase: .bodyScan),
        .init(timeOffset: 495,  displayText: "Core & lower back", audioFile: "g30_10", spokenText: "Notice your belly rising and falling with each breath.",                      phase: .bodyScan),
        .init(timeOffset: 545,  displayText: "Legs & feet",       audioFile: "g30_11", spokenText: "Awareness flows down through your hips, your thighs.",                       phase: .bodyScan),
        .init(timeOffset: 605,  displayText: "Completely relaxed",audioFile: "g30_12", spokenText: "Your entire body is now completely relaxed.",                                 phase: .bodyScan),
        .init(timeOffset: 660,  displayText: "Breath as anchor",  audioFile: "g30_13", spokenText: "Return your full attention to your breath.",                                  phase: .awareness),
        .init(timeOffset: 730,  displayText: "The witness",       audioFile: "g30_14", spokenText: "You are the observer of your experience.",                                    phase: .awareness),
        .init(timeOffset: 815,  displayText: "Open awareness",    audioFile: "g30_15", spokenText: "Now expand your awareness outward.",                                          phase: .awareness),
        .init(timeOffset: 900,  displayText: "Pure presence",     audioFile: "g30_16", spokenText: "Rest in pure presence.",                                                      phase: .deepMeditation),
        .init(timeOffset: 990,  displayText: "Inner light",       audioFile: "g30_17", spokenText: "Imagine a luminous light at the very centre of your being.",                  phase: .visualization),
        .init(timeOffset: 1090, displayText: "Sacred space",      audioFile: "g30_18", spokenText: "Allow yourself to enter a place of perfect peace.",                           phase: .visualization),
        .init(timeOffset: 1205, displayText: "Soak it in",        audioFile: "g30_19", spokenText: "Breathe this peace deeply into every cell of your body.",                    phase: .visualization),
        .init(timeOffset: 1320, displayText: "Loving kindness",   audioFile: "g30_20", spokenText: "Now silently offer yourself kindness.",                                       phase: .deepMeditation),
        .init(timeOffset: 1420, displayText: "Extend kindness",   audioFile: "g30_21", spokenText: "Now extend that same loving kindness outward.",                              phase: .deepMeditation),
        .init(timeOffset: 1510, displayText: "Rest in stillness", audioFile: "g30_22", spokenText: "Rest now in the deepest stillness.",                                          phase: .deepMeditation),
        .init(timeOffset: 1610, displayText: "Gratitude",         audioFile: "g30_23", spokenText: "Bring to mind three things you are genuinely grateful for.",                  phase: .closing),
        .init(timeOffset: 1690, displayText: "Begin to return",   audioFile: "g30_24", spokenText: "Gently begin to return your awareness to your physical body.",               phase: .closing),
        .init(timeOffset: 1750, displayText: "Gentle awakening",  audioFile: "g30_25", spokenText: "Slowly begin to move.",                                                       phase: .closing),
        .init(timeOffset: 1790, displayText: "Carry this forward",audioFile: "g30_26", spokenText: "You have completed thirty minutes of deep meditation. Well done.",            phase: .closing),
    ]
}
