import Foundation

/// Parses Server-Sent Events (SSE) from a byte stream
struct SSEParser {
    /// Extract the content delta from an SSE data line.
    /// Supports reasoning models that use `reasoning_content` during thinking
    /// and then emit actual content in `content`.
    static func parseContentDelta(from line: String) -> String? {
        guard line.hasPrefix("data: ") else { return nil }

        let jsonString = String(line.dropFirst(6))
        if jsonString == "[DONE]" { return nil }

        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let delta = firstChoice["delta"] as? [String: Any] else {
            return nil
        }

        // First try `content` — the actual response
        if let content = delta["content"] as? String, !content.isEmpty {
            return content
        }

        // Skip `reasoning_content` — it's the model thinking, not the answer
        // Return nil so we don't yield empty tokens
        return nil
    }

    /// Check if the SSE line indicates the stream is done
    static func isDone(_ line: String) -> Bool {
        line.hasPrefix("data: [DONE]")
    }
}
