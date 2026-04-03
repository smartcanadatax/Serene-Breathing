import SwiftUI

// MARK: - Sound Library Category

enum SoundLibraryCategory: String, CaseIterable {
    case nature    = "Nature"
    case meditation = "Meditation"
    case sleep     = "Sleep"

    var icon: String {
        switch self {
        case .nature:     return "leaf.fill"
        case .meditation: return "brain.head.profile"
        case .sleep:      return "moon.stars.fill"
        }
    }
}

extension SoundPlayer.SoundType {
    var libraryCategory: SoundLibraryCategory {
        switch self {
        case .ocean, .forest, .meditationRiver, .ambience, .downpour,
             .immersiveNature, .relaxingNature:
            return .nature
        case .rainSleep, .sleepMeditation, .relaxSleep, .yogaRelaxing,
             .stillWaters, .deepSleepBg, .sleepCMajor, .veryDeepSleep:
            return .sleep
        default:
            return .meditation
        }
    }
}

// MARK: - Relaxing Sounds View

struct RelaxingSoundsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var soundPlayer: SoundPlayer
    @EnvironmentObject var userPrefs:   UserPreferencesStore
    @EnvironmentObject var premium:     PremiumStore
    @State private var selectedCategory: SoundLibraryCategory = .nature
    @State private var showPaywallFromNav = false

    private var tracks: [SoundPlayer.SoundType] {
        SoundPlayer.SoundType.allCases.filter { $0.libraryCategory == selectedCategory }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            CalmBackground()

            VStack(spacing: 0) {
                // Nav header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                    Text("Sounds Library")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 10) {
                        SleepTimerButton()
                        if !premium.isPremium {
                            Button { showPaywallFromNav = true } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "crown.fill").font(.system(size: 11))
                                    Text("Premium").font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.calmDeep)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Capsule().fill(Color.calmAccent))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Category picker
                Picker("", selection: $selectedCategory) {
                    ForEach(SoundLibraryCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(tracks) { sound in
                            SoundLibraryRow(sound: sound)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    DisclaimerFooter()
                        .padding(.bottom, soundPlayer.playing != nil ? 100 : 32)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            // Mini player
            if soundPlayer.playing != nil {
                SoundMiniPlayer()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.3), value: soundPlayer.playing)
        .fullScreenCover(isPresented: $showPaywallFromNav) {
            PaywallView(isPresented: $showPaywallFromNav)
                .environmentObject(premium)
        }
    }
}

// MARK: - Sound Library Row

private struct SoundLibraryRow: View {
    @EnvironmentObject var soundPlayer: SoundPlayer
    @EnvironmentObject var userPrefs:   UserPreferencesStore
    @EnvironmentObject var premium:     PremiumStore
    let sound: SoundPlayer.SoundType

    @State private var showPaywall = false

    private var isActive:  Bool { soundPlayer.playing == sound }
    private var isLocked:  Bool { !sound.isFree && !premium.isPremium }
    private var isFav:     Bool { userPrefs.isFavorite(sound) }

    var body: some View {
        Button {
            if isLocked {
                showPaywall = true
            } else {
                if isActive {
                    soundPlayer.stop()
                } else {
                    soundPlayer.play(sound)
                    userPrefs.recordUsed(sound)
                }
            }
        } label: {
            HStack(spacing: 14) {
                // Play indicator
                ZStack {
                    Circle()
                        .fill(isActive ? Color.calmAccent.opacity(0.20) : Color.white.opacity(0.08))
                        .frame(width: 46, height: 46)
                    Image(systemName: isLocked ? "lock.fill" : (isActive ? "pause.fill" : "play.fill"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isLocked ? .white.opacity(0.35) : (isActive ? .calmAccent : .white.opacity(0.70)))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(sound.rawValue)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(isLocked ? .white.opacity(0.45) : (isActive ? .calmAccent : .white))
                    Text(isLocked ? "Premium" : sound.subtitle)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(isLocked ? .calmAccent.opacity(0.70) : .white.opacity(0.60))
                }

                Spacer()

                if !isLocked {
                    Button {
                        userPrefs.toggleFavorite(sound)
                    } label: {
                        Image(systemName: isFav ? "heart.fill" : "heart")
                            .font(.system(size: 15))
                            .foregroundColor(isFav ? Color(red: 1.0, green: 0.40, blue: 0.55) : .white.opacity(0.30))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                if isActive {
                    AmbientSoundWaveView(active: true)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isActive ? Color.calmAccent.opacity(0.10) : Color.white.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(isActive ? Color.calmAccent.opacity(0.40) : Color.clear, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall)
                .environmentObject(premium)
        }
    }
}

// MARK: - Sound Mini Player

private struct SoundMiniPlayer: View {
    @EnvironmentObject var soundPlayer: SoundPlayer

    var body: some View {
        VStack(spacing: 0) {
            // Thin top bar
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(height: 2)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(soundPlayer.playing?.rawValue ?? "")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text(soundPlayer.playing?.subtitle ?? "")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.white.opacity(0.60))
                }

                Spacer()

                // Sleep timer label if active
                if soundPlayer.sleepTimerMinutes != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "moon.zzz.fill").font(.system(size: 11))
                        Text(soundPlayer.sleepTimerLabel).font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.calmAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.10)))
                }

                Button { soundPlayer.stop() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.40))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(
            Color(red: 0.10, green: 0.22, blue: 0.45)
                .opacity(0.97)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Sleep Timer Button

struct SleepTimerButton: View {
    @EnvironmentObject var soundPlayer: SoundPlayer
    @State private var showPicker = false
    private let options = [15, 30, 45, 60]

    var body: some View {
        Button {
            if soundPlayer.sleepTimerMinutes != nil {
                soundPlayer.cancelSleepTimer()
            } else {
                showPicker = true
            }
        } label: {
            if soundPlayer.sleepTimerMinutes != nil {
                HStack(spacing: 4) {
                    Image(systemName: "moon.zzz.fill").font(.system(size: 12))
                    Text(soundPlayer.sleepTimerLabel).font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.calmAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.15)))
            } else {
                Image(systemName: "moon.zzz")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.80))
            }
        }
        .confirmationDialog("Stop sounds after…", isPresented: $showPicker, titleVisibility: .visible) {
            ForEach(options, id: \.self) { min in
                Button("\(min) minutes") { soundPlayer.setSleepTimer(minutes: min) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Sound Wave Animation

struct SoundWaveView: View {
    let color: Color
    @State private var animating = false

    private let heights: [CGFloat] = [8, 14, 10, 6]
    private let minH:    [CGFloat] = [3,  6,  4,  3]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 3, height: animating ? heights[i] : minH[i])
                    .animation(
                        .easeInOut(duration: 0.45)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.1),
                        value: animating
                    )
            }
        }
        .onAppear  { animating = true  }
        .onDisappear { animating = false }
    }
}

// MARK: - Legacy Sound Card (kept for compatibility)

struct SoundSection<Content: View>: View {
    let title: String
    let icon:  String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.90))
                    .tracking(1.2)
            }
            .padding(.leading, 4)
            VStack(spacing: 12) { content() }
        }
    }
}

struct SoundCard: View {
    @EnvironmentObject var soundPlayer: SoundPlayer
    @EnvironmentObject var userPrefs:   UserPreferencesStore
    @EnvironmentObject var premium:     PremiumStore
    let sound: SoundPlayer.SoundType
    @State private var showPaywall = false

    private var isPlaying:  Bool { soundPlayer.playing == sound }
    private var isFavorite: Bool { userPrefs.isFavorite(sound) }
    private var isLocked:   Bool { !sound.isFree && !premium.isPremium }

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(sound.color.opacity(isPlaying ? 0.35 : (isLocked ? 0.08 : 0.18)))
                    .frame(width: 54, height: 54)
                Image(systemName: isLocked ? "lock.fill" : sound.icon)
                    .font(.system(size: 21))
                    .foregroundColor(isLocked ? .white.opacity(0.35) : sound.color)
            }
            .animation(.easeInOut(duration: 0.3), value: isPlaying)

            VStack(alignment: .leading, spacing: 3) {
                Text(sound.rawValue)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(isLocked ? .white.opacity(0.45) : .white)
                Text(isLocked ? "Premium" : sound.subtitle)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(isLocked ? .calmAccent.opacity(0.70) : .white.opacity(0.92))
            }

            Spacer()

            if isLocked {
                Button { showPaywall = true } label: {
                    Text("Unlock")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.calmDeep)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.calmAccent))
                }
                .buttonStyle(.plain)
            } else {
                Button { userPrefs.toggleFavorite(sound) } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 17))
                        .foregroundColor(isFavorite ? Color(red: 1.0, green: 0.40, blue: 0.55) : .white.opacity(0.30))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)

                Button {
                    if isPlaying { soundPlayer.stop() }
                    else { soundPlayer.play(sound); userPrefs.recordUsed(sound) }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isPlaying ? sound.color : Color.white.opacity(0.10))
                            .frame(width: 42, height: 42)
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 14))
                            .foregroundColor(isPlaying ? .white : .white.opacity(0.55))
                    }
                    .animation(.easeInOut(duration: 0.3), value: isPlaying)
                }
                .buttonStyle(.plain)

                if isPlaying { SoundWaveView(color: sound.color) }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(isPlaying ? 0.11 : (isLocked ? 0.03 : 0.06)))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(isPlaying ? sound.color.opacity(0.40) : Color.white.opacity(0.08), lineWidth: 1))
        )
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall).environmentObject(premium)
        }
    }
}
