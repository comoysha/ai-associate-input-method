import Foundation

struct ConversationContext {
    let pageContent: String
    let currentInput: String

    var isEmpty: Bool {
        pageContent.isEmpty && currentInput.isEmpty
    }
}
