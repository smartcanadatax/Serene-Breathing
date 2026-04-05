import SwiftUI
import Charts

// MARK: - Progress Tab
struct ProgressTabView: View {
    @EnvironmentObject var journal:  JournalStore
    @EnvironmentObject var premium:  PremiumStore

    enum Section: String, CaseIterable {
        case challenge = "Challenge"
        case mood      = "Mood"
        case sleep     = "Sleep"
        case gratitude = "Gratitude"
    }

    @State private var section: Section = .challenge
    @State private var showPaywall = false
    @State private var showGratitude = false
    @State private var showDailyPrompt = false
    @AppStorage("lastDailyPromptDate") private var lastPromptDateString = ""

    var body: some View {
        ZStack {
            CalmBackground()

            VStack(spacing: 0) {
                // Segment picker
                Picker("", selection: $section) {
                    ForEach(Section.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 4)

                ScrollView(showsIndicators: false) {
                    switch section {
                    case .challenge: ChallengeSection()
                    case .mood:      MoodSection()
                    case .sleep:     SleepSection()
                    case .gratitude: GratitudeSectionView(showJournal: $showGratitude)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Progress")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if !premium.isPremium {
                    Button { showPaywall = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill").font(.system(size: 11))
                            Text("Premium").font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.calmDeep)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Capsule().fill(Color.calmAccent))
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall).environmentObject(premium)
        }
        .fullScreenCover(isPresented: $showGratitude) {
            GratitudeJournalView().environmentObject(journal)
        }
        .sheet(isPresented: $showDailyPrompt) {
            DailyJournalPromptSheet()
                .environmentObject(journal)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            let today = Calendar.current.startOfDay(for: Date())
            let todayStr = ISO8601DateFormatter().string(from: today)
            guard todayStr != lastPromptDateString else { return }
            if !journal.hasMoodEntryToday || !journal.hasSleepEntryToday {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showDailyPrompt = true
                    lastPromptDateString = todayStr
                }
            }
        }
    }
}

// MARK: - Daily Journal Prompt Sheet
private struct DailyJournalPromptSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var journal: JournalStore

    @State private var selectedMood: Int = 0
    @State private var sleepQuality: Int = 3
    @State private var moodDone = false
    @State private var sleepDone = false

    var body: some View {
        ZStack {
            Color(red: 0.13, green: 0.10, blue: 0.22).ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Daily Check-In")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Track your mood and sleep to see patterns over time.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.70))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.top, 8)

                // Mood
                if !journal.hasMoodEntryToday {
                    VStack(spacing: 10) {
                        Text("How are you feeling today?")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        HStack(spacing: 6) {
                            ForEach([1,2,3,5,6], id: \.self) { level in
                                Button {
                                    selectedMood = level
                                    journal.addMoodEntry(MoodEntry(mood: level, source: "daily-prompt"))
                                    withAnimation { moodDone = true }
                                } label: {
                                    Text(level.moodEmoji)
                                        .font(.system(size: 30))
                                        .frame(minWidth: 44, minHeight: 44)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .opacity(moodDone ? (selectedMood == level ? 1 : 0.35) : 1)
                            }
                        }
                        if moodDone {
                            Label("Mood saved", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.calmAccent)
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.07)))
                    .padding(.horizontal, 20)
                }

                // Sleep
                if !journal.hasSleepEntryToday {
                    VStack(spacing: 10) {
                        Text("How did you sleep last night?")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { q in
                                Button {
                                    sleepQuality = q
                                    journal.addSleepEntry(SleepEntry(quality: q, note: "", bedtime: nil, wakeTime: nil, dreamType: 0, dreamNote: ""))
                                    withAnimation { sleepDone = true }
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: q <= sleepQuality ? "star.fill" : "star")
                                            .font(.system(size: 22))
                                            .foregroundColor(q <= sleepQuality ? .calmAccent : .white.opacity(0.30))
                                    }
                                    .frame(minWidth: 44, minHeight: 44)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .disabled(sleepDone)
                            }
                        }
                        if sleepDone {
                            Label("Sleep saved", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.calmAccent)
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.07)))
                    .padding(.horizontal, 20)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.calmDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.calmAccent))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - Challenge Section
struct ChallengeSection: View {
    @EnvironmentObject var journal: JournalStore
    @State private var showAlreadyMarked = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    // Which badge are we working toward?
    private var nextBadge: MeditationBadge? { journal.nextBadge }

    // Days completed before this tier started
    private var tierStart: Int {
        MeditationBadge.allCases.last(where: { journal.totalChallengeDays >= $0.requiredDays })?.requiredDays ?? 0
    }
    // Total days needed for this tier (e.g. 30, 60, 90…)
    private var tierEnd: Int   { nextBadge?.requiredDays ?? (tierStart + 30) }
    private var tierSize: Int  { tierEnd - tierStart }
    private var doneInTier: Int {
        journal.markedChallengeIndices.filter { $0 >= tierStart && $0 < tierEnd }.count
    }
    private var tierPct: Double { tierSize > 0 ? min(1.0, Double(doneInTier) / Double(tierSize)) : 1.0 }
    private var challengeTitle: String {
        if let b = nextBadge { return "\(b.emoji) Road to \(b.title) — \(tierEnd) Days" }
        return "👑 Legend — All Challenges Complete!"
    }

    var body: some View {
        VStack(spacing: 20) {
            // Stats row
            let quoteGradient = LinearGradient(
                colors: [Color(red: 0.52, green: 0.30, blue: 0.80), Color(red: 0.68, green: 0.44, blue: 0.80)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            HStack(spacing: 12) {
                StatCard(value: "\(journal.currentStreak)",       label: "Day Streak",  icon: "flame.fill",         color: .white, gradient: quoteGradient)
                StatCard(value: "\(doneInTier)/\(tierSize)",      label: "This Level",  icon: "checkmark.seal.fill",color: .white, gradient: quoteGradient)
                StatCard(value: "\(journal.totalChallengeDays)",  label: "Total Days",  icon: "calendar",           color: .white, gradient: quoteGradient)
            }

            // Share streak
            if journal.currentStreak > 0 {
                let shareText = "🧘 I've meditated for \(journal.currentStreak) day\(journal.currentStreak == 1 ? "" : "s") in a row with Serene Breathing. Building calm one breath at a time. 🌿"
                ShareLink(item: shareText) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13))
                        Text("Share your \(journal.currentStreak)-day streak")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(Color(red: 0.10, green: 0.22, blue: 0.42))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(Color(red: 0.87, green: 0.89, blue: 0.96)))
                }
            }

            // Numbered 1–N grid for current tier
            JournalCard(title: challengeTitle, icon: "calendar.badge.clock") {
                VStack(spacing: 10) {
                    // Progress bar
                    VStack(spacing: 6) {
                        HStack {
                            Text("\(doneInTier) of \(tierSize) days completed")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                            Spacer()
                            Text("\(Int(tierPct * 100))%")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.calmAccent)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.10)).frame(height: 6)
                                Capsule()
                                    .fill(LinearGradient(colors: [.calmAccent, .calmTeal],
                                                         startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * CGFloat(tierPct), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }

                    // Tappable numbered boxes — tap any box to mark/unmark a day
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(1...max(1, tierSize), id: \.self) { dayNum in
                            let globalIndex = tierStart + dayNum - 1
                            let filled  = journal.markedChallengeIndices.contains(globalIndex)
                            let current = !filled && globalIndex == journal.totalChallengeDays
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(filled  ? Color.calmAccent.opacity(0.85)
                                                  : Color(red: 0.87, green: 0.89, blue: 0.96))
                                    .frame(height: 34)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(current ? Color.calmAccent : Color.clear, lineWidth: 1.5)
                                    )
                                if filled {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.calmDeep)
                                } else {
                                    Text("\(dayNum)")
                                        .font(.system(size: 11, weight: current ? .semibold : .regular))
                                        .foregroundColor(current ? Color(red: 0.541, green: 0.357, blue: 0.804) : Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.45))
                                }
                            }
                            .onTapGesture {
                                if filled {
                                    // Always allow unmark
                                    journal.toggleChallengeIndex(globalIndex)
                                } else if journal.challengeMarkedToday {
                                    // Block second mark on same day
                                    showAlreadyMarked = true
                                } else {
                                    journal.toggleChallengeIndex(globalIndex)
                                }
                            }
                        }
                    }

                    if showAlreadyMarked {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 14))
                            Text("You've already marked a day today. Come back tomorrow.")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                showAlreadyMarked = false
                            }
                        }
                    }

                    // Log today button (marks next challenge day, once per day)
                    let markedToday = journal.challengeMarkedToday
                    Button {
                        if !markedToday { journal.markChallengeDay() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: markedToday ? "checkmark.circle.fill" : "plus.circle.fill")
                            Text(markedToday ? "Logged today ✓" : "Log today's meditation")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(markedToday ? .calmTeal : .calmDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(markedToday
                            ? Color.calmTeal.opacity(0.15)
                            : Color.calmAccent))
                    }
                    .disabled(markedToday)
                    .padding(.top, 4)
                }
            }

            // MARK: Badges earned
            if !journal.earnedBadges.isEmpty {
                JournalCard(title: "Your Badges", icon: "rosette") {
                    VStack(spacing: 12) {
                        // Current badge hero
                        if let badge = journal.currentBadge {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(badge.color.opacity(0.20))
                                        .frame(width: 64, height: 64)
                                    Text(badge.emoji).font(.system(size: 34))
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(badge.title)
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        .foregroundColor(badge.color)
                                    Text(badge.description)
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.70))
                                }
                                Spacer()
                            }
                            .padding(.bottom, 4)
                        }

                        // All badge progression
                        HStack(spacing: 0) {
                            ForEach(MeditationBadge.allCases, id: \.title) { badge in
                                let earned = journal.totalChallengeDays >= badge.requiredDays
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(earned ? badge.color.opacity(0.22) : Color(red: 0.541, green: 0.357, blue: 0.804).opacity(0.08))
                                            .frame(width: 44, height: 44)
                                        Text(badge.emoji)
                                            .font(.system(size: earned ? 22 : 18))
                                            .opacity(earned ? 1.0 : 0.25)
                                    }
                                    Text(badge.title)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(earned ? badge.color : Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.30))
                                    Text("\(badge.requiredDays)d")
                                        .font(.system(size: 8))
                                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.55))
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }

            // MARK: Milestone Badges
            JournalCard(title: "Milestone Badges", icon: "medal.fill") {
                VStack(spacing: 10) {
                    ForEach(MilestoneBadge.allCases, id: \.title) { badge in
                        let earned = journal.earnedMilestoneBadges.contains { $0.title == badge.title }
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(earned ? badge.color.opacity(0.22) : Color(red: 0.541, green: 0.357, blue: 0.804).opacity(0.08))
                                    .frame(width: 48, height: 48)
                                Text(badge.emoji)
                                    .font(.system(size: 24))
                                    .opacity(earned ? 1.0 : 0.20)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(badge.title)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(earned ? badge.color : Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.30))
                                Text(badge.description)
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(earned ? Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.65) : Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.30))
                            }
                            Spacer()
                            if earned {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(badge.color)
                                    .font(.system(size: 18))
                            }
                        }
                        if badge.title != MilestoneBadge.allCases.last?.title {
                            Divider().background(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.10))
                        }
                    }
                }
            }

            // Next badge progress
            if let next = journal.nextBadge {
                JournalCard(title: "Next Badge", icon: "target",
                            bgColor: Color(red: 0.74, green: 0.64, blue: 0.91),
                            headerColor: Color(red: 0.541, green: 0.357, blue: 0.804)) {
                    HStack(spacing: 14) {
                        Text(next.emoji).font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(next.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(next.color)
                                Spacer()
                                Text("\(journal.daysToNextBadge) days to go")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.65))
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.10)).frame(height: 6)
                                    let prev = MeditationBadge.allCases.last { journal.totalChallengeDays > $0.requiredDays }
                                    let from = Double(prev?.requiredDays ?? 0)
                                    let to   = Double(next.requiredDays)
                                    let pct  = min(1.0, (Double(journal.totalChallengeDays) - from) / (to - from))
                                    Capsule()
                                        .fill(LinearGradient(colors: [next.color.opacity(0.80), next.color], startPoint: .leading, endPoint: .trailing))
                                        .frame(width: geo.size.width * pct, height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }

            // Motivation message
            if journal.currentStreak > 0 {
                JournalCard(title: "Keep Going", icon: "star.fill") {
                    Text(streakMessage)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                        .lineSpacing(4)
                }
            }

            disclaimerText("This challenge tracker is for personal motivation only. It is not a medical or therapeutic programme.")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 36)
    }

    private var streakMessage: String {
        switch journal.currentStreak {
        case 1:       return "Great start — you've begun your journey. Come back tomorrow to build your streak."
        case 2..<7:   return "You're building momentum! \(journal.currentStreak) days in a row. Keep it going."
        case 7..<14:  return "One full week! Your mind is growing stronger with every session."
        case 14..<30: return "Incredible — \(journal.currentStreak) days straight. You're forming a real habit."
        case 30..<60: return "30 days complete! You've earned your Star badge. Now push for Gold — keep going!"
        case 60..<90: return "60 days! Gold meditator. Platinum is within reach — just \(90 - journal.currentStreak) more days."
        case 90..<180: return "90 days — Platinum achieved! You're now in the top tier of dedicated meditators."
        case 180..<365: return "180 days! Diamond meditator. The legendary 365-day crown is your next goal."
        default:      return "365 days! You are a Legend. Your dedication to mindfulness is truly inspiring."
        }
    }
}

// MARK: - Mood Section
struct MoodSection: View {
    @EnvironmentObject var journal: JournalStore
    @EnvironmentObject var premium: PremiumStore
    @State private var period:       JournalPeriod   = .week
    @State private var showingEntry  = false
    @State private var selectedMood  = 3
    @State private var moodNote      = ""
    @State private var selectedTags: [String] = []
    @State private var showPaywall   = false

    var body: some View {
        VStack(spacing: 20) {
            // Log mood button
            if journal.hasMoodEntryToday {
                Button { showingEntry = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 16))
                        Text("Mood logged today — tap to update")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.75))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Capsule().fill(Color(red: 0.87, green: 0.89, blue: 0.96)).shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2))
                }
                .buttonStyle(.plain)
            } else {
                Button { showingEntry = true } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill").font(.system(size: 18))
                        Text("Log How You Feel Now")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.calmDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Capsule().fill(Color.calmAccent).shadow(color: .calmAccent.opacity(0.35), radius: 10))
                }
                .buttonStyle(.plain)
            }

            // Period picker — premium only
            if premium.isPremium {
                Picker("", selection: $period) {
                    ForEach(JournalPeriod.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            } else {
                // Upsell banner
                Button { showPaywall = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "crown.fill").font(.system(size: 14)).foregroundColor(.calmAccent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Showing last 7 days")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Upgrade to view full history & trends")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.70))
                        }
                        Spacer()
                        Text("Unlock")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.calmDeep)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.calmAccent))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.calmAccent.opacity(0.30), lineWidth: 1)))
                }
                .buttonStyle(.plain)
            }

            let entries = premium.isPremium
                ? journal.moodEntries(for: period)
                : journal.moodEntries(for: .week)

            if entries.isEmpty {
                EmptyJournalView(message: "No mood entries yet.\nLog how you feel after each meditation.")
            } else {
                // Average mood card
                let avg = entries.map(\.mood).reduce(0, +)
                let avgVal = Double(avg) / Double(entries.count)
                let avgInt = Int(avgVal.rounded())

                JournalCard(title: "Average Mood", icon: "chart.line.uptrend.xyaxis",
                            headerColor: .white.opacity(0.80),
                            bgGradient: LinearGradient(colors: [Color(red: 0.52, green: 0.30, blue: 0.80), Color(red: 0.68, green: 0.44, blue: 0.80)], startPoint: .topLeading, endPoint: .bottomTrailing)) {
                    HStack(spacing: 16) {
                        Text(avgInt.moodEmoji).font(.system(size: 44))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(avgInt.moodLabel)
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                            Text(String(format: "%.1f / 7.0 across \(entries.count) entries", avgVal))
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white.opacity(0.75))
                        }
                        Spacer()
                    }
                }

                // Weekly mood trend line chart
                JournalCard(title: "Mood Trend", icon: "chart.line.uptrend.xyaxis",
                            bgColor: Color(red: 0.88, green: 0.82, blue: 0.97)) {
                    MoodTrendChart(entries: entries)
                }

                // Mood bar chart
                JournalCard(title: "Mood Distribution", icon: "chart.bar.fill") {
                    VStack(spacing: 8) {
                        ForEach(1...7, id: \.self) { level in
                            let count  = entries.filter { $0.mood == level }.count
                            let pct    = entries.isEmpty ? 0.0 : Double(count) / Double(entries.count)
                            MoodBarRow(level: level, count: count, percent: pct)
                        }
                    }
                }

                // Recent entries list
                JournalCard(title: "Recent Entries", icon: "list.bullet") {
                    VStack(spacing: 10) {
                        ForEach(entries.prefix(10)) { entry in
                            HStack(alignment: .top, spacing: 12) {
                                Text(entry.mood.moodEmoji).font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(entry.mood.moodLabel)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                                        if entry.source == "post-session" {
                                            Text("after session")
                                                .font(.system(size: 10, weight: .regular))
                                                .foregroundColor(.calmAccent.opacity(0.80))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Capsule().fill(Color.calmAccent.opacity(0.12)))
                                        }
                                    }
                                    Text(entry.date, style: .date)
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.50))
                                    if !entry.tags.isEmpty {
                                        HStack(spacing: 4) {
                                            ForEach(entry.tags, id: \.self) { tag in
                                                Text(tag)
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.55))
                                                    .padding(.horizontal, 7)
                                                    .padding(.vertical, 3)
                                                    .background(Capsule().fill(Color(red: 0.541, green: 0.357, blue: 0.804).opacity(0.08)))
                                            }
                                        }
                                    }
                                }
                                Spacer()
                            }
                            if entry.id != entries.prefix(10).last?.id {
                                Divider().background(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.10))
                            }
                        }
                    }
                }
            }

            // Supportive card for latest mood
            if let latest = journal.moodEntries.first {
                JournalCard(title: "Latest Check-In", icon: "heart.fill",
                            bgColor: Color(red: 0.74, green: 0.64, blue: 0.91),
                            headerColor: .white.opacity(0.90)) {
                    HStack(alignment: .top, spacing: 12) {
                        Text(latest.mood.moodEmoji).font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 6) {
                            Text(latest.mood.moodLabel)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(latest.mood.moodColor)
                            Text(supportiveMessage(for: latest.mood))
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.70))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            disclaimerText("The Mood Journal is for personal reflection only. It is not a diagnostic tool. If you are experiencing persistent low mood, please speak to a healthcare professional.")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 36)
        .sheet(isPresented: $showingEntry) {
            MoodEntrySheet(selectedMood: $selectedMood, note: $moodNote, selectedTags: $selectedTags) {
                journal.addMoodEntry(MoodEntry(mood: selectedMood, note: moodNote, tags: selectedTags))
                moodNote = ""
                selectedTags = []
                showingEntry = false
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall).environmentObject(premium)
        }
    }
}

// MARK: - Sleep Section
struct SleepSection: View {
    @EnvironmentObject var journal: JournalStore
    @EnvironmentObject var premium: PremiumStore
    @State private var period      = JournalPeriod.week
    @State private var showingEntry = false
    @State private var showPaywall  = false
    @State private var quality      = 3
    @State private var hours        = 7.0
    @State private var sleepNote    = ""
    @State private var bedtime: Date  = {
        Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date()) ?? Date()
    }()
    @State private var wakeTime: Date = {
        Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    @State private var dreamType    = 0
    @State private var dreamNote    = ""

    var body: some View {
        VStack(spacing: 20) {
            if !premium.isPremium {
                // Locked state
                VStack(spacing: 16) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.40))
                    Text("Sleep Journal is Premium")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Track your sleep quality, hours, and patterns over time.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                    Button { showPaywall = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill").font(.system(size: 13))
                            Text("Unlock Premium")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.calmDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Capsule().fill(Color.calmAccent).shadow(color: .calmAccent.opacity(0.35), radius: 10))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 40)
                .fullScreenCover(isPresented: $showPaywall) {
                    PaywallView(isPresented: $showPaywall).environmentObject(premium)
                }
            } else {
                if journal.hasSleepEntryToday {
                    Button { showingEntry = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 16))
                            Text("Sleep logged today — tap to update")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Capsule().fill(Color(red: 0.87, green: 0.89, blue: 0.96)).shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button { showingEntry = true } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill").font(.system(size: 18))
                            Text("Log Last Night's Sleep")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.calmDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Capsule().fill(Color.calmAccent).shadow(color: .calmAccent.opacity(0.35), radius: 10))
                    }
                    .buttonStyle(.plain)
                }

                Picker("", selection: $period) {
                    ForEach(JournalPeriod.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                let entries = journal.sleepEntries(for: period)

                if entries.isEmpty {
                    EmptyJournalView(message: "No sleep entries yet.\nLog your sleep each morning.")
                } else {
                    let avgQuality = Double(entries.map(\.quality).reduce(0, +)) / Double(entries.count)
                    let avgHours   = entries.map(\.hours).reduce(0, +) / Double(entries.count)

                    let sleepGradient = LinearGradient(
                        colors: [Color(red: 0.52, green: 0.30, blue: 0.80), Color(red: 0.68, green: 0.44, blue: 0.80)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    HStack(spacing: 12) {
                        StatCard(value: String(format: "%.1f", avgHours), label: "Avg Hours", icon: "moon.fill", color: .white, gradient: sleepGradient)
                        StatCard(value: String(format: "%.1f/5", avgQuality), label: "Avg Quality", icon: "star.fill", color: .white, gradient: sleepGradient)
                        StatCard(value: "\(entries.count)", label: "Entries", icon: "calendar", color: .white, gradient: sleepGradient)
                    }

                    // Sleep trend chart
                    JournalCard(title: "Sleep Trend", icon: "moon.fill",
                                bgColor: Color(red: 0.88, green: 0.82, blue: 0.97)) {
                        SleepTrendChart(entries: entries)
                    }

                    // Sleep insight
                    let insight = sleepInsight(avgHours: avgHours, avgQuality: avgQuality)
                    JournalCard(title: insight.title, icon: "lightbulb.fill") {
                        HStack(alignment: .top, spacing: 12) {
                            Text(insight.emoji).font(.system(size: 28))
                            Text(insight.message)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Sleep tips
                    JournalCard(title: "Sleep Tips", icon: "moon.stars.fill",
                                bgColor: Color(red: 0.74, green: 0.64, blue: 0.91),
                                headerColor: Color(red: 0.541, green: 0.357, blue: 0.804)) {
                        VStack(alignment: .leading, spacing: 12) {
                            let tipColor = Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.75)
                            SleepTipRow(emoji: "🧘", tip: "Meditate for 10 minutes before bed to calm your nervous system", textColor: tipColor)
                            SleepTipRow(emoji: "📱", tip: "Avoid screens for 30 minutes before sleep to reduce blue light exposure", textColor: tipColor)
                            SleepTipRow(emoji: "⏰", tip: "Go to bed and wake up at the same time every day — even weekends", textColor: tipColor)
                            SleepTipRow(emoji: "🌡️", tip: "Keep your room cool and comfortable for deeper, more restorative sleep", textColor: tipColor)
                            SleepTipRow(emoji: "🎵", tip: "Play a calming sound from the Sounds tab as you drift off", textColor: tipColor)
                        }
                    }

                    JournalCard(title: "Sleep Log", icon: "list.bullet") {
                        VStack(spacing: 10) {
                            ForEach(entries.prefix(10)) { entry in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(sleepQualityColor(entry.quality).opacity(0.20)).frame(width: 38, height: 38)
                                        Text("\(entry.quality)★")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(sleepQualityColor(entry.quality))
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 8) {
                                            Text(String(format: "%.1f hrs", entry.hours))
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                                            if entry.dreamType > 0 {
                                                Text(entry.dreamType == 1 ? "Light dreams" : "Vivid dreams")
                                                    .font(.system(size: 10, weight: .regular))
                                                    .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.65))
                                                    .padding(.horizontal, 7)
                                                    .padding(.vertical, 2)
                                                    .background(Capsule().fill(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.08)))
                                            }
                                        }
                                        Text(entry.date, style: .date)
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.55))
                                    }
                                    Spacer()
                                }
                                if entry.id != entries.prefix(10).last?.id {
                                    Divider().background(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.10))
                                }
                            }
                        }
                    }
                }

            disclaimerText("The Sleep Journal is for personal reflection only and is not a medical sleep study or clinical tool. If you have sleep concerns, please consult a healthcare professional.")
            } // end premium else
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 36)
        .sheet(isPresented: $showingEntry) {
            SleepEntrySheet(quality: $quality, hours: $hours, note: $sleepNote,
                            bedtime: $bedtime, wakeTime: $wakeTime,
                            dreamType: $dreamType, dreamNote: $dreamNote) {
                journal.addSleepEntry(SleepEntry(quality: quality, note: sleepNote,
                                                  bedtime: bedtime, wakeTime: wakeTime,
                                                  dreamType: dreamType, dreamNote: dreamNote))
                sleepNote = ""
                dreamNote = ""
                dreamType = 0
                showingEntry = false
            }
        }
    }
}

// MARK: - Mood Entry Sheet
// MARK: - Sleep helpers
func sleepQualityEmoji(_ q: Int) -> String {
    switch q {
    case 1: return "😴"
    case 2: return "🥱"
    case 3: return "😑"
    case 4: return "🌙"
    case 5: return "⭐"
    default: return "🌙"
    }
}

func sleepQualityColor(_ q: Int) -> Color {
    switch q {
    case 1: return Color(red: 0.90, green: 0.35, blue: 0.35)
    case 2: return Color(red: 0.95, green: 0.60, blue: 0.30)
    case 3: return Color(red: 0.541, green: 0.357, blue: 0.804)
    case 4: return Color(red: 0.45, green: 0.75, blue: 0.95)
    case 5: return Color(red: 0.65, green: 0.85, blue: 0.55)
    default: return .white
    }
}

func sleepQualityMessage(_ q: Int) -> String {
    switch q {
    case 1: return "Poor sleep is tough, but you're here and aware — that's the first step. Try a short body scan meditation tonight before bed and aim to sleep and wake at the same time each day."
    case 2: return "A restless night can leave you feeling drained. Be gentle with yourself today. Even a short breathing session can restore some of that energy."
    case 3: return "Average sleep is a starting point. Your meditation habit is already working in your favour — consistent practice often leads to deeper, more restorative sleep over time."
    case 4: return "Good sleep is the foundation of a healthy mind. Your body is recovering well. Keep your evening routine consistent and you may find it gets even better."
    case 5: return "Excellent sleep! Your mind and body are well rested. Research shows that regular meditation is linked to deeper sleep — your practice is clearly paying off."
    default: return ""
    }
}


func sleepInsight(avgHours: Double, avgQuality: Double) -> (emoji: String, title: String, message: String) {
    switch (avgHours, avgQuality) {
    case (_, _) where avgHours < 6 && avgQuality < 3:
        return ("⚠️", "Your sleep needs attention", "You're getting less than 6 hours with low quality sleep. This can affect mood, focus and wellbeing. Try meditating before bed and setting a consistent sleep time.")
    case (_, _) where avgHours < 6:
        return ("⏰", "You need more sleep", "You're averaging under 6 hours. Most adults need 7–9 hours for full recovery. A calming sound session before bed may help you wind down earlier.")
    case (_, _) where avgQuality < 3:
        return ("🌊", "Improve your sleep quality", "Your sleep hours are okay but quality is low. Try a body scan or breathing exercise before bed to calm your nervous system.")
    case (_, _) where avgHours >= 7 && avgQuality >= 4:
        return ("✨", "Your sleep is thriving", "Excellent sleep patterns! You're getting good hours and high quality rest. Your meditation practice is clearly supporting deep, restorative sleep.")
    case (_, _) where avgQuality >= 4:
        return ("🌙", "Great sleep quality", "Your sleep quality is high — well done. Keeping a consistent bedtime and continuing your meditation practice will maintain this.")
    default:
        return ("💤", "Building good habits", "You're on the right track. Consistent meditation, reduced screen time before bed and a regular sleep schedule will improve your rest over time.")
    }
}

// MARK: - Shared mood helpers (used in ProgressView + MeditationTimerView)
func supportiveMessage(for mood: Int) -> String {
    switch mood {
    case 1: return "Anger is a natural emotion and it's okay to feel it. Take a slow breath — you don't have to act on it. Let this moment of stillness help you find your ground again."
    case 2: return "It's okay to feel sad. You don't have to fix it right now. Be kind to yourself today — you showed up, and that matters more than you know."
    case 3: return "Anxiety can feel overwhelming, but you are safe right now. Each breath you take is bringing calm back into your body. You've got through hard moments before — you'll get through this too."
    case 4: return "A steady, neutral mind is a good place to be. Not every day needs to be extraordinary. You're present, and that's enough."
    case 5: return "You're feeling relaxed — let that feeling sink in deeply. Your mind and body deserve this peace. Carry this calmness with you into the rest of your day."
    case 6: return "Happiness looks good on you. Savour this feeling — let it fill you up completely. Joy shared is joy multiplied, so spread a little of this warmth today."
    case 7: return "Gratitude is one of the most powerful things you can feel. When you notice what is good, more good finds its way to you. Hold onto this feeling — it is a gift."
    default: return ""
    }
}

struct MoodEntrySheet: View {
    @Binding var selectedMood: Int
    @Binding var note: String
    @Binding var selectedTags: [String]
    let onSave: () -> Void

    private let allTags = ["Breathing", "Meditation", "Walk", "Music", "Rest", "Talk", "Exercise"]

    var body: some View {
        NavigationStack {
            ZStack {
                CalmBackground()
                VStack(spacing: 28) {
                    Text("How are you feeling?")
                        .font(.system(size: 22, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 16)

                    // Mood selector — 4 top + 3 bottom
                    let topMoods    = Array(1...4)
                    let bottomMoods = Array(5...7)

                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            ForEach(topMoods, id: \.self) { level in
                                MoodButton(level: level, selected: selectedMood == level) { selectedMood = level }
                            }
                        }
                        HStack(spacing: 8) {
                            Spacer()
                            ForEach(bottomMoods, id: \.self) { level in
                                MoodButton(level: level, selected: selectedMood == level) { selectedMood = level }
                                    .frame(maxWidth: .infinity)
                            }
                            Spacer()
                        }
                    }

                    // Message for every mood
                    HStack(alignment: .top, spacing: 12) {
                        Text(selectedMood.moodEmoji).font(.system(size: 22))
                        Text(supportiveMessage(for: selectedMood))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.82))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(selectedMood.moodColor.opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedMood.moodColor.opacity(0.25), lineWidth: 1))
                    )
                    .animation(.easeInOut(duration: 0.25), value: selectedMood)

                    // What helped tags
                    VStack(alignment: .leading, spacing: 10) {
                        Text("WHAT HELPED TODAY?")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))
                            .tracking(1.0)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 8) {
                            ForEach(allTags, id: \.self) { tag in
                                let selected = selectedTags.contains(tag)
                                Button {
                                    if selected { selectedTags.removeAll { $0 == tag } }
                                    else        { selectedTags.append(tag) }
                                } label: {
                                    Text(tag)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(selected ? .calmDeep : .white.opacity(0.80))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule().fill(selected ? Color.white : Color.white.opacity(0.08))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Optional note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add a note (optional)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.90))
                            .tracking(1.0)
                        TextField("How was your session?", text: $note)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
                    }

                    Button(action: onSave) {
                        Text("Save Entry")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.calmDeep)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color.calmAccent))
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Mood Journal")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Sleep Entry Sheet
struct SleepEntrySheet: View {
    @Binding var quality:   Int
    @Binding var hours:     Double
    @Binding var note:      String
    @Binding var bedtime:   Date
    @Binding var wakeTime:  Date
    @Binding var dreamType: Int
    @Binding var dreamNote: String
    let onSave: () -> Void

    private var computedHours: Double {
        var diff = wakeTime.timeIntervalSince(bedtime)
        if diff < 0 { diff += 86400 }
        return diff / 3600
    }

    private let dreamOptions = ["No Dreams", "Light Dreams", "Vivid Dreams"]
    private let dreamIcons   = ["moon.zzz.fill", "moon.stars.fill", "sparkles"]

    var body: some View {
        NavigationStack {
            ZStack {
                CalmBackground()
                VStack(spacing: 24) {
                    Text("How did you sleep?")
                        .font(.system(size: 22, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 16)

                    // Bedtime + wake time pickers
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(Color(red: 0.55, green: 0.50, blue: 0.90))
                                .frame(width: 20)
                            Text("Bedtime")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white)
                            Spacer()
                            DatePicker("", selection: $bedtime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                        Divider().background(Color.white.opacity(0.10))
                        HStack {
                            Image(systemName: "sun.rise.fill")
                                .foregroundColor(Color(red: 1.0, green: 0.80, blue: 0.35))
                                .frame(width: 20)
                            Text("Wake time")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white)
                            Spacer()
                            DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                        Divider().background(Color.white.opacity(0.10))
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.calmAccent)
                                .frame(width: 20)
                            Text("Total sleep")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white)
                            Spacer()
                            Text(String(format: "%.1f hrs", computedHours))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.calmAccent)
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.07)))

                    // Quality picker
                    VStack(spacing: 10) {
                        Text("Sleep quality")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.90))
                            .tracking(1.0)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { level in
                                Button { quality = level } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: level <= quality ? "star.fill" : "star")
                                            .font(.system(size: 22))
                                            .foregroundColor(level <= quality ? Color(red: 1.0, green: 0.80, blue: 0.25) : .white.opacity(0.25))
                                        Text("\(level)")
                                            .font(.system(size: 10))
                                            .foregroundColor(.white.opacity(0.90))
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.07)))

                    // Message based on quality
                    HStack(alignment: .top, spacing: 12) {
                        Text(sleepQualityEmoji(quality)).font(.system(size: 22))
                        Text(sleepQualityMessage(quality))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.82))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(sleepQualityColor(quality).opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(sleepQualityColor(quality).opacity(0.28), lineWidth: 1))
                    )
                    .animation(.easeInOut(duration: 0.25), value: quality)

                    // Dream log
                    VStack(alignment: .leading, spacing: 10) {
                        Text("DREAM LOG")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))
                            .tracking(1.0)
                        HStack(spacing: 10) {
                            ForEach(0..<3, id: \.self) { i in
                                Button { dreamType = i } label: {
                                    VStack(spacing: 5) {
                                        Image(systemName: dreamIcons[i])
                                            .font(.system(size: 18))
                                            .foregroundColor(dreamType == i ? .calmDeep : .white.opacity(0.60))
                                        Text(dreamOptions[i])
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(dreamType == i ? .calmDeep : .white.opacity(0.60))
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(RoundedRectangle(cornerRadius: 12)
                                        .fill(dreamType == i ? Color.calmAccent : Color.white.opacity(0.08)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if dreamType > 0 {
                            TextField("Describe your dream (optional)", text: $dreamNote)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                        }
                    }

                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.90))
                            .tracking(1.0)
                        TextField("Dreams, disturbances, thoughts...", text: $note)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
                    }

                    Button(action: onSave) {
                        Text("Save Entry")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.calmDeep)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color.calmAccent))
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Sleep Journal")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Reusable Components

// MARK: - Mood Button
struct SleepTipRow: View {
    let emoji: String
    let tip:   String
    var textColor: Color = .white.opacity(0.72)
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(emoji).font(.system(size: 16))
            Text(tip)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(textColor)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct MoodButton: View {
    let level:    Int
    let selected: Bool
    let action:   () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(level.moodEmoji).font(.system(size: 26))
                Text(level.moodLabel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(selected ? level.moodColor : .white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? level.moodColor.opacity(0.18) : Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(selected ? level.moodColor.opacity(0.55) : Color.clear, lineWidth: 1.5))
            )
        }
        .buttonStyle(.plain)
    }
}

struct JournalCard<Content: View>: View {
    let title:   String
    let icon:    String
    var bgColor: Color = Color(red: 0.87, green: 0.89, blue: 0.96)
    var headerColor: Color = Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.60)
    var bgGradient: LinearGradient? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(headerColor)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(headerColor)
                    .tracking(1.2)
            }
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Group {
                if let gradient = bgGradient {
                    RoundedRectangle(cornerRadius: 18).fill(gradient)
                } else {
                    RoundedRectangle(cornerRadius: 18).fill(bgColor)
                }
            }
        )
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon:  String
    let color: Color
    var bgColor:    Color = Color(red: 0.87, green: 0.89, blue: 0.96)
    var valueColor: Color = Color(red: 0.10, green: 0.10, blue: 0.12)
    var labelColor: Color = Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.60)
    var gradient:   LinearGradient? = nil

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(gradient != nil ? .white.opacity(0.90) : color)
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(gradient != nil ? .white : valueColor)
            Text(label)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(gradient != nil ? .white.opacity(0.75) : labelColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(gradient.map { AnyShapeStyle($0) } ?? AnyShapeStyle(bgColor))
        )
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

struct MoodBarRow: View {
    let level:   Int
    let count:   Int
    let percent: Double

    var body: some View {
        HStack(spacing: 10) {
            Text(level.moodEmoji).font(.system(size: 16)).frame(width: 24)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.10)).frame(height: 8)
                    Capsule()
                        .fill(Color(red: 0.541, green: 0.357, blue: 0.804).opacity(0.80))
                        .frame(width: max(4, geo.size.width * percent), height: 8)
                }
            }
            .frame(height: 8)
            Text("\(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                .frame(width: 24, alignment: .trailing)
        }
    }
}

struct EmptyJournalView: View {
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray").font(.system(size: 32)).foregroundColor(.white.opacity(0.85))
            Text(message)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.90))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}

// MARK: - Mood Trend Chart
struct MoodTrendChart: View {
    let entries: [MoodEntry]

    private struct DayMood: Identifiable {
        let id = UUID()
        let date: Date
        let avg: Double
    }

    private var dailyAverages: [DayMood] {
        let cal = Calendar.current
        var grouped: [Date: [MoodEntry]] = [:]
        for entry in entries {
            let day = cal.startOfDay(for: entry.date)
            grouped[day, default: []].append(entry)
        }
        let mapped: [DayMood] = grouped.map { date, items in
            let sum = items.map(\.mood).reduce(0, +)
            let avg = Double(sum) / Double(items.count)
            return DayMood(date: date, avg: avg)
        }
        return Array(mapped.sorted { $0.date < $1.date }.suffix(7))
    }

    var body: some View {
        if dailyAverages.count < 2 {
            VStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.25))
                Text("Log your mood daily to see your trend")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        } else {
            let avgLine = dailyAverages.map(\.avg).reduce(0, +) / Double(dailyAverages.count)
            Chart {
                ForEach(dailyAverages) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Mood", day.avg)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.55, green: 0.50, blue: 0.95),
                                Color(red: 0.35, green: 0.30, blue: 0.75)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                }
                RuleMark(y: .value("Avg", avgLine))
                    .foregroundStyle(Color.white.opacity(0.40))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("avg")
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(.white.opacity(0.40))
                    }
            }
            .chartYScale(domain: 0...7)
            .chartYAxis {
                AxisMarks(values: [1, 3, 5, 7]) { val in
                    AxisValueLabel {
                        if let v = val.as(Int.self) {
                            Text(v.moodEmoji).font(.system(size: 10))
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.10))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .foregroundStyle(Color.white.opacity(0.60))
                }
            }
            .frame(height: 140)
        }
    }
}

// MARK: - Sleep Trend Chart
struct SleepTrendChart: View {
    let entries: [SleepEntry]

    private struct DaySleep: Identifiable {
        let id = UUID()
        let date: Date
        let avgHours: Double
        let avgQuality: Double
    }

    private var dailyAverages: [DaySleep] {
        let cal = Calendar.current
        var grouped: [Date: [SleepEntry]] = [:]
        for entry in entries {
            let day = cal.startOfDay(for: entry.date)
            grouped[day, default: []].append(entry)
        }
        let mapped: [DaySleep] = grouped.map { date, items in
            let avgH = items.map(\.hours).reduce(0, +) / Double(items.count)
            let avgQ = Double(items.map(\.quality).reduce(0, +)) / Double(items.count)
            return DaySleep(date: date, avgHours: avgH, avgQuality: avgQ)
        }
        return Array(mapped.sorted { $0.date < $1.date }.suffix(7))
    }

    var body: some View {
        if dailyAverages.count < 2 {
            VStack(spacing: 8) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.25))
                Text("Log your sleep daily to see your trend")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        } else {
            let avgLine = dailyAverages.map(\.avgHours).reduce(0, +) / Double(dailyAverages.count)
            Chart {
                ForEach(dailyAverages) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Hours", day.avgHours)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.55, green: 0.50, blue: 0.95),
                                Color(red: 0.35, green: 0.30, blue: 0.75)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                }
                RuleMark(y: .value("Avg", avgLine))
                    .foregroundStyle(Color.white.opacity(0.40))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("avg")
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(.white.opacity(0.40))
                    }
            }
            .chartYScale(domain: 0...12)
            .chartYAxis {
                AxisMarks(values: [0, 4, 6, 8, 10]) { val in
                    AxisValueLabel {
                        if let v = val.as(Int.self) {
                            Text("\(v)h")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.10))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .foregroundStyle(Color.white.opacity(0.60))
                }
            }
            .frame(height: 140)
        }
    }
}

private func disclaimerText(_ text: String) -> some View {
    HStack(spacing: 6) {
        Image(systemName: "info.circle")
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.88))
        Text(text)
            .font(.caption2)
            .foregroundColor(.white.opacity(0.88))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.top, 4)
}

// MARK: - Gratitude Section
struct GratitudeSectionView: View {
    @EnvironmentObject var journal: JournalStore
    @Binding var showJournal: Bool

    var body: some View {
        VStack(spacing: 16) {

            // Open journal button
            Button { showJournal = true } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Color(red: 0.541, green: 0.357, blue: 0.804).opacity(0.12)).frame(width: 52, height: 52)
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(red: 0.541, green: 0.357, blue: 0.804))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gratitude Journal")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                        Text(journal.gratitudeEntryToday ? "Logged today ✓" : "Write today's entry")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.55))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.35))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(red: 0.87, green: 0.89, blue: 0.96))
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
                )
            }
            .buttonStyle(.plain)

            // Privacy notice
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.40))
                Text("Journal entries are stored privately on your device.")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.40))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)

            // Streak
            JournalCard(title: "Gratitude Streak", icon: "flame.fill",
                        bgColor: Color(red: 0.74, green: 0.64, blue: 0.91),
                        headerColor: Color(red: 0.50, green: 0.42, blue: 0.70)) {
                let streak = gratitudeStreak
                VStack(spacing: 6) {
                    Text("\(streak)")
                        .font(.system(size: 48, weight: .regular, design: .rounded))
                        .foregroundColor(Color(red: 0.40, green: 0.30, blue: 0.65))
                    Text(streak == 1 ? "day in a row" : "days in a row")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(red: 0.40, green: 0.30, blue: 0.65).opacity(0.70))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // Recent entries
            if !journal.gratitudeEntries.isEmpty {
                JournalCard(title: "Recent Entries", icon: "list.bullet") {
                    VStack(spacing: 10) {
                        ForEach(journal.gratitudeEntries.prefix(5)) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.date, style: .date)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Color(red: 0.50, green: 0.42, blue: 0.70))
                                ForEach(entry.text.components(separatedBy: "\n").filter { !$0.isEmpty }, id: \.self) { line in
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("•").foregroundColor(Color(red: 0.40, green: 0.30, blue: 0.65).opacity(0.40)).font(.system(size: 12))
                                        Text(line)
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.80))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            if entry.id != journal.gratitudeEntries.prefix(5).last?.id {
                                Divider().background(Color(red: 0.40, green: 0.30, blue: 0.65).opacity(0.15))
                            }
                        }
                    }
                }
            }

            DisclaimerFooter().padding(.bottom, 32)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var gratitudeStreak: Int {
        let cal = Calendar.current
        let days = journal.gratitudeEntries.map { cal.startOfDay(for: $0.date) }
        let unique = Array(Set(days)).sorted(by: >)
        guard !unique.isEmpty else { return 0 }
        var streak = 0
        var check = cal.startOfDay(for: Date())
        if !unique.contains(check) { check = cal.date(byAdding: .day, value: -1, to: check)! }
        for day in unique {
            if day == check { streak += 1; check = cal.date(byAdding: .day, value: -1, to: check)! }
            else { break }
        }
        return streak
    }
}
