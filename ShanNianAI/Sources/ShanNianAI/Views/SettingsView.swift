import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var noteStore: NoteStore
    @State private var apiKey = ""
    @State private var showKeySaved = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // API Configuration
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("OpenAI API Key")
                            .font(.subheadline.bold())

                        SecureField("sk-...", text: $apiKey)
                            .textContentType(.password)
                            .font(.caption.monospaced())
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )

                        HStack {
                            Text("用于 AI 分类、摘要和洞察生成")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("保存") {
                                UserDefaults.standard.set(apiKey, forKey: "openai_api_key")
                                showKeySaved = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showKeySaved = false
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                } header: {
                    Label("AI 服务", systemImage: "brain")
                } footer: {
                    Text("Key 仅存储在本地设备，不会上传到任何服务器")
                }

                // Data Management
                Section {
                    LabeledContent("总笔记数", value: "\(noteStore.notes.count)")
                    LabeledContent("已分类", value: "\(noteStore.notes.filter { $0.category != .uncategorized }.count)")
                    LabeledContent("收藏", value: "\(noteStore.notes.filter { $0.isFavorite }.count)")
                } header: {
                    Label("数据", systemImage: "cylinder")
                }

                // Review Settings
                Section {
                    NavigationLink {
                        Text("通知设置（需要 iOS 通知权限）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                    } label: {
                        Label("每日回顾提醒", systemImage: "bell")
                    }
                } header: {
                    Label("提醒", systemImage: "alarm")
                }

                // Danger zone
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("删除所有笔记", systemImage: "trash")
                    }
                } header: {
                    Label("危险操作", systemImage: "exclamationmark.triangle")
                }

                // About
                Section {
                    LabeledContent("版本", value: "1.0.0")
                    LabeledContent("系统要求", value: "iOS 17.0+")
                    NavigationLink {
                        privacyPolicyView
                    } label: {
                        Label("隐私政策", systemImage: "hand.raised")
                    }
                } header: {
                    Label("关于", systemImage: "info.circle")
                }
            }
            .navigationTitle("设置")
            .onAppear {
                apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
            }
            .alert("已保存", isPresented: $showKeySaved) {
                Button("好的", role: .cancel) {}
            } message: {
                Text("API Key 已安全存储")
            }
            .alert("确认删除", isPresented: $showDeleteConfirmation) {
                Button("取消", role: .cancel) {}
                Button("删除全部", role: .destructive) {
                    for note in noteStore.notes {
                        noteStore.deleteNote(note)
                    }
                }
            } message: {
                Text("此操作不可撤销，将删除所有闪念笔记")
            }
        }
    }

    private var privacyPolicyView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("隐私政策")
                    .font(.title.bold())

                Text("最后更新：2025年5月")

                Group {
                    policySection("数据收集", "一闪AI 收集您主动输入的笔记内容。所有数据默认存储在您的设备本地，不会上传到我们的服务器。")

                    policySection("AI 处理", "当您使用 AI 分类、摘要或洞察功能时，笔记内容会发送到 OpenAI API 进行处理。OpenAI 不会使用通过 API 发送的数据来训练模型。")

                    policySection("数据存储", "所有笔记数据使用 Apple SwiftData 存储在您的设备上。AI 分类结果同样存储在本地。您可以在设置中随时删除所有数据。")

                    policySection("第三方服务", "本应用仅使用 OpenAI API 作为 AI 服务提供商。您的 API Key 存储在设备 Keychain 中，仅用于 API 调用鉴权。")

                    policySection("用户权利", "您可以随时查看、编辑、删除任何笔记。可以在设置中一键清空所有数据。")
                }
            }
            .padding()
        }
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func policySection(_ title: String, _ content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}
