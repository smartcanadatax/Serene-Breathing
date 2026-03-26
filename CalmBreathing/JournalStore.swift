import SwiftUI

// MARK: - Data Models

struct MeditationDay: Codable {
    let date: Date
    let duration: Int   // minutes
}

struct MoodEntry: Codable, Identifiable {
    let id:     UUID
    let date:   Date
    let mood:   Int      // 1 = Angry … 7 = Grateful
    let note:   String
    var tags:   [String] // what helped today
    var source: String   // "manual" | "post-session"

    init(mood: Int, note: String = "", tags: [String] = [], source: String = "manual") {
        self.id = UUID(); self.date = Date()
        self.mood = mood; self.note = note
        self.tags = tags; self.source = source
    }

    // Backward-compatible decoder — old entries missing tags/source decode fine
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id     = try c.decode(UUID.self,   forKey: .id)
        date   = try c.decode(Date.self,   forKey: .date)
        mood   = try c.decode(Int.self,    forKey: .mood)
        note   = try c.decode(String.self, forKey: .note)
        tags   = (try? c.decode([String].self, forKey: .tags))   ?? []
        source = (try? c.decode(String.self,   forKey: .source)) ?? "manual"
    }
}

struct SleepEntry: Codable, Identifiable {
    let id:       UUID
    let date:     Date
    let quality:  Int     // 1–5
    var hours:    Double  // stored; computed from bedtime/wakeTime when available
    let note:     String
    var bedtime:  Date?
    var wakeTime: Date?
    var dreamType: Int    // 0 = None  1 = Light  2 = Vivid
    var dreamNote: String

    var computedHours: Double {
        guard let bed = bedtime, let wake = wakeTime else { return hours }
        var diff = wake.timeIntervalSince(bed)
        if diff < 0 { diff += 86400 } // crossed midnight
        return diff / 3600
    }

    init(quality: Int, hours: Double = 0, note: String = "",
         bedtime: Date? = nil, wakeTime: Date? = nil,
         dreamType: Int = 0, dreamNote: String = "") {
        self.id = UUID(); self.date = Date()
        self.quality = quality; self.hours = hours; self.note = note
        self.bedtime = bedtime; self.wakeTime = wakeTime
        self.dreamType = dreamType; self.dreamNote = dreamNote
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decode(UUID.self,   forKey: .id)
        date      = try c.decode(Date.self,   forKey: .date)
        quality   = try c.decode(Int.self,    forKey: .quality)
        hours     = try c.decode(Double.self, forKey: .hours)
        note      = try c.decode(String.self, forKey: .note)
        bedtime   = try? c.decode(Date.self,   forKey: .bedtime)
        wakeTime  = try? c.decode(Date.self,   forKey: .wakeTime)
        dreamType = (try? c.decode(Int.self,    forKey: .dreamType)) ?? 0
        dreamNote = (try? c.decode(String.self, forKey: .dreamNote)) ?? ""
    }
}

// MARK: - Journal Store

class JournalStore: ObservableObject {

    // MARK: Meditation log
    @Published private(set) var meditationDays: [MeditationDay] = []

    // MARK: Mood journal
    @Published private(set) var moodEntries: [MoodEntry] = []

    // MARK: Sleep journal
    @Published private(set) var sleepEntries: [SleepEntry] = []

    // MARK: Gratitude journal
    @Published private(set) var gratitudeEntries: [GratitudeEntry] = []

    // MARK: Challenge grid (tap-to-mark, independent of calendar)
    @Published private(set) var markedChallengeIndices: Set<Int> = []
    var totalChallengeDays: Int { markedChallengeIndices.count }

    var challengeMarkedToday: Bool {
        guard let stored = UserDefaults.standard.object(forKey: "lastChallengeMarkDate") as? Date else { return false }
        return Calendar.current.isDateInToday(stored)
    }

    func markChallengeDay() {
        markedChallengeIndices.insert(totalChallengeDays)
        UserDefaults.standard.set(Date(), forKey: "lastChallengeMarkDate")
        save()
    }

    func toggleChallengeIndex(_ index: Int) {
        if markedChallengeIndices.contains(index) {
            markedChallengeIndices.remove(index)
        } else {
            markedChallengeIndices.insert(index)
            UserDefaults.standard.set(Date(), forKey: "lastChallengeMarkDate")
        }
        save()
    }

    // MARK: Sleep journal always available
    var sleepJournalUnlocked: Bool { true }

    var hasMoodEntryToday: Bool {
        guard let latest = moodEntries.first else { return false }
        return Calendar.current.isDateInToday(latest.date)
    }

    var hasSleepEntryToday: Bool {
        guard let latest = sleepEntries.first else { return false }
        return Calendar.current.isDateInToday(latest.date)
    }
    var uniqueMeditationDays: Int {
        let cal   = Calendar.current
        let days  = Set(meditationDays.map { cal.startOfDay(for: $0.date) })
        return days.count
    }

    // MARK: Current streak
    var currentStreak: Int {
        let cal  = Calendar.current
        let days = Set(meditationDays.map { cal.startOfDay(for: $0.date) }).sorted(by: >)
        guard !days.isEmpty else { return 0 }
        var streak = 0
        var check  = cal.startOfDay(for: Date())
        // If no entry today, allow streak to continue from yesterday
        if !days.contains(check) {
            check = cal.date(byAdding: .day, value: -1, to: check)!
        }
        for day in days {
            if day == check {
                streak += 1
                check = cal.date(byAdding: .day, value: -1, to: check)!
            } else {
                break
            }
        }
        return streak
    }

    // MARK: 30-day challenge progress
    var challengeProgress: Int { min(uniqueMeditationDays, 30) }

    // MARK: Calendar days for challenge grid (last 30)
    func meditatedOn(_ date: Date) -> Bool {
        let cal = Calendar.current
        return meditationDays.contains { cal.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - Log a completed session
    func logMeditation(duration: Int) {
        let entry = MeditationDay(date: Date(), duration: duration)
        meditationDays.append(entry)
        // Auto-advance challenge if not already marked today
        if !challengeMarkedToday {
            markedChallengeIndices.insert(totalChallengeDays)
            UserDefaults.standard.set(Date(), forKey: "lastChallengeMarkDate")
        }
        save()
    }

    // MARK: - Toggle a day manually from the challenge grid
    func toggleDay(_ date: Date) {
        let cal = Calendar.current
        if meditatedOn(date) {
            meditationDays.removeAll { cal.isDate($0.date, inSameDayAs: date) }
        } else {
            meditationDays.append(MeditationDay(date: date, duration: 0))
        }
        save()
    }

    // MARK: - Mood
    func addMoodEntry(_ entry: MoodEntry) {
        moodEntries.insert(entry, at: 0)
        deduplicateMoodEntries()
        save()
    }

    private func deduplicateMoodEntries() {
        let cal = Calendar.current
        var seen = Set<Date>()
        moodEntries = moodEntries.filter { entry in
            let day = cal.startOfDay(for: entry.date)
            return seen.insert(day).inserted
        }
    }

    func moodEntries(for period: JournalPeriod) -> [MoodEntry] {
        let cutoff = period.cutoffDate
        return moodEntries.filter { $0.date >= cutoff }
    }

    var averageMood: Double {
        guard !moodEntries.isEmpty else { return 0 }
        return Double(moodEntries.map(\.mood).reduce(0, +)) / Double(moodEntries.count)
    }

    // MARK: - Sleep
    func addSleepEntry(_ entry: SleepEntry) {
        var e = entry
        e.hours = e.computedHours   // persist computed duration for charts
        sleepEntries.insert(e, at: 0)
        deduplicateSleepEntries()
        save()
    }

    private func deduplicateSleepEntries() {
        let cal = Calendar.current
        var seen = Set<Date>()
        sleepEntries = sleepEntries.filter { entry in
            let day = cal.startOfDay(for: entry.date)
            return seen.insert(day).inserted
        }
    }

    func sleepEntries(for period: JournalPeriod) -> [SleepEntry] {
        let cutoff = period.cutoffDate
        return sleepEntries.filter { $0.date >= cutoff }
    }

    // MARK: - Persistence
    private func save() {
        if let d = try? JSONEncoder().encode(meditationDays)              { UserDefaults.standard.set(d, forKey: "meditationDays") }
        if let d = try? JSONEncoder().encode(moodEntries)                 { UserDefaults.standard.set(d, forKey: "moodEntries") }
        if let d = try? JSONEncoder().encode(sleepEntries)                { UserDefaults.standard.set(d, forKey: "sleepEntries") }
        if let d = try? JSONEncoder().encode(Array(markedChallengeIndices)) { UserDefaults.standard.set(d, forKey: "challengeIndices") }
        if let d = try? JSONEncoder().encode(gratitudeEntries)            { UserDefaults.standard.set(d, forKey: "gratitudeEntries") }
        writeWidgetData()
    }

    // MARK: - Widget Data (shared via App Group)
    private static let widgetGroupID = "group.com.serenebreathing.app"

    func writeWidgetData() {
        let shared = UserDefaults(suiteName: Self.widgetGroupID) ?? UserDefaults.standard
        shared.set(currentStreak, forKey: "widgetStreak")
        shared.set(totalMindfulMinutes, forKey: "widgetMindfulMinutes")
        shared.set(hasMoodEntryToday, forKey: "widgetCheckedInToday")
    }

    init() {
        if let d = UserDefaults.standard.data(forKey: "meditationDays"),
           let v = try? JSONDecoder().decode([MeditationDay].self, from: d) { meditationDays = v }
        if let d = UserDefaults.standard.data(forKey: "moodEntries"),
           let v = try? JSONDecoder().decode([MoodEntry].self, from: d)     { moodEntries = v }
        if let d = UserDefaults.standard.data(forKey: "sleepEntries"),
           let v = try? JSONDecoder().decode([SleepEntry].self, from: d)    { sleepEntries = v }
        if let d = UserDefaults.standard.data(forKey: "challengeIndices"),
           let v = try? JSONDecoder().decode([Int].self, from: d)           { markedChallengeIndices = Set(v) }
        if let d = UserDefaults.standard.data(forKey: "gratitudeEntries"),
           let v = try? JSONDecoder().decode([GratitudeEntry].self, from: d) { gratitudeEntries = v }
        // Clean up any duplicates from before the one-per-day rule was enforced
        deduplicateMoodEntries()
        deduplicateSleepEntries()
        writeWidgetData()
    }
}

// MARK: - Badge System

enum MeditationBadge: CaseIterable {
    case star, gold, platinum, diamond, legend

    var requiredDays: Int {
        switch self {
        case .star:     return 30
        case .gold:     return 60
        case .platinum: return 90
        case .diamond:  return 180
        case .legend:   return 365
        }
    }

    var title: String {
        switch self {
        case .star:     return "Star"
        case .gold:     return "Gold"
        case .platinum: return "Platinum"
        case .diamond:  return "Diamond"
        case .legend:   return "Legend"
        }
    }

    var emoji: String {
        switch self {
        case .star:     return "⭐"
        case .gold:     return "🥇"
        case .platinum: return "🪙"
        case .diamond:  return "💎"
        case .legend:   return "👑"
        }
    }

    var color: Color {
        switch self {
        case .star:     return Color(red: 1.00, green: 0.85, blue: 0.30)
        case .gold:     return Color(red: 1.00, green: 0.65, blue: 0.10)
        case .platinum: return Color(red: 0.75, green: 0.85, blue: 0.95)
        case .diamond:  return Color(red: 0.45, green: 0.90, blue: 1.00)
        case .legend:   return Color(red: 0.85, green: 0.55, blue: 1.00)
        }
    }

    var description: String {
        switch self {
        case .star:     return "30 days of meditation"
        case .gold:     return "60 days of meditation"
        case .platinum: return "90 days of meditation"
        case .diamond:  return "180 days of meditation"
        case .legend:   return "365 days of meditation"
        }
    }
}

extension JournalStore {
    var earnedBadges: [MeditationBadge] {
        MeditationBadge.allCases.filter { totalChallengeDays >= $0.requiredDays }
    }

    var currentBadge: MeditationBadge? {
        earnedBadges.last
    }

    var nextBadge: MeditationBadge? {
        MeditationBadge.allCases.first { totalChallengeDays < $0.requiredDays }
    }

    var daysToNextBadge: Int {
        guard let next = nextBadge else { return 0 }
        return next.requiredDays - totalChallengeDays
    }

    // MARK: - Milestone Badges

    var totalMindfulMinutes: Int {
        meditationDays.reduce(0) { $0 + $1.duration }
    }

    var sleepStreak: Int {
        let cal  = Calendar.current
        let days = sleepEntries.map { cal.startOfDay(for: $0.date) }
        let unique = Array(Set(days)).sorted(by: >)
        guard !unique.isEmpty else { return 0 }
        var streak = 0
        var check  = cal.startOfDay(for: Date())
        if !unique.contains(check) {
            check = cal.date(byAdding: .day, value: -1, to: check)!
        }
        for day in unique {
            if day == check {
                streak += 1
                check = cal.date(byAdding: .day, value: -1, to: check)!
            } else { break }
        }
        return streak
    }

    var earnedMilestoneBadges: [MilestoneBadge] {
        MilestoneBadge.allCases.filter { badge in
            switch badge {
            case .mindfulMinutes100:  return totalMindfulMinutes >= 100
            case .mindfulMinutes500:  return totalMindfulMinutes >= 500
            case .sleepStreak7:       return sleepStreak >= 7
            case .sleepStreak30:      return sleepStreak >= 30
            }
        }
    }
}

// MARK: - Milestone Badge

enum MilestoneBadge: CaseIterable {
    case mindfulMinutes100, mindfulMinutes500
    case sleepStreak7, sleepStreak30

    var emoji: String {
        switch self {
        case .mindfulMinutes100: return "⏱️"
        case .mindfulMinutes500: return "🧘"
        case .sleepStreak7:      return "🌙"
        case .sleepStreak30:     return "💤"
        }
    }

    var title: String {
        switch self {
        case .mindfulMinutes100: return "100 Mindful Minutes"
        case .mindfulMinutes500: return "500 Mindful Minutes"
        case .sleepStreak7:      return "7-Day Sleep Streak"
        case .sleepStreak30:     return "30-Day Sleep Streak"
        }
    }

    var description: String {
        switch self {
        case .mindfulMinutes100: return "You've logged 100 minutes of mindfulness"
        case .mindfulMinutes500: return "500 minutes of peace — incredible dedication"
        case .sleepStreak7:      return "7 days of tracking your sleep in a row"
        case .sleepStreak30:     return "30 nights of consistent sleep tracking"
        }
    }

    var color: Color {
        switch self {
        case .mindfulMinutes100: return Color(red: 0.40, green: 0.85, blue: 0.75)
        case .mindfulMinutes500: return Color(red: 0.30, green: 0.70, blue: 1.00)
        case .sleepStreak7:      return Color(red: 0.65, green: 0.50, blue: 1.00)
        case .sleepStreak30:     return Color(red: 0.85, green: 0.55, blue: 1.00)
        }
    }
}

// MARK: - Gratitude

struct GratitudeEntry: Codable, Identifiable {
    let id:   UUID
    let date: Date
    let text: String
    init(text: String) { id = UUID(); date = Date(); self.text = text }
}

extension JournalStore {
    var gratitudeEntryToday: Bool {
        gratitudeEntries.first.map { Calendar.current.isDateInToday($0.date) } ?? false
    }
    func addGratitudeEntry(_ text: String) {
        gratitudeEntries.insert(GratitudeEntry(text: text), at: 0)
        save()
    }
}

// MARK: - Period Filter

enum JournalPeriod: String, CaseIterable {
    case week  = "1 Week"
    case month = "1 Month"
    case year  = "1 Year"

    var cutoffDate: Date {
        let cal = Calendar.current
        switch self {
        case .week:  return cal.date(byAdding: .day,   value: -7,   to: Date())!
        case .month: return cal.date(byAdding: .month, value: -1,   to: Date())!
        case .year:  return cal.date(byAdding: .year,  value: -1,   to: Date())!
        }
    }
}

// MARK: - Mood Helpers

extension Int {
    var moodLabel: String {
        switch self {
        case 1: return "Angry"
        case 2: return "Sad"
        case 3: return "Stressed"
        case 4: return "Neutral"
        case 5: return "Relaxed"
        case 6: return "Happy"
        case 7: return "Grateful"
        default: return ""
        }
    }
    var moodEmoji: String {
        switch self {
        case 1: return "😠"
        case 2: return "😢"
        case 3: return "😤"
        case 4: return "😐"
        case 5: return "😌"
        case 6: return "😊"
        case 7: return "🙏"
        default: return ""
        }
    }
    var moodColor: Color {
        switch self {
        case 1: return Color(red: 0.95, green: 0.30, blue: 0.30)
        case 2: return Color(red: 0.45, green: 0.65, blue: 0.95)
        case 3: return Color(red: 0.95, green: 0.60, blue: 0.25)
        case 4: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 5: return Color(red: 0.35, green: 0.85, blue: 0.75)
        case 6: return Color(red: 1.00, green: 0.80, blue: 0.25)
        case 7: return Color(red: 0.75, green: 0.55, blue: 1.00)
        default: return .white
        }
    }
}
