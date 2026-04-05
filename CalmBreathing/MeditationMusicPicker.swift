import SwiftUI
import AVFoundation

// MARK: - Meditation Background Music Options
// Order: tracks first, None last
let meditationMusicOptions: [BgMusicOption] = [
    BgMusicOption(name: "Serene",      filename: "serene_mindfulness"),
    BgMusicOption(name: "Sleep Calm",  filename: "sleep_meditation_bg"),
    BgMusicOption(name: "Ocean",       filename: "ocean",              ext: "m4a"),
    BgMusicOption(name: "Zen Water",   filename: "zen_water"),
    BgMusicOption(name: "Forest",      filename: "forest"),
    BgMusicOption(name: "Ohm",         filename: "ohm"),
    BgMusicOption(name: "Rain",        filename: "rain_sleep_holizna"),
    BgMusicOption(name: "None",        filename: ""),
]

private func icon(for option: BgMusicOption) -> String {
    switch option.filename {
    case "serene_mindfulness":  return "sparkles"
    case "sleep_meditation_bg": return "moon.fill"
    case "ocean":               return "water.waves"
    case "zen_water":           return "drop.fill"
    case "forest":              return "leaf.fill"
    case "ohm":                 return "waveform"
    case "rain_sleep_holizna":  return "cloud.rain.fill"
    default:                    return "speaker.slash.fill"  // None
    }
}

// MARK: - Picker Sheet

struct MeditationMusicPickerSheet: View {
    @Binding var selectedMusic: BgMusicOption
    @Environment(\.dismiss) private var dismiss

    private let purple   = Color(red: 0.541, green: 0.357, blue: 0.804)
    private let cardBase = Color(red: 0.87, green: 0.89, blue: 0.96)
    private let columns  = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            CalmBackground()

            VStack(spacing: 0) {
                // Handle bar
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                // Header
                HStack {
                    Spacer()
                    Text("Background Sound")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.bottom, 20)

                // Options grid
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(meditationMusicOptions, id: \.filename) { option in
                            let isSelected = selectedMusic == option
                            Button { selectedMusic = option } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(alignment: .top) {
                                        ZStack {
                                            Circle()
                                                .fill(purple.opacity(0.08))
                                                .frame(width: 40, height: 40)
                                            Image(systemName: icon(for: option))
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(purple)
                                        }
                                        Spacer()
                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(purple)
                                                .padding(.top, 4)
                                        }
                                    }
                                    Text(option.name)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(.calmDeep)
                                        .lineLimit(1)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(cardBase)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Shared prepareBgMusic helper
// Call this in each view's prepareBgMusic() passing the selected option.
func makeBgPlayer(for option: BgMusicOption, volume: Float = 0.07) -> AVAudioPlayer? {
    guard !option.filename.isEmpty,
          let url = Bundle.main.url(forResource: option.filename,
                                    withExtension: option.ext,
                                    subdirectory: "Audio"),
          let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
    player.numberOfLoops = -1
    player.volume = volume
    player.prepareToPlay()
    return player
}
