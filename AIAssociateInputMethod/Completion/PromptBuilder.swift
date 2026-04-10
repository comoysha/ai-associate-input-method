import Foundation

struct PromptBuilder {
    /// Build messages array for the API call
    static func buildMessages(context: ConversationContext, settings: AppSettings) -> [[String: String]] {
        var messages: [[String: String]] = [
            ["role": "system", "content": settings.systemPrompt]
        ]

        // Build user message with optional context
        var userMessage = ""

        if !context.pageContent.isEmpty {
            let truncated = truncateToLastN(context.pageContent, characters: 3000)
            userMessage += "对话上下文：\(truncated)\n"
        }

        userMessage += "用户正在输入：\(context.currentInput)"

        messages.append(["role": "user", "content": userMessage])

        return messages
    }

    private static func truncateToLastN(_ text: String, characters: Int) -> String {
        if text.count <= characters { return text }
        let startIndex = text.index(text.endIndex, offsetBy: -characters)
        return String(text[startIndex...])
    }
}
