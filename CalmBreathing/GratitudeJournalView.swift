import SwiftUI

// MARK: - Gratitude Journal View

struct GratitudeJournalView: View {
    @EnvironmentObject var journal: JournalStore
    @Environment(\.dismiss) private var dismiss

    @State private var line1 = ""
    @State private var line2 = ""
    @State private var line3 = ""
    @State private var saved = false
    @FocusState private var focused: Int?

    private var hasContent: Bool {
        !line1.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var alreadySavedToday: Bool { journal.gratitudeEntryToday }

    var body: some View {
        ZStack {
            CalmBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // MARK: Header
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        Spacer()
                        Text("Gratitude Journal")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Color.clear.frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Privacy notice
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.40))
                        Text("Stored privately on your device. Never shared.")
                            .font(.system(size: 11, weight: .light))
                            .foregroundColor(.white.opacity(0.40))
                    }

                    // MARK: Quote
                    Text("\"Gratitude turns what we have into enough.\"")
                        .font(.system(size: 13, weight: .light, design: .rounded))
                        .foregroundColor(.white.opacity(0.70))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    // MARK: Today's Entry
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Today I'm grateful for…", systemImage: "heart.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))

                        if alreadySavedToday && !saved {
                            // Show today's saved entry
                            if let entry = journal.gratitudeEntries.first {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(entry.text.components(separatedBy: "\n").filter { !$0.isEmpty }, id: \.self) { line in
                                        HStack(alignment: .top, spacing: 10) {
                                            Text("•")
                                                .foregroundColor(.calmAccent)
                                            Text(line)
                                                .font(.system(size: 15, weight: .light))
                                                .foregroundColor(.white.opacity(0.90))
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                                Text("You've already journaled today. Come back tomorrow!")
                                    .font(.system(size: 12, weight: .light))
                                    .foregroundColor(.white.opacity(0.55))
                                    .padding(.top, 4)
                            }
                        } else {
                            // Input fields
                            VStack(spacing: 12) {
                                gratitudeLine(number: 1, text: $line1, focus: 1)
                                gratitudeLine(number: 2, text: $line2, focus: 2)
                                gratitudeLine(number: 3, text: $line3, focus: 3)
                            }

                            if saved {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.calmAccent)
                                    Text("Saved! See you tomorrow.")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                                .transition(.opacity.combined(with: .scale))
                            } else {
                                Button { saveEntry() } label: {
                                    Text("Save Today's Gratitude")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.calmDeep)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Capsule().fill(Color.calmAccent))
                                }
                                .disabled(!hasContent)
                                .opacity(hasContent ? 1 : 0.45)
                            }
                        }
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.10)))
                    .padding(.horizontal, 20)

                    // MARK: Past Entries
                    let past = journal.gratitudeEntries.dropFirst(alreadySavedToday ? 1 : 0).prefix(10)
                    if !past.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PAST ENTRIES")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.55))
                                .padding(.leading, 4)

                            ForEach(Array(past)) { entry in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(entry.date, style: .date)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.calmAccent.opacity(0.80))
                                    ForEach(entry.text.components(separatedBy: "\n").filter { !$0.isEmpty }, id: \.self) { line in
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("•").foregroundColor(.white.opacity(0.45))
                                            Text(line)
                                                .font(.system(size: 13, weight: .light))
                                                .foregroundColor(.white.opacity(0.80))
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.07)))
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    DisclaimerFooter().padding(.bottom, 32)
                }
            }
        }
        .focused($focused, equals: nil)
        .onTapGesture { focused = nil }
    }

    private func gratitudeLine(number: Int, text: Binding<String>, focus: Int) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.calmAccent)
                .frame(width: 20)
            TextField("Something you appreciate…", text: text)
                .font(.system(size: 15, weight: .light))
                .foregroundColor(.white)
                .tint(.white)
                .focused($focused, equals: focus)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.10))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(focused == focus ? Color.calmAccent.opacity(0.60) : Color.clear, lineWidth: 1))
                )
                .submitLabel(number < 3 ? .next : .done)
                .onSubmit {
                    if number < 3 { focused = focus + 1 }
                    else { focused = nil }
                }
        }
    }

    private func saveEntry() {
        let lines = [line1, line2, line3]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        guard !lines.isEmpty else { return }
        journal.addGratitudeEntry(lines)
        withAnimation { saved = true }
        focused = nil
    }
}
