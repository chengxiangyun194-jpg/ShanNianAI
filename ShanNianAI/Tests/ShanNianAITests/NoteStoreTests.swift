import XCTest
import SwiftData
@testable import ShanNianAI

@MainActor
final class NoteStoreTests: XCTestCase {

    var store: NoteStore!
    var container: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Note.self, configurations: config)
        store = NoteStore()
        store.configure(with: container.mainContext)
    }

    override func tearDown() async throws {
        store = nil
        container = nil
        try await super.tearDown()
    }

    // MARK: - CRUD

    func testCreateNote() {
        store.createNote(content: "测试笔记内容")

        XCTAssertEqual(store.notes.count, 1)
        XCTAssertEqual(store.notes.first?.content, "测试笔记内容")
        XCTAssertEqual(store.notes.first?.category, .uncategorized)
    }

    func testCreateMultipleNotes() {
        for i in 0..<5 {
            store.createNote(content: "笔记 \(i)")
        }
        XCTAssertEqual(store.notes.count, 5)
    }

    func testCreateNoteWithEmptyContent() {
        store.createNote(content: "")

        // Empty content should still create a note
        XCTAssertEqual(store.notes.count, 1)
        XCTAssertEqual(store.notes.first?.content, "")
    }

    func testUpdateNote() {
        store.createNote(content: "原始内容")
        let note = store.notes.first!

        store.updateNote(note, content: "修改后的内容")

        XCTAssertEqual(store.notes.first?.content, "修改后的内容")
        XCTAssertGreaterThan(note.modifiedAt, note.createdAt)
    }

    func testDeleteNote() {
        store.createNote(content: "待删除")
        XCTAssertEqual(store.notes.count, 1)

        let note = store.notes.first!
        store.deleteNote(note)

        XCTAssertEqual(store.notes.count, 0)
    }

    func testDeleteNoteOnlyRemovesOne() {
        store.createNote(content: "笔记1")
        store.createNote(content: "笔记2")
        XCTAssertEqual(store.notes.count, 2)

        store.deleteNote(store.notes.first!)
        XCTAssertEqual(store.notes.count, 1)
    }

    // MARK: - Favorites

    func testToggleFavorite() {
        store.createNote(content: "收藏测试")
        let note = store.notes.first!
        XCTAssertFalse(note.isFavorite)

        store.toggleFavorite(note)
        XCTAssertTrue(note.isFavorite)

        store.toggleFavorite(note)
        XCTAssertFalse(note.isFavorite)
    }

    // MARK: - Review

    func testMarkReviewed() {
        store.createNote(content: "回顾测试")
        let note = store.notes.first!

        XCTAssertEqual(note.reviewCount, 0)
        XCTAssertNil(note.reviewedAt)

        store.markReviewed(note)
        XCTAssertEqual(note.reviewCount, 1)
        XCTAssertNotNil(note.reviewedAt)

        store.markReviewed(note)
        XCTAssertEqual(note.reviewCount, 2)
    }

    // MARK: - Search

    func testSearchByContent() {
        store.createNote(content: "SwiftUI 学习笔记")
        store.createNote(content: "Python 数据分析")
        store.createNote(content: "iOS 开发计划")

        let results = store.searchNotes(query: "Swift")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.content, "SwiftUI 学习笔记")
    }

    func testSearchCaseInsensitive() {
        store.createNote(content: "SWIFT 学习")
        let results = store.searchNotes(query: "swift")
        XCTAssertEqual(results.count, 1)
    }

    func testSearchEmptyQueryReturnsAll() {
        store.createNote(content: "笔记1")
        store.createNote(content: "笔记2")
        let results = store.searchNotes(query: "")
        XCTAssertEqual(results.count, 2)
    }

    func testSearchNoMatch() {
        store.createNote(content: "iOS开发")
        let results = store.searchNotes(query: "Python")
        XCTAssertEqual(results.count, 0)
    }

    func testSearchByTag() {
        let note = Note(content: "测试", tags: ["Swift", "iOS"])
        container.mainContext.insert(note)
        try? container.mainContext.save()
        store.configure(with: container.mainContext)

        let results = store.searchNotes(query: "Swift")
        XCTAssertEqual(results.count, 1)
    }

    // MARK: - Category Filter

    func testNotesByCategory() {
        let note1 = Note(content: "灵感笔记", category: .inspiration)
        let note2 = Note(content: "待办笔记", category: .todo)
        container.mainContext.insert(note1)
        container.mainContext.insert(note2)
        try? container.mainContext.save()
        store.configure(with: container.mainContext)

        let inspiration = store.notesByCategory(.inspiration)
        XCTAssertEqual(inspiration.count, 1)
        XCTAssertEqual(inspiration.first?.content, "灵感笔记")

        let todos = store.notesByCategory(.todo)
        XCTAssertEqual(todos.count, 1)
    }

    func testNotesByCategoryExcludesArchived() {
        let note = Note(content: "已归档", category: .idea)
        note.isArchived = true
        container.mainContext.insert(note)
        try? container.mainContext.save()
        store.configure(with: container.mainContext)

        let ideas = store.notesByCategory(.idea)
        XCTAssertEqual(ideas.count, 0)
    }

    // MARK: - Review by Days Ago

    func testNotesForReviewReturnsCorrectRange() {
        let today = Calendar.current.startOfDay(for: Date())

        // Note from 7 days ago
        if let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: today) {
            let note = Note(content: "7天前的笔记")
            note.createdAt = sevenDaysAgo
            container.mainContext.insert(note)
            try? container.mainContext.save()
            store.configure(with: container.mainContext)

            let results = store.notesForReview(daysAgo: 7)
            XCTAssertEqual(results.count, 1)
        }
    }

    func testNotesForReviewNoMatch() {
        store.createNote(content: "今天的笔记")
        let results = store.notesForReview(daysAgo: 30)
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Sort Order

    func testNotesSortedByCreatedAtDescending() {
        store.createNote(content: "旧的")
        Thread.sleep(forTimeInterval: 0.01) // ensure different timestamps
        store.createNote(content: "新的")

        XCTAssertEqual(store.notes.first?.content, "新的")
        XCTAssertEqual(store.notes.last?.content, "旧的")
    }

    // MARK: - Edge Cases

    func testEmptyStore() {
        XCTAssertEqual(store.notes.count, 0)
        XCTAssertNil(store.weeklyInsight)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.errorMessage)
    }

    func testDeleteAllNotes() {
        for i in 0..<10 {
            store.createNote(content: "笔记\(i)")
        }
        XCTAssertEqual(store.notes.count, 10)

        for note in store.notes {
            store.deleteNote(note)
        }
        XCTAssertEqual(store.notes.count, 0)
    }
}
