import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ExportFormat: CaseIterable, Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let utType: UTType
    let color: Color

    static let markdown = ExportFormat(
        id: "markdown",
        name: "Markdown",
        icon: "doc.richtext",
        utType: .plainText,
        color: .blue
    )

    static let json = ExportFormat(
        id: "json",
        name: "JSON",
        icon: "curlybraces",
        utType: .json,
        color: .orange
    )

    static let csv = ExportFormat(
        id: "csv",
        name: "CSV",
        icon: "tablecells",
        utType: .commaSeparatedText,
        color: .green
    )

    static var allCases: [ExportFormat] { [.markdown, .json, .csv] }
}

final class DataExporter {
    static let shared = DataExporter()

    private init() {}

    func export(notes: [Note], format: ExportFormat) -> URL? {
        switch format.id {
        case "markdown": return exportMarkdown(notes)
        case "json": return exportJSON(notes)
        case "csv": return exportCSV(notes)
        default: return nil
        }
    }

    private func exportMarkdown(_ notes: [Note]) -> URL? {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm"

        var md = "# 一闪AI 笔记导出\n\n"
        md += "导出时间：\(df.string(from: Date()))\n"
        md += "共 \(notes.count) 条笔记\n\n---\n\n"

        for note in notes.sorted(by: { $0.createdAt > $1.createdAt }) {
            md += "## \(note.content.prefix(40).replacingOccurrences(of: "\n", with: " "))\n\n"
            md += "- **分类**：\(note.category.rawValue)\n"
            if let summary = note.aiSummary { md += "- **AI 摘要**：\(summary)\n" }
            if !note.tags.isEmpty { md += "- **标签**：\(note.tags.map { "#\($0)" }.joined(separator: " "))\n" }
            md += "- **时间**：\(df.string(from: note.createdAt))\n"
            if note.reviewCount > 0 { md += "- **回顾**：\(note.reviewCount) 次\n" }
            md += "\n\(note.content)\n\n---\n\n"
        }

        return write(md, name: "ShanNianAI_Notes", ext: "md")
    }

    private func exportJSON(_ notes: [Note]) -> URL? {
        let df = ISO8601DateFormatter()

        let exportNotes = notes.map { note -> [String: Any] in
            var dict: [String: Any] = [
                "id": note.id.uuidString,
                "content": note.content,
                "category": note.category.rawValue,
                "tags": note.tags,
                "createdAt": df.string(from: note.createdAt),
                "modifiedAt": df.string(from: note.modifiedAt),
                "isFavorite": note.isFavorite,
                "isPinned": note.isPinned,
                "reviewCount": note.reviewCount,
            ]
            if let summary = note.aiSummary { dict["aiSummary"] = summary }
            if let insight = note.aiInsight { dict["aiInsight"] = insight }
            return dict
        }

        let root: [String: Any] = [
            "app": "一闪AI",
            "exportDate": df.string(from: Date()),
            "noteCount": notes.count,
            "notes": exportNotes,
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: root, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }

        return write(jsonString, name: "ShanNianAI_Notes", ext: "json")
    }

    private func exportCSV(_ notes: [Note]) -> URL? {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var csv = "ID,分类,内容,标签,AI摘要,创建时间,收藏,置顶,回顾次数\n"

        for note in notes {
            let content = note.content
                .replacingOccurrences(of: "\"", with: "\"\"")
                .replacingOccurrences(of: "\n", with: " ")
            let tags = note.tags.joined(separator: ";")
            let summary = (note.aiSummary ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\"\(note.id.uuidString)\","
            csv += "\"\(note.category.rawValue)\","
            csv += "\"\(content)\","
            csv += "\"\(tags)\","
            csv += "\"\(summary)\","
            csv += "\"\(df.string(from: note.createdAt))\","
            csv += "\(note.isFavorite ? "是" : "否"),"
            csv += "\(note.isPinned ? "是" : "否"),"
            csv += "\(note.reviewCount)\n"
        }

        return write(csv, name: "ShanNianAI_Notes", ext: "csv")
    }

    private func write(_ content: String, name: String, ext: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("\(name).\(ext)")

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
