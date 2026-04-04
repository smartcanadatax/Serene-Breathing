import SwiftUI
import UserNotifications

// MARK: - Settings View
struct SettingsView: View {
    @AppStorage("meditationPalette") private var meditationPalette = "blue"
    @AppStorage("meditationBgSound") private var meditationBgSound = "none"

    @AppStorage("dailyReminder")    private var dailyReminder    = false
    @AppStorage("darkMode")         private var darkMode         = false
    @AppStorage("reminderHour")     private var reminderHour     = 8
    @AppStorage("reminderMin")      private var reminderMin      = 0
    @AppStorage("streakNotif")      private var streakNotif      = false
    @AppStorage("streakNotifHour")  private var streakNotifHour  = 20
    @AppStorage("streakNotifMin")   private var streakNotifMin   = 0
    @AppStorage("checkInNotif")     private var checkInNotif     = false
    @AppStorage("checkInNotifHour") private var checkInNotifHour = 9
    @AppStorage("checkInNotifMin")  private var checkInNotifMin  = 0

    @State private var reminderTime = Calendar.current.date(
        bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var streakTime = Calendar.current.date(
        bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var checkInTime = Calendar.current.date(
        bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var showPermissionAlert = false

    private struct MusicCredit { let title: String; let attribution: String }
    private let musicCredits: [MusicCredit] = [
        .init(title: "Ocean — Close Sea Waves Loop",
              attribution: "\"Close Sea Waves Loop\" by Mixkit · mixkit.co · Mixkit Free License"),
        .init(title: "Forest — Escape Forest",
              attribution: "\"Escape Forest\" by FSM Team · free-stock-music.com · CC BY 4.0"),
        .init(title: "Ambience — Ambient Music Nature",
              attribution: "\"Ambient Music Nature\" by Alex Productions · free-stock-music.com · CC BY 3.0"),
        .init(title: "Ohm",
              attribution: "\"Ohm\" by Jason Shaw · audionautix.com · CC BY 4.0"),
        .init(title: "Nature Meditate — Meditate with Nature",
              attribution: "\"Meditate with Nature\" by ChilledMusic · free-stock-music.com · CC BY 4.0"),
        .init(title: "Rain Sleep — Rain Sleep Meditation",
              attribution: "\"Rain Sleep Meditation\" by Holizna · CC0 1.0 Public Domain"),
        .init(title: "Peaceful Mind — Peaceful Mind",
              attribution: "\"Peaceful Mind\" by Astron · free-stock-music.com · CC BY 4.0"),
        .init(title: "Spiritual Yoga — Spiritual Yoga",
              attribution: "\"Spiritual Yoga\" by ChilledMusic · free-stock-music.com · CC BY 4.0"),
        .init(title: "Zen Water — Zen Water Healing",
              attribution: "\"Zen Water Healing\" by ChilledMusic · free-stock-music.com · CC BY 4.0"),
        .init(title: "Downpour",
              attribution: "\"Downpour\" by Keys of Moon · keysofmoon.com · CC BY 4.0"),
    ]

    var body: some View {
        ZStack {
            CalmBackground()

            ScrollView {
                LazyVStack(spacing: 20) {

                    // MARK: Reminders
                    settingsSection(header: "Daily Reminder") {
                        // Toggle
                        settingsRow {
                            HStack {
                                iconBadge("bell.fill")
                                Text("Remind me to meditate")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.calmDeep)
                                Spacer()
                                Toggle("", isOn: $dailyReminder)
                                    .tint(.calmAccent)
                                    .onChange(of: dailyReminder) { _, on in
                                        if on { requestNotificationPermission() }
                                        else  { cancelReminder() }
                                    }
                            }
                        }

                        // Time picker — only visible when reminder is on
                        if dailyReminder {
                            settingsRow {
                                HStack {
                                    iconBadge("clock.fill")
                                    Text("Reminder Time")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.calmDeep)
                                    Spacer()
                                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .onChange(of: reminderTime) { _, t in
                                            scheduleReminder(at: t)
                                        }
                                }
                            }
                        }
                    }

                    // MARK: Check-In Reminder
                    settingsSection(header: "Daily Check-In Reminder") {
                        settingsRow {
                            HStack {
                                iconBadge("sun.and.horizon.fill")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Remind me to check in")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.calmDeep)
                                    Text("Daily reminder to log your mood and sleep")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.calmMid)
                                }
                                Spacer()
                                Toggle("", isOn: $checkInNotif)
                                    .tint(.calmAccent)
                                    .onChange(of: checkInNotif) { _, on in
                                        if on { requestCheckInPermission() }
                                        else  { cancelCheckInReminder() }
                                    }
                            }
                        }

                        if checkInNotif {
                            settingsRow {
                                HStack {
                                    iconBadge("clock.fill")
                                    Text("Reminder Time")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.calmDeep)
                                    Spacer()
                                    DatePicker("", selection: $checkInTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .onChange(of: checkInTime) { _, t in
                                            scheduleCheckInReminder(at: t)
                                        }
                                }
                            }
                        }
                    }

                    // MARK: Streak Reminder
                    settingsSection(header: "Streak Reminder") {
                        settingsRow {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    iconBadge("flame.fill")
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Evening streak nudge")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(.calmDeep)
                                        Text("Daily evening reminder to maintain your streak")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.calmMid)
                                    }
                                    Spacer()
                                    Toggle("", isOn: $streakNotif)
                                        .tint(.calmAccent)
                                        .onChange(of: streakNotif) { _, on in
                                            if on { requestStreakPermission() }
                                            else  { cancelStreakReminder() }
                                        }
                                }
                            }
                        }

                        if streakNotif {
                            settingsRow {
                                HStack {
                                    iconBadge("clock.fill")
                                    Text("Reminder Time")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.calmDeep)
                                    Spacer()
                                    DatePicker("", selection: $streakTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .onChange(of: streakTime) { _, t in
                                            scheduleStreakReminder(at: t)
                                        }
                                }
                            }
                        }
                    }

                    // MARK: Appearance
                    settingsSection(header: "Appearance") {
                        settingsRow {
                            HStack {
                                iconBadge("moon.fill")
                                Text("Dark Mode")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.calmDeep)
                                Spacer()
                                Toggle("", isOn: $darkMode)
                                    .tint(.calmAccent)
                            }
                        }
                    }

                    // MARK: About
                    settingsSection(header: "About") {
                        settingsRow {
                            HStack {
                                iconBadge("info.circle.fill")
                                Text("Version")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.calmDeep)
                                Spacer()
                                Text("1.0.0")
                                    .font(.system(size: 14))
                                    .foregroundColor(.calmMid)
                            }
                        }
                        NavigationLink(destination: LegalView()) {
                            settingsRow {
                                HStack {
                                    iconBadge("doc.text.fill")
                                    Text("Disclaimer, Privacy & Terms")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.calmDeep)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.calmMid.opacity(0.60))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        settingsRow {
                            HStack {
                                iconBadge("heart.fill")
                                Text("Made with care for your calm")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.calmDeep)
                                Spacer()
                            }
                        }
                    }

                    // MARK: Music Credits
                    settingsSection(header: "Music Credits") {
                        ForEach(musicCredits, id: \.title) { credit in
                            settingsRow {
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "music.note")
                                            .font(.system(size: 12))
                                            .foregroundColor(.calmAccent)
                                        Text(credit.title)
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.calmDeep)
                                    }
                                    Text(credit.attribution)
                                        .font(.system(size: 11))
                                        .foregroundColor(.calmMid)
                                        .padding(.leading, 20)
                                }
                            }
                        }
                    }

                    // Disclaimer
                    Text("Serene Breathing is not a medical application. If you have a health condition please consult a professional.")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Settings")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .alert("Notifications Disabled", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { dailyReminder = false }
        } message: {
            Text("Please allow notifications in Settings to receive daily meditation reminders.")
        }
    }

    // MARK: - Reusable Layout Helpers
    private func settingsSection<Content: View>(header: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(header.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.90))
                .padding(.leading, 6)

            VStack(spacing: 1) { content() }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.95, green: 0.95, blue: 0.98))
                )
        }
    }

    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
    }

    private func iconBadge(_ icon: String, color: Color = .calmAccent) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: 34, height: 34)
                .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(.calmAccent)
        }
        .padding(.trailing, 6)
    }

    // MARK: - Notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    self.scheduleReminder(at: self.reminderTime)
                } else {
                    self.dailyReminder   = false
                    self.showPermissionAlert = true
                }
            }
        }
    }

    private func scheduleReminder(at time: Date) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["calmDaily"])
        guard dailyReminder else { return }

        let content      = UNMutableNotificationContent()
        content.title    = "Time to Breathe 🌿"
        content.body     = "Take a moment for your daily meditation."
        content.sound    = .default

        let comps   = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "calmDaily", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    private func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["calmDaily"])
    }

    // MARK: - Streak Notifications
    private func requestStreakPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    self.scheduleStreakReminder(at: self.streakTime)
                } else {
                    self.streakNotif = false
                    self.showPermissionAlert = true
                }
            }
        }
    }

    private func scheduleStreakReminder(at time: Date) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["streakReminder"])
        guard streakNotif else { return }

        let messages = [
            "🔥 Don't break your streak — take a moment to breathe today.",
            "🌿 Your streak is waiting. A few minutes of calm can change your whole evening.",
            "✨ One meditation away from keeping your streak alive.",
            "🧘 Small steps build big habits. Meditate for just 5 minutes tonight.",
            "🌙 End your day with peace. Your streak is worth protecting.",
        ]
        let body = messages[Calendar.current.component(.weekday, from: Date()) % messages.count]

        let content      = UNMutableNotificationContent()
        content.title    = "Serene Breathing"
        content.body     = body
        content.sound    = .default

        let comps   = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "streakReminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    private func cancelStreakReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["streakReminder"])
    }

    // MARK: - Check-In Notifications
    private func requestCheckInPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    self.scheduleCheckInReminder(at: self.checkInTime)
                } else {
                    self.checkInNotif = false
                    self.showPermissionAlert = true
                }
            }
        }
    }

    private func scheduleCheckInReminder(at time: Date) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["checkInReminder"])
        guard checkInNotif else { return }

        let content      = UNMutableNotificationContent()
        content.title    = "How are you today?"
        content.body     = "Take a moment to log your mood and last night's sleep. Serene has a personalized insight waiting for you."
        content.sound    = .default

        let comps   = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "checkInReminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    private func cancelCheckInReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["checkInReminder"])
    }
}

// MARK: - Palette Options
enum MeditationPalette: String, CaseIterable {
    case blue   = "blue"
    case indigo = "indigo"
    case teal   = "teal"
    case sage   = "sage"
    case slate  = "slate"

    var gradient: LinearGradient {
        switch self {
        case .blue:
            return LinearGradient(colors: [Color(red: 0.31, green: 0.44, blue: 0.77), Color(red: 0.28, green: 0.41, blue: 0.74)], startPoint: .top, endPoint: .bottom)
        case .indigo:
            return LinearGradient(colors: [Color(red: 0.22, green: 0.18, blue: 0.55), Color(red: 0.18, green: 0.14, blue: 0.48)], startPoint: .top, endPoint: .bottom)
        case .teal:
            return LinearGradient(colors: [Color(red: 0.15, green: 0.48, blue: 0.58), Color(red: 0.12, green: 0.42, blue: 0.52)], startPoint: .top, endPoint: .bottom)
        case .sage:
            return LinearGradient(colors: [Color(red: 0.22, green: 0.44, blue: 0.36), Color(red: 0.18, green: 0.38, blue: 0.30)], startPoint: .top, endPoint: .bottom)
        case .slate:
            return LinearGradient(colors: [Color(red: 0.24, green: 0.28, blue: 0.40), Color(red: 0.20, green: 0.24, blue: 0.36)], startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - Background Sound Options
enum MeditationBgSound: String, CaseIterable {
    case none   = "none"
    case ocean  = "ocean"
    case forest = "forest"
    case rain   = "rain"
    case zen    = "zen_water"

    var label: String {
        switch self {
        case .none:   return "None"
        case .ocean:  return "Ocean Waves"
        case .forest: return "Forest"
        case .rain:   return "Rain"
        case .zen:    return "Zen Water"
        }
    }

    var icon: String {
        switch self {
        case .none:   return "speaker.slash.fill"
        case .ocean:  return "water.waves"
        case .forest: return "leaf.fill"
        case .rain:   return "cloud.rain.fill"
        case .zen:    return "drop.fill"
        }
    }
}
