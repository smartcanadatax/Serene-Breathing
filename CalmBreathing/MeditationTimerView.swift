import SwiftUI
import UIKit
import StoreKit
import AVFoundation

// MARK: - Meditation Background Theme
enum MeditationBackground: String, CaseIterable {
    case sky      = "sky"
    case clouds   = "clouds"
    case night    = "night"
    case valley   = "valley"
    case hills    = "hills"
    case meadow   = "meadow"
    case sunset   = "sunset"
    case lavender = "lavender"
    case rose     = "rose"
    case sand     = "sand"

    var label: String {
        switch self {
        case .sky:      return "Ocean"
        case .clouds:   return "Sky"
        case .sunset:   return "Sunset"
        case .night:    return "Night"
        case .valley:   return "Valley"
        case .hills:    return "Hills"
        case .meadow:   return "Meadow"
        case .lavender: return "Lavender"
        case .rose:     return "Rose"
        case .sand:     return "Sand"
        }
    }

    var imageName: String { "" }

    var overlayColor: Color { .clear }

    var bgGradient: LinearGradient {
        switch self {
        case .sky:
            return LinearGradient(colors: [Color(red: 0.31, green: 0.44, blue: 0.77), Color(red: 0.30, green: 0.43, blue: 0.76), Color(red: 0.28, green: 0.41, blue: 0.74)], startPoint: .top, endPoint: .bottom)
        case .clouds:
            return LinearGradient(colors: [Color(red: 0.18, green: 0.30, blue: 0.58), Color(red: 0.08, green: 0.18, blue: 0.42)], startPoint: .top, endPoint: .bottom)
        case .sunset:
            return LinearGradient(colors: [Color(red: 0.35, green: 0.10, blue: 0.40), Color(red: 0.12, green: 0.05, blue: 0.25)], startPoint: .top, endPoint: .bottom)
        case .night:
            return LinearGradient(colors: [Color(red: 0.06, green: 0.06, blue: 0.18), Color(red: 0.02, green: 0.02, blue: 0.10)], startPoint: .top, endPoint: .bottom)
        case .valley:
            return LinearGradient(colors: [Color(red: 0.06, green: 0.22, blue: 0.28), Color(red: 0.03, green: 0.12, blue: 0.18)], startPoint: .top, endPoint: .bottom)
        case .hills:
            return LinearGradient(colors: [Color(red: 0.08, green: 0.22, blue: 0.18), Color(red: 0.04, green: 0.12, blue: 0.10)], startPoint: .top, endPoint: .bottom)
        case .meadow:
            return LinearGradient(colors: [Color(red: 0.06, green: 0.20, blue: 0.14), Color(red: 0.03, green: 0.10, blue: 0.08)], startPoint: .top, endPoint: .bottom)
        case .lavender:
            return LinearGradient(colors: [Color(red: 0.28, green: 0.22, blue: 0.48), Color(red: 0.16, green: 0.12, blue: 0.30)], startPoint: .top, endPoint: .bottom)
        case .rose:
            return LinearGradient(colors: [Color(red: 0.42, green: 0.16, blue: 0.26), Color(red: 0.22, green: 0.08, blue: 0.16)], startPoint: .top, endPoint: .bottom)
        case .sand:
            return LinearGradient(colors: [Color(red: 0.38, green: 0.28, blue: 0.18), Color(red: 0.20, green: 0.14, blue: 0.08)], startPoint: .top, endPoint: .bottom)
        }
    }

    var swatchGradient: LinearGradient {
        switch self {
        case .sky:
            return LinearGradient(colors: [Color(red: 0.31, green: 0.44, blue: 0.77), Color(red: 0.28, green: 0.41, blue: 0.74)], startPoint: .top, endPoint: .bottom)
        case .clouds:
            return LinearGradient(colors: [Color(red: 0.70, green: 0.88, blue: 1.00), Color(red: 0.90, green: 0.95, blue: 1.00)], startPoint: .top, endPoint: .bottom)
        case .sunset:
            return LinearGradient(colors: [Color(red: 0.98, green: 0.60, blue: 0.80), Color(red: 0.60, green: 0.20, blue: 0.55)], startPoint: .top, endPoint: .bottom)
        case .night:
            return LinearGradient(colors: [Color(red: 0.10, green: 0.10, blue: 0.28), Color(red: 0.02, green: 0.02, blue: 0.10)], startPoint: .top, endPoint: .bottom)
        case .valley:
            return LinearGradient(colors: [Color(red: 0.35, green: 0.62, blue: 0.50), Color(red: 0.20, green: 0.45, blue: 0.35)], startPoint: .top, endPoint: .bottom)
        case .hills:
            return LinearGradient(colors: [Color(red: 0.45, green: 0.68, blue: 0.22), Color(red: 0.72, green: 0.58, blue: 0.15)], startPoint: .top, endPoint: .bottom)
        case .meadow:
            return LinearGradient(colors: [Color(red: 0.30, green: 0.55, blue: 0.18), Color(red: 0.18, green: 0.40, blue: 0.12)], startPoint: .top, endPoint: .bottom)
        case .lavender:
            return LinearGradient(colors: [Color(red: 0.72, green: 0.62, blue: 0.95), Color(red: 0.48, green: 0.36, blue: 0.78)], startPoint: .top, endPoint: .bottom)
        case .rose:
            return LinearGradient(colors: [Color(red: 0.95, green: 0.58, blue: 0.72), Color(red: 0.75, green: 0.28, blue: 0.50)], startPoint: .top, endPoint: .bottom)
        case .sand:
            return LinearGradient(colors: [Color(red: 0.92, green: 0.78, blue: 0.58), Color(red: 0.72, green: 0.55, blue: 0.32)], startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - Meditation Background View
struct MeditationBgView: View {
    let theme: MeditationBackground

    var body: some View {
        theme.bgGradient
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

// MARK: - Sound → Background mapping
extension SoundPlayer.SoundType {
    var suggestedBackground: MeditationBackground {
        switch self {
        case .rainSleep, .sleepMeditation, .relaxSleep, .deepRelaxation, .deepMeditation:
            return .night
        case .spiritualYoga, .ohm, .spiritualMeditation, .angelicMeditation,
             .planetFrequencies, .meditationRelaxation, .meditationDelos,
             .meditationPlaystarz, .meditationMiromax, .meditationFree:
            return .sunset
        case .forest, .natureMeditate, .meditationRiver:
            return .valley
        case .balanceEnergy, .yogaRelaxing, .meditationMonda:
            return .hills
        case .focusMeditation, .peacefulMind, .mindfulnessMeditation, .sereneMindfulness:
            return .meadow
        case .ocean, .downpour, .zenWater, .ambience:
            return .clouds
        default:
            return .sky
        }
    }
}

extension AmbientCategory {
    var suggestedBackground: MeditationBackground {
        switch self {
        case .sleep:      return .night
        case .creativity: return .sunset
        default:          return .sky
        }
    }
}

// MARK: - Meditation Timer View
struct MeditationTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var soundPlayer: SoundPlayer
    @EnvironmentObject var journal:     JournalStore
    @EnvironmentObject var premium:     PremiumStore
    @Environment(\.requestReview) private var requestReview
    @AppStorage("meditationBackground") private var selectedBgRaw: String = MeditationBackground.sky.rawValue
    private var selectedBg: MeditationBackground {
        MeditationBackground(rawValue: selectedBgRaw) ?? .sky
    }

    // MARK: - Configuration
    private let durations = [5, 10, 15, 20, 30, 60]
    @State private var selectedDuration = 10
    @State private var showMoodPrompt   = false

    // Background sound selection (persisted across navigation)
    @AppStorage("meditationSelectedSound") private var selectedSoundRaw: String = "Inner Peace"
    private var selectedSound: SoundPlayer.SoundType? {
        get { SoundPlayer.SoundType(rawValue: selectedSoundRaw) }
        set { selectedSoundRaw = newValue?.rawValue ?? "" }
    }
    @State private var silentBellMode: Bool

    // Ambient music
    @StateObject private var ambientEngine = AmbientMusicEngine()
    @State private var selectedAmbientTrack: AmbientTrack? = nil
    @State private var selectedAmbientCategory: AmbientCategory = .focus
    enum ActiveSheet: Identifiable {
        case sound, settings, paywall
        var id: Self { self }
    }
    @State private var activeSheet: ActiveSheet?
    @AppStorage("meditationVolume") private var savedVolume: Double = 0.85

    init(startSilent: Bool = false) {
        _silentBellMode = State(initialValue: startSilent)
    }

    // MARK: - Timer State
    @State private var timeRemaining: Int = 600
    @State private var sessionStartDate: Date = Date()
    @State private var isRunning  = false
    @State private var isPaused   = false
    @State private var isDone       = false
    @State private var timer: Timer?
    @State private var promptMood   = 3
    @State private var promptNote   = ""


    // MARK: - Derived
    private var totalSeconds: Int { selectedDuration * 60 }

    private var progress: Double {
        1.0 - Double(timeRemaining) / Double(totalSeconds)
    }

    private var timeString: String {
        String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60)
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            MeditationBgView(theme: selectedBg)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Space for custom nav bar overlay
                Color.clear.frame(height: 60)

                // Now-playing badge when running
                if isRunning {
                    if let ambTrack = selectedAmbientTrack {
                        HStack(spacing: 6) {
                            Image(systemName: ambTrack.category.icon).font(.caption2)
                            Text("\(ambTrack.title) playing")
                                .font(.caption2)
                            SoundWaveMini()
                        }
                        .foregroundColor(.white.opacity(0.65))
                        .padding(.top, 8)
                    } else if let s = selectedSound {
                        HStack(spacing: 6) {
                            Image(systemName: s.icon).font(.caption2)
                            Text("\(s.rawValue) playing")
                                .font(.caption2)
                            SoundWaveMini()
                        }
                        .foregroundColor(.white.opacity(0.65))
                        .padding(.top, 8)
                    } else if silentBellMode {
                        HStack(spacing: 6) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text("A bell rings every 5 min to bring you back to your breath")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    }
                }

                // ── Volume Slider (shown when any sound is active) ───────
                if (selectedSound != nil || selectedAmbientTrack != nil) && !silentBellMode {
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.65))
                        Slider(value: Binding(
                            get: { savedVolume },
                            set: { v in
                                savedVolume = v
                                soundPlayer.setVolume(Float(v))
                            }
                        ), in: 0...1)
                        .tint(.white)
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 10)
                }

                Spacer()

                // ── Breathing Ring ───────────────────────────────────────
                LotusOrbView(isAnimating: isRunning)
                    .frame(width: 240, height: 240)
                    .id(isRunning)

                VStack(spacing: 6) {
                    Text(timeString)
                        .font(.system(size: 46, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()

                    Text(statusLabel)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.92))
                }
                .padding(.top, 72)

                Spacer()

                // ── Controls ────────────────────────────────────────────
                HStack(spacing: 20) {
                    Button(action: resetTimer) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 19))
                            .foregroundColor(.white.opacity(0.95))
                            .frame(width: 54, height: 54)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }

                    Button(action: toggleTimer) {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.calmAccent)
                            .frame(width: 72, height: 72)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.15), radius: 14)
                            )
                    }

                    Button {
                        activeSheet = .sound
                    } label: {
                        Image(systemName: "music.note")
                            .font(.system(size: 19))
                            .foregroundColor(.white.opacity(0.95))
                            .frame(width: 54, height: 54)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                }

                Text(focusGuidanceText)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 36)
                    .padding(.top, 20)

                DisclaimerFooter()
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)

            if isDone { completionOverlay }
            if showMoodPrompt { moodPromptOverlay }

            // ── Custom nav bar overlay ────────────────────────────────
            VStack {
                HStack {
                    Button {
                        stopTimer()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                    Text("Meditation Timer")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 8) {
                        if !isRunning && !isPaused {
                            Button { activeSheet = .settings } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Color.white.opacity(0.20)))
                            }
                            .buttonStyle(.plain)
                        }
                        if !premium.isPremium {
                            Button { activeSheet = .paywall } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 11))
                                    Text("Premium")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.calmDeep)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(Color.calmAccent))
                            }
                        }
                    }
                    .frame(minWidth: 44, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                Spacer()
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .sound:
                SoundPickerSheet(
                    selectedSound: Binding(
                        get: { selectedSound },
                        set: { selectedSoundRaw = $0?.rawValue ?? "" }
                    ),
                    silentBellMode:       $silentBellMode,
                    selectedAmbientTrack: $selectedAmbientTrack
                )
                .environmentObject(premium)
            case .settings:
                let showPaywallBinding = Binding<Bool>(
                    get: { false },
                    set: { if $0 { activeSheet = .paywall } }
                )
                SettingsSheet(
                    silentBellMode: $silentBellMode,
                    selectedSound: Binding(
                        get: { selectedSound },
                        set: { selectedSoundRaw = $0?.rawValue ?? "" }
                    ),
                    selectedAmbientTrack: $selectedAmbientTrack,
                    selectedDuration: $selectedDuration,
                    timeRemaining: $timeRemaining,
                    isRunning: isRunning,
                    durations: durations,
                    showPaywall: showPaywallBinding
                )
                .environmentObject(premium)
            case .paywall:
                let isPresentedBinding = Binding<Bool>(
                    get: { true },
                    set: { if !$0 { activeSheet = nil } }
                )
                PaywallView(isPresented: isPresentedBinding)
                    .environmentObject(premium)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .watchToggleTimer)) { _ in
            toggleTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { note in
            guard let info = note.userInfo,
                  let typeVal = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeVal) else { return }
            switch type {
            case .began:
                soundPlayer.stop()
                ambientEngine.pause()
            case .ended:
                let opts = (info[AVAudioSessionInterruptionOptionKey] as? UInt)
                    .map { AVAudioSession.InterruptionOptions(rawValue: $0) } ?? []
                if opts.contains(.shouldResume), isRunning {
                    try? AVAudioSession.sharedInstance().setActive(true)
                    if let ambTrack = selectedAmbientTrack {
                        ambientEngine.resume()
                    } else if !silentBellMode {
                        let sound = selectedSound ?? .sereneMindfulness
                        soundPlayer.setVolume(Float(savedVolume))
                        soundPlayer.play(sound, forceRestart: true)
                    }
                }
            @unknown default: break
            }
        }
        .onDisappear {
            stopTimer()
            soundPlayer.stop()
            soundPlayer.playing = nil
            ambientEngine.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: selectedSoundRaw) { _, _ in
            guard isRunning, !silentBellMode else { return }
            ambientEngine.stop()
            if let sound = selectedSound {
                soundPlayer.setVolume(Float(savedVolume))
                soundPlayer.play(sound, forceRestart: true)
            } else {
                soundPlayer.stop()
            }
        }
        .onChange(of: selectedAmbientTrack?.id) { _, newID in
            guard isRunning, !silentBellMode else { return }
            soundPlayer.stop()
            if let track = selectedAmbientTrack {
                ambientEngine.play(track)
            } else {
                ambientEngine.stop()
            }
        }
        .onChange(of: silentBellMode) { _, isSilent in
            guard isRunning else { return }
            if isSilent {
                soundPlayer.stop()
                ambientEngine.stop()
            }
        }
    }

    // MARK: - Current sound label/icon for dropdown header
    private var currentSoundLabel: String {
        if silentBellMode { return "Silent Bell" }
        if let s = selectedSound { return s.rawValue }
        if let t = selectedAmbientTrack { return t.title }
        return "Select"
    }
    private var currentSoundIcon: String {
        if silentBellMode { return "bell.fill" }
        if let s = selectedSound { return s.icon }
        if let t = selectedAmbientTrack { return t.category.icon }
        return "speaker.slash.fill"
    }

    // MARK: - Sound Row (dropdown item)
    private func soundRow(label: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 13))
                    .foregroundColor(isSelected ? .calmDeep : .calmMid)
                    .frame(width: 20)
                Text(label).font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .calmDeep : .calmMid)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark").font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.calmDeep)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(isSelected ? Color.calmAccent.opacity(0.25) : Color.clear))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sound Pill
    private func soundPill(label: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 11))
                Text(label).font(.system(size: 12, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? .calmDeep : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(isSelected ? Color.calmAccent : Color.white.opacity(0.22))
            )
        }
    }

    // MARK: - Status Label
    private var statusLabel: String {
        if isDone    { return "Session complete ✓" }
        if isRunning { return "Breathe deeply…" }
        if isPaused  { return "Paused" }
        return "\(selectedDuration) min session"
    }

    // MARK: - Focus Guidance
    private var focusGuidanceText: String {
        if !isRunning && !isPaused {
            if silentBellMode {
                return "Sit comfortably and close your eyes.\nA gentle bell will ring every 5 minutes\nto invite you back to your breath."
            }
            return "Find a comfortable position and close your eyes."
        }
        if silentBellMode {
            return "Rest in silence and follow your natural breath.\nEach time the bell rings, let it gently\nbring your attention back to the present moment."
        }
        if selectedAmbientTrack != nil {
            return "Let the music carry you deeper into stillness.\nRest your awareness gently on the sound."
        }
        if selectedSound != nil {
            return "Let the sound anchor you in the present moment.\nNotice the rise and fall of your chest with each breath."
        }
        return "Rest your attention on your breath.\nThere is nothing to do — just be here."
    }

    // MARK: - Completion Overlay
    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(Color.calmAccent.opacity(0.15))
                        .frame(width: 90, height: 90)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.calmAccent)
                }

                Text("Well Done")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("Your \(selectedDuration)-minute session is complete.\nTake a moment to notice how you feel.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button("Done") {
                    isDone = false
                    soundPlayer.stop()
                    resetTimer()
                    showMoodPrompt = true
                }
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.calmDeep)
                .padding(.horizontal, 44)
                .padding(.vertical, 14)
                .background(Capsule().fill(Color.calmAccent))
                .padding(.top, 6)
            }
            .padding(36)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.calmMid.opacity(0.95))
            )
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Timer Logic
    private func toggleTimer() {
        isRunning ? pauseTimer() : startTimer()
    }

    private func startTimer() {
        isRunning = true
        isPaused  = false
        isDone    = false
        sessionStartDate = Date()
        HapticManager.start()
        UIApplication.shared.isIdleTimerDisabled = true

        // Silent Meditation: ring bell 3 times at start
        if silentBellMode {
            soundPlayer.playBell()
        } else if let ambTrack = selectedAmbientTrack {
            if ambientEngine.currentTrack?.id == ambTrack.id && !ambientEngine.isPlaying {
                ambientEngine.resume()
            } else {
                ambientEngine.play(ambTrack)
            }
        } else {
            let sound = selectedSound ?? .sereneMindfulness
            soundPlayer.setVolume(Float(savedVolume))
            soundPlayer.play(sound, forceRestart: true)
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    // Silent meditation: single bell every 5 minutes
                    let elapsed = self.totalSeconds - self.timeRemaining
                    if self.silentBellMode && elapsed > 0 && elapsed % 300 == 0 {
                        self.soundPlayer.playSingleBell()
                        HapticManager.complete()
                    }
                } else {
                    self.finishSession()
                }
            }
        }
    }

    private func pauseTimer() {
        isRunning = false
        isPaused  = true
        timer?.invalidate()
        timer = nil
        soundPlayer.stop()
        ambientEngine.pause()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        ambientEngine.stop()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func resetTimer() {
        stopTimer()
        isPaused      = false
        isDone        = false
        timeRemaining = selectedDuration * 60
    }

    private func finishSession() {
        stopTimer()
        isDone = true
        HapticManager.complete()
        journal.logMeditation(duration: selectedDuration)
        HealthKitManager.shared.saveMindfulSession(startDate: sessionStartDate, endDate: Date())
        soundPlayer.stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            soundPlayer.playBell()
        }
        // Ask for a review after the 3rd and 10th completed sessions
        let count = journal.meditationDays.count
        if count == 3 || count == 10 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                requestReview()
            }
        }
    }
}

// MARK: - Mood Prompt Overlay
extension MeditationTimerView {
    var moodPromptOverlay: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("How do you feel?")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        ForEach(1...4, id: \.self) { level in
                            MoodButton(level: level, selected: promptMood == level) { promptMood = level }
                        }
                    }
                    HStack(spacing: 8) {
                        Spacer()
                        ForEach(5...7, id: \.self) { level in
                            MoodButton(level: level, selected: promptMood == level) { promptMood = level }
                                .frame(maxWidth: .infinity)
                        }
                        Spacer()
                    }
                }

                // Message for selected mood
                HStack(alignment: .top, spacing: 10) {
                    Text(promptMood.moodEmoji).font(.system(size: 18))
                    Text(supportiveMessage(for: promptMood))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(promptMood.moodColor.opacity(0.10))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(promptMood.moodColor.opacity(0.25), lineWidth: 1))
                )
                .animation(.easeInOut(duration: 0.25), value: promptMood)

                TextField("Add a note (optional)", text: $promptNote)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.09)))

                HStack(spacing: 12) {
                    Button("Skip") {
                        showMoodPrompt = false
                        promptNote = ""
                    }
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.92))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.white.opacity(0.08)))

                    Button("Save") {
                        journal.addMoodEntry(MoodEntry(mood: promptMood, note: promptNote))
                        showMoodPrompt = false
                        promptNote = ""
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.calmDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.calmAccent))
                }
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 28).fill(Color.calmMid.opacity(0.96)))
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Settings Sheet (Configure Sounds & Themes)
private struct SettingsSheet: View {
    @EnvironmentObject var premium: PremiumStore
    @Binding var silentBellMode: Bool
    @Binding var selectedSound: SoundPlayer.SoundType?
    @Binding var selectedAmbientTrack: AmbientTrack?
    @Binding var selectedDuration: Int
    @Binding var timeRemaining: Int
    let isRunning: Bool
    let durations: [Int]
    @Binding var showPaywall: Bool
    @AppStorage("meditationBackground") private var selectedBgRaw: String = MeditationBackground.sky.rawValue
    private var selectedBg: MeditationBackground { MeditationBackground(rawValue: selectedBgRaw) ?? .sky }
    @Environment(\.dismiss) private var dismiss

    private let natureSounds:     [SoundPlayer.SoundType] = [.ocean, .forest, .meditationRiver, .downpour]
    private let meditationSounds: [SoundPlayer.SoundType] = [
        .rainSleep, .ohm, .ambience, .natureMeditate, .peacefulMind, .spiritualYoga,
        .zenWater, .mindfulnessMeditation, .focusMeditation, .meditationBlue,
        .deepRelaxation, .balanceEnergy, .sleepMeditation, .angelicMeditation,
        .meditationRelaxation, .deepMeditation, .spiritualMeditation, .meditationMiromax,
        .relaxSleep, .meditationDelos, .meditationPlaystarz, .yogaRelaxing,
        .meditationMonda, .meditationFree, .planetFrequencies, .sereneMindfulness
    ]

    private let brandPurple = Color(red: 0.541, green: 0.357, blue: 0.804)

    var body: some View {
        ZStack {
            CalmBackground()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.20)))
                    }
                    Spacer()
                    Text("Settings")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 52, alignment: .trailing)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {

                        // ── Session Duration ─────────────────────────────
                        settingsCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("SESSION DURATION")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.60))
                                    .tracking(0.8)
                                let cols = [GridItem(.adaptive(minimum: 72), spacing: 10)]
                                LazyVGrid(columns: cols, spacing: 10) {
                                    ForEach(durations, id: \.self) { mins in
                                        let locked = mins > 10 && !premium.isPremium
                                        Button {
                                            if locked {
                                                showPaywall = true
                                            } else {
                                                selectedDuration = mins
                                                if !isRunning { timeRemaining = mins * 60 }
                                            }
                                        } label: {
                                            HStack(spacing: 4) {
                                                Text("\(mins) min")
                                                    .font(.system(size: 14, weight: selectedDuration == mins ? .semibold : .regular, design: .rounded))
                                                    .foregroundColor(locked ? .white.opacity(0.30) : (selectedDuration == mins ? brandPurple : .white))
                                                if locked {
                                                    Image(systemName: "lock.fill")
                                                        .font(.system(size: 10))
                                                        .foregroundColor(brandPurple.opacity(0.35))
                                                }
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(selectedDuration == mins ? brandPurple.opacity(0.30) : Color.white.opacity(0.12))
                                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                                        .stroke(selectedDuration == mins ? brandPurple.opacity(0.50) : Color.clear, lineWidth: 1.5))
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(16)
                        }

                        // ── Visual Theme ────────────────────────────────
                        settingsCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("VISUAL THEME")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.60))
                                    .tracking(0.8)
                                let cols = [GridItem(.adaptive(minimum: 52), spacing: 14)]
                                LazyVGrid(columns: cols, spacing: 14) {
                                    ForEach(MeditationBackground.allCases, id: \.rawValue) { theme in
                                        Button { selectedBgRaw = theme.rawValue } label: {
                                            VStack(spacing: 5) {
                                                Circle()
                                                    .fill(theme.swatchGradient)
                                                    .frame(width: 36, height: 36)
                                                    .overlay(Circle().stroke(brandPurple, lineWidth: selectedBg == theme ? 2.5 : 0).padding(-1))
                                                    .shadow(color: .black.opacity(0.12), radius: 4)
                                                Text(theme.label)
                                                    .font(.system(size: 9, weight: selectedBg == theme ? .semibold : .regular, design: .rounded))
                                                    .foregroundColor(selectedBg == theme ? brandPurple : .white.opacity(0.65))
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(16)
                        }

                        // ── Ambient Sounds ──────────────────────────────
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("AMBIENT SOUNDS")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.60))
                                    .tracking(0.8)

                                soundRow(label: "None", icon: "speaker.slash.fill",
                                         isSelected: !silentBellMode && selectedSound == nil && selectedAmbientTrack == nil) {
                                    silentBellMode = false; selectedSound = nil; selectedAmbientTrack = nil
                                }
                                Divider()
                                soundRow(label: "Silent Bell", icon: "bell.fill", isSelected: silentBellMode) {
                                    silentBellMode = true; selectedSound = nil; selectedAmbientTrack = nil
                                }
                                Divider()
                                ForEach(natureSounds, id: \.self) { sound in
                                    soundRow(label: sound.rawValue, icon: sound.icon,
                                             locked: !sound.isFree && !premium.isPremium,
                                             isSelected: selectedSound == sound && !silentBellMode) {
                                        silentBellMode = false; selectedSound = sound; selectedAmbientTrack = nil
                                    }
                                    Divider()
                                }
                                ForEach(Array(meditationSounds.enumerated()), id: \.element) { idx, sound in
                                    soundRow(label: sound.rawValue, icon: sound.icon,
                                             locked: !sound.isFree && !premium.isPremium,
                                             isSelected: selectedSound == sound && !silentBellMode) {
                                        silentBellMode = false; selectedSound = sound; selectedAmbientTrack = nil
                                    }
                                    if idx < meditationSounds.count - 1 { Divider() }
                                }
                            }
                            .padding(16)
                        }

                        Spacer().frame(height: 32)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }
            }
        }
    }

    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.14)))
    }

    private func soundRow(label: String, icon: String, locked: Bool = false, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { if !locked { action() } }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? brandPurple.opacity(0.35) : Color.white.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundColor(locked ? .white.opacity(0.25) : (isSelected ? .white : .white.opacity(0.75)))
                }
                Text(label)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundColor(locked ? .white.opacity(0.35) : .white)
                Spacer()
                if locked {
                    Image(systemName: "lock.fill").font(.system(size: 11)).foregroundColor(.white.opacity(0.30))
                } else if isSelected {
                    Image(systemName: "speaker.wave.2.fill").font(.system(size: 12)).foregroundColor(brandPurple)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Timer Picker Sheet
private struct TimerPickerSheet: View {
    @EnvironmentObject var premium: PremiumStore
    @Binding var selectedDuration: Int
    @Binding var timeRemaining: Int
    let durations: [Int]
    @AppStorage("meditationBackground") private var selectedBgRaw: String = MeditationBackground.sky.rawValue
    private var selectedBg: MeditationBackground { MeditationBackground(rawValue: selectedBgRaw) ?? .sky }
    @Environment(\.dismiss) private var dismiss

    private let brandPurple = Color(red: 0.541, green: 0.357, blue: 0.804)

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.96, blue: 0.98).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.40, green: 0.40, blue: 0.45))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(red: 0.90, green: 0.90, blue: 0.93)))
                    }
                    Spacer()
                    Text("Select Timer")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.calmDeep)
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(brandPurple)
                        .frame(width: 52, alignment: .trailing)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)

                VStack(spacing: 10) {
                    ForEach(durations, id: \.self) { mins in
                        let locked = mins > 10 && !premium.isPremium
                        Button {
                            if !locked {
                                selectedDuration = mins
                                timeRemaining = mins * 60
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Text("\(mins) min")
                                    .font(.system(size: 16, weight: selectedDuration == mins ? .semibold : .regular, design: .rounded))
                                    .foregroundColor(locked ? Color(red: 0.60, green: 0.60, blue: 0.65) : .calmDeep)
                                Spacer()
                                if locked {
                                    Image(systemName: "lock.fill").font(.system(size: 12)).foregroundColor(brandPurple.opacity(0.35))
                                } else if selectedDuration == mins {
                                    Image(systemName: "checkmark").font(.system(size: 13, weight: .semibold)).foregroundColor(brandPurple)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(selectedDuration == mins ? brandPurple.opacity(0.10) : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(selectedDuration == mins ? brandPurple.opacity(0.35) : Color.clear, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }
}

// MARK: - Sound Picker Sheet
private struct SoundPickerSheet: View {
    @EnvironmentObject var premium: PremiumStore
    @Binding var selectedSound:        SoundPlayer.SoundType?
    @Binding var silentBellMode:       Bool
    @Binding var selectedAmbientTrack: AmbientTrack?
    @AppStorage("meditationBackground") private var selectedBgRaw: String = MeditationBackground.sky.rawValue
    private var selectedBg: MeditationBackground { MeditationBackground(rawValue: selectedBgRaw) ?? .sky }
    @Environment(\.dismiss) private var dismiss


    private let natureSounds:     [SoundPlayer.SoundType] = [.ocean, .forest, .meditationRiver, .downpour]
    private let meditationSounds: [SoundPlayer.SoundType] = [
        .rainSleep, .ohm, .ambience, .natureMeditate, .peacefulMind, .spiritualYoga,
        .zenWater, .mindfulnessMeditation, .focusMeditation, .meditationBlue,
        .deepRelaxation, .balanceEnergy, .sleepMeditation, .angelicMeditation,
        .meditationRelaxation, .deepMeditation, .spiritualMeditation, .meditationMiromax,
        .relaxSleep, .meditationDelos, .meditationPlaystarz, .yogaRelaxing,
        .meditationMonda, .meditationFree, .planetFrequencies, .sereneMindfulness
    ]

    private let brandPurple = Color(red: 0.541, green: 0.357, blue: 0.804)

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.96, blue: 0.98).ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Choose Sound")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.calmDeep)
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(brandPurple)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 8) {

                        // ── Silence / Bell ───────────────────────────────
                        sectionHeader("Basic")
                        VStack(spacing: 0) {
                            row(label: "None", subtitle: "Complete silence", icon: "speaker.slash.fill",
                                isSelected: !silentBellMode && selectedSound == nil && selectedAmbientTrack == nil) {
                                silentBellMode = false; selectedSound = nil; selectedAmbientTrack = nil; dismiss()
                            }
                            Divider().padding(.leading, 52)
                            row(label: "Silent Bell", subtitle: "Bell rings every 5 min", icon: "bell.fill",
                                isSelected: silentBellMode) {
                                silentBellMode = true; selectedSound = nil; selectedAmbientTrack = nil; dismiss()
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                        .padding(.horizontal, 16)

                        // ── Nature Sounds ────────────────────────────────
                        sectionHeader("Nature Sounds")
                        VStack(spacing: 0) {
                            ForEach(Array(natureSounds.enumerated()), id: \.element) { idx, sound in
                                row(label: sound.rawValue, subtitle: sound.subtitle, icon: sound.icon,
                                    locked: !sound.isFree && !premium.isPremium,
                                    isSelected: selectedSound == sound && !silentBellMode) {
                                    silentBellMode = false; selectedSound = sound; selectedAmbientTrack = nil; dismiss()
                                }
                                if idx < natureSounds.count - 1 { Divider().padding(.leading, 52) }
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                        .padding(.horizontal, 16)

                        // ── Meditation Music ─────────────────────────────
                        sectionHeader("Meditation Music")
                        VStack(spacing: 0) {
                            ForEach(Array(meditationSounds.enumerated()), id: \.element) { idx, sound in
                                row(label: sound.rawValue, subtitle: sound.subtitle, icon: sound.icon,
                                    locked: !sound.isFree && !premium.isPremium,
                                    isSelected: selectedSound == sound && !silentBellMode) {
                                    silentBellMode = false; selectedSound = sound; selectedAmbientTrack = nil; dismiss()
                                }
                                if idx < meditationSounds.count - 1 { Divider().padding(.leading, 52) }
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Color(red: 0.50, green: 0.50, blue: 0.55))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.bottom, 4)
            .padding(.top, 8)
    }

    private func row(label: String, subtitle: String, icon: String, locked: Bool = false, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { if !locked { action() } }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? brandPurple.opacity(0.12) : Color(red: 0.92, green: 0.92, blue: 0.95))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(locked ? brandPurple.opacity(0.30) : (isSelected ? brandPurple : Color(red: 0.25, green: 0.25, blue: 0.30)))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .rounded))
                        .foregroundColor(locked ? Color(red: 0.60, green: 0.60, blue: 0.65) : .calmDeep)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.60))
                }
                Spacer()
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                        .foregroundColor(brandPurple.opacity(0.35))
                } else if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(brandPurple)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Small Wave Animation (shown in now-playing badge)
private struct SoundWaveMini: View {
    @State private var on = false
    var body: some View {
        HStack(spacing: 2) {
            ForEach([0.6, 1.0, 0.7, 0.5] as [Double], id: \.self) { h in
                RoundedRectangle(cornerRadius: 1)
                    .frame(width: 2, height: on ? h * 8 : h * 3)
                    .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: on)
            }
        }
        .foregroundColor(.calmAccent.opacity(0.65))
        .onAppear { on = true }
    }
}
