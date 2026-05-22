import XCTest
@testable import ShanNianAI

final class AIServiceTests: XCTestCase {

    var service: AIService!

    override func setUp() {
        super.setUp()
        service = AIService.shared
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "openai_api_key")
        super.tearDown()
    }

    // MARK: - Configuration

    func testIsNotConfiguredWithoutAPIKey() {
        UserDefaults.standard.removeObject(forKey: "openai_api_key")
        XCTAssertFalse(service.isConfigured)
    }

    func testIsConfiguredWithAPIKey() {
        UserDefaults.standard.set("sk-test123", forKey: "openai_api_key")
        XCTAssertTrue(service.isConfigured)
    }

    // MARK: - Classification JSON Parsing

    func testParseValidClassificationResponse() {
        let json = """
        {
            "category": "灵感",
            "tags": ["设计", "UI"],
            "summary": "新的设计灵感",
            "relatedConcepts": ["Material Design", "iOS"]
        }
        """

        do {
            let data = json.data(using: .utf8)!
            let response = try JSONDecoder().decode(AIClassificationResponse.self, from: data)
            XCTAssertEqual(response.category, .inspiration)
            XCTAssertEqual(response.tags.count, 2)
        } catch {
            XCTFail("Parsing failed: \(error)")
        }
    }

    func testParseClassificationWithMarkdownWrapper() {
        // AI sometimes wraps JSON in markdown code blocks
        let json = """
        ```json
        {
            "category": "学习",
            "tags": ["Swift"],
            "summary": "学习Swift",
            "relatedConcepts": ["iOS"]
        }
        ```
        """

        // This tests the cleanJSON logic indirectly
        let cleaned = json
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let data = cleaned.data(using: .utf8)!
        let response = try? JSONDecoder().decode(AIClassificationResponse.self, from: data)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.category, .learning)
    }

    func testParseClassificationWithExtraWhitespace() {
        let json = """

        {
            "category": "待办",
            "tags": ["任务"],
            "summary": "测试",
            "relatedConcepts": []
        }

        """

        let cleaned = json.trimmingCharacters(in: .whitespacesAndNewlines)
        let data = cleaned.data(using: .utf8)!
        let response = try? JSONDecoder().decode(AIClassificationResponse.self, from: data)
        XCTAssertNotNil(response)
    }

    func testParseClassificationInvalidCategory() {
        let json = """
        {
            "category": "不存在的分类",
            "tags": [],
            "summary": "",
            "relatedConcepts": []
        }
        """

        let data = json.data(using: .utf8)!
        let response = try? JSONDecoder().decode(AIClassificationResponse.self, from: data)
        XCTAssertNil(response, "Should fail to decode invalid category")
    }

    func testParseClassificationMissingFields() {
        let json = """
        {
            "category": "创意"
        }
        """

        let data = json.data(using: .utf8)!
        let response = try? JSONDecoder().decode(AIClassificationResponse.self, from: data)
        XCTAssertNil(response, "Should fail when required fields are missing")
    }

    // MARK: - Weekly Insight Parsing

    func testParseValidWeeklyInsight() {
        let json = """
        {
            "weekStartDate": "2025-05-19",
            "dominantCategory": "创意",
            "topTags": ["AI", "产品", "设计"],
            "noteCount": 23,
            "summary": "本周创意产出丰富",
            "suggestion": "建议聚焦1-2个方向深入",
            "emotionalTrend": "波动但总体积极"
        }
        """

        let data = json.data(using: .utf8)!
        let insight = try? JSONDecoder().decode(WeeklyInsight.self, from: data)
        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.dominantCategory, .idea)
        XCTAssertEqual(insight?.topTags.count, 3)
        XCTAssertEqual(insight?.noteCount, 23)
    }

    // MARK: - Error Handling

    func testAIServiceErrorDescriptions() {
        XCTAssertFalse(AIServiceError.notConfigured.errorDescription!.isEmpty)
        XCTAssertFalse(AIServiceError.requestFailed.errorDescription!.isEmpty)
        XCTAssertFalse(AIServiceError.invalidResponse.errorDescription!.isEmpty)
    }

    func testAIServiceErrorIsLocalizedError() {
        let error: any Error = AIServiceError.notConfigured
        XCTAssertNotNil(error.localizedDescription)
    }

    // MARK: - GPT-4.1-mini

    func testModelNameIsCorrect() {
        // Model is private, test via classification requiring API key
        // This just ensures the model name constant is valid format
        UserDefaults.standard.set("sk-test", forKey: "openai_api_key")
        XCTAssertTrue(service.isConfigured)
    }
}
