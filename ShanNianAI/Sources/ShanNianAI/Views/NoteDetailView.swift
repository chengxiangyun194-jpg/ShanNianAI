import SwiftUI

struct NoteDetailView: View {
    @EnvironmentObject var noteStore: NoteStore
    @State var note: Note
    @State private var isEditing = false
    @State private var editedContent = ""
    @State private var showRelatedNotes = false
    @State private var showDeleteConfirm = false
    @State private var appeared = false

    // 灵感分析
    @State private var isAnalyzing = false
    @State private var analysis: InspirationAnalysis?
    @State private var showAnalysis = false
    @State private var analysisError: String?

    // 分享
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Category badge + editable + actions
                HStack(spacing: 8) {
                    Menu {
                        ForEach(NoteCategory.allCases, id: \.self) { cat in
                            Button {
                                HapticManager.light()
                                note.category = cat
                                note.modifiedAt = Date()
                            } label: {
                                Label(cat.rawValue, systemImage: note.category == cat ? "checkmark" : cat.icon)
                            }
                        }
                    } label: {
                        Label(note.category.rawValue, systemImage: note.category.icon)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(note.category.color.opacity(0.15))
                            )
                            .foregroundColor(note.category.color)
                    }

                    if note.isFavorite {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                    }
                    if note.isPinned {
                        Image(systemName: "pin.fill").foregroundColor(.blue)
                    }

                    Spacer()

                    Button {
                        HapticManager.light()
                        noteStore.togglePin(note)
                    } label: {
                        Image(systemName: note.isPinned ? "pin.slash" : "pin")
                            .font(.title3).foregroundColor(.blue)
                    }

                    Button {
                        HapticManager.light()
                        noteStore.toggleFavorite(note)
                    } label: {
                        Image(systemName: note.isFavorite ? "star.fill" : "star")
                            .font(.title3).foregroundColor(.yellow)
                    }
                }

                // Content
                if isEditing {
                    TextEditor(text: $editedContent)
                        .font(.body)
                        .frame(minHeight: 200)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                } else {
                    MarkdownText(text: note.content)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                }

                // AI Summary
                if let summary = note.aiSummary {
                    aiBox(icon: "sparkles", title: "AI 摘要", color: .purple) {
                        Text(summary).font(.subheadline)
                    }
                }

                // 灵感分析按钮
                if note.category == .inspiration {
                    VStack(spacing: 10) {
                        if isAnalyzing {
                            HStack {
                                ProgressView()
                                Text("AI 深度分析中...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.orange.opacity(0.08))
                            )
                        } else if let err = analysisError {
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("分析失败")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.orange)
                                }
                                Text(err)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                Button("重试") {
                                    analysisError = nil
                                    performAnalysis()
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                                .tint(.orange)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.orange.opacity(0.06))
                            )
                        } else if !showAnalysis {
                            Button {
                                HapticManager.medium()
                                performAnalysis()
                            } label: {
                                Label("灵感深度分析", systemImage: "brain.head.profile")
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            colors: [.orange, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }

                        // 分析结果
                        if let a = analysis, showAnalysis {
                            inspirationAnalysisCard(a)
                        }
                    }
                }

                // Tags
                if !note.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("标签").font(.caption).foregroundColor(.secondary)
                        FlowLayout(spacing: 6) {
                            ForEach(note.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Capsule().fill(Color(.systemGray5)))
                            }
                        }
                    }
                }

                // Related notes
                if !note.relatedNoteIDs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            withAnimation { showRelatedNotes.toggle() }
                        } label: {
                            HStack {
                                Image(systemName: "link").foregroundColor(.orange)
                                Text("关联笔记 (\(note.relatedNoteIDs.count))").font(.subheadline)
                                Spacer()
                                Image(systemName: showRelatedNotes ? "chevron.up" : "chevron.down")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                        if showRelatedNotes {
                            ForEach(note.relatedNoteIDs, id: \.self) { id in
                                if let related = noteStore.notes.first(where: { $0.id == id }) {
                                    NavigationLink {
                                        NoteDetailView(note: related)
                                    } label: {
                                        HStack {
                                            Image(systemName: related.category.icon)
                                                .foregroundColor(related.category.color)
                                            Text(related.content.prefix(50))
                                                .font(.caption).lineLimit(1)
                                            Spacer()
                                            Image(systemName: "chevron.right").font(.caption2)
                                        }
                                        .padding(10)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                                    }
                                }
                            }
                        }
                    }
                }

                // Meta info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("创建于 \(formatDate(note.createdAt))").font(.caption2).foregroundColor(.secondary)
                        if note.reviewCount > 0 {
                            Text("· 已回顾 \(note.reviewCount) 次").font(.caption2).foregroundColor(.orange)
                        }
                    }
                    if note.modifiedAt > note.createdAt {
                        Text("修改于 \(formatDate(note.modifiedAt))").font(.caption2).foregroundColor(.secondary)
                    }
                }

                // Bottom actions
                HStack(spacing: 16) {
                    // Edit
                    Button {
                        if isEditing {
                            noteStore.updateNote(note, content: editedContent)
                        } else {
                            editedContent = note.content
                        }
                        withAnimation { isEditing.toggle() }
                    } label: {
                        Label(isEditing ? "保存" : "编辑", systemImage: isEditing ? "checkmark" : "pencil")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)

                    // Review
                    Button {
                        HapticManager.light()
                        noteStore.markReviewed(note)
                    } label: {
                        Label("回顾", systemImage: "eye")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    // Share button
                    Button {
                        HapticManager.light()
                        generateShareImage()
                    } label: {
                        Label("分享", systemImage: "square.and.arrow.up")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

                    // Delete
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash").font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
        .navigationTitle("笔记详情")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { withAnimation(.easeOut(duration: 0.3)) { appeared = true } }
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage {
                ShareSheet(items: [img, "来自 一闪AI — \(note.content.prefix(30))..."])
            }
        }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                noteStore.deleteNote(note)
            }
        }
    }

    // MARK: - Analysis

    private func performAnalysis() {
        isAnalyzing = true
        analysisError = nil
        // 在主 actor 上提取纯数据，避免跨 actor 访问 SwiftData Model
        let noteContent = note.content
        let noteSummary = note.aiSummary
        let noteTags = note.tags
        Task {
            do {
                let result = try await AIService.shared.analyzeInspiration(
                    content: noteContent,
                    aiSummary: noteSummary,
                    tags: noteTags
                )
                analysis = result
                withAnimation(.easeInOut(duration: 0.4)) { showAnalysis = true }
            } catch {
                analysisError = error.localizedDescription
            }
            isAnalyzing = false
        }
    }

    // MARK: - Share

    private func generateShareImage() {
        // 先提取数据避免跨 actor 访问 SwiftData Model
        let cardData = ShareCardData(
            categoryName: note.category.rawValue,
            categoryIcon: note.category.icon,
            categoryColor: note.category.color,
            content: note.content,
            tags: note.tags,
            aiSummary: note.aiSummary,
            createdAt: note.createdAt
        )

        // 先展示文本分享，图片异步生成后自动更新
        shareImage = nil
        showShareSheet = true

        // 异步生成卡片，不阻塞 UI
        Task.detached(priority: .background) {
            let cardView = ShareCardView(data: cardData)
            let renderer = await MainActor.run {
                ImageRenderer(content: cardView.frame(width: 350))
            }
            // 给 ImageRenderer 一点时间渲染
            try? await Task.sleep(nanoseconds: 100_000_000)
            if let img = await MainActor.run(body: { renderer.uiImage }) {
                await MainActor.run {
                    shareImage = img
                }
            }
        }
    }

    private var shareText: String {
        var text = "一闪AI 灵感笔记\n\n"
        text += "【\(note.category.rawValue)】\n"
        text += note.content + "\n"
        if let s = note.aiSummary { text += "\nAI 摘要：\(s)" }
        if !note.tags.isEmpty { text += "\n标签：\(note.tags.map { "#\($0)" }.joined(separator: " "))" }
        return text
    }

    private var shareCardView: some View {
        // Deprecated: use ShareCardView(data:) directly
        let cardData = ShareCardData(
            categoryName: note.category.rawValue,
            categoryIcon: note.category.icon,
            categoryColor: note.category.color,
            content: note.content,
            tags: note.tags,
            aiSummary: note.aiSummary,
            createdAt: note.createdAt
        )
        return ShareCardView(data: cardData).frame(width: 350)
    }

    // MARK: - Inspiration Analysis Card

    private func inspirationAnalysisCard(_ a: InspirationAnalysis) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.orange)
                    Text("灵感深度分析")
                        .font(.headline)
                    Spacer()
                    Button {
                        withAnimation { showAnalysis = false; analysis = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }

                // 核心洞察
                insightBox(icon: "💡", title: "核心洞察", color: .orange) {
                    Text(a.coreInsight).font(.body)
                }

                // 市场角度 + 用户痛点
                HStack(alignment: .top, spacing: 10) {
                    insightBox(icon: "📊", title: "市场切口", color: .blue) {
                        Text(a.marketAngle).font(.subheadline)
                    }
                    insightBox(icon: "🎯", title: "用户痛点", color: .red) {
                        Text(a.userPainPoint).font(.subheadline)
                    }
                }

                // 可执行步骤
                VStack(alignment: .leading, spacing: 8) {
                    Text("🪜 执行路线图").font(.subheadline.bold())
                    ForEach(Array(a.actionableSteps.enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("Step \(i + 1)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().fill(Color.orange))
                            Text(step).font(.subheadline)
                        }
                    }
                }

                // 变现 + 风险 + 壁垒
                HStack(alignment: .top, spacing: 10) {
                    insightBox(icon: "💰", title: "变现逻辑", color: .green) {
                        Text(a.monetization).font(.subheadline)
                    }
                    insightBox(icon: "⚠️", title: "最大风险", color: .red) {
                        Text(a.riskWarning).font(.subheadline)
                    }
                }
                insightBox(icon: "🏰", title: "竞争壁垒", color: .purple) {
                    Text(a.moat).font(.subheadline)
                }

                // 延伸方向
                if !a.extensions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🔮 未来延伸").font(.subheadline.bold())
                        ForEach(Array(a.extensions.enumerated()), id: \.offset) { i, ext in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "circle.fill").font(.system(size: 6))
                                    .foregroundColor(.orange).padding(.top, 5)
                                Text(ext).font(.subheadline)
                            }
                        }
                    }
                }

                // 类似案例
                if !a.relatedCases.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📚 类似案例").font(.subheadline.bold())
                        ForEach(a.relatedCases, id: \.self) { case_ in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.caption).foregroundColor(.blue)
                                Text(case_).font(.subheadline)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            )
        }
    }

    private func insightBox(icon: String, title: String, color: Color, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(icon) \(title)").font(.caption.bold()).foregroundColor(color)
            content()
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.06))
                )
        }
    }

    // MARK: - Helpers

    private func aiBox<Content: View>(icon: String, title: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundColor(color)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.06))
        )
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: date)
    }
}

// MARK: - Markdown Renderer

struct MarkdownText: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(parseMarkdown(text).enumerated()), id: \.offset) { _, block in
                switch block {
                case .heading(let content, let level):
                    Text(content)
                        .font(headingFont(level))
                        .fontWeight(.bold)
                        .padding(.top, level <= 2 ? 12 : 4)
                case .paragraph(let content):
                    Text(content).font(.body)
                case .bullet(let content):
                    HStack(alignment: .top, spacing: 8) {
                        Text("•").foregroundColor(.secondary)
                        Text(content).font(.body)
                    }
                case .numbered(let num, let content):
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(num).").foregroundColor(.secondary)
                        Text(content).font(.body)
                    }
                case .codeBlock(let content):
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(content)
                            .font(.caption.monospaced())
                            .padding(12)
                    }
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
}

// MARK: - Markdown Parser

enum MarkdownBlock {
    case heading(String, Int)
    case paragraph(String)
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

    func flushParagraph() {
        let trimmed = currentParagraph.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            blocks.append(.paragraph(trimmed))
        }
        currentParagraph = ""
    }

    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

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
        } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            flushParagraph()
            blocks.append(.bullet(String(trimmed.dropFirst(2))))
        } else if let match = try? Regex("^(\\d+)\\.\\s(.+)").wholeMatch(in: trimmed) {
            flushParagraph()
            if let numStr = match[1].substring, let num = Int(numStr) {
                blocks.append(.numbered(num, String(match[2].substring ?? "")))
            }
        } else if trimmed.isEmpty {
            flushParagraph()
        } else {
            if !currentParagraph.isEmpty { currentParagraph += "\n" }
            currentParagraph += line
        }
    }

    if inCodeBlock && !codeBlockBuffer.isEmpty {
        blocks.append(.codeBlock(codeBlockBuffer))
    }

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

// MARK: - Share Card Data & View

struct ShareCardData {
    let categoryName: String
    let categoryIcon: String
    let categoryColor: Color
    let content: String
    let tags: [String]
    let aiSummary: String?
    let createdAt: Date

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: createdAt)
    }
}

struct ShareCardView: View {
    let data: ShareCardData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("一闪AI", systemImage: "sparkles")
                    .font(.title3.bold())
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)
                    )
                Spacer()
                Text(data.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Category
            HStack {
                Image(systemName: data.categoryIcon)
                    .foregroundColor(data.categoryColor)
                Text(data.categoryName)
                    .font(.subheadline.bold())
                    .foregroundColor(data.categoryColor)
                if !data.tags.isEmpty {
                    Text(data.tags.prefix(3).map { "#\($0)" }.joined(separator: " "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Content
            Text(data.content)
                .font(.body)
                .lineLimit(8)

            // AI summary
            if let summary = data.aiSummary {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI 摘要").font(.caption.bold()).foregroundColor(.purple)
                    Text(summary).font(.subheadline).foregroundColor(.secondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.purple.opacity(0.06))
                )
            }

            Divider()

            // Footer
            HStack {
                Text("来自 一闪AI").font(.caption).foregroundColor(.secondary)
                Spacer()
                Text("抓住每个闪念").font(.caption2).foregroundColor(.secondary.opacity(0.6))
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
    }
}

