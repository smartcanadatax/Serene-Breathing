import Foundation

// MARK: - Mood
enum MeditationMood: String, CaseIterable, Identifiable {
    case stressed     = "Stressed"
    case anxious      = "Anxious"
    case cantSleep    = "Can't Sleep"
    case overwhelmed  = "Overwhelmed"
    case sad          = "Sad"
    case unfocused    = "Unfocused"
    case tired        = "Tired"
    case lonely       = "Lonely"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .stressed:    return "bolt.fill"
        case .anxious:     return "heart.fill"
        case .cantSleep:   return "moon.fill"
        case .overwhelmed: return "cloud.fill"
        case .sad:         return "drop.fill"
        case .unfocused:   return "scope"
        case .tired:       return "zzz"
        case .lonely:      return "person.fill"
        }
    }

    var tagline: String {
        switch self {
        case .stressed:    return "Release tension & pressure"
        case .anxious:     return "Find calm in the moment"
        case .cantSleep:   return "Drift into restful sleep"
        case .overwhelmed: return "Clear your mind"
        case .sad:         return "Gentle self-compassion"
        case .unfocused:   return "Sharpen your attention"
        case .tired:       return "Restore your energy"
        case .lonely:      return "Feel held and connected"
        }
    }

    var openingText: String {
        switch self {
        case .stressed:    return "Let's release that tension together.\nClose your eyes and breathe slowly."
        case .anxious:     return "You are safe here.\nClose your eyes and let your breath settle."
        case .cantSleep:   return "It's time to let go of the day.\nClose your eyes and soften your body."
        case .overwhelmed: return "You don't need to do anything right now.\nClose your eyes and just breathe."
        case .sad:         return "You showed up for yourself.\nClose your eyes and breathe gently."
        case .unfocused:   return "Let's bring you back to center.\nClose your eyes and follow your breath."
        case .tired:       return "You've done enough today.\nClose your eyes and let yourself rest."
        case .lonely:      return "You are not alone in this moment.\nClose your eyes and breathe."
        }
    }
}

// MARK: - Length
enum MeditationLength: Int, CaseIterable, Identifiable {
    case short = 3
    var id: Int { rawValue }
    var label: String { "\(rawValue) min" }
}

// MARK: - Script Models
struct ScriptSentence: Identifiable {
    let id = UUID()
    let text: String
    let pauseAfter: TimeInterval

    init(_ text: String, pause: TimeInterval = 0.6) {
        self.text = text
        self.pauseAfter = pause
    }
}

struct ScriptSection {
    let phase: String
    let sentences: [ScriptSentence]
}

// MARK: - Generator
struct PersonalizedMeditationGenerator {

    static func generate(mood: MeditationMood, length: MeditationLength) -> [ScriptSection] {
        var sections: [ScriptSection] = []
        sections.append(intro(mood: mood))
        sections.append(settle())
        sections.append(breathingAnchor(mood: mood))
        sections.append(bodyAwareness(length: length))
        sections.append(moodMiddle(mood: mood, length: length))
        sections.append(closing())
        return sections
    }

    // MARK: - Intro
    private static func intro(mood: MeditationMood) -> ScriptSection {
        let pools: [[ScriptSentence]]
        switch mood {
        case .stressed:
            pools = [
                [ScriptSentence("Hello. I'm glad you're here.", pause: 0.8), ScriptSentence("Whatever has been weighing on you today, you can set it down for now.", pause: 1.0)],
                [ScriptSentence("Welcome. Stress often lives in the body as tension.", pause: 0.8), ScriptSentence("In the next few minutes, we are going to release it.", pause: 1.0)],
                [ScriptSentence("You've made time for yourself, and that matters.", pause: 0.8), ScriptSentence("Let this be a space where you can simply breathe.", pause: 1.0)],
            ]
        case .anxious:
            pools = [
                [ScriptSentence("Welcome. You are safe here.", pause: 0.8), ScriptSentence("Anxiety often lives in the future — for the next few minutes, there is only now.", pause: 1.0)],
                [ScriptSentence("Hello. Whatever is making you anxious right now, you don't need to solve it here.", pause: 0.8), ScriptSentence("Just breathe.", pause: 1.2)],
                [ScriptSentence("Welcome. I'm glad you chose to pause.", pause: 0.8), ScriptSentence("Anxiety shrinks when we give it space instead of fighting it.", pause: 1.0)],
            ]
        case .cantSleep:
            pools = [
                [ScriptSentence("Hello. It's okay that sleep hasn't come yet.", pause: 1.0), ScriptSentence("Let go of any effort to fall asleep. Simply rest here with me.", pause: 1.2)],
                [ScriptSentence("Welcome. There is nothing you need to do right now.", pause: 1.0), ScriptSentence("Your only task is to be still.", pause: 1.4)],
                [ScriptSentence("Hello. The day is over. You have done enough.", pause: 1.0), ScriptSentence("Allow yourself to simply let go.", pause: 1.4)],
            ]
        case .overwhelmed:
            pools = [
                [ScriptSentence("Hello. When everything feels like too much, the breath is always an anchor.", pause: 0.8), ScriptSentence("Come back to it now.", pause: 1.2)],
                [ScriptSentence("Welcome. You don't need to fix anything right now.", pause: 0.8), ScriptSentence("This moment is just for you.", pause: 1.2)],
                [ScriptSentence("Hello. It's okay to pause.", pause: 0.8), ScriptSentence("You cannot pour from an empty cup — so let's fill yours.", pause: 1.0)],
            ]
        case .sad:
            pools = [
                [ScriptSentence("Hello. Whatever you are feeling right now is valid.", pause: 0.8), ScriptSentence("You don't need to push it away or explain it.", pause: 1.0)],
                [ScriptSentence("Welcome. Sadness is one of the most human feelings there is.", pause: 0.8), ScriptSentence("Let's sit with it gently, together.", pause: 1.2)],
                [ScriptSentence("Hello. I'm glad you chose to be here.", pause: 0.8), ScriptSentence("Sometimes the most courageous thing we can do is simply be still.", pause: 1.0)],
            ]
        case .unfocused:
            pools = [
                [ScriptSentence("Hello. A scattered mind is completely normal.", pause: 0.8), ScriptSentence("In the next few minutes we are going to gently gather it back.", pause: 1.0)],
                [ScriptSentence("Welcome. Focus is like a muscle — it responds to gentle training.", pause: 0.8), ScriptSentence("Let's train it now.", pause: 1.2)],
                [ScriptSentence("Hello. Let go of wherever your mind has been.", pause: 0.8), ScriptSentence("This moment is a fresh start.", pause: 1.2)],
            ]
        case .tired:
            pools = [
                [ScriptSentence("Hello. Tiredness is your body asking for care.", pause: 0.8), ScriptSentence("You've come to the right place.", pause: 1.2)],
                [ScriptSentence("Welcome. Even a few minutes of stillness can restore you.", pause: 0.8), ScriptSentence("Let's begin.", pause: 1.4)],
                [ScriptSentence("Hello. You are allowed to rest.", pause: 1.0), ScriptSentence("There is nothing more important than this right now.", pause: 1.2)],
            ]
        case .lonely:
            pools = [
                [ScriptSentence("Hello. Loneliness is one of the most deeply human feelings.", pause: 0.8), ScriptSentence("You are not alone in feeling alone.", pause: 1.2)],
                [ScriptSentence("Welcome. Even in this quiet moment, you are held.", pause: 0.8), ScriptSentence("Let's sit together for a little while.", pause: 1.2)],
                [ScriptSentence("Hello. I'm glad you're here.", pause: 0.8), ScriptSentence("This space is yours — and right now, it's ours.", pause: 1.2)],
            ]
        }
        return ScriptSection(phase: "Welcome", sentences: pools.randomElement()!)
    }

    // MARK: - Settle
    private static func settle() -> ScriptSection {
        let pools: [[ScriptSentence]] = [
            [ScriptSentence("Find a comfortable position.", pause: 0.8), ScriptSentence("Close your eyes gently.", pause: 1.0)],
            [ScriptSentence("Allow your body to settle into the surface beneath you.", pause: 1.0), ScriptSentence("You don't need to be anywhere else right now.", pause: 1.2)],
            [ScriptSentence("Let your hands rest softly wherever they feel comfortable.", pause: 0.8), ScriptSentence("Allow your jaw to unclench.", pause: 1.0)],
        ]
        return ScriptSection(phase: "Settle In", sentences: pools.randomElement()!)
    }

    // MARK: - Breathing Anchor
    private static func breathingAnchor(mood: MeditationMood) -> ScriptSection {
        switch mood {
        case .anxious, .stressed:
            let pools: [[ScriptSentence]] = [
                [
                    ScriptSentence("We'll use a calming breath pattern.", pause: 0.8),
                    ScriptSentence("Breathe in through your nose for a count of four.", pause: 4.5),
                    ScriptSentence("Hold gently for seven.", pause: 7.0),
                    ScriptSentence("Exhale slowly through your mouth for eight.", pause: 8.5),
                    ScriptSentence("Again. Breathe in — two, three, four.", pause: 4.5),
                    ScriptSentence("Hold — two through seven.", pause: 7.0),
                    ScriptSentence("Exhale — two through eight.", pause: 8.5),
                ],
                [
                    ScriptSentence("Let's use the four-seven-eight breath to calm your nervous system.", pause: 0.8),
                    ScriptSentence("Inhale through your nose — one, two, three, four.", pause: 4.5),
                    ScriptSentence("Hold the breath — one through seven.", pause: 7.0),
                    ScriptSentence("Exhale completely — one through eight.", pause: 8.5),
                    ScriptSentence("Once more. Inhale — one, two, three, four.", pause: 4.5),
                    ScriptSentence("Hold — one through seven.", pause: 7.0),
                    ScriptSentence("Exhale — one through eight.", pause: 8.5),
                ],
            ]
            return ScriptSection(phase: "Breathe", sentences: pools.randomElement()!)
        case .cantSleep:
            let pools: [[ScriptSentence]] = [
                [
                    ScriptSentence("Let's breathe slowly and deeply.", pause: 0.8),
                    ScriptSentence("Breathe in very slowly through your nose.", pause: 4.0),
                    ScriptSentence("And exhale even more slowly through your mouth.", pause: 6.0),
                    ScriptSentence("Again. Breathe in.", pause: 4.0),
                    ScriptSentence("And release.", pause: 6.0),
                    ScriptSentence("With each exhale, allow yourself to sink a little deeper.", pause: 1.2),
                ],
                [
                    ScriptSentence("Take a slow, easy breath in.", pause: 4.0),
                    ScriptSentence("Hold it softly at the top.", pause: 2.0),
                    ScriptSentence("Now let it go completely.", pause: 6.0),
                    ScriptSentence("In again.", pause: 4.0),
                    ScriptSentence("And out. Long and slow.", pause: 6.0),
                    ScriptSentence("With every exhale, let yourself grow heavier.", pause: 1.2),
                ],
            ]
            return ScriptSection(phase: "Breathe", sentences: pools.randomElement()!)
        default:
            let pools: [[ScriptSentence]] = [
                [
                    ScriptSentence("Take a slow, deep breath in through your nose.", pause: 4.0),
                    ScriptSentence("Hold it gently for four counts.", pause: 4.0),
                    ScriptSentence("Exhale slowly through your mouth for four.", pause: 4.0),
                    ScriptSentence("And again. Breathe in.", pause: 4.0),
                    ScriptSentence("Hold.", pause: 4.0),
                    ScriptSentence("And release.", pause: 4.0),
                    ScriptSentence("Now let your breathing settle into its own natural rhythm.", pause: 1.0),
                ],
                [
                    ScriptSentence("Breathe in deeply, filling your lungs completely.", pause: 4.0),
                    ScriptSentence("Exhale fully, releasing everything.", pause: 4.0),
                    ScriptSentence("One more deep breath in.", pause: 4.0),
                    ScriptSentence("And a long, complete exhale.", pause: 5.0),
                    ScriptSentence("Allow your breathing to find its own comfortable pace.", pause: 1.0),
                ],
            ]
            return ScriptSection(phase: "Breathe", sentences: pools.randomElement()!)
        }
    }

    // MARK: - Body Awareness
    private static func bodyAwareness(length: MeditationLength) -> ScriptSection {
        let sentences: [ScriptSentence] = [
            ScriptSentence("Bring your awareness to the top of your head.", pause: 0.8),
            ScriptSentence("Allow any tension in your face and jaw to soften.", pause: 1.0),
            ScriptSentence("Drop your shoulders. Let your arms grow heavy.", pause: 1.0),
        ]
        return ScriptSection(phase: "Relax", sentences: sentences)
    }

    // MARK: - Mood Middle
    private static func moodMiddle(mood: MeditationMood, length: MeditationLength) -> ScriptSection {
        let all = moodContent(mood: mood)
        return ScriptSection(phase: moodPhaseLabel(mood), sentences: Array(all.prefix(3)))
    }

    private static func moodPhaseLabel(_ mood: MeditationMood) -> String {
        switch mood {
        case .stressed:    return "Release"
        case .anxious:     return "Be Safe"
        case .cantSleep:   return "Let Go"
        case .overwhelmed: return "Clarity"
        case .sad:         return "Compassion"
        case .unfocused:   return "Focus"
        case .tired:       return "Restore"
        case .lonely:      return "Connection"
        }
    }

    private static func moodContent(mood: MeditationMood) -> [ScriptSentence] {
        switch mood {
        case .stressed:
            return [
                ScriptSentence("Stress is energy that needs to move through you, not stay in you.", pause: 1.0),
                ScriptSentence("With each exhale, imagine that tension leaving your body as a warm mist.", pause: 1.2),
                ScriptSentence("You are not your stress. You are the awareness noticing it.", pause: 1.2),
                ScriptSentence("The pressure you feel exists in your thoughts — not in this present breath.", pause: 1.0),
                ScriptSentence("Let your shoulders drop even further. You are safe here.", pause: 1.2),
                ScriptSentence("Breathe out anything that doesn't belong in this moment.", pause: 1.2),
                ScriptSentence("Every time you exhale, you release a little more.", pause: 1.0),
                ScriptSentence("You are doing this. You are here. That is enough.", pause: 1.4),
            ]
        case .anxious:
            return [
                ScriptSentence("Notice what you can feel right now — the surface beneath you, the air on your skin.", pause: 1.2),
                ScriptSentence("This is the present moment. Anxiety cannot live here.", pause: 1.2),
                ScriptSentence("Your body is safe. Your breath is steady.", pause: 1.2),
                ScriptSentence("Let the next exhale carry the worry away.", pause: 1.4),
                ScriptSentence("You do not need to have all the answers right now.", pause: 1.2),
                ScriptSentence("The breath will always bring you home.", pause: 1.4),
                ScriptSentence("You are held. You are okay.", pause: 1.4),
                ScriptSentence("Each breath is proof that you are here, and you are safe.", pause: 1.2),
            ]
        case .cantSleep:
            return [
                ScriptSentence("There is nowhere you need to be. Nothing you need to do.", pause: 1.4),
                ScriptSentence("Allow your eyelids to feel heavy.", pause: 1.4),
                ScriptSentence("Your body knows how to sleep. Trust it.", pause: 1.4),
                ScriptSentence("Let go of the need to try. Simply rest.", pause: 1.6),
                ScriptSentence("Your thoughts may drift — and that is perfectly fine.", pause: 1.4),
                ScriptSentence("Imagine a warm, gentle heaviness spreading through your limbs.", pause: 1.6),
                ScriptSentence("With each breath, you sink a little deeper into rest.", pause: 1.6),
                ScriptSentence("You are safe. You are warm. You are drifting.", pause: 1.8),
            ]
        case .overwhelmed:
            return [
                ScriptSentence("You cannot do everything at once. And that is okay.", pause: 1.2),
                ScriptSentence("Right now, the only task is this breath.", pause: 1.2),
                ScriptSentence("One breath at a time. One moment at a time.", pause: 1.2),
                ScriptSentence("Imagine placing all your worries into a box, just for now.", pause: 1.2),
                ScriptSentence("They will still be there later if you need them.", pause: 1.0),
                ScriptSentence("But right now, you don't.", pause: 1.4),
                ScriptSentence("Feel the space that opens when you choose to simply be still.", pause: 1.2),
                ScriptSentence("From this stillness, clarity will come.", pause: 1.4),
            ]
        case .sad:
            return [
                ScriptSentence("Place one hand gently on your heart.", pause: 1.2),
                ScriptSentence("Feel it beating. It has been beating for you your whole life.", pause: 1.2),
                ScriptSentence("You are worthy of the same kindness you would give a friend.", pause: 1.2),
                ScriptSentence("Feelings are visitors — they arrive, and they pass.", pause: 1.2),
                ScriptSentence("You are not broken. You are human.", pause: 1.4),
                ScriptSentence("Breathe into the heaviness in your chest. Let it soften.", pause: 1.4),
                ScriptSentence("You are stronger than this moment.", pause: 1.2),
                ScriptSentence("You are not alone.", pause: 1.6),
            ]
        case .unfocused:
            return [
                ScriptSentence("Gently bring all of your attention to the tip of your nose.", pause: 1.0),
                ScriptSentence("Notice the air entering — slightly cool.", pause: 1.2),
                ScriptSentence("Notice the air leaving — slightly warmer.", pause: 1.2),
                ScriptSentence("Each time your mind wanders, bring it back to this single point.", pause: 1.2),
                ScriptSentence("This is what training focus feels like.", pause: 1.0),
                ScriptSentence("Breath in. Breath out. Stay here.", pause: 1.4),
                ScriptSentence("Your attention is sharpening with every return to the breath.", pause: 1.2),
                ScriptSentence("Five more conscious breaths. Stay with each one completely.", pause: 1.4),
            ]
        case .tired:
            return [
                ScriptSentence("Imagine a warm golden light entering your body with each inhale.", pause: 1.2),
                ScriptSentence("It fills your chest, your belly, your limbs.", pause: 1.0),
                ScriptSentence("This light is gentle energy — not the rushed kind, but the quiet kind.", pause: 1.2),
                ScriptSentence("You don't need to push yourself. Just breathe and receive.", pause: 1.2),
                ScriptSentence("With every breath in, a little more energy.", pause: 1.0),
                ScriptSentence("With every breath out, a little more ease.", pause: 1.2),
                ScriptSentence("Rest and restoration are productive. You are not wasting time.", pause: 1.2),
                ScriptSentence("Allow yourself to be fully refilled.", pause: 1.4),
            ]
        case .lonely:
            return [
                ScriptSentence("Right now, in this very moment, you are not alone.", pause: 1.2),
                ScriptSentence("Millions of people are breathing just as you are — quietly, searching for peace.", pause: 1.2),
                ScriptSentence("You are part of something vast and connected.", pause: 1.2),
                ScriptSentence("Place your hand on your heart. Feel the warmth there.", pause: 1.4),
                ScriptSentence("That warmth is yours. It has always been yours.", pause: 1.2),
                ScriptSentence("You are worthy of deep connection and belonging.", pause: 1.2),
                ScriptSentence("Breathe in the knowing that you are seen.", pause: 1.2),
                ScriptSentence("You matter. And you are not alone.", pause: 1.6),
            ]
        }
    }

    // MARK: - Stillness Bridge
    private static func stillnessBridge() -> ScriptSection {
        let pools: [[ScriptSentence]] = [
            [ScriptSentence("Return now to your breath.", pause: 0.8), ScriptSentence("Simply observe its natural rhythm without trying to change it.", pause: 1.2)],
            [ScriptSentence("Let everything settle.", pause: 1.0), ScriptSentence("Rest in the quiet between thoughts.", pause: 1.4)],
            [ScriptSentence("Come back to this moment.", pause: 0.8), ScriptSentence("The breath is here. You are here.", pause: 1.2)],
        ]
        return ScriptSection(phase: "Be Still", sentences: pools.randomElement()!)
    }

    // MARK: - Extended (8 min only)
    private static func extended(mood: MeditationMood) -> ScriptSection {
        switch mood {
        case .stressed, .overwhelmed:
            return ScriptSection(phase: "Let Go", sentences: [
                ScriptSentence("Imagine standing at the edge of a calm, still lake at sunrise.", pause: 1.2),
                ScriptSentence("The water is completely still, reflecting the soft light of the sky.", pause: 1.2),
                ScriptSentence("In your hands, you hold a stone — it represents everything weighing on you.", pause: 1.2),
                ScriptSentence("Feel its weight.", pause: 1.4),
                ScriptSentence("Now, gently release it into the water.", pause: 1.2),
                ScriptSentence("Watch the ripples spread outward — and then disappear.", pause: 1.4),
                ScriptSentence("You are lighter now.", pause: 1.6),
            ])
        case .anxious:
            return ScriptSection(phase: "Safe Place", sentences: [
                ScriptSentence("Imagine a place where you feel completely safe.", pause: 1.2),
                ScriptSentence("It might be a room, a forest, a beach — anywhere that feels like home.", pause: 1.2),
                ScriptSentence("Look around this place. What do you see?", pause: 1.6),
                ScriptSentence("What do you hear? What can you feel beneath your feet?", pause: 1.6),
                ScriptSentence("Nothing can harm you here.", pause: 1.4),
                ScriptSentence("Breathe in the safety of this place.", pause: 1.4),
                ScriptSentence("You can return here any time you need.", pause: 1.4),
            ])
        case .cantSleep:
            return ScriptSection(phase: "Drift", sentences: [
                ScriptSentence("Imagine yourself floating on a warm, calm ocean.", pause: 1.4),
                ScriptSentence("The water holds you completely. You don't need to do anything.", pause: 1.6),
                ScriptSentence("Feel the gentle movement beneath you.", pause: 1.6),
                ScriptSentence("The sky above is dark and full of stars.", pause: 1.6),
                ScriptSentence("You are warm. You are floating. You are safe.", pause: 1.8),
                ScriptSentence("With each wave, you drift a little further from wakefulness.", pause: 1.8),
                ScriptSentence("Let yourself go.", pause: 2.0),
            ])
        case .sad:
            return ScriptSection(phase: "Kindness", sentences: [
                ScriptSentence("Silently say to yourself: May I be happy.", pause: 1.6),
                ScriptSentence("May I be healthy.", pause: 1.6),
                ScriptSentence("May I be at peace.", pause: 1.8),
                ScriptSentence("Now think of someone you love.", pause: 1.2),
                ScriptSentence("May they be happy. May they be healthy. May they be at peace.", pause: 1.8),
                ScriptSentence("Now extend this wish to all beings everywhere.", pause: 1.4),
                ScriptSentence("May all beings be at peace.", pause: 1.8),
            ])
        case .unfocused:
            return ScriptSection(phase: "Clarity", sentences: [
                ScriptSentence("Imagine your mind as a clear blue sky.", pause: 1.2),
                ScriptSentence("Thoughts are clouds passing through — but the sky remains.", pause: 1.2),
                ScriptSentence("You are the sky. Vast, open, and undisturbed.", pause: 1.4),
                ScriptSentence("Watch each thought arise.", pause: 1.0),
                ScriptSentence("And watch it pass.", pause: 1.4),
                ScriptSentence("The sky is always there, no matter how many clouds pass through it.", pause: 1.2),
                ScriptSentence("This is your natural state — clear, open, and at ease.", pause: 1.4),
            ])
        case .tired:
            return ScriptSection(phase: "Restore", sentences: [
                ScriptSentence("Imagine a warm, golden light above you.", pause: 1.2),
                ScriptSentence("With every inhale, it flows into you — filling every cell.", pause: 1.2),
                ScriptSentence("It reaches your shoulders, your arms, your hands.", pause: 1.2),
                ScriptSentence("It flows into your core, your legs, your feet.", pause: 1.2),
                ScriptSentence("You are completely filled with warm, renewing light.", pause: 1.4),
                ScriptSentence("Every breath adds more.", pause: 1.2),
                ScriptSentence("You are restored.", pause: 1.6),
            ])
        case .lonely:
            return ScriptSection(phase: "Connection", sentences: [
                ScriptSentence("Imagine a warm light surrounding you — the light of everyone who cares for you.", pause: 1.4),
                ScriptSentence("They may not be here right now, but their warmth is real.", pause: 1.4),
                ScriptSentence("Feel yourself held by that light.", pause: 1.4),
                ScriptSentence("You have touched lives. You have mattered to people.", pause: 1.4),
                ScriptSentence("Connection is not about distance. It lives inside you.", pause: 1.4),
                ScriptSentence("Breathe in belonging.", pause: 1.4),
                ScriptSentence("You are not alone.", pause: 1.8),
            ])
        }
    }

    // MARK: - Closing
    private static func closing() -> ScriptSection {
        let pools: [[ScriptSentence]] = [
            [
                ScriptSentence("Your session is complete.", pause: 0.8),
                ScriptSentence("Take one final deep breath in.", pause: 3.0),
                ScriptSentence("And let it go.", pause: 2.0),
                ScriptSentence("Gently open your eyes. Well done.", pause: 1.0),
            ],
            [
                ScriptSentence("Begin to return your awareness to the room around you.", pause: 0.8),
                ScriptSentence("Wiggle your fingers and toes.", pause: 1.2),
                ScriptSentence("Take a deep breath, and when you're ready, open your eyes.", pause: 1.0),
            ],
        ]
        return ScriptSection(phase: "Return", sentences: pools.randomElement()!)
    }
}
