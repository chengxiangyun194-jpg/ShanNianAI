import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var noteStore: NoteStore
    @EnvironmentObject var notificationManager: NotificationManager
    @StateObject private var storeManager = StoreManager.shared
    @AppStorage("icloud_sync_enabled") private var iCloudSyncEnabled = false
    @State private var apiKey = ""
    @State private var showKeySaved = false
    @State private var showDeleteConfirmation = false
    @State private var showProSheet = false
    @State private var showExporter = false
    @State private var exportURL: URL?
    @State private var selectedExportFormat: ExportFormat = .markdown
    @State private var isExporting = false

    var body: some View {
        NavigationStack {
            List {
                // Pro
                if !storeManager.isPro {
                    Section {
                        Button { showProSheet = true } label: {
                            HStack {
                                Image(systemName: "sparkles").foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("升级一闪Pro").font(.subheadline.bold())
                                    Text("解锁无限 AI 功能").font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                            }.padding(.vertical, 4)
                        }
                    }
                } else {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                            Text("一闪Pro 会员").font(.subheadline.bold())
                            Spacer()
                            Text("已激活").font(.caption).foregroundColor(.green)
                        }
                    }
                }

                // AI
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("OpenAI API Key").font(.subheadline.bold())
                        SecureField("sk-...", text: $apiKey)
                            .textContentType(.password)
                            .font(.caption.monospaced())
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                        HStack {
                            Text("用于 AI 分类、摘要和洞察生成").font(.caption2).foregroundColor(.secondary)
                            Spacer()
                            Button("保存") {
                                UserDefaults.standard.set(apiKey, forKey: "openai_api_key")
                                HapticManager.success()
                                showKeySaved = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showKeySaved = false }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                } header: { Label("AI 服务", systemImage: "brain") }
                footer: { Text("Key 仅存储在本地设备") }

                // iCloud
                Section {
                    Toggle(isOn: $iCloudSyncEnabled) {
                        Label("iCloud 同步", systemImage: "icloud").foregroundColor(.blue)
                    }.onChange(of: iCloudSyncEnabled) { _, _ in HapticManager.selection() }
                } header: { Label("同步", systemImage: "arrow.triangle.2.circlepath") }
                footer: { Text(iCloudSyncEnabled ? "笔记自动同步到 iCloud，切换后需重启" : "开启后通过 iCloud 多设备同步") }

                // Notifications
                Section {
                    if !notificationManager.isAuthorized {
                        Button {
                            HapticManager.medium()
                            Task { await notificationManager.requestAuthorization() }
                        } label: {
                            HStack {
                                Label("开启通知权限", systemImage: "bell.badge").foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    Toggle(isOn: $notificationManager.dailyReminderEnabled) {
                        Label("每日记录提醒", systemImage: "sun.max").foregroundColor(.orange)
                    }.disabled(!notificationManager.isAuthorized)
                    if notificationManager.dailyReminderEnabled {
                        DatePicker("提醒时间", selection: $notificationManager.reminderTime, displayedComponents: .hourAndMinute)
                    }
                    Toggle(isOn: $notificationManager.reviewReminderEnabled) {
                        Label("回顾提醒", systemImage: "clock.arrow.circlepath").foregroundColor(.blue)
                    }.disabled(!notificationManager.isAuthorized)
                    if notificationManager.reviewReminderEnabled {
                        Text("每天早上 9:00 提醒回顾 1/7/30 天前的笔记").font(.caption).foregroundColor(.secondary)
                    }
                } header: { Label("通知", systemImage: "bell") }

                // Data Export
                Section {
                    Picker("格式", selection: $selectedExportFormat) {
                        ForEach(ExportFormat.allCases) { fmt in
                            Label(fmt.name, systemImage: fmt.icon).tag(fmt)
                        }
                    }
                    Button {
                        isExporting = true
                        DispatchQueue.global().async {
                            let url = DataExporter.shared.export(
                                notes: noteStore.notes.filter { !$0.isArchived },
                                format: selectedExportFormat
                            )
                            DispatchQueue.main.async {
                                isExporting = false
                                exportURL = url
                                showExporter = true
                                HapticManager.success()
                            }
                        }
                    } label: {
                        HStack {
                            if isExporting {
                                ProgressView().padding(.trailing, 6)
                            }
                            Text(isExporting ? "导出中..." : "导出笔记")
                        }
                    }
                    .disabled(noteStore.notes.isEmpty || isExporting)
                } header: { Label("数据导出", systemImage: "square.and.arrow.up") }
                footer: { Text("支持 Markdown、JSON、CSV 格式") }

                // Data stats
                Section {
                    LabeledContent("总笔记数", value: "\(noteStore.notes.count)")
                    LabeledContent("已分类", value: "\(noteStore.notes.filter { $0.category != .uncategorized }.count)")
                    LabeledContent("收藏", value: "\(noteStore.notes.filter { $0.isFavorite }.count)")
                    if noteStore.currentStreak > 0 {
                        HStack {
                            Image(systemName: "flame.fill").foregroundColor(.orange)
                            Text("连续记录")
                            Spacer()
                            Text("\(noteStore.currentStreak) 天").foregroundColor(.orange).bold()
                        }
                    }
                } header: { Label("数据", systemImage: "cylinder") }

                // Danger
                Section {
                    Button(role: .destructive) { showDeleteConfirmation = true } label: {
                        Label("删除所有笔记", systemImage: "trash")
                    }
                } header: { Label("危险操作", systemImage: "exclamationmark.triangle") }

                // About
                Section {
                    LabeledContent("版本", value: "1.0.0 (Build 4)")
                    LabeledContent("系统", value: "iOS 17.0+")
                    NavigationLink { privacyPolicyView } label: { Label("隐私政策", systemImage: "hand.raised") }
                } header: { Label("关于", systemImage: "info.circle") }
            }
            .navigationTitle("设置")
            .onAppear { apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? "" }
            .sheet(isPresented: $showProSheet) { ProSubscriptionView() }
            .sheet(isPresented: $showExporter) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .task {
                await storeManager.loadProducts()
                await storeManager.checkEntitlements()
            }
            .alert("已保存", isPresented: $showKeySaved) {
                Button("好的", role: .cancel) {}
            } message: { Text("API Key 已安全存储") }
            .alert("确认删除", isPresented: $showDeleteConfirmation) {
                Button("取消", role: .cancel) {}
                Button("删除全部", role: .destructive) {
                    HapticManager.warning()
                    for note in noteStore.notes { noteStore.deleteNote(note) }
                }
            } message: { Text("此操作不可撤销") }
        }
    }

    private var privacyPolicyView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("隐私政策").font(.title.bold())
                Text("最后更新：2026年5月")
                policySection("数据收集", "一闪AI 收集您主动输入的笔记内容，默认存储在设备本地。")
                policySection("AI 处理", "笔记内容发送到 OpenAI API 处理，OpenAI 不会用于训练。")
                policySection("iCloud 同步", "开启后通过 Apple CloudKit 在您的设备间同步。")
                policySection("订阅付费", "一闪Pro 通过 Apple App Store 处理，遵循 Apple 隐私政策。")
                policySection("通知权限", "本地通知，不涉及服务器。")
            }.padding()
        }
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func policySection(_ title: String, _ content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(content).font(.body).foregroundColor(.secondary)
        }
    }
}

// MARK: - Share Sheet (for export)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
