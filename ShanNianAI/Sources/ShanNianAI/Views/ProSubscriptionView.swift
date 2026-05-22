import SwiftUI
import StoreKit

struct ProSubscriptionView: View {
    @StateObject private var storeManager = StoreManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("一闪Pro")
                            .font(.system(size: 32, weight: .bold, design: .rounded))

                        Text("解锁全部 AI 功能")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        featureRow(icon: "infinity", color: .orange, title: "无限笔记", desc: "无限制记录闪念")
                        featureRow(icon: "brain.head.profile", color: .purple, title: "AI 无限次", desc: "不限次数 AI 分类和摘要")
                        featureRow(icon: "chart.bar.doc.horizontal", color: .blue, title: "AI 周报", desc: "每周自动生成成长洞察报告")
                        featureRow(icon: "link", color: .green, title: "关联发现", desc: "AI 发现笔记间的隐藏关联")
                        featureRow(icon: "icloud", color: .teal, title: "iCloud 同步", desc: "多设备数据同步")
                        featureRow(icon: "tag", color: .pink, title: "自定义标签", desc: "自由创建和管理标签")
                    }
                    .padding(.horizontal, 32)

                    // Pricing
                    VStack(spacing: 12) {
                        if storeManager.isPro {
                            // Already Pro
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.green)
                                Text("你已是一闪Pro会员")
                                    .font(.headline)
                                Text("享受所有 Pro 功能")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 20)
                        } else if storeManager.isLoading && storeManager.products.isEmpty {
                            ProgressView("加载中...")
                                .padding()
                        } else if !storeManager.products.isEmpty {
                            ForEach(storeManager.products, id: \.id) { product in
                                productCard(product)
                            }
                        } else {
                            Button {
                                Task { await storeManager.loadProducts() }
                            } label: {
                                Text("加载订阅方案")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(.orange)
                                    )
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Restore
                    if !storeManager.isPro {
                        Button {
                            Task { await storeManager.restorePurchases() }
                        } label: {
                            Text("恢复购买")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .disabled(storeManager.isLoading)
                    }

                    // Footer
                    VStack(spacing: 4) {
                        Text("免费版：每月 30 条笔记 + 30 次 AI 分类")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("订阅可随时在系统设置中取消")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("一闪Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .task {
                await storeManager.loadProducts()
                await storeManager.checkEntitlements()
            }
            .alert("错误", isPresented: .init(
                get: { storeManager.errorMessage != nil },
                set: { if !$0 { storeManager.errorMessage = nil } }
            )) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(storeManager.errorMessage ?? "")
            }
        }
    }

    // MARK: - Product Card

    private func productCard(_ product: Product) -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.headline)
                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3.bold())
                    if let period = product.subscription?.subscriptionPeriod {
                        Text(periodText(period))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Button {
                Task { await storeManager.purchase(product) }
            } label: {
                if storeManager.isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                } else {
                    Text("订阅")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(storeManager.isLoading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
        .overlay(alignment: .topTrailing) {
            if product.id.contains("yearly") {
                Text("推荐")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(.orange)
                    )
                    .padding(8)
            }
        }
    }

    private func featureRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func periodText(_ period: Product.SubscriptionPeriod) -> String {
        switch (period.value, period.unit) {
        case (1, .month): return "每月"
        case (1, .year): return "每年"
        case (let n, .month): return "每\(n)月"
        case (let n, .year): return "每\(n)年"
        default: return "每\(period.value)\(unitSymbol(period.unit))"
        }
    }

    private func unitSymbol(_ unit: Product.SubscriptionPeriod.Unit) -> String {
        switch unit {
        case .day: return "天"
        case .week: return "周"
        case .month: return "月"
        case .year: return "年"
        @unknown default: return ""
        }
    }
}

extension Product {
    var displayName: String {
        if id.contains("yearly") { return "年度订阅" }
        if id.contains("monthly") { return "月度订阅" }
        return self.id
    }
}
