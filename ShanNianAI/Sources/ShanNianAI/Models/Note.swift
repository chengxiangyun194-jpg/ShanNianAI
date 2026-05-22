import Foundation
import SwiftData
import SwiftUI

@Model
final class Note {
    var id: UUID
    var content: String
    var category: NoteCategory
    var tags: [String]
    var aiSummary: String?
    var aiInsight: String?
    var relatedNoteIDs: [UUID]
    var createdAt: Date
    var modifiedAt: Date
    var reviewedAt: Date?
    var reviewCount: Int
    var isFavorite: Bool
    var isArchived: Bool
    var isPinned: Bool

    init(
        content: String,
        category: NoteCategory = .uncategorized,
        tags: [String] = [],
        aiSummary: String? = nil,
        aiInsight: String? = nil
    ) {
        self.id = UUID()
        self.content = content
        self.category = category
        self.tags = tags
        self.aiSummary = aiSummary
        self.aiInsight = aiInsight
        self.relatedNoteIDs = []
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.reviewedAt = nil
        self.reviewCount = 0
        self.isFavorite = false
        self.isArchived = false
        self.isPinned = false
    }
}

enum NoteCategory: String, Codable, CaseIterable {
    case inspiration = "灵感"
    case todo = "待办"
    case bookmark = "收藏"
    case journal = "日记"
    case idea = "创意"
    case question = "问题"
    case learning = "学习"
    case uncategorized = "未分类"

    var color: Color {
        switch self {
        case .inspiration: return .yellow
        case .todo: return .blue
        case .bookmark: return .green
        case .journal: return .purple
        case .idea: return .orange
        case .question: return .red
        case .learning: return .teal
        case .uncategorized: return .gray
        }
    }

    var icon: String {
        switch self {
        case .inspiration: return "sparkles"
        case .todo: return "checklist"
        case .bookmark: return "bookmark"
        case .journal: return "book"
        case .idea: return "lightbulb"
        case .question: return "questionmark.circle"
        case .learning: return "graduationcap"
        case .uncategorized: return "folder"
        }
    }
}

// MARK: - Streak Data

@Model
final class DailyRecord {
    var date: Date
    var noteCount: Int

    init(date: Date, noteCount: Int = 0) {
        self.date = Calendar.current.startOfDay(for: date)
        self.noteCount = noteCount
    }
}

// MARK: - AI Response Models

struct AIClassificationResponse: Codable {
    let category: NoteCategory
    let tags: [String]
    let summary: String
    let relatedConcepts: [String]
}

struct WeeklyInsight: Codable, Identifiable {
    var id: String { weekStartDate }
    let weekStartDate: String
    let dominantCategory: NoteCategory
    let topTags: [String]
    let noteCount: Int
    let summary: String
    let suggestion: String
    let emotionalTrend: String
}
