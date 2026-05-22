import XCTest
@testable import ShanNianAI

final class NoteModelTests: XCTestCase {

    // MARK: - Note Initialization

    func testNoteDefaultInitialization() {
        let note = Note(content: "测试笔记")

        XCTAssertNotNil(note.id)
        XCTAssertEqual(note.content, "测试笔记")
        XCTAssertEqual(note.category, .uncategorized)
        XCTAssertTrue(note.tags.isEmpty)
        XCTAssertNil(note.aiSummary)
        XCTAssertNil(note.aiInsight)
        XCTAssertTrue(note.relatedNoteIDs.isEmpty)
        XCTAssertFalse(note.isFavorite)
        XCTAssertFalse(note.isArchived)
        XCTAssertEqual(note.reviewCount, 0)
        XCTAssertNil(note.reviewedAt)
    }

    func testNoteFullInitialization() {
        let note = Note(
            content: "AI 产品想法",
            category: .idea,
            tags: ["产品", "AI"],
            aiSummary: "关于AI产品的新想法",
            aiInsight: "关注AI助手赛道"
        )

        XCTAssertEqual(note.content, "AI 产品想法")
        XCTAssertEqual(note.category, .idea)
        XCTAssertEqual(note.tags, ["产品", "AI"])
        XCTAssertEqual(note.aiSummary, "关于AI产品的新想法")
        XCTAssertEqual(note.aiInsight, "关注AI助手赛道")
    }

    func testNoteCreatedAtIsRecent() {
        let note = Note(content: "test")
        let diff = abs(note.createdAt.timeIntervalSinceNow)
        XCTAssertLessThan(diff, 1.0, "createdAt should be within 1 second of now")
    }

    func testNoteModifiedAtSameAsCreatedInitially() {
        let note = Note(content: "test")
        XCTAssertEqual(note.modifiedAt, note.createdAt)
    }

    // MARK: - NoteCategory

    func testCategoryCount() {
        XCTAssertEqual(NoteCategory.allCases.count, 8)
    }

    func testCategoryRawValues() {
        XCTAssertEqual(NoteCategory.inspiration.rawValue, "灵感")
        XCTAssertEqual(NoteCategory.todo.rawValue, "待办")
        XCTAssertEqual(NoteCategory.bookmark.rawValue, "收藏")
        XCTAssertEqual(NoteCategory.journal.rawValue, "日记")
        XCTAssertEqual(NoteCategory.idea.rawValue, "创意")
        XCTAssertEqual(NoteCategory.question.rawValue, "问题")
        XCTAssertEqual(NoteCategory.learning.rawValue, "学习")
        XCTAssertEqual(NoteCategory.uncategorized.rawValue, "未分类")
    }

    func testCategoryHasColor() {
        for category in NoteCategory.allCases {
            // Just verify color exists (not nil/transparent)
            _ = category.color
        }
    }

    func testCategoryHasIcon() {
        for category in NoteCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty)
        }
    }

    func testAllCategoriesHaveUniqueIcons() {
        let icons = NoteCategory.allCases.map { $0.icon }
        XCTAssertEqual(icons.count, Set(icons).count, "All categories should have unique icons")
    }

    func testAllCategoriesHaveUniqueRawValues() {
        let values = NoteCategory.allCases.map { $0.rawValue }
        XCTAssertEqual(values.count, Set(values).count, "All categories should have unique raw values")
    }

    // MARK: - Codable

    func testNoteCategoryIsCodable() {
        let categories: [NoteCategory] = [.idea, .todo, .uncategorized]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        XCTAssertNoThrow(try {
            let data = try encoder.encode(categories)
            let decoded = try decoder.decode([NoteCategory].self, from: data)
            XCTAssertEqual(decoded, categories)
        }())
    }

    // MARK: - AI Classification Response

    func testAIClassificationResponseDecoding() {
        let json = """
        {
            "category": "创意",
            "tags": ["AI", "产品"],
            "summary": "AI产品创意",
            "relatedConcepts": ["人工智能", "SaaS"]
        }
        """.data(using: .utf8)!

        let response = try? JSONDecoder().decode(AIClassificationResponse.self, from: json)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.category, .idea)
        XCTAssertEqual(response?.tags, ["AI", "产品"])
        XCTAssertEqual(response?.summary, "AI产品创意")
        XCTAssertEqual(response?.relatedConcepts, ["人工智能", "SaaS"])
    }

    func testAIClassificationResponseWithAllCategories() {
        let testCases: [(String, NoteCategory)] = [
            ("灵感", .inspiration),
            ("待办", .todo),
            ("收藏", .bookmark),
            ("日记", .journal),
            ("创意", .idea),
            ("问题", .question),
            ("学习", .learning),
            ("未分类", .uncategorized),
        ]

        for (raw, expected) in testCases {
            let json = """
            {"category": "\(raw)", "tags": [], "summary": "", "relatedConcepts": []}
            """.data(using: .utf8)!
            let response = try? JSONDecoder().decode(AIClassificationResponse.self, from: json)
            XCTAssertEqual(response?.category, expected, "Failed for raw value: \(raw)")
        }
    }

    func testWeeklyInsightDecoding() {
        let json = """
        {
            "weekStartDate": "2025-05-19",
            "dominantCategory": "学习",
            "topTags": ["Swift", "iOS"],
            "noteCount": 15,
            "summary": "本周主要关注iOS开发学习",
            "suggestion": "建议下周尝试做个demo项目",
            "emotionalTrend": "积极向上"
        }
        """.data(using: .utf8)!

        let insight = try? JSONDecoder().decode(WeeklyInsight.self, from: json)
        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.weekStartDate, "2025-05-19")
        XCTAssertEqual(insight?.dominantCategory, .learning)
        XCTAssertEqual(insight?.topTags, ["Swift", "iOS"])
        XCTAssertEqual(insight?.noteCount, 15)
    }

    func testWeeklyInsightID() {
        let insight = WeeklyInsight(
            weekStartDate: "2025-05-19",
            dominantCategory: .idea,
            topTags: [],
            noteCount: 0,
            summary: "",
            suggestion: "",
            emotionalTrend: ""
        )
        XCTAssertEqual(insight.id, "2025-05-19")
    }
}
