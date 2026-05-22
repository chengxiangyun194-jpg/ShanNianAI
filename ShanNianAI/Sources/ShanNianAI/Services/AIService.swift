import Foundation

final class AIService {
    static let shared = AIService()

    // MARK: - 配置
    // 优先走服务端代理；如果代理不可用且设置了本地 Key，走直连
    private let proxyURL = "https://YOUR_PROJECT.vercel.app/api"

    private var directBaseURL: String { "https://api.deepseek.com/v1" }
    private var directAPIKey: String {
        UserDefaults.standard.string(forKey: "dev_direct_api_key") ?? ""
    }
    private var useDirectMode: Bool { !directAPIKey.isEmpty }

    private let appToken = "shan-nian-ai-2026"
    private let model = "deepseek-chat"

    private var session: URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        return URLSession(configuration: config)
    }

    var isConfigured: Bool { true }

    // MARK: - Classification

    func classify(content: String) async throws -> AIClassificationResponse {
        let prompt = """
        你是一个智能笔记分类助手。分析以下笔记内容，返回JSON格式的分类结果。

        笔记内容：
        \(content)

        请返回如下JSON（不要包含markdown代码块标记）：
        {
          "category": "灵感|待办|收藏|日记|创意|问题|学习|未分类",
          "tags": ["标签1", "标签2", "标签3"],
          "summary": "20字以内的核心总结",
          "relatedConcepts": ["相关概念1", "相关概念2"]
        }
        """

        let data = try await chatCompletion(prompt: prompt)
        return try decode(from: data)
    }

    // MARK: - Weekly Insights

    func generateWeeklyInsight(notes: [Note], weekStart: Date) async throws -> WeeklyInsight {
        let notesText = notes.map { "- [\($0.category.rawValue)] \($0.content)" }.joined(separator: "\n")

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let weekStr = formatter.string(from: weekStart)

        let prompt = """
        你是一个个人成长分析助手。分析用户本周的笔记，生成洞察报告。

        本周笔记：
        \(notesText)

        请返回如下JSON：
        {
          "weekStartDate": "\(weekStr)",
          "dominantCategory": "主要分类",
          "topTags": ["高频标签1", "高频标签2"],
          "noteCount": \(notes.count),
          "summary": "本周核心洞察（50字内）",
          "suggestion": "给用户的行动建议（50字内）",
          "emotionalTrend": "整体情绪趋势描述"
        }
        """

        let data = try await chatCompletion(prompt: prompt)
        let insight = try JSONDecoder().decode(WeeklyInsight.self, from: data)
        return insight
    }

    // MARK: - Find Related Notes

    func findRelatedNotes(current: Note, allNotes: [Note]) async throws -> [UUID] {
        let others = allNotes.filter { $0.id != current.id }.prefix(20)
        let contextText = others.map { "[\($0.id)] \($0.content)" }.joined(separator: "\n")

        let prompt = """
        找出与以下笔记内容相关的笔记ID。只返回可能存在关联的ID。

        当前笔记：\(current.content)

        候选笔记：
        \(contextText)

        返回JSON格式：
        {
          "relatedIDs": ["id1", "id2"]
        }
        """

        let data = try await chatCompletion(prompt: prompt)
        struct RelatedResponse: Codable {
            let relatedIDs: [String]
        }
        let resp = try JSONDecoder().decode(RelatedResponse.self, from: data)
        return resp.relatedIDs.compactMap { UUID(uuidString: $0) }
    }

    // MARK: - Inspiration Analysis

    func analyzeInspiration(_ note: Note) async throws -> InspirationAnalysis {
        let prompt = """
        你是一个创意孵化助手。请对以下灵感笔记进行深度分析和延伸。

        灵感内容：
        \(note.content)

        AI摘要：\(note.aiSummary ?? "无")
        标签：\(note.tags.joined(separator: "、"))

        请返回如下JSON（不要包含markdown代码块标记）：
        {
          "extensions": ["创意延伸1", "创意延伸2", "创意延伸3"],
          "suggestions": ["实践建议1", "实践建议2"],
          "relatedFields": ["相关领域1", "相关领域2"],
          "coreInsight": "核心洞察（30字内）"
        }
        """

        let data = try await chatCompletion(prompt: prompt)
        return try decode(from: data)
    }

    // MARK: - Private

    private func chatCompletion(prompt: String) async throws -> Data {
        // 优先代理，失败回退直连
        if useDirectMode {
            return try await directChatCompletion(prompt: prompt)
        }

        do {
            return try await proxyChatCompletion(prompt: prompt)
        } catch {
            return try await directChatCompletion(prompt: prompt)
        }
    }

    private func proxyChatCompletion(prompt: String) async throws -> Data {
        let url = URL(string: "\(proxyURL)/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appToken, forHTTPHeaderField: "X-App-Token")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "你是一个精确的JSON输出助手，只输出要求的JSON格式，不加任何markdown标记。"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
            "max_tokens": 800
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.requestFailed
        }

        if httpResponse.statusCode == 401 {
            throw AIServiceError.notConfigured
        }

        guard httpResponse.statusCode == 200 else {
            throw AIServiceError.requestFailed
        }

        return try extractContent(from: data)
    }

    private func directChatCompletion(prompt: String) async throws -> Data {
        guard !directAPIKey.isEmpty else {
            throw AIServiceError.notConfigured
        }

        let url = URL(string: "\(directBaseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(directAPIKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "你是一个精确的JSON输出助手，只输出要求的JSON格式，不加任何markdown标记。"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
            "max_tokens": 800
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIServiceError.requestFailed
        }

        return try extractContent(from: data)
    }

    private func extractContent(from data: Data) throws -> Data {
        struct ChatResponse: Codable {
            struct Choice: Codable {
                struct Message: Codable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }

        let chatResp = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = chatResp.choices.first?.message.content else {
            throw AIServiceError.invalidResponse
        }

        return content.data(using: .utf8) ?? Data()
    }

    private func decode<T: Decodable>(from data: Data) throws -> T {
        let cleaned = cleanJSON(data)
        return try JSONDecoder().decode(T.self, from: cleaned)
    }

    private func cleanJSON(_ data: Data) -> Data {
        var text = String(data: data, encoding: .utf8) ?? ""
        text = text.replacingOccurrences(of: "```json", with: "")
        text = text.replacingOccurrences(of: "```", with: "")
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.data(using: .utf8) ?? data
    }
}

enum AIServiceError: LocalizedError {
    case notConfigured
    case requestFailed
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "AI 服务未配置，请在设置中添加 API Key"
        case .requestFailed: return "AI 服务请求失败，请检查网络或 Key"
        case .invalidResponse: return "AI 返回数据异常，请重试"
        }
    }
}
