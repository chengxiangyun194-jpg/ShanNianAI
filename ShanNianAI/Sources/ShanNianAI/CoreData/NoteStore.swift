import Foundation
import SwiftData
import SwiftUI

@MainActor
final class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    @Published var weeklyInsight: WeeklyInsight?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var modelContext: ModelContext?
    private let aiService = AIService.shared

    func configure(with context: ModelContext) {
        self.modelContext = context
        fetchNotes()
    }

    // MARK: - CRUD

    func createNote(content: String) {
        guard let ctx = modelContext else { return }
        let note = Note(content: content)
        ctx.insert(note)
        save()
        fetchNotes()

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

        Task { await autoClassify(note) }
    }

    func deleteNote(_ note: Note) {
        guard let ctx = modelContext else { return }
        ctx.delete(note)
        save()
        fetchNotes()
    }

    func toggleFavorite(_ note: Note) {
        note.isFavorite.toggle()
        save()
    }

    func markReviewed(_ note: Note) {
        note.reviewedAt = Date()
        note.reviewCount += 1
        save()
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
        } catch {
            // Non-critical, silently ignore
        }
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
        return notes.filter { $0.createdAt >= startOfDay && $0.createdAt < endOfDay }
    }

    func searchNotes(query: String) -> [Note] {
        guard !query.isEmpty else { return notes }
        return notes.filter {
            $0.content.localizedCaseInsensitiveContains(query) ||
            $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) }) ||
            ($0.aiSummary ?? "").localizedCaseInsensitiveContains(query)
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
