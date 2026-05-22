import UIKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let modelContainer: ModelContainer = {
        let schema = Schema([Note.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: config)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            completeRequest()
            return
        }

        Task {
            var capturedText = ""

            for provider in attachments {
                // Text
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    if let text = try? await loadItem(provider: provider, type: String.self) {
                        capturedText += text
                    }
                }
                // URL (e.g., shared from Safari)
                else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    if let url = try? await loadItem(provider: provider, type: URL.self) {
                        if !capturedText.isEmpty { capturedText += "\n" }
                        capturedText += url.absoluteString
                    }
                }
            }

            if !capturedText.isEmpty {
                await saveNote(capturedText)
            }

            await MainActor.run { completeRequest() }
        }
    }

    private func loadItem<T>(provider: NSItemProvider, type: T.Type) async throws -> T? {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { item, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: item as? T)
                }
            }
        }
    }

    private func saveNote(_ content: String) async {
        let note = Note(content: content)
        await MainActor.run {
            modelContainer.mainContext.insert(note)
            try? modelContainer.mainContext.save()
        }

        // Update widget data
        let notes = (try? modelContainer.mainContext.fetch(FetchDescriptor<Note>())) ?? []
        let todayCount = notes.filter { Calendar.current.isDateInToday($0.createdAt) }.count
        if let ud = UserDefaults(suiteName: "group.com.shanian.flashai") {
            ud.set(notes.count, forKey: "widget_note_count")
            ud.set(todayCount, forKey: "widget_today_count")
        }
    }

    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}
