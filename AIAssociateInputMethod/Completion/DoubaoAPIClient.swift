import Foundation
import os

final class DoubaoAPIClient: @unchecked Sendable {
    private let settings: AppSettings
    private let logger = Logger(subsystem: "com.aiassociate.inputmethod", category: "DoubaoAPI")

    init(settings: AppSettings) {
        self.settings = settings
    }

    /// Stream completion tokens from the Doubao API
    func streamCompletion(
        messages: [[String: String]],
        maxTokens: Int? = nil,
        temperature: Double? = nil
    ) -> AsyncStream<String> {
        AsyncStream { continuation in
            let task = Task {
                do {
                    guard let url = URL(string: "\(settings.baseURL)/chat/completions") else {
                        DebugLog.log("ERROR: Invalid URL")
                        continuation.finish()
                        return
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
                    request.timeoutInterval = 15

                    let body: [String: Any] = [
                        "model": settings.endpointId,
                        "messages": messages,
                        "stream": true,
                        "max_tokens": maxTokens ?? settings.maxTokens,
                        "temperature": temperature ?? settings.temperature,
                        "thinking": ["type": "disabled"],
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    DebugLog.log("API request: model=\(settings.endpointId), thinking=disabled")

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    DebugLog.log("HTTP status: \(statusCode)")

                    guard statusCode == 200 else {
                        var errorBody = ""
                        for try await line in bytes.lines {
                            errorBody += line
                            if errorBody.count > 500 { break }
                        }
                        DebugLog.log("ERROR response: \(errorBody)")
                        continuation.finish()
                        return
                    }

                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        if SSEParser.isDone(line) { break }
                        if let content = SSEParser.parseContentDelta(from: line) {
                            continuation.yield(content)
                        }
                    }
                } catch is CancellationError {
                    // Normal cancellation, no logging needed
                } catch {
                    DebugLog.log("API error: \(error)")
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
