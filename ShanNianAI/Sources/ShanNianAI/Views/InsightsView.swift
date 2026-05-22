import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var noteStore: NoteStore
    @State private var isGenerating = false
    @State private var selectedTimeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "本周"
        case month = "本月"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Time range picker
                    Picker("时间范围", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Stats cards
                    statsGrid

                    // Category distribution
                    categorySection

                    // AI Insight card
                    aiInsightSection

                    // Generate button
                    if noteStore.weeklyInsight == nil {
                        generateButton
                    }

                    // Review prompt
                    reviewSection
                }
                .padding()
            }
            .navigationTitle("数据洞察")
            .refreshable {
                await generateInsight()
            }
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "总笔记",
                value: "\(noteStore.notes.count)",
                icon: "note.text",
                color: .blue
            )

            StatCard(
                title: "本周新增",
                value: "\(weekCount)",
                icon: "plus.circle",
                color: .green
            )

            StatCard(
                title: "已分类",
                value: "\(noteStore.notes.filter { $0.category != .uncategorized }.count)",
                icon: "folder.fill",
                color: .orange
            )

            StatCard(
                title: "待回顾",
                value: "\(noteStore.notes.filter { $0.reviewedAt == nil && !$0.isArchived }.count)",
                icon: "clock",
                color: .purple
            )
        }
    }

    // MARK: - Category Distribution

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类分布")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(NoteCategory.allCases, id: \.self) { category in
                let count = noteStore.notesByCategory(category).count
                let total = max(noteStore.notes.count, 1)
                let ratio = Double(count) / Double(total)

                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .foregroundColor(category.color)
                        .frame(width: 24)

                    Text(category.rawValue)
                        .font(.subheadline)

                    Spacer()

                    Text("\(count)")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }

                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(category.color.opacity(0.3))
                        .frame(width: geo.size.width * ratio)
                }
                .frame(height: 6)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }

    // MARK: - AI Insight

    private var aiInsightSection: some View {
        Group {
            if isGenerating {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("AI 正在分析你的笔记...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if let insight = noteStore.weeklyInsight {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("AI 周报")
                            .font(.headline)
                        Spacer()
                        Text(insight.weekStartDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    insightRow(icon: "chart.pie", label: "主要关注", value: insight.dominantCategory.rawValue)
                    insightRow(icon: "tag", label: "高频标签", value: insight.topTags.map { "#\($0)" }.joined(separator: " "))
                    insightRow(icon: "text.quote", label: "核心洞察", value: insight.summary)
                    insightRow(icon: "lightbulb", label: "建议行动", value: insight.suggestion)
                    insightRow(icon: "waveform.path.ecg", label: "情绪趋势", value: insight.emotionalTrend)

                    if insight.noteCount > 0 {
                        Text("基于本周 \(insight.noteCount) 条笔记生成")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.purple.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.purple.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }

    private func insightRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 20)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(.subheadline)
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            Task { await generateInsight() }
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("生成 AI 洞察")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.purple, .pink.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isGenerating)
    }

    // MARK: - Review Section

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("回顾提醒", systemImage: "clock.arrow.circlepath")
                .font(.headline)

            ForEach([1, 7, 30], id: \.self) { days in
                let count = noteStore.notesForReview(daysAgo: days).count
                HStack {
                    Text("\(days)天前")
                        .font(.subheadline)
                    Spacer()
                    Text("\(count) 条笔记待回顾")
                        .font(.caption)
                        .foregroundColor(count > 0 ? .orange : .secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }

    // MARK: - Helpers

    private var weekCount: Int {
        let weekStart = Calendar.current.date(
            from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        ) ?? Date()
        return noteStore.notes.filter { $0.createdAt >= weekStart }.count
    }

    private func generateInsight() async {
        isGenerating = true
        await noteStore.generateWeeklyInsight()
        isGenerating = false
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.title.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        )
    }
}
