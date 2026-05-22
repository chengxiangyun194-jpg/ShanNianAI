import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var noteStore: NoteStore
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "bolt.fill",
            gradient: [.orange, .pink],
            title: "一闪AI",
            subtitle: "抓住每一个闪念，AI 帮你整理",
            description: "灵感转瞬即逝，一闪帮你瞬间捕捉。\nAI 自动分类、生成摘要、发现关联。"
        ),
        OnboardingPage(
            icon: "brain.head.profile",
            gradient: [.purple, .blue],
            title: "AI 智能整理",
            subtitle: "自动分类 · 智能摘要 · 洞察周报",
            description: "AI 自动为每条笔记分类、打标签、生成摘要。\n每周生成个性化成长洞察，帮你发现思考的轨迹。"
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            gradient: [.green, .teal],
            title: "追踪成长",
            subtitle: "连续记录 · 定时回顾 · 数据洞察",
            description: "保持每日记录，积累连续天数。\n定期回顾过去的笔记，见证自己的成长轨迹。"
        ),
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("跳过") {
                            completeOnboarding()
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                    }
                }

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                // Bottom button
                VStack(spacing: 12) {
                    Button {
                        handleContinue()
                    } label: {
                        Text(currentPage < pages.count - 1 ? "继续" : "开始使用")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: pages[currentPage].gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 40)

                    // Dots indicator
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Circle()
                                .fill(i == currentPage ? pages[currentPage].gradient[0] : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func handleContinue() {
        if currentPage < pages.count - 1 {
            HapticManager.selection()
            withAnimation { currentPage += 1 }
        } else {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        HapticManager.success()
        withAnimation(.easeInOut(duration: 0.4)) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Models

struct OnboardingPage {
    let icon: String
    let gradient: [Color]
    let title: String
    let subtitle: String
    let description: String
}

// MARK: - Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(
                        LinearGradient(
                            colors: page.gradient.map { $0.opacity(0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: page.icon)
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: page.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 10) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text(page.subtitle)
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: page.gradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }
}
