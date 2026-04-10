import Foundation

struct PromptBuilder {
    static let systemPrompt = """
    续写用户正在输入的文字。直接输出续写内容，不要重复用户已输入的部分。只输出一种最可能的续写，不超过30个字。不要输出任何解释。
    """

    /// Build messages array for the API call
    static func buildMessages(context: ConversationContext) -> [[String: String]] {
        var messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
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
