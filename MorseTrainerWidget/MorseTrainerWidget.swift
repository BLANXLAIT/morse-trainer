import WidgetKit
import SwiftUI

struct MorseTrainerWidget: Widget {
    let kind: String = "MorseTrainerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MorseTrainerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Morse Trainer")
        .description("Practice Morse code with character of the day or quick-start training.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), character: "K", characterOfDay: "K", pattern: ".- -")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), character: "K", characterOfDay: "K", pattern: ".- -")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Get character of the day based on current date
        let calendar = Calendar.current
        let today = Date()
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        
        // Cycle through Koch sequence characters
        let characterIndex = (dayOfYear - 1) % KochSequence.order.count
        let characterOfDay = KochSequence.order[characterIndex]
        
        // Get the Morse pattern for this character
        let morseChar = MorseCharacter.character(for: characterOfDay)
        let pattern = morseChar?.pattern.map { $0 == .dit ? "•" : "—" }.joined(separator: " ") ?? ""

        // Generate a timeline with a single entry for today
        // Refresh at midnight
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: today)!)
        let entry = SimpleEntry(date: today, character: String(characterOfDay), characterOfDay: String(characterOfDay), pattern: pattern)
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .after(midnight))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let character: String
    let characterOfDay: String
    let pattern: String
}

struct MorseTrainerWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.2)
            
            VStack(spacing: 8) {
                Text("Character of the Day")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text(entry.character)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(entry.pattern)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("Tap to practice")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding()
        }
        .widgetURL(URL(string: "morsetrainer://character/\(entry.character)")!)
    }
}

struct MediumWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 20) {
                // Character of the Day section
                VStack(alignment: .leading, spacing: 4) {
                    Text("Character of the Day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(entry.character)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text(entry.pattern)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Quick Start section
                VStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                    
                    Text("Quick Start")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("2 min practice")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .widgetURL(URL(string: "morsetrainer://quickstart")!)
    }
}

@main
struct MorseTrainerWidgetBundle: WidgetBundle {
    var body: some Widget {
        MorseTrainerWidget()
    }
}

#Preview("Small", as: .systemSmall) {
    MorseTrainerWidget()
} timeline: {
    SimpleEntry(date: .now, character: "K", characterOfDay: "K", pattern: "— • —")
}

#Preview("Medium", as: .systemMedium) {
    MorseTrainerWidget()
} timeline: {
    SimpleEntry(date: .now, character: "K", characterOfDay: "K", pattern: "— • —")
}
