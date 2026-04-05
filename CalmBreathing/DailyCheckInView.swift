import SwiftUI

// MARK: - Daily Check-In View
struct DailyCheckInView: View {
    @EnvironmentObject var journal: JournalStore
    @EnvironmentObject var premium: PremiumStore
    @Environment(\.dismiss) private var dismiss

    // Mood
    @State private var selectedMood: Int = 0

    // Sleep
    @State private var sleepQuality: Int = 3
    @State private var bedtime: Date  = {
        if let saved = UserDefaults.standard.object(forKey: "lastBedtime") as? Date { return saved }
        return Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date()) ?? Date()
    }()
    @State private var wakeTime: Date = {
        if let saved = UserDefaults.standard.object(forKey: "lastWakeTime") as? Date { return saved }
        return Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    @State private var dreamType: Int = 0

    // Optional
    @State private var selectedTags: [String] = []
    @State private var showOptional = false
    @State private var showMoodAlert = false
    @State private var moodNote = ""

    // AI
    @State private var fullResponse  = ""
    @State private var insight       = ""
    @State private var technique     = ""
    @State private var reason        = ""
    @State private var isGenerating  = false
    @State private var errorText: String?
    @State private var saved         = false

    // Auto coach
    @State private var coachMessage     = ""
    @State private var isLoadingCoach   = false
    @State private var lastCoachedMood  = 0

    // Coach chat
    @State private var showCoachChat = false

    // Session launch
    @State private var showMorning   = false
    @State private var showBodyScan  = false
    @State private var showBreath    = false
    @State private var showPersonal  = false
    @State private var showSounds    = false
    @State private var showSleepMed  = false

    private let allTags = ["Breathing", "Meditation", "Walk", "Music", "Rest", "Talk", "Exercise"]
    private let dreamOptions = ["No Dreams", "Light Dreams", "Vivid Dreams"]
    private let dreamIcons   = ["moon.zzz.fill", "moon.stars.fill", "sparkles"]

    private var computedHours: Double {
        var diff = wakeTime.timeIntervalSince(bedtime)
        if diff < 0 { diff += 86400 }
        return diff / 3600
    }

    private var canGenerate: Bool { selectedMood > 0 }

    // Morning briefing based on most recent sleep entry (today or yesterday)
    private var morningBriefing: (icon: String, color: Color, message: String)? {
        guard let last = journal.sleepEntries.first else { return nil }
        let daysSince = Calendar.current.dateComponents([.day], from: last.date, to: Date()).day ?? 999
        guard daysSince <= 1 else { return nil }
        let hrs = last.computedHours
        let q   = last.quality
        if q <= 2 || hrs < 6 {
            return (
                "moon.zzz.fill",
                Color(red: 0.55, green: 0.50, blue: 0.90),
                "Your sleep was a bit light last night. I've suggested a gentle 5-minute Morning Meditation below to help you start softly."
            )
        } else if q >= 4 && hrs >= 7 {
            return (
                "sun.max.fill",
                Color(red: 1.0, green: 0.80, blue: 0.35),
                "You slept well last night! Great energy ahead. I've recommended a Morning Meditation to set a positive intention for today."
            )
        }
        return nil
    }

    var body: some View {
        ZStack {
            CalmBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Header
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        Spacer()
                        Text("Daily Check-In")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Color.clear.frame(width: 32, height: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Morning Briefing (shown when recent sleep data exists)
                    if let briefing = morningBriefing {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: briefing.icon)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(briefing.color)
                                Text("MORNING BRIEFING")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(briefing.color)
                                    .tracking(1.0)
                            }
                            Text(briefing.message)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.calmDeep)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                            Button {
                                showMorning = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 11))
                                    Text("Open Morning Meditation")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(briefing.color)
                                .padding(.top, 2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(briefing.color.opacity(0.10))
                                .overlay(RoundedRectangle(cornerRadius: 16)
                                    .stroke(briefing.color.opacity(0.25), lineWidth: 1))
                        )
                        .padding(.horizontal, 20)
                    }

                    // SECTION 1 — Mood
                    sectionCard {
                        VStack(spacing: 14) {
                            sectionHeader(icon: "face.smiling", title: "HOW ARE YOU FEELING?")

                            HStack(spacing: 0) {
                                ForEach(1...7, id: \.self) { level in
                                    Button {
                                        withAnimation(.spring(response: 0.3)) { selectedMood = level }
                                        if level <= 3 && level != lastCoachedMood { fetchCoachMessage(for: level) }
                                        else if level > 3 { coachMessage = ""; isLoadingCoach = false }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(level.moodEmoji)
                                                .font(.system(size: selectedMood == level ? 32 : 24))
                                                .scaleEffect(selectedMood == level ? 1.15 : 1.0)
                                            if selectedMood == level {
                                                Circle()
                                                    .fill(level.moodColor)
                                                    .frame(width: 5, height: 5)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .contentShape(Rectangle())
                                        .animation(.spring(response: 0.3), value: selectedMood)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if selectedMood > 0 {
                                Text(selectedMood.moodLabel)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(selectedMood.moodColor)
                                    .transition(.opacity)
                            }

                            // Auto AI coach card for stressed/anxious moods
                            if selectedMood > 0 && selectedMood <= 3 {
                                Button { showCoachChat = true } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 11))
                                                .foregroundColor(.calmAccent)
                                            Text("SERENE COACH")
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundColor(.calmAccent)
                                                .tracking(1.0)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.calmAccent.opacity(0.70))
                                        }
                                        if isLoadingCoach {
                                            HStack(spacing: 8) {
                                                ProgressView().tint(.calmAccent).scaleEffect(0.7)
                                                Text("Here for you…")
                                                    .font(.system(size: 13, weight: .regular))
                                                    .foregroundColor(.calmMid)
                                            }
                                        } else if !coachMessage.isEmpty {
                                            Text(coachMessage)
                                                .font(.system(size: 13, weight: .regular))
                                                .foregroundColor(.calmDeep)
                                                .lineSpacing(4)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .transition(.opacity)
                                        }
                                        Text("Tap to chat with Serene")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.calmAccent.opacity(0.70))
                                    }
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.calmAccent.opacity(0.10))
                                            .overlay(RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.calmAccent.opacity(0.25), lineWidth: 1))
                                    )
                                }
                                .buttonStyle(.plain)
                                .transition(.opacity)
                            }
                        }
                    }

                    // SECTION 2 — Sleep
                    sectionCard {
                        VStack(spacing: 14) {
                            sectionHeader(icon: "moon.stars.fill", title: "HOW DID YOU SLEEP?")

                            // Quality
                            HStack(spacing: 10) {
                                ForEach(1...5, id: \.self) { level in
                                    Button { sleepQuality = level } label: {
                                        Image(systemName: level <= sleepQuality ? "star.fill" : "star")
                                            .font(.system(size: 24))
                                            .foregroundColor(level <= sleepQuality ? Color(red: 1.0, green: 0.80, blue: 0.25) : .calmMid.opacity(0.25))
                                            .frame(maxWidth: .infinity, minHeight: 44)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Divider().background(Color.black.opacity(0.08))

                            // Time pickers
                            HStack {
                                Image(systemName: "moon.fill")
                                    .foregroundColor(Color(red: 0.55, green: 0.50, blue: 0.90))
                                    .frame(width: 20)
                                Text("Bedtime")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.calmDeep)
                                Spacer()
                                DatePicker("", selection: $bedtime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .colorScheme(.light)
                                    .onChange(of: bedtime) { _, v in
                                        UserDefaults.standard.set(v, forKey: "lastBedtime")
                                    }
                            }

                            HStack {
                                Image(systemName: "sun.rise.fill")
                                    .foregroundColor(Color(red: 1.0, green: 0.80, blue: 0.35))
                                    .frame(width: 20)
                                Text("Wake time")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.calmDeep)
                                Spacer()
                                DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .colorScheme(.light)
                                    .onChange(of: wakeTime) { _, v in
                                        UserDefaults.standard.set(v, forKey: "lastWakeTime")
                                    }
                            }

                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.calmAccent)
                                    .frame(width: 20)
                                Text("Total sleep")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.calmDeep)
                                Spacer()
                                Text(String(format: "%.1f hrs", computedHours))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.calmAccent)
                            }

                            // Dream log
                            Divider().background(Color.black.opacity(0.08))
                            HStack(spacing: 8) {
                                ForEach(0..<3, id: \.self) { i in
                                    Button { dreamType = i } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: dreamIcons[i])
                                                .font(.system(size: 16))
                                                .foregroundColor(dreamType == i ? .calmDeep : .calmMid)
                                            Text(dreamOptions[i])
                                                .font(.system(size: 10))
                                                .foregroundColor(dreamType == i ? .calmDeep : .calmMid)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(RoundedRectangle(cornerRadius: 10)
                                            .fill(dreamType == i ? Color.calmAccent : Color(red: 0.82, green: 0.85, blue: 0.95).opacity(0.80)))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // SECTION 3 — Optional (What helped)
                    sectionCard {
                        VStack(spacing: 12) {
                            Button {
                                withAnimation { showOptional.toggle() }
                            } label: {
                                HStack {
                                    sectionHeader(icon: "plus.circle.fill", title: "WHAT HELPED? (OPTIONAL)")
                                    Spacer()
                                    Image(systemName: showOptional ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(.calmMid.opacity(0.70))
                                }
                            }
                            .buttonStyle(.plain)

                            if showOptional {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 88))], spacing: 8) {
                                    ForEach(allTags, id: \.self) { tag in
                                        let selected = selectedTags.contains(tag)
                                        Button {
                                            if selected { selectedTags.removeAll { $0 == tag } }
                                            else        { selectedTags.append(tag) }
                                        } label: {
                                            Text(tag)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(selected ? .calmDeep : .calmDeep)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(Capsule().fill(selected ? Color.white : Color(red: 0.82, green: 0.85, blue: 0.95).opacity(0.80)))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .transition(.opacity)
                            }
                        }
                    }

                    // Error
                    if let err = errorText {
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // Generate button / Insight card
                    if insight.isEmpty {
                        Button {
                            if selectedMood == 0 {
                                showMoodAlert = true
                            } else {
                                saveAndGenerate()
                            }
                        } label: {
                            Group {
                                if isGenerating {
                                    HStack(spacing: 10) {
                                        ProgressView().tint(.calmDeep)
                                        Text("Getting your insight…")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(.calmDeep)
                                    }
                                } else {
                                    Label("Get My Insight", systemImage: "sparkles")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.calmDeep)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(canGenerate ? Color.calmAccent : Color.white.opacity(0.20))
                                .shadow(color: canGenerate ? .calmAccent.opacity(0.35) : .clear, radius: 10))
                        }
                        .disabled(isGenerating)
                        .padding(.horizontal, 24)
                    } else {
                        insightCard
                    }

                    DisclaimerFooter().padding(.bottom, 40)
                }
            }
        }
        .alert("Select Your Mood", isPresented: $showMoodAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please select how you're feeling before getting your insight.")
        }
        .fullScreenCover(isPresented: $showCoachChat) { CoachChatView().environmentObject(journal).environmentObject(premium) }
        .fullScreenCover(isPresented: $showMorning)  { MorningMeditationView().environmentObject(journal) }
        .fullScreenCover(isPresented: $showBodyScan) { BodyScanView().environmentObject(journal) }
        .fullScreenCover(isPresented: $showBreath)   { BreathingView() }
        .fullScreenCover(isPresented: $showPersonal) { PersonalizedMeditationView().environmentObject(premium) }
        .fullScreenCover(isPresented: $showSounds)   { RelaxingSoundsView() }
        .fullScreenCover(isPresented: $showSleepMed) { SleepMeditationView().environmentObject(journal) }
    }

    // MARK: - Insight Card
    private var insightCard: some View {
        VStack(spacing: 16) {
            // Saved badge
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.calmAccent)
                Text("Logged to your journal")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.calmMid)
            }

            // Insight text
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(.calmAccent)
                    Text("YOUR INSIGHT")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.calmAccent)
                        .tracking(1.0)
                }

                Text(insight)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.calmDeep)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                if !technique.isEmpty {
                    Divider().background(Color.black.opacity(0.08))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("RECOMMENDED FOR YOU")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.calmMid)
                            .tracking(1.0)
                        Text(technique)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.calmDeep)
                        if !reason.isEmpty {
                            Text(reason)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.calmMid)
                                .lineSpacing(4)
                        }
                        Button {
                            launchSession(technique)
                        } label: {
                            Label("Open \(technique)", systemImage: "play.fill")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.calmDeep)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(Color.calmAccent).shadow(color: .calmAccent.opacity(0.35), radius: 8))
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.85))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.calmAccent.opacity(0.25), lineWidth: 1))
            )
            .padding(.horizontal, 24)

            Button { dismiss() } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.calmMid)
                    .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Helpers
    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.85)))
            .padding(.horizontal, 20)
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.calmDeep)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.calmDeep)
                .tracking(1.0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Auto Coach
    private func fetchCoachMessage(for level: Int) {
        lastCoachedMood = level
        coachMessage    = ""
        isLoadingCoach  = true
        Task {
            do {
                for try await chunk in MoodCoachService.stream(mood: level.moodLabel) {
                    await MainActor.run { coachMessage += chunk }
                }
                await MainActor.run { isLoadingCoach = false }
            } catch {
                await MainActor.run { isLoadingCoach = false }
            }
        }
    }

    // MARK: - Save & Generate
    private func saveAndGenerate() {
        // Persist bedtime/wake for next open
        UserDefaults.standard.set(bedtime, forKey: "lastBedtime")
        UserDefaults.standard.set(wakeTime, forKey: "lastWakeTime")
        // Save mood
        journal.addMoodEntry(MoodEntry(mood: selectedMood, tags: selectedTags, source: "daily-checkin"))
        // Save sleep
        journal.addSleepEntry(SleepEntry(quality: sleepQuality, note: "",
                                          bedtime: bedtime, wakeTime: wakeTime,
                                          dreamType: dreamType, dreamNote: ""))
        saved = true
        errorText = nil
        isGenerating = true

        let dreamLabel = ["no dreams", "light dreams", "vivid dreams"][dreamType]
        let tagText = selectedTags.isEmpty ? "nothing specific" : selectedTags.joined(separator: ", ")
        let summary = """
        Mood: \(selectedMood.moodLabel) (\(selectedMood)/7)
        Sleep quality: \(sleepQuality)/5
        Sleep duration: \(String(format: "%.1f", computedHours)) hours
        Dreams: \(dreamLabel)
        What helped today: \(tagText)
        """

        Task {
            do {
                for try await chunk in DailyCheckInService.stream(summary) {
                    await MainActor.run { fullResponse += chunk }
                }
                await MainActor.run {
                    parseResponse(fullResponse)
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    errorText = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }

    private func parseResponse(_ text: String) {
        let opts: String.CompareOptions = [.caseInsensitive]
        if let r = text.range(of: "INSIGHT:", options: opts) {
            // skip optional space after colon
            var start = r.upperBound
            if start < text.endIndex && text[start] == " " { start = text.index(after: start) }
            let after = String(text[start...])
            if let end = after.range(of: "TECHNIQUE:", options: opts) {
                insight = String(after[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                insight = after.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        if let r = text.range(of: "TECHNIQUE:", options: opts) {
            var start = r.upperBound
            if start < text.endIndex && text[start] == " " { start = text.index(after: start) }
            let after = String(text[start...])
            technique = (after.components(separatedBy: "\n").first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let r = text.range(of: "REASON:", options: opts) {
            var start = r.upperBound
            if start < text.endIndex && text[start] == " " { start = text.index(after: start) }
            let after = String(text[start...])
            reason = (after.components(separatedBy: "\n").first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if insight.isEmpty { insight = text.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private func launchSession(_ name: String) {
        let lower = name.lowercased()
        if lower.contains("morning")    { showMorning   = true }
        else if lower.contains("body")  { showBodyScan  = true }
        else if lower.contains("4-7-8") || lower.contains("breathing") { showBreath = true }
        else if lower.contains("box")   { showBreath    = true }
        else if lower.contains("personal") { showPersonal = true }
        else if lower.contains("sound") { showSounds    = true }
        else if lower.contains("sleep") { showSleepMed  = true }
        else                            { showMorning   = true }
    }
}
