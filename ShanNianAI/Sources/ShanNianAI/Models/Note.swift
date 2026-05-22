import Foundation
import SwiftData
import SwiftUI



// MARK: - Inspiration Analysis

struct InspirationAnalysis: Codable, Identifiable {
    var id: String { coreInsight }
    let extensions: [String]
    let suggestions: [String]
    let relatedFields: [String]
    let coreInsight: String
}


// MARK: - Streak Data

@Model
final class DailyRecord {
    var date: Date = Date()
    var noteCount: Int = 0

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
