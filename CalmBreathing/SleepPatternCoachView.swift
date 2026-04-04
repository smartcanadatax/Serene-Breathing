import SwiftUI

// MARK: - Sleep Pattern Coach

struct SleepPatternCoachView: View {

    @EnvironmentObject var journal: JournalStore
    @Environment(\.dismiss) private var dismiss

    @State private var showSleepLog = false
    @State private var sleepQuality = 3
    @State private var sleepHours   = 7.0
    @State private var sleepNote    = ""
    @State private var sleepBedtime: Date  = {
        Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date()) ?? Date()
    }()
    @State private var sleepWakeTime: Date = {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: tomorrow) ?? Date()
    }()
    @State private var sleepDreamType = 0
    @State private var sleepDreamNote = ""
    @State private var fullResponse = ""
    @State private var insight      = ""
    @State private var technique    = ""
    @State private var script       = ""
    @State private var isGenerating  = false
    @State private var showSession   = false
    @State private var errorText:    String?
    @State private var showSleepMed  = false
    @State private var showBreathing = false
    @State private var showMorning   = false
    @State private var showBodyScan  = false

    private var recentSleep: [SleepEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        return journal.sleepEntries.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
    }

    private var hasSufficientData: Bool { recentSleep.count >= 7 }

    private var avgHours: Double {
        guard !recentSleep.isEmpty else { return 0 }
        return recentSleep.map(\.hours).reduce(0, +) / Double(recentSleep.count)
    }

    private var avgQuality: Double {
        guard !recentSleep.isEmpty else { return 0 }
        return Double(recentSleep.map(\.quality).reduce(0, +)) / Double(recentSleep.count)
    }

    var body: some View {
        ZStack {
            CalmBackground()
            if showSession {
                sessionView
            } else {
                inputView
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSleepLog) {
            SleepEntrySheet(quality: $sleepQuality, hours: $sleepHours, note: $sleepNote,
                            bedtime: $sleepBedtime, wakeTime: $sleepWakeTime,
                            dreamType: $sleepDreamType, dreamNote: $sleepDreamNote) {
                journal.addSleepEntry(SleepEntry(quality: sleepQuality, note: sleepNote,
                                                  bedtime: sleepBedtime, wakeTime: sleepWakeTime,
                                                  dreamType: sleepDreamType, dreamNote: sleepDreamNote))
                sleepNote = ""
                sleepDreamNote = ""
                sleepDreamType = 0
                showSleepLog = false
            }
            .environmentObject(journal)
        }
    }

    // MARK: - Input View

    private var inputView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                HStack {
                    Button { dismiss() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.calmDeep)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Header
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 80, height: 80)
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 34))
                            .foregroundColor(.calmDeep)
                    }
                    Text("Sleep Pattern Coach")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundColor(.calmDeep)
                    Text("I analyze your last 7 nights of sleep data and suggest the best guided session from the app to help you sleep better.")
                        .font(.system(size: 14))
                        .foregroundColor(.calmMid)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                // Sleep trend card
                if !recentSleep.isEmpty {
                    sleepTrendCard
                }

                // Not enough data
                if !hasSufficientData {
                    VStack(spacing: 12) {
                        Image(systemName: "moon.zzz")
                            .font(.system(size: 28))
                            .foregroundColor(.calmMid)
                        Text("Log your sleep for at least 7 nights to unlock your personalized sleep pattern analysis. \(max(0, 7 - recentSleep.count)) more night\(max(0, 7 - recentSleep.count) == 1 ? "" : "s") to go.")
                            .font(.system(size: 13))
                            .foregroundColor(.calmDeep.opacity(0.80))
                            .multilineTextAlignment(.center)
                        if journal.hasSleepEntryToday {
                            Label("Sleep logged today", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.calmAccent)
                        } else {
                            Button { showSleepLog = true } label: {
                                Label("Log Last Night's Sleep", systemImage: "plus.circle.fill")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.calmDeep)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(Color.calmAccent))
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.85)))
                    .padding(.horizontal, 24)
                }

                if let err = errorText {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(.calmDeep)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.25)))
                        .padding(.horizontal, 24)
                }

                Button { Task { await generate() } } label: {
                    HStack(spacing: 10) {
                        if isGenerating {
                            ProgressView().tint(.calmDeep)
                            Text("Analyzing your sleep…")
                        } else {
                            Image(systemName: "sparkles")
                            Text("Analyze My Sleep")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.calmDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(
                        hasSufficientData ? Color.calmAccent : Color.calmAccent.opacity(0.45)
                    ))
                }
                .disabled(!hasSufficientData || isGenerating)
                .padding(.horizontal, 24)

                DisclaimerFooter().padding(.bottom, 16)
            }
        }
    }

    // MARK: - Sleep Trend Card

    private var sleepTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Last \(recentSleep.count) Nights")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.calmDeep)
                Spacer()
            }

            // Sleep hours bar chart
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(recentSleep.suffix(14)) { entry in
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(qualityColor(entry.quality).opacity(0.85))
                            .frame(width: 14, height: CGFloat(entry.hours) * 8)
                        Text(String(format: "%.0f", entry.hours))
                            .font(.system(size: 7))
                            .foregroundColor(.calmMid)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                Label(String(format: "%.1fh avg", avgHours), systemImage: "clock.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.calmMid)
                Label(String(format: "%.1f/5 quality", avgQuality), systemImage: "star.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.calmMid)
                if avgHours < 7 {
                    Label("Low sleep", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.20))
                }
            }

            // Quality legend
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { q in
                    HStack(spacing: 3) {
                        Circle().fill(qualityColor(q)).frame(width: 8, height: 8)
                        Text(qualityLabel(q))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.calmMid)
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.85)))
        .padding(.horizontal, 24)
    }

    private func qualityColor(_ q: Int) -> Color {
        switch q {
        case 1: return Color(red: 0.95, green: 0.30, blue: 0.30)
        case 2: return Color(red: 0.95, green: 0.60, blue: 0.25)
        case 3: return Color(red: 1.00, green: 0.85, blue: 0.30)
        case 4: return Color(red: 0.35, green: 0.85, blue: 0.75)
        case 5: return Color(red: 0.45, green: 0.90, blue: 1.00)
        default: return .white
        }
    }

    private func qualityLabel(_ q: Int) -> String {
        switch q {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "OK"
        case 4: return "Good"
        case 5: return "Great"
        default: return ""
        }
    }

    // MARK: - Session View

    private var sessionView: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    showSession = false
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.calmDeep)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    if !insight.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Sleep Pattern Detected", systemImage: "moon.zzz.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.calmAccent)
                            Text(insight)
                                .font(.system(size: 14))
                                .foregroundColor(.calmDeep)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.85)))
                        .padding(.horizontal, 24)
                    }

                    if !technique.isEmpty {
                        Text(technique)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.calmDeep)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.white.opacity(0.55)))
                    }

                    ZStack {
                        Circle().fill(Color.white.opacity(0.18)).frame(width: 100, height: 100)
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white.opacity(0.85))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Label("Your Sleep Plan", systemImage: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.calmDeep)
                        Text(script)
                            .font(.system(size: 14))
                            .foregroundColor(.calmDeep)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.45)))
                    .padding(.horizontal, 24)

                    // Start Session Button
                    if !technique.isEmpty {
                        Button { openSuggestedSession(technique) } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14))
                                Text("Start Recommended Session")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.calmDeep)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(Color(red: 0.541, green: 0.357, blue: 0.804)))
                            .shadow(color: Color(red: 0.541, green: 0.357, blue: 0.804).opacity(0.35), radius: 10)
                        }
                        .padding(.horizontal, 24)
                    }

                    DisclaimerFooter().padding(.bottom, 16)
                }
                .padding(.top, 8)
            }
        }
        .fullScreenCover(isPresented: $showSleepMed)  { SleepMeditationView().environmentObject(journal) }
        .fullScreenCover(isPresented: $showBreathing) { BreathingView() }
        .fullScreenCover(isPresented: $showMorning)   { MorningMeditationView().environmentObject(journal) }
        .fullScreenCover(isPresented: $showBodyScan)  { BodyScanView().environmentObject(journal) }
    }

    private func openSuggestedSession(_ text: String) {
        let lower = text.lowercased()
        if lower.contains("sleep")                              { showSleepMed  = true }
        else if lower.contains("breathing") || lower.contains("breath") { showBreathing = true }
        else if lower.contains("morning")                       { showMorning   = true }
        else if lower.contains("body")                          { showBodyScan  = true }
        else                                                     { showSleepMed  = true }
    }

    // MARK: - Logic

    private func buildSleepSummary() -> String {
        let df = DateFormatter()
        df.dateFormat = "EEE MMM d"

        var summary = "Here is my sleep data for the past 7 days:\n\n"
        summary += "SLEEP LOG (quality 1=Poor, 2=Fair, 3=OK, 4=Good, 5=Great):\n"
        for entry in recentSleep {
            summary += "- \(df.string(from: entry.date)): \(String(format: "%.1f", entry.hours)) hours, quality \(entry.quality)/5\n"
        }

        summary += "\nAverage: \(String(format: "%.1f", avgHours)) hours/night, \(String(format: "%.1f", avgQuality))/5 quality"
        summary += "\n\nPlease analyze my sleep patterns and suggest the most suitable guided session from the app."
        return summary
    }

    @MainActor
    private func generate() async {
        isGenerating = true
        errorText    = nil
        fullResponse = ""
        insight      = ""
        technique    = ""
        script       = ""

        do {
            for try await chunk in SleepPatternCoachService.stream(buildSleepSummary()) {
                fullResponse += chunk
            }
            parseResponse(fullResponse)
            showSession = true
        } catch {
            errorText = error.localizedDescription
        }
        isGenerating = false
    }

    private func parseResponse(_ text: String) {
        if let range = text.range(of: "INSIGHT:") {
            let after = text[range.upperBound...]
            insight = (after.components(separatedBy: "\n").first ?? "")
                .trimmingCharacters(in: .whitespaces)
        }
        if let range = text.range(of: "TECHNIQUE:") {
            let after = text[range.upperBound...]
            technique = (after.components(separatedBy: "\n").first ?? "")
                .trimmingCharacters(in: .whitespaces)
        }
        if let range = text.range(of: "SCRIPT:") {
            script = String(text[range.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            script = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

}
