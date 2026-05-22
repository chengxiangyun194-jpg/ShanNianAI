import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), noteCount: 42, todayCount: 3, streak: 7)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let ud = UserDefaults.shared
        let entry = SimpleEntry(
            date: Date(),
            noteCount: ud?.integer(forKey: "widget_note_count") ?? 0,
            todayCount: ud?.integer(forKey: "widget_today_count") ?? 0,
            streak: ud?.integer(forKey: "widget_streak") ?? 0
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let ud = UserDefaults.shared
        let entry = SimpleEntry(
            date: Date(),
            noteCount: ud?.integer(forKey: "widget_note_count") ?? 0,
            todayCount: ud?.integer(forKey: "widget_today_count") ?? 0,
            streak: ud?.integer(forKey: "widget_streak") ?? 0
        )
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let noteCount: Int
    let todayCount: Int
    let streak: Int
}

extension UserDefaults {
    static let shared = UserDefaults(suiteName: "group.com.shanian.flashai")
}

// MARK: - Small Widget

struct ShanNianSmallWidgetView: View {
    var entry: SimpleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("一闪")
                    .font(.caption.bold())
                Spacer()
            }

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.todayCount)")
                    .font(.largeTitle.bold())
                    .foregroundColor(.orange)
                Text("今日闪念")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                if entry.streak > 0 {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.orange)
                    Text("\(entry.streak)天")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

// MARK: - Medium Widget

struct ShanNianMediumWidgetView: View {
    var entry: SimpleEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: stats
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.orange)
                    Text("一闪")
                        .font(.caption.bold())
                }

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.todayCount)")
                        .font(.largeTitle.bold())
                        .foregroundColor(.orange)
                    Text("今日闪念")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 16) {
                    if entry.streak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                                .font(.caption2)
                            Text("连续\(entry.streak)天")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack(spacing: 2) {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("共\(entry.noteCount)条")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            // Right: quick tips
            VStack(alignment: .leading, spacing: 8) {
                Text("快速捕捉")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                quickTip(icon: "plus.circle.fill", text: "点击进入捕捉")
                quickTip(icon: "brain", text: "AI 自动分类")
                quickTip(icon: "chart.bar", text: "周报洞察")

                Spacer()

                Text("长按 → 编辑小组件")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .padding()
    }

    private func quickTip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.orange)
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Widget Configuration

struct ShanNianWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: SimpleEntry

    var body: some View {
        switch family {
        case .systemSmall:
            ShanNianSmallWidgetView(entry: entry)
                .widgetURL(URL(string: "shanian://capture"))
        case .systemMedium:
            ShanNianMediumWidgetView(entry: entry)
                .widgetURL(URL(string: "shanian://capture"))
        default:
            ShanNianSmallWidgetView(entry: entry)
                .widgetURL(URL(string: "shanian://capture"))
        }
    }
}

struct ShanNianWidget: Widget {
    let kind = "ShanNianWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                ShanNianWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                ShanNianWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("一闪")
        .description("快速查看闪念笔记统计，点击进入捕捉")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
