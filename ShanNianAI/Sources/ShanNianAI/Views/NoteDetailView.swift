import SwiftUI

struct NoteDetailView: View {
    @EnvironmentObject var noteStore: NoteStore
    @State var note: Note
    @State private var isEditing = false
    @State private var editedContent = ""
    @State private var showRelatedNotes = false
    @State private var showDeleteConfirm = false
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Category badge + actions
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

                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    // Quick action buttons
                    Button {
                        HapticManager.light()
                        noteStore.togglePin(note)
                    } label: {
                        Image(systemName: note.isPinned ? "pin.slash" : "pin")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel(note.isPinned ? "取消置顶" : "置顶")

                    Button {
                        HapticManager.light()
                        noteStore.toggleFavorite(note)
                    } label: {
                        Image(systemName: note.isFavorite ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundColor(.yellow)
                    }
                    .accessibilityLabel(note.isFavorite ? "取消收藏" : "收藏")
                }

                // Content with markdown rendering
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
                    MarkdownText(note.content)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
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
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showRelatedNotes.toggle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.orange)
                                Text("关联笔记 (\(note.relatedNoteIDs.count))")
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: showRelatedNotes ? "chevron.up" : "chevron.down")
                                    .font(.caption)
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
                                .transition(.opacity.combined(with: .move(edge: .top)))
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
                        HapticManager.success()
                        noteStore.markReviewed(note)
                    } label: {
                        Label("标记已回顾", systemImage: "checkmark.circle")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appeared = true
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
                            HapticManager.medium()
                            noteStore.updateNote(note, content: editedContent)
                            isEditing = false
                        }
                    }
                }
            }
        }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                HapticManager.warning()
                noteStore.deleteNote(note)
            }
        } message: {
            Text("删除后无法恢复")
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

// MARK: - Markdown Text Renderer

struct MarkdownText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        let blocks = parseMarkdown(text)

        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .heading(let content, let level):
                    Text(content)
                        .font(headingFont(level))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top, level <= 2 ? 12 : 4)

                case .paragraph(let content):
                    Text(content)
                        .font(.body)
                        .lineSpacing(4)

                case .bold(let content):
                    Text(content).bold()
                        + Text(parseInline(text: content).1)

                case .bullet(let content):
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(content)
                            .font(.body)
                    }
                    .padding(.leading, 8)

                case .numbered(let index, let content):
                    HStack(alignment: .top, spacing: 6) {
                        Text("\(index).")
                            .foregroundColor(.secondary)
                        Text(content)
                            .font(.body)
                    }
                    .padding(.leading, 8)

                case .codeBlock(let content):
                    Text(content)
                        .font(.caption.monospaced())
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                }
            }
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .title
        case 2: return .title2
        case 3: return .title3
        default: return .headline
        }
    }

    private func parseInline(text: String) -> (String, String) {
        return (text, "")
    }
}

// MARK: - Markdown Block Types

enum MarkdownBlock {
    case heading(String, Int)      // content, level (1-6)
    case paragraph(String)
    case bold(String)
    case bullet(String)
    case numbered(Int, String)
    case codeBlock(String)
}

func parseMarkdown(_ text: String) -> [MarkdownBlock] {
    let lines = text.components(separatedBy: "\n")
    var blocks: [MarkdownBlock] = []
    var codeBlockBuffer = ""
    var inCodeBlock = false
    var currentParagraph = ""
    var numberIndex = 1

    func flushParagraph() {
        let trimmed = currentParagraph.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            blocks.append(.paragraph(trimmed))
        }
        currentParagraph = ""
    }

    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Code block fences
        if trimmed.hasPrefix("```") {
            if inCodeBlock {
                if !codeBlockBuffer.isEmpty {
                    blocks.append(.codeBlock(codeBlockBuffer))
                }
                codeBlockBuffer = ""
                inCodeBlock = false
            } else {
                flushParagraph()
                inCodeBlock = true
            }
            continue
        }

        if inCodeBlock {
            codeBlockBuffer += (codeBlockBuffer.isEmpty ? "" : "\n") + line
            continue
        }

        // Headings
        if trimmed.hasPrefix("#### ") {
            flushParagraph()
            blocks.append(.heading(String(trimmed.dropFirst(5)), 4))
        } else if trimmed.hasPrefix("### ") {
            flushParagraph()
            blocks.append(.heading(String(trimmed.dropFirst(4)), 3))
        } else if trimmed.hasPrefix("## ") {
            flushParagraph()
            blocks.append(.heading(String(trimmed.dropFirst(3)), 2))
        } else if trimmed.hasPrefix("# ") {
            flushParagraph()
            blocks.append(.heading(String(trimmed.dropFirst(2)), 1))
        }
        // Bullet list
        else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            flushParagraph()
            blocks.append(.bullet(String(trimmed.dropFirst(2))))
        }
        // Numbered list
        else if let match = try? Regex("^(\\d+)\\.\\s(.+)").wholeMatch(in: trimmed) {
            flushParagraph()
            if let numStr = match[1].substring, let num = Int(numStr) {
                blocks.append(.numbered(num, String(match[2].substring ?? "")))
            }
        }
        // Empty line = paragraph break
        else if trimmed.isEmpty {
            flushParagraph()
        }
        // Regular text
        else {
            if !currentParagraph.isEmpty { currentParagraph += "\n" }
            currentParagraph += line
        }
    }

    // Flush remaining code block
    if inCodeBlock && !codeBlockBuffer.isEmpty {
        blocks.append(.codeBlock(codeBlockBuffer))
    }

    // Flush remaining paragraph
    flushParagraph()

    return blocks
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
