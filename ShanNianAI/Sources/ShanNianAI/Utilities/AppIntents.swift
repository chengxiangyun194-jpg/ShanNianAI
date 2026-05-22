import AppIntents
import SwiftData
import SwiftUI

// MARK: - Capture Flash Note Intent

struct CaptureFlashNote: AppIntent {
    static let title: LocalizedStringResource = "捕捉闪念"
    static let description = IntentDescription(
        "快速记录一闪而过的念头",
        categoryName: "笔记",
        searchKeywords: ["捕捉", "闪念", "笔记", "记录", "灵感"]
    )
    static let openAppWhenRun = false

    @Parameter(
        title: "内容",
        description: "要记录的笔记内容",
        requestValueDialog: "你想记录什么？"
    )
    var content: String

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard !content.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw $content.needsValueError("请输入要记录的内容")
        }

        // Create note directly with SwiftData
        let container = try ModelContainer(for: Note.self)
        let context = container.mainContext
        let note = Note(content: content)
        context.insert(note)
        try context.save()

        // Update widget data
        let notes = (try? context.fetch(FetchDescriptor<Note>())) ?? []
        let todayCount = notes.filter { Calendar.current.isDateInToday($0.createdAt) }.count
        if let ud = UserDefaults(suiteName: "group.com.shanian.flashai") {
            ud.set(notes.count, forKey: "widget_note_count")
            ud.set(todayCount, forKey: "widget_today_count")
        }

        let category = note.category.rawValue
        return .result(value: "已保存！分类：「\(category)」", dialog: "闪念已捕捉，分类为\(category)")
    }
}

// MARK: - View Recent Notes Intent

struct ViewRecentNotes: AppIntent {
    static let title: LocalizedStringResource = "查看最近笔记"
    static let description = IntentDescription(
        "查看最近记录的闪念笔记",
        categoryName: "笔记",
        searchKeywords: ["查看", "最近", "笔记"]
    )
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Shortcuts Provider

struct ShanNianShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureFlashNote(),
            phrases: [
                "在\(.applicationName)记录",
                "\(.applicationName)捕捉",
                "用\(.applicationName)记一下",
                "用${applicationName}闪念记录",
            ],
            shortTitle: "捕捉闪念",
            systemImageName: "sparkles"
        )

        AppShortcut(
            intent: ViewRecentNotes(),
            phrases: [
                "查看\(.applicationName)笔记",
                "打开\(.applicationName)",
            ],
            shortTitle: "查看笔记",
            systemImageName: "list.bullet"
        )
    }
}
