import SwiftUI
import UserNotifications

// MARK: - User Preferences Store
/// Persists favourites, recently-used sounds, and daily reminder settings.
class UserPreferencesStore: ObservableObject {

    // MARK: - Favourites
    @Published private(set) var favorites: Set<String> {
        didSet { UserDefaults.standard.set(Array(favorites), forKey: "favorites") }
    }

    func toggleFavorite(_ sound: SoundPlayer.SoundType) {
        if favorites.contains(sound.rawValue) {
            favorites.remove(sound.rawValue)
        } else {
            favorites.insert(sound.rawValue)
        }
    }

    func isFavorite(_ sound: SoundPlayer.SoundType) -> Bool {
        favorites.contains(sound.rawValue)
    }

    var favoriteSounds: [SoundPlayer.SoundType] {
        SoundPlayer.SoundType.allCases.filter { favorites.contains($0.rawValue) }
    }

    // MARK: - Recently Used
    @Published private(set) var recentlyUsed: [String] {
        didSet { UserDefaults.standard.set(recentlyUsed, forKey: "recentlyUsed") }
    }

    private let maxRecent = 5

    func recordUsed(_ sound: SoundPlayer.SoundType) {
        var updated = recentlyUsed.filter { $0 != sound.rawValue }
        updated.insert(sound.rawValue, at: 0)
        recentlyUsed = Array(updated.prefix(maxRecent))
    }

    var recentSounds: [SoundPlayer.SoundType] {
        recentlyUsed.compactMap { raw in
            SoundPlayer.SoundType.allCases.first { $0.rawValue == raw }
        }
    }

    // MARK: - Daily Reminder
    @AppStorage("dailyReminder") var dailyReminderEnabled: Bool = false

    func requestReminderPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func scheduleReminder(hour: Int, minute: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["calmDaily"])
        guard dailyReminderEnabled else { return }

        let content      = UNMutableNotificationContent()
        content.title    = "Time to Breathe"
        content.body     = "Take a moment for your daily meditation."
        content.sound    = .default

        var comps        = DateComponents()
        comps.hour       = hour
        comps.minute     = minute
        let trigger      = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request      = UNNotificationRequest(identifier: "calmDaily", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["calmDaily"])
    }

    // MARK: - Init
    init() {
        let savedFavs    = UserDefaults.standard.stringArray(forKey: "favorites") ?? []
        let savedRecent  = UserDefaults.standard.stringArray(forKey: "recentlyUsed") ?? []
        self.favorites   = Set(savedFavs)
        self.recentlyUsed = savedRecent
    }
}
