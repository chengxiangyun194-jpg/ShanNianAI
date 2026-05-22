import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), noteCount: 42, todayCount: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(
            date: Date(),
            noteCount: UserDefaults.shared?.integer(forKey: "widget_note_count") ?? 0,
            todayCount: UserDefaults.shared?.integer(forKey: "widget_today_count") ?? 0
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(
            date: Date(),
            noteCount: UserDefaults.shared?.integer(forKey: "widget_note_count") ?? 0,
            todayCount: UserDefaults.shared?.integer(forKey: "widget_today_count") ?? 0
        )
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let noteCount: Int
    let todayCount: Int
}

extension UserDefaults {
    static let shared = UserDefaults(suiteName: "group.com.shanian.flashai")
}

struct ShanNianWidgetEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.orange)
                Text("一闪")
                    .font(.caption.bold())
                Spacer()
            }

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.todayCount)")
                    .font(.title.bold())
                    .foregroundColor(.orange)
                Text("今日闪念")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack {
                Image(systemName: "note.text")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("共 \(entry.noteCount) 条")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct ShanNianWidget: Widget {
    let kind = "ShanNianWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ShanNianWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("一闪")
        .description("快速查看闪念笔记统计")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
