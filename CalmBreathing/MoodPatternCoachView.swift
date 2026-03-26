import SwiftUI

// MARK: - Mood Pattern Coach

struct MoodPatternCoachView: View {

    @EnvironmentObject var journal: JournalStore
    @Environment(\.dismiss) private var dismiss

    @State private var showMoodLog   = false
    @State private var selectedMood  = 4
    @State private var moodNote      = ""
    @State private var selectedTags: [String] = []
    @State private var fullResponse  = ""
    @State private var insight       = ""
    @State private var technique     = ""
    @State private var script        = ""
    @State private var isGenerating  = false
    @State private var showSession   = false
    @State private var errorText:    String?

    // Last 14 days of mood entries
    private var recentMoods: [MoodEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        return journal.moodEntries.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
    }

    private var recentSleep: [SleepEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        return journal.sleepEntries.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
    }

    private var hasSufficientData: Bool { recentMoods.count >= 7 }

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
        .sheet(isPresented: $showMoodLog) {
            MoodEntrySheet(selectedMood: $selectedMood, note: $moodNote, selectedTags: $selectedTags) {
                journal.addMoodEntry(MoodEntry(mood: selectedMood, note: moodNote, tags: selectedTags))
                moodNote = ""
                selectedTags = []
                showMoodLog = false
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
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 34))
                            .foregroundColor(.white)
                    }
                    Text("Mood Pattern Coach")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundColor(.calmDeep)
                    Text("I analyze your last 7 days of mood data and suggest the best guided session from the app — based on your actual patterns, not just today.")
                        .font(.system(size: 14))
                        .foregroundColor(.calmMid)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                // Mood trend chart
                if !recentMoods.isEmpty {
                    moodTrendCard
                }

                // Not enough data message
                if !hasSufficientData {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.60))
                        Text("Log your mood for at least 7 days to unlock your personalized pattern analysis. \(max(0, 7 - recentMoods.count)) more day\(max(0, 7 - recentMoods.count) == 1 ? "" : "s") to go.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.80))
                            .multilineTextAlignment(.center)
                        if journal.hasMoodEntryToday {
                            Label("Mood logged today", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.calmAccent)
                        } else {
                            Button { showMoodLog = true } label: {
                                Label("Log Today's Mood", systemImage: "plus.circle.fill")
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
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.10)))
                    .padding(.horizontal, 24)
                }

                if let err = errorText {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.25)))
                        .padding(.horizontal, 24)
                }

                // Generate button
                Button { Task { await generate() } } label: {
                    HStack(spacing: 10) {
                        if isGenerating {
                            ProgressView().tint(.calmDeep)
                            Text("Reading your patterns…")
                        } else {
                            Image(systemName: "sparkles")
                            Text("Analyze My Patterns")
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

    // MARK: - Mood Trend Card

    private var moodTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Last \(recentMoods.count) Days")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                let avg = Double(recentMoods.map(\.mood).reduce(0, +)) / Double(recentMoods.count)
                Text("Avg: \(avg, specifier: "%.1f") \(Int(avg.rounded()).moodEmoji)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.calmAccent)
            }

            // Mini bar chart
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(recentMoods.suffix(14)) { entry in
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(entry.mood.moodColor.opacity(0.85))
                            .frame(width: 14, height: CGFloat(entry.mood) * 10)
                        Text(entry.mood.moodEmoji)
                            .font(.system(size: 8))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Sleep summary if available
            if !recentSleep.isEmpty {
                let avgSleep = recentSleep.map(\.hours).reduce(0, +) / Double(recentSleep.count)
                let avgQuality = Double(recentSleep.map(\.quality).reduce(0, +)) / Double(recentSleep.count)
                HStack(spacing: 16) {
                    Label(String(format: "%.1fh avg sleep", avgSleep), systemImage: "moon.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                    Label(String(format: "%.1f/5 quality", avgQuality), systemImage: "star.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.12)))
        .padding(.horizontal, 24)
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

                    // Insight card
                    if !insight.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Pattern Detected", systemImage: "brain.head.profile")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.calmAccent)
                            Text(insight)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.90))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.12)))
                        .padding(.horizontal, 24)
                    }

                    // Technique badge
                    if !technique.isEmpty {
                        Text(technique)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.calmDeep)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.white.opacity(0.55)))
                    }

                    // Script card
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Your Wellness Plan", systemImage: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Text(script)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.calmDeep)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.45)))
                    .padding(.horizontal, 24)

                    DisclaimerFooter().padding(.bottom, 16)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Logic

    private func buildMoodSummary() -> String {
        let df = DateFormatter()
        df.dateFormat = "EEE MMM d"

        var summary = "Here is my mood data for the past 7 days:\n\n"

        summary += "MOOD LOG (scale 1=Angry, 2=Sad, 3=Anxious, 4=Neutral, 5=Relaxed, 6=Happy, 7=Grateful):\n"
        for entry in recentMoods {
            summary += "- \(df.string(from: entry.date)): \(entry.mood) (\(entry.mood.moodLabel))\n"
        }

        summary += "\nPlease analyze my mood patterns and suggest the most suitable guided session from the app."
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
            for try await chunk in MoodPatternCoachService.stream(buildMoodSummary()) {
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
            let lines = after.components(separatedBy: "\n")
            insight = lines.first?.trimmingCharacters(in: .whitespaces) ?? ""
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
