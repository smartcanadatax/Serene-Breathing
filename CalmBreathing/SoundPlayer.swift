import AVFoundation
import SwiftUI

// MARK: - Sound Player
/// Generates ambient sounds as WAV data in memory and plays them with AVAudioPlayer.
/// This approach works reliably on both the iOS Simulator and real devices.
class SoundPlayer: ObservableObject {

    // MARK: - Sound Types
    enum SoundType: String, CaseIterable, Identifiable {
        // Nature
        case ocean           = "Ocean"
        case forest          = "Forest"
        case meditationRiver = "River"
        // Classic
        case ambience        = "Ambience"
        case ohm             = "Ohm"
        case natureMeditate  = "Nature Meditate"
        case rainSleep       = "Gentle Rain"
        case peacefulMind    = "Peaceful Mind"
        case spiritualYoga   = "Spiritual Yoga"
        case zenWater        = "Zen Water"
        // New meditation
        case mindfulnessMeditation = "Mindfulness"
        case focusMeditation       = "Focus"
        case meditationBlue        = "Blue Meditation"
        case deepRelaxation        = "Deep Relaxation"
        case balanceEnergy         = "Balance & Energy"
        case angelicMeditation     = "Angelic"
        case meditationRelaxation  = "Meditation & Relax"
        case deepMeditation        = "Journey Within"
        case spiritualMeditation   = "Spiritual"
        case meditationMiromax     = "Miromax Meditation"
        case relaxSleep            = "Relax & Sleep"
        case meditationDelos       = "Delos Meditation"
        case meditationPlaystarz   = "Meditation Music"
        case yogaRelaxing          = "Yoga Relaxing"
        case meditationMonda       = "Monda Meditation"
        case meditationFree        = "Calm Meditation"
        case downpour              = "Downpour"
        case sereneMindfulness     = "Inner Peace"
        // New nature
        case immersiveNature       = "Immersive Nature"
        case relaxingNature        = "Relaxing Nature"
        case alexNatureAmbient     = "Nature Ambient"
        case soothingNature        = "Soothing Nature"
        // New sleep
        case stillWaters           = "Still Waters"
        case deepSleepBg           = "Deep Sleep"
        case sleepCMajor           = "Sleep in C Major"
        case veryDeepSleep         = "Very Deep Sleep"
        // Quietphase ambient
        case calmAmbient           = "Calm Ambient"
        case zenAmbient            = "Mindful Zen"
        case meditationFlow        = "Meditation Flow"
        case slowAmbient           = "Slow Ambient"
        case yogaAmbient           = "Yoga Ambient"
        // The Mountain ambient
        case inspiringJourney      = "Inspiring Journey"
        case mountainNature        = "Mountain Nature"
        case mountainCalm          = "Mountain Calm"
        case mountainYoga          = "Mountain Yoga"
        // Other new ambient
        case ambientSerenity       = "Ambient Serenity"
        case spaceAmbient          = "Space Ambient"
        case dreamscape            = "Dreamscape"
        case cinematicCalm         = "Cinematic Calm"
        case ambientBliss          = "Ambient Bliss"
        case cinematicAmbient      = "Ambient Tones"
        case relaxingRain          = "Relaxing Rain"
        // New nature additions
        case quietphaseAmbientMeditation = "Ambient Meditation"
        case quietphaseZenMusic          = "Zen Music"
        case rainSleepHolizna            = "Rain & Sleep"
        case sleepBlueHour               = "Blue Hour"

        var id: String { rawValue }

        var isFree: Bool {
            switch self {
            case .ocean, .forest, .rainSleep, .ohm, .ambience: return true
            default: return false
            }
        }

        var icon: String {
            switch self {
            case .ocean:                 return "water.waves"
            case .forest:                return "tree.fill"
            case .meditationRiver:       return "water.waves"
            case .ambience:              return "leaf.fill"
            case .ohm:                   return "waveform"
            case .natureMeditate:        return "figure.mind.and.body"
            case .rainSleep:             return "moon.stars.fill"
            case .peacefulMind:          return "brain.head.profile"
            case .spiritualYoga:         return "figure.yoga"
            case .zenWater:              return "drop.fill"
            case .mindfulnessMeditation: return "sparkles"
            case .focusMeditation:       return "scope"
            case .meditationBlue:        return "circle.hexagongrid.fill"
            case .deepRelaxation:        return "bed.double.fill"
            case .balanceEnergy:         return "bolt.heart.fill"
            case .angelicMeditation:     return "staroflife.fill"
            case .meditationRelaxation:  return "heart.fill"
            case .deepMeditation:        return "waveform.path"
            case .spiritualMeditation:   return "rays"
            case .meditationMiromax:     return "music.note"
            case .relaxSleep:            return "zzz"
            case .meditationDelos:       return "antenna.radiowaves.left.and.right"
            case .meditationPlaystarz:   return "music.quarternote.3"
            case .yogaRelaxing:          return "figure.yoga"
            case .meditationMonda:       return "waveform"
            case .meditationFree:        return "cloud"
            case .downpour:              return "cloud.heavyrain.fill"
            case .sereneMindfulness:     return "sparkles"
            case .immersiveNature:       return "tree.fill"
            case .relaxingNature:        return "leaf.fill"
            case .alexNatureAmbient:     return "wind"
            case .soothingNature:        return "leaf.fill"
            case .stillWaters:           return "drop.fill"
            case .deepSleepBg:           return "bed.double.fill"
            case .sleepCMajor:           return "music.note"
            case .veryDeepSleep:         return "moon.zzz.fill"
            case .calmAmbient:           return "cloud.fill"
            case .zenAmbient:            return "sparkles"
            case .meditationFlow:        return "waveform"
            case .slowAmbient:           return "tortoise.fill"
            case .yogaAmbient:           return "figure.yoga"
            case .inspiringJourney:      return "star.fill"
            case .mountainNature:        return "mountain.2.fill"
            case .mountainCalm:          return "leaf.fill"
            case .mountainYoga:          return "figure.mind.and.body"
            case .ambientSerenity:       return "rays"
            case .spaceAmbient:          return "moon.stars.fill"
            case .dreamscape:            return "cloud.moon.fill"
            case .cinematicCalm:         return "film.fill"
            case .ambientBliss:          return "heart.fill"
            case .cinematicAmbient:      return "music.note.list"
            case .relaxingRain:          return "cloud.rain.fill"
            case .quietphaseAmbientMeditation: return "sparkles"
            case .quietphaseZenMusic:          return "music.note"
            case .rainSleepHolizna:            return "cloud.drizzle.fill"
            case .sleepBlueHour:               return "moon.fill"
            }
        }

        var subtitle: String {
            switch self {
            case .ocean:                 return "Rhythmic ocean waves"
            case .forest:                return "Peaceful forest wind"
            case .meditationRiver:       return "Flowing river & zen"
            case .ambience:              return "Serene nature ambience"
            case .ohm:                   return "Sacred Ohm chant"
            case .natureMeditate:        return "Meditate with nature"
            case .rainSleep:             return "Gentle rain for deep sleep"
            case .peacefulMind:          return "Calm your mind & thoughts"
            case .spiritualYoga:         return "Soulful yoga ambience"
            case .zenWater:              return "Healing water & zen tones"
            case .mindfulnessMeditation: return "Mindful awareness music"
            case .focusMeditation:       return "Deep focus & clarity"
            case .meditationBlue:        return "Tranquil blue tones"
            case .deepRelaxation:        return "Nervous system healing"
            case .balanceEnergy:         return "Balance & deep meditation"
            case .angelicMeditation:     return "Angelic calm tones"
            case .meditationRelaxation:  return "Meditation & relaxation"
            case .deepMeditation:        return "Deep meditation journey"
            case .spiritualMeditation:   return "Spiritual ambient music"
            case .meditationMiromax:     return "Pure meditation tones"
            case .relaxSleep:            return "Relax, meditate & sleep"
            case .meditationDelos:       return "Ambient meditation"
            case .meditationPlaystarz:   return "Meditation music blend"
            case .yogaRelaxing:          return "Yoga & relaxing music"
            case .meditationMonda:       return "Calm meditation sounds"
            case .meditationFree:        return "Free-flowing calm"
            case .downpour:              return "Dramatic rain atmosphere"
            case .sereneMindfulness:     return "Serene mindfulness journey"
            case .immersiveNature:       return "Immersive nature soundscape"
            case .relaxingNature:        return "Relaxing music with nature"
            case .alexNatureAmbient:     return "Ambient nature music"
            case .soothingNature:        return "Soothing nature sounds"
            case .stillWaters:           return "Peaceful still water sounds"
            case .deepSleepBg:           return "Background music for deep sleep"
            case .sleepCMajor:           return "Sleep music in C major"
            case .veryDeepSleep:         return "Very deep sleep tones"
            case .calmAmbient:           return "Peaceful calm ambience"
            case .zenAmbient:            return "Zen & mindful tones"
            case .meditationFlow:        return "Flowing meditation music"
            case .slowAmbient:           return "Slow & restorative sounds"
            case .yogaAmbient:           return "Ambient yoga atmosphere"
            case .inspiringJourney:      return "Uplifting ambient journey"
            case .mountainNature:        return "Mountain nature sounds"
            case .mountainCalm:          return "Calm mountain retreat"
            case .mountainYoga:          return "Yoga & mountain serenity"
            case .ambientSerenity:       return "Serene ambient music"
            case .spaceAmbient:          return "Spacious deep ambient"
            case .dreamscape:            return "Dark ambient dreamscape"
            case .cinematicCalm:         return "Slow cinematic textures"
            case .ambientBliss:          return "Blissful ambient meditation"
            case .cinematicAmbient:      return "Cinematic ambient tones"
            case .relaxingRain:          return "Relaxing rain & music"
            case .quietphaseAmbientMeditation: return "Ambient meditation tones"
            case .quietphaseZenMusic:          return "Peaceful zen music"
            case .rainSleepHolizna:            return "Rain sounds for deep sleep"
            case .sleepBlueHour:               return "Twilight tones for sleep"
            }
        }

        var color: Color {
            switch self {
            case .ocean:                 return Color(red: 0.05, green: 0.45, blue: 0.60)
            case .forest:                return Color(red: 0.08, green: 0.45, blue: 0.22)
            case .meditationRiver:       return Color(red: 0.05, green: 0.40, blue: 0.50)
            case .ambience:              return Color(red: 0.20, green: 0.42, blue: 0.10)
            case .ohm:                   return Color(red: 0.38, green: 0.18, blue: 0.60)
            case .natureMeditate:        return Color(red: 0.05, green: 0.42, blue: 0.32)
            case .rainSleep:             return Color(red: 0.12, green: 0.22, blue: 0.58)
            case .peacefulMind:          return Color(red: 0.20, green: 0.38, blue: 0.62)
            case .spiritualYoga:         return Color(red: 0.55, green: 0.30, blue: 0.05)
            case .zenWater:              return Color(red: 0.05, green: 0.38, blue: 0.55)
            case .mindfulnessMeditation: return Color(red: 0.30, green: 0.20, blue: 0.60)
            case .focusMeditation:       return Color(red: 0.15, green: 0.30, blue: 0.65)
            case .meditationBlue:        return Color(red: 0.10, green: 0.25, blue: 0.70)
            case .deepRelaxation:        return Color(red: 0.18, green: 0.35, blue: 0.55)
            case .balanceEnergy:         return Color(red: 0.45, green: 0.20, blue: 0.55)
            case .angelicMeditation:     return Color(red: 0.60, green: 0.45, blue: 0.20)
            case .meditationRelaxation:  return Color(red: 0.50, green: 0.20, blue: 0.35)
            case .deepMeditation:        return Color(red: 0.20, green: 0.15, blue: 0.50)
            case .spiritualMeditation:   return Color(red: 0.45, green: 0.25, blue: 0.45)
            case .meditationMiromax:     return Color(red: 0.15, green: 0.40, blue: 0.55)
            case .relaxSleep:            return Color(red: 0.10, green: 0.30, blue: 0.50)
            case .meditationDelos:       return Color(red: 0.30, green: 0.15, blue: 0.55)
            case .meditationPlaystarz:   return Color(red: 0.20, green: 0.45, blue: 0.40)
            case .yogaRelaxing:          return Color(red: 0.35, green: 0.45, blue: 0.20)
            case .meditationMonda:       return Color(red: 0.25, green: 0.35, blue: 0.60)
            case .meditationFree:        return Color(red: 0.15, green: 0.35, blue: 0.60)
            case .downpour:              return Color(red: 0.15, green: 0.20, blue: 0.40)
            case .sereneMindfulness:     return Color(red: 0.20, green: 0.35, blue: 0.60)
            case .immersiveNature:       return Color(red: 0.08, green: 0.40, blue: 0.25)
            case .relaxingNature:        return Color(red: 0.10, green: 0.42, blue: 0.28)
            case .alexNatureAmbient:     return Color(red: 0.08, green: 0.45, blue: 0.30)
            case .soothingNature:        return Color(red: 0.12, green: 0.44, blue: 0.22)
            case .stillWaters:           return Color(red: 0.05, green: 0.35, blue: 0.55)
            case .deepSleepBg:           return Color(red: 0.06, green: 0.12, blue: 0.40)
            case .sleepCMajor:           return Color(red: 0.15, green: 0.18, blue: 0.48)
            case .veryDeepSleep:         return Color(red: 0.08, green: 0.10, blue: 0.35)
            case .calmAmbient:           return Color(red: 0.20, green: 0.40, blue: 0.60)
            case .zenAmbient:            return Color(red: 0.30, green: 0.20, blue: 0.60)
            case .meditationFlow:        return Color(red: 0.25, green: 0.30, blue: 0.65)
            case .slowAmbient:           return Color(red: 0.15, green: 0.35, blue: 0.55)
            case .yogaAmbient:           return Color(red: 0.35, green: 0.45, blue: 0.25)
            case .inspiringJourney:      return Color(red: 0.45, green: 0.30, blue: 0.60)
            case .mountainNature:        return Color(red: 0.10, green: 0.40, blue: 0.30)
            case .mountainCalm:          return Color(red: 0.12, green: 0.38, blue: 0.28)
            case .mountainYoga:          return Color(red: 0.30, green: 0.42, blue: 0.22)
            case .ambientSerenity:       return Color(red: 0.25, green: 0.20, blue: 0.55)
            case .spaceAmbient:          return Color(red: 0.08, green: 0.12, blue: 0.45)
            case .dreamscape:            return Color(red: 0.12, green: 0.08, blue: 0.40)
            case .cinematicCalm:         return Color(red: 0.35, green: 0.25, blue: 0.50)
            case .ambientBliss:          return Color(red: 0.50, green: 0.22, blue: 0.40)
            case .cinematicAmbient:      return Color(red: 0.20, green: 0.18, blue: 0.50)
            case .relaxingRain:          return Color(red: 0.15, green: 0.25, blue: 0.50)
            case .quietphaseAmbientMeditation: return Color(red: 0.25, green: 0.20, blue: 0.58)
            case .quietphaseZenMusic:          return Color(red: 0.10, green: 0.35, blue: 0.55)
            case .rainSleepHolizna:            return Color(red: 0.12, green: 0.20, blue: 0.48)
            case .sleepBlueHour:               return Color(red: 0.08, green: 0.15, blue: 0.50)
            }
        }
    }

    // MARK: - Published
    @Published var playing: SoundType? = nil
    @Published var sleepTimerMinutes: Int? = nil   // nil = off
    @Published var sleepTimerSecondsLeft: Int = 0
    @Published var volume: Float = 0.85

    // MARK: - Private
    private var ambientPlayer: AVAudioPlayer?
    private var bellPlayer:    AVAudioPlayer?
    private var fadeTimer:     Timer?
    private var sleepTimer:    Timer?

    // MARK: - Init
    init() {
        configureSession()
    }

    // MARK: - Audio Session
    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    // MARK: - Play / Stop
    func play(_ type: SoundType, forceRestart: Bool = false) {
        guard playing != type || forceRestart else { return }

        cancelFade()
        ambientPlayer?.stop()
        ambientPlayer = nil
        playing = type

        let bundledFile: (name: String, ext: String)? = {
            switch type {
            case .forest:                return ("forest",             "mp3")
            case .ambience:              return ("ambience",           "mp3")
            case .ocean:                 return ("ocean",              "m4a")
            case .ohm:                   return ("ohm",                "mp3")
            case .natureMeditate:        return ("nature_meditation",  "mp3")
            case .rainSleep:             return ("rain_sleep",         "mp3")
            case .peacefulMind:          return ("peaceful_mind",      "mp3")
            case .spiritualYoga:         return ("spiritual_yoga",     "mp3")
            case .zenWater:              return ("zen_water",          "mp3")
            case .meditationRiver:       return ("meditation_river",   "mp3")
            case .mindfulnessMeditation: return ("mindfulness_meditation", "mp3")
            case .focusMeditation:       return ("focus_meditation",   "mp3")
            case .meditationBlue:        return ("meditation_blue",    "mp3")
            case .deepRelaxation:        return ("deep_relaxation",    "mp3")
            case .balanceEnergy:         return ("balance_energy",     "mp3")
            case .angelicMeditation:     return ("angelic_meditation", "mp3")
            case .meditationRelaxation:  return ("meditation_relaxation", "mp3")
            case .deepMeditation:        return ("deep_meditation",    "mp3")
            case .spiritualMeditation:   return ("spiritual_meditation", "mp3")
            case .meditationMiromax:     return ("meditation_miromax", "mp3")
            case .relaxSleep:            return ("relax_sleep",        "mp3")
            case .meditationDelos:       return ("meditation_delos",   "mp3")
            case .meditationPlaystarz:   return ("meditation_playstarz", "mp3")
            case .yogaRelaxing:          return ("yoga_relaxing",      "mp3")
            case .meditationMonda:       return ("meditation_monda",   "mp3")
            case .meditationFree:        return ("meditation_free",    "mp3")
            case .downpour:              return ("downpour",                "mp3")
            case .sereneMindfulness:     return ("serene_mindfulness",   "mp3")
            case .immersiveNature:       return ("immersive_nature",     "mp3")
            case .relaxingNature:        return ("relaxing_nature",      "mp3")
            case .alexNatureAmbient:     return ("alex_nature_ambient",  "mp3")
            case .soothingNature:        return ("soothing_nature",      "mp3")
            case .stillWaters:           return ("still_waters",         "mp3")
            case .deepSleepBg:           return ("deep_sleep_bg",        "mp3")
            case .sleepCMajor:           return ("sleep_c_major",        "mp3")
            case .veryDeepSleep:         return ("very_deep_sleep",      "mp3")
            case .calmAmbient:           return ("quietphase-ambient-calm-491578", "mp3")
            case .zenAmbient:            return ("quietphase-ambient-zen-489706", "mp3")
            case .meditationFlow:        return ("quietphase-meditation-ambient-484356", "mp3")
            case .slowAmbient:           return ("quietphase-slow-ambient-490875", "mp3")
            case .yogaAmbient:           return ("quietphase-yoga-ambient-485882", "mp3")
            case .inspiringJourney:      return ("the_mountain-ambient-inspiring-music-141464", "mp3")
            case .mountainNature:        return ("the_mountain-ambient-nature-132350", "mp3")
            case .mountainCalm:          return ("the_mountain-calm-ambient-146122", "mp3")
            case .mountainYoga:          return ("the_mountain-yoga-meditation-165602", "mp3")
            case .ambientSerenity:       return ("paulyudin-ambient-ambient-music-482398", "mp3")
            case .spaceAmbient:          return ("monume-space-ambient-498030", "mp3")
            case .dreamscape:            return ("mondamusic-dark-ambient-soundscape-dreamscape-2-487315", "mp3")
            case .cinematicCalm:         return ("desifreemusic-emotional-ambient-piece-with-slow-cinematic-textures-370144", "mp3")
            case .ambientBliss:          return ("playstarz_music-ambient-meditation-486609", "mp3")
            case .cinematicAmbient:      return ("yevhenastafiev-cinematic-ambient-481810", "mp3")
            case .relaxingRain:          return ("clavier-music-relaxing-ambient-music-rain-354479", "mp3")
            case .quietphaseAmbientMeditation: return ("quietphase-ambient-meditation-485723", "mp3")
            case .quietphaseZenMusic:          return ("quietphase-music-zen-490876",          "mp3")
            case .rainSleepHolizna:            return ("rain_sleep_holizna",                   "mp3")
            case .sleepBlueHour:               return ("sleep_blue_hour",                      "mp3")
            }
        }()

        guard let file = bundledFile,
              let url = Bundle.main.url(forResource: file.name, withExtension: file.ext, subdirectory: "Audio"),
              let p = try? AVAudioPlayer(contentsOf: url) else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        p.numberOfLoops = -1
        p.volume        = 0
        p.prepareToPlay()
        p.play()
        ambientPlayer = p
        fadeVolume(player: p, to: volume, over: 2.0)
    }

    func setVolume(_ v: Float) {
        volume = max(0, min(1, v))
        ambientPlayer?.volume = volume
    }

    func stop() {
        cancelSleepTimer()
        playing = nil
        guard let p = ambientPlayer else { return }
        fadeVolume(player: p, to: 0, over: 2.0) {
            p.stop()
            self.ambientPlayer = nil
        }
    }

    // MARK: - Sleep Timer
    func setSleepTimer(minutes: Int) {
        cancelSleepTimer()
        sleepTimerMinutes = minutes
        sleepTimerSecondsLeft = minutes * 60
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                if self.sleepTimerSecondsLeft > 0 {
                    self.sleepTimerSecondsLeft -= 1
                } else {
                    self.stop()
                    self.cancelSleepTimer()
                }
            }
        }
    }

    func cancelSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        sleepTimerMinutes = nil
        sleepTimerSecondsLeft = 0
    }

    var sleepTimerLabel: String {
        guard sleepTimerMinutes != nil else { return "" }
        let m = sleepTimerSecondsLeft / 60
        let s = sleepTimerSecondsLeft % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Meditation Background Music
    private var meditationPlayer: AVAudioPlayer?

    /// Plays ambient rain track during guided meditation sessions.
    func playMeditationMusic() {
        guard let url = Bundle.main.url(forResource: "peaceful_mind",
                                        withExtension: "mp3",
                                        subdirectory: "Audio"),
              let p = try? AVAudioPlayer(contentsOf: url) else { return }
        p.numberOfLoops = -1
        p.volume        = 0
        p.prepareToPlay()
        p.play()
        meditationPlayer = p
        fadeVolume(player: p, to: 0.50, over: 4.0)
    }

    func stopMeditationMusic() {
        guard let p = meditationPlayer else { return }
        fadeVolume(player: p, to: 0, over: 3.0) {
            p.stop()
            self.meditationPlayer = nil
        }
    }

    // MARK: - Bell (end of meditation)
    /// Synthesises a 432 Hz singing-bowl tone and plays it three times.
    /// WAV generation runs on a background thread to avoid blocking the UI.
    func playBell() {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let wav = self.generateTripleBellWAV()
            await MainActor.run {
                guard let p = try? AVAudioPlayer(data: wav) else { return }
                p.volume = 0.9
                p.prepareToPlay()
                p.play()
                self.bellPlayer = p     // hold reference so it isn't deallocated
            }
        }
    }

    /// Single 432 Hz singing-bowl ring — used for interval chimes.
    func playSingleBell() {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let wav = self.generateBellWAV()
            await MainActor.run {
                guard let p = try? AVAudioPlayer(data: wav) else { return }
                p.volume = 0.9
                p.prepareToPlay()
                p.play()
                self.bellPlayer = p
            }
        }
    }

    // MARK: - Fade Helper
    private func fadeVolume(player: AVAudioPlayer, to target: Float, over duration: Double, completion: (() -> Void)? = nil) {
        cancelFade()
        let steps    = 25
        let interval = duration / Double(steps)
        let start    = player.volume
        let delta    = (target - start) / Float(steps)
        var step     = 0

        fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] t in
            step += 1
            player.volume = max(0, min(1, start + delta * Float(step)))
            if step >= steps {
                t.invalidate()
                self?.fadeTimer = nil
                completion?()
            }
        }
    }

    private func cancelFade() {
        fadeTimer?.invalidate()
        fadeTimer = nil
    }


    /// Warm ambient pad for guided meditation — six harmonic sine layers with slow breath-like
    /// amplitude modulation. Produces a lush, human-feeling drone (not electronic-sounding).
    ///
    /// Tone stack:  F2 · C4 · E4 · G4 · C5 · E5  (open major chord, 174–659 Hz)
    /// Modulation:  45-second breath LFO + 18-second shimmer LFO + per-voice micro-detune
    private func generateMeditationPadWAV() -> Data {
        let sr      = 44100
        let seconds = 60          // 60-second seamless loop
        let count   = sr * seconds
        var samples = [Int16](repeating: 0, count: count)

        // Each tone: (frequency Hz, relative amplitude)
        let tones: [(Double, Double)] = [
            (174.61, 0.32),   // F below middle C — deep grounding drone
            (261.63, 0.24),   // C4 middle C — warm body
            (329.63, 0.17),   // E4 — major third, colour and warmth
            (392.00, 0.12),   // G4 — perfect fifth, openness
            (523.25, 0.07),   // C5 — octave shimmer
            (659.26, 0.04),   // E5 — soft, airy high shimmer
        ]

        for i in 0..<count {
            let t = Double(i) / Double(sr)

            // Very slow "breath" LFO — 45-second cycle
            let breathMod = 0.58 + 0.42 * sin(2 * .pi * 0.0222 * t - .pi / 2)
            // Gentle shimmer LFO — 18-second cycle
            let shimMod   = 0.74 + 0.26 * sin(2 * .pi * 0.0556 * t + 1.1)
            // Micro-variation for organic feel
            let microMod  = 1.0  + 0.025 * sin(2 * .pi * 0.19 * t + 0.6)

            var s: Double = 0
            for (j, (freq, amp)) in tones.enumerated() {
                // Slight per-voice detuning creates a warm chorus / beating effect
                let detune = 1.0 + 0.0018 * sin(2 * .pi * 0.073 * t * Double(j + 1) + Double(j))
                s += amp * sin(2 * .pi * freq * detune * t)
            }

            // Apply modulation envelope and master level
            s = s * breathMod * shimMod * microMod * 0.46

            samples[i] = Int16(max(-32767, min(32767, Int32(s * 32767))))
        }

        return buildWAV(samples: samples, sampleRate: sr)
    }

    /// 432 Hz singing-bowl bell — fundamental + 2 harmonics, exponential decay over 5 s
    private func generateBellWAV() -> Data {
        let sr    = 44100
        let dur   = 5
        let count = sr * dur
        let freq  = 432.0
        var samples = [Int16](repeating: 0, count: count)

        for i in 0..<count {
            let t   = Double(i) / Double(sr)
            let env = exp(-t * 1.1)
            let s   = sin(2 * .pi * freq       * t) * env * 0.42
                    + sin(2 * .pi * freq * 2.0 * t) * env * 0.14
                    + sin(2 * .pi * freq * 3.0 * t) * env * 0.06
            samples[i] = Int16(max(-32767, min(32767, Int32(s * 32767))))
        }

        return buildWAV(samples: samples, sampleRate: sr)
    }

    /// Three 432 Hz bell rings separated by 2 s of silence (total ≈ 19 s)
    private func generateTripleBellWAV() -> Data {
        let sr       = 44100
        let ringDur  = 5          // seconds per ring
        let gapDur   = 2          // seconds of silence between rings
        let ringLen  = sr * ringDur
        let gapLen   = sr * gapDur
        let total    = ringLen * 3 + gapLen * 2
        let freq     = 432.0
        var samples  = [Int16](repeating: 0, count: total)

        let offsets = [0, ringLen + gapLen, (ringLen + gapLen) * 2]
        for offset in offsets {
            for i in 0..<ringLen {
                let t   = Double(i) / Double(sr)
                let env = exp(-t * 1.1)
                let s   = sin(2 * .pi * freq       * t) * env * 0.42
                        + sin(2 * .pi * freq * 2.0 * t) * env * 0.14
                        + sin(2 * .pi * freq * 3.0 * t) * env * 0.06
                samples[offset + i] = Int16(max(-32767, min(32767, Int32(s * 32767))))
            }
        }

        return buildWAV(samples: samples, sampleRate: sr)
    }

    /// Wraps Int16 PCM samples in a standard WAV container
    private func buildWAV(samples: [Int16], sampleRate: Int) -> Data {
        var d        = Data()
        let dataSize = samples.count * 2

        func u32(_ v: UInt32) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 4)) }
        func u16(_ v: UInt16) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 2)) }

        // RIFF header
        d.append(contentsOf: Array("RIFF".utf8))
        u32(UInt32(36 + dataSize))
        d.append(contentsOf: Array("WAVE".utf8))

        // fmt chunk — PCM, mono, 16-bit
        d.append(contentsOf: Array("fmt ".utf8))
        u32(16)                            // chunk size
        u16(1)                             // PCM
        u16(1)                             // mono
        u32(UInt32(sampleRate))
        u32(UInt32(sampleRate * 2))        // byte rate
        u16(2)                             // block align
        u16(16)                            // bits per sample

        // data chunk
        d.append(contentsOf: Array("data".utf8))
        u32(UInt32(dataSize))
        samples.withUnsafeBufferPointer { d.append(Data(buffer: $0)) }

        return d
    }
}
