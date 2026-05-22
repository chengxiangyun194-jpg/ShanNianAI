import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var noteStore: NoteStore
    @EnvironmentObject var notificationManager: NotificationManager
    @StateObject private var storeManager = StoreManager.shared
    @AppStorage("icloud_sync_enabled") private var iCloudSyncEnabled = false
    @State private var showDeleteConfirmation = false
    @State private var showProSheet = false
    @State private var devApiKey = UserDefaults.standard.string(forKey: "dev_direct_api_key") ?? ""
    @State private var showDevKeySaved = false
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

                // AI 状态

                // 开发者 Key（优先使用代理，Key 为回退）
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("开发者：直连 API Key").font(.subheadline.bold())
                        SecureField("sk-...（DeepSeek 或 OpenAI）", text: $devApiKey)
                            .textContentType(.password)
                            .font(.caption.monospaced())
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                        HStack {
                            Text("仅开发测试用，优先走代理").font(.caption2).foregroundColor(.secondary)
                            Spacer()
                            Button("保存") {
                                UserDefaults.standard.set(devApiKey, forKey: "dev_direct_api_key")
                                HapticManager.success()
                                showDevKeySaved = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showDevKeySaved = false }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(devApiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
                footer: { Text("Key 仅存本地。留空则走服务端代理") }

                Section {
                    HStack {
                        Image(systemName: "brain.fill").foregroundColor(.purple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI 服务").font(.subheadline.bold())
                            Text("由服务端代理，无需自行配置")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                footer: {
                    Text("AI 调用通过服务端代理，安全可靠")
                }

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
                } header: { Label("通知", systemImage: "bell") }

                // Data
                Section {
                    Picker("导出格式", selection: $selectedExportFormat) {
                        ForEach(ExportFormat.allCases, id: \.id) { format in
                            Text(format.name).tag(format)
                        }
                    }

                    Button {
                        Task {
                            isExporting = true
                            HapticManager.medium()
                            let exporter = DataExporter.shared
                            let url = await exporter.export(notes: noteStore.notes, format: selectedExportFormat)
                            isExporting = false
                            if let url = url {
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
            .alert("已保存", isPresented: $showDevKeySaved) {
                Button("好的", role: .cancel) {}
            } message: { Text("本地 API Key 已存储") }

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
                policySection("AI 处理", "笔记内容通过服务端代理发送到 AI 模型处理，不会用于训练。")
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
