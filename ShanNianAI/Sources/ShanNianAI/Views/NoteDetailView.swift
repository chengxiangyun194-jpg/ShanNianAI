import SwiftUI

struct NoteDetailView: View {
    @EnvironmentObject var noteStore: NoteStore
    @State var note: Note
    @State private var isEditing = false
    @State private var editedContent = ""
    @State private var showRelatedNotes = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Category badge
                HStack(spacing: 8) {
                    Label(note.category.rawValue, systemImage: note.category.icon)
                        .font(.subheadline.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(note.category.color.opacity(0.15))
                        )
                        .foregroundColor(note.category.color)

                    if note.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }

                // Content
                if isEditing {
                    TextEditor(text: $editedContent)
                        .font(.body)
                        .frame(minHeight: 200)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                } else {
                    Text(note.content)
                        .font(.body)
                        .lineSpacing(6)
                }

                // AI Summary
                if let summary = note.aiSummary {
                    aiBox(
                        icon: "sparkles",
                        title: "AI 摘要",
                        color: .purple
                    ) {
                        Text(summary)
                            .font(.subheadline)
                    }
                }

                // Tags
                if !note.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("标签")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        FlowLayout(spacing: 6) {
                            ForEach(note.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color(.systemGray5))
                                    )
                            }
                        }
                    }
                }

                // Related notes
                if !note.relatedNoteIDs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            showRelatedNotes.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.orange)
                                Text("关联笔记 (\(note.relatedNoteIDs.count))")
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: showRelatedNotes ? "chevron.up" : "chevron.down")
                            }
                            .foregroundColor(.primary)
                        }

                        if showRelatedNotes {
                            let relatedNotes = noteStore.notes.filter { note.relatedNoteIDs.contains($0.id) }
                            ForEach(relatedNotes) { related in
                                NavigationLink(destination: NoteDetailView(note: related)) {
                                    NoteRowView(note: related)
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color(.systemGray6))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Metadata
                VStack(alignment: .leading, spacing: 4) {
                    LabeledContent("创建时间", value: note.createdAt.formatted(date: .long, time: .shortened))
                    LabeledContent("修改时间", value: note.modifiedAt.formatted(date: .long, time: .shortened))
                    if note.reviewCount > 0 {
                        LabeledContent("回顾次数", value: "\(note.reviewCount) 次")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("笔记详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    noteStore.toggleFavorite(note)
                } label: {
                    Image(systemName: note.isFavorite ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }

                Menu {
                    Button {
                        editedContent = note.content
                        isEditing = true
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }

                    Button {
                        noteStore.markReviewed(note)
                    } label: {
                        Label("标记已回顾", systemImage: "checkmark.circle")
                    }

                    Divider()

                    Button(role: .destructive) {
                        noteStore.deleteNote(note)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                VStack {
                    TextEditor(text: $editedContent)
                        .font(.body)
                        .padding()
                }
                .navigationTitle("编辑笔记")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { isEditing = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            noteStore.updateNote(note, content: editedContent)
                            isEditing = false
                        }
                    }
                }
            }
        }
    }

    private func aiBox(
        icon: String,
        title: String,
        color: Color,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundColor(color)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        let totalHeight = currentY + lineHeight
        return (CGSize(width: maxWidth, height: totalHeight), frames)
    }
}
