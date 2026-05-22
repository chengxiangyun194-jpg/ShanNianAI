import Foundation
import SwiftData
import SwiftUI
import WidgetKit

@MainActor
final class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    @Published var weeklyInsight: WeeklyInsight?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentStreak: Int = 0

    private var modelContext: ModelContext?
    private let aiService = AIService.shared

    func configure(with context: ModelContext) {
        self.modelContext = context
        fetchNotes()
        updateStreak()
        syncWidgetData()
    }

    // MARK: - Widget Sync

    private func syncWidgetData() {
        guard let ud = UserDefaults(suiteName: "group.com.shanian.flashai") else { return }
        let todayCount = notes.filter { Calendar.current.isDateInToday($0.createdAt) }.count
        ud.set(notes.count, forKey: "widget_note_count")
        ud.set(todayCount, forKey: "widget_today_count")
        ud.set(currentStreak, forKey: "widget_streak")
        ud.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - CRUD

    func createNote(content: String) {
        guard let ctx = modelContext else { return }
        let note = Note(content: content)
        ctx.insert(note)
        save()
        recordTodayActivity()
        fetchNotes()
        updateStreak()
        syncWidgetData()

        Task {
            await autoClassify(note)
            await findRelated(for: note)
        }
    }

    func updateNote(_ note: Note, content: String) {
        note.content = content
        note.modifiedAt = Date()
        save()
        fetchNotes()
        syncWidgetData()

        Task { await autoClassify(note) }
    }

    func deleteNote(_ note: Note) {
        guard let ctx = modelContext else { return }
        ctx.delete(note)
        save()
        fetchNotes()
        syncWidgetData()
    }

    func toggleFavorite(_ note: Note) {
        note.isFavorite.toggle()
        save()
    }

    func togglePin(_ note: Note) {
        note.isPinned.toggle()
        save()
        fetchNotes()
    }

    func markReviewed(_ note: Note) {
        note.reviewedAt = Date()
        note.reviewCount += 1
        save()
    }

    // MARK: - Streak

    private func recordTodayActivity() {
        guard let ctx = modelContext else { return }
        let today = Calendar.current.startOfDay(for: Date())

        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate { $0.date == today }
        )

        if let existing = try? ctx.fetch(descriptor).first {
            existing.noteCount += 1
        } else {
            let record = DailyRecord(date: today, noteCount: 1)
            ctx.insert(record)
        }
        save()
    }

    func updateStreak() {
        guard let ctx = modelContext else { return }
        let allRecords = (try? ctx.fetch(FetchDescriptor<DailyRecord>())) ?? []
        let sorted = allRecords.sorted { $0.date < $1.date }

        var streak = 0
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var checkDate = today

        // Walk backwards from today
        for record in sorted.reversed() {
            let recordDay = calendar.startOfDay(for: record.date)
            let diff = calendar.dateComponents([.day], from: recordDay, to: checkDate).day ?? 999

            if diff == 0 {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if diff == 1 && (try? ctx.fetch(FetchDescriptor<DailyRecord>(predicate: #Predicate { $0.date == checkDate })).first) == nil {
                // Allow one gap day
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: recordDay) ?? recordDay
            } else if recordDay < checkDate {
                break
            }
        }

        currentStreak = streak
    }

    // MARK: - AI Pipelines

    func autoClassify(_ note: Note) async {
        guard aiService.isConfigured else { return }
        do {
            let result = try await aiService.classify(content: note.content)
            note.category = result.category
            note.tags = result.tags
            note.aiSummary = result.summary
            note.modifiedAt = Date()
            save()
            fetchNotes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func findRelated(for note: Note) async {
        guard aiService.isConfigured, notes.count > 1 else { return }
        do {
            let related = try await aiService.findRelatedNotes(current: note, allNotes: notes)
            note.relatedNoteIDs = related
            save()
        } catch { }
    }

    func generateWeeklyInsight() async {
        guard aiService.isConfigured else {
            errorMessage = "请先配置 AI 服务"
            return
        }

        let weekStart = Calendar.current.date(
            from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        )!

        let thisWeek = notes.filter { $0.createdAt >= weekStart }
        guard !thisWeek.isEmpty else {
            errorMessage = "本周暂无笔记"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let insight = try await aiService.generateWeeklyInsight(
                notes: thisWeek,
                weekStart: weekStart
            )
            weeklyInsight = insight
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Reviews

    func notesForReview(daysAgo: Int) -> [Note] {
        guard let targetDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) else {
            return []
        }
        let startOfDay = Calendar.current.startOfDay(for: targetDate)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        return notes.filter { !$0.isArchived && $0.createdAt >= startOfDay && $0.createdAt < endOfDay }
    }

    func searchNotes(query: String) -> [Note] {
        guard !query.isEmpty else { return notes.filter { !$0.isArchived } }
        return notes.filter {
            !$0.isArchived &&
            ($0.content.localizedCaseInsensitiveContains(query) ||
            $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) }) ||
            ($0.aiSummary ?? "").localizedCaseInsensitiveContains(query))
        }
    }

    func notesByCategory(_ category: NoteCategory) -> [Note] {
        notes.filter { $0.category == category && !$0.isArchived }
    }

    // MARK: - Private

    private func fetchNotes() {
        guard let ctx = modelContext else { return }
        let descriptor = FetchDescriptor<Note>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        notes = (try? ctx.fetch(descriptor)) ?? []
    }

    private func save() {
        try? modelContext?.save()
    }
}
