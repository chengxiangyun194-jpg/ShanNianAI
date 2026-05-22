import SwiftUI

struct NoteListView: View {
    @EnvironmentObject var noteStore: NoteStore
    @State private var searchQuery = ""
    @State private var selectedCategory: NoteCategory?
    @State private var showReviewSheet = false
    @State private var reviewDaysAgo = 7

    private var filteredNotes: [Note] {
        var notes = noteStore.searchNotes(query: searchQuery)
            .filter { !$0.isArchived }

        if let category = selectedCategory {
            notes = notes.filter { $0.category == category }
        }

        return notes
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter chips
                categoryFilterBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                // Notes list
                if filteredNotes.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(filteredNotes) { note in
                            NavigationLink(destination: NoteDetailView(note: note)) {
                                NoteRowView(note: note)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    noteStore.deleteNote(note)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }

                                Button {
                                    noteStore.toggleFavorite(note)
                                } label: {
                                    Label("收藏", systemImage: note.isFavorite ? "star.slash" : "star")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("闪念笔记")
            .searchable(text: $searchQuery, prompt: "搜索笔记内容或标签")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showReviewSheet = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showReviewSheet) {
                reviewView
            }
        }
    }

    // MARK: - Subviews

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    label: "全部",
                    icon: "tray.full",
                    color: .gray,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(NoteCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        label: category.rawValue,
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            Text("还没有笔记")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("回到「捕捉」页面\n写下第一个闪念吧 ✨")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.6))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var reviewView: some View {
        NavigationStack {
            List {
                Section("回顾过去的笔记") {
                    ForEach([1, 3, 7, 14, 30], id: \.self) { days in
                        let reviewNotes = noteStore.notesForReview(daysAgo: days)
                        Button {
                            reviewDaysAgo = days
                        } label: {
                            HStack {
                                Text("\(days)天前")
                                Spacer()
                                Text("\(reviewNotes.count) 条")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .disabled(reviewNotes.isEmpty)
                    }
                }

                Section("\(reviewDaysAgo)天前的笔记") {
                    let notes = noteStore.notesForReview(daysAgo: reviewDaysAgo)
                    if notes.isEmpty {
                        Text("这天没有笔记")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(notes) { note in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(note.content)
                                    .font(.body)
                                HStack {
                                    Label(note.category.rawValue, systemImage: note.category.icon)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    if note.reviewCount > 0 {
                                        Text("已回顾\(note.reviewCount)次")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .swipeActions {
                                Button {
                                    noteStore.markReviewed(note)
                                } label: {
                                    Label("已回顾", systemImage: "checkmark.circle")
                                }
                                .tint(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("笔记回顾")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { showReviewSheet = false }
                }
            }
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? color.opacity(0.2) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color : .clear, lineWidth: 1)
            )
            .foregroundColor(isSelected ? color : .secondary)
        }
    }
}

// MARK: - Note Row

struct NoteRowView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: note.category.icon)
                    .foregroundColor(note.category.color)
                Text(note.category.rawValue)
                    .font(.caption)
                    .foregroundColor(note.category.color)
                if note.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
                Spacer()
                Text(note.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(note.content)
                .font(.subheadline)
                .lineLimit(2)

            if let summary = note.aiSummary {
                Text(summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            if !note.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(note.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color(.systemGray5))
                                )
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            if !note.relatedNoteIDs.isEmpty {
                Text("关联 \(note.relatedNoteIDs.count) 条笔记")
                    .font(.caption2)
                    .foregroundColor(.orange.opacity(0.7))
            }
        }
        .padding(.vertical, 4)
    }
}
