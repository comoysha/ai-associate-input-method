import SwiftUI

@Observable
final class AppSettings {
    var apiKey: String {
        get { UserDefaults.standard.string(forKey: "apiKey") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "apiKey") }
    }

    var endpointId: String {
        get { UserDefaults.standard.string(forKey: "endpointId") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "endpointId") }
    }

    var baseURL: String {
        get { UserDefaults.standard.string(forKey: "baseURL") ?? "https://ark.cn-beijing.volces.com/api/v3" }
        set { UserDefaults.standard.set(newValue, forKey: "baseURL") }
    }

    var maxTokens: Int {
        get { UserDefaults.standard.integer(forKey: "maxTokens").nonZero ?? 64 }
        set { UserDefaults.standard.set(newValue, forKey: "maxTokens") }
    }

    var temperature: Double {
        get {
            let val = UserDefaults.standard.double(forKey: "temperature")
            return val == 0 ? 0.3 : val
        }
        set { UserDefaults.standard.set(newValue, forKey: "temperature") }
    }

    var debounceMs: Int {
        get { UserDefaults.standard.integer(forKey: "debounceMs").nonZero ?? 300 }
        set { UserDefaults.standard.set(newValue, forKey: "debounceMs") }
    }

    var overlayDismissSec: Int {
        get { UserDefaults.standard.integer(forKey: "overlayDismissSec").nonZero ?? 5 }
        set { UserDefaults.standard.set(newValue, forKey: "overlayDismissSec") }
    }

    var systemPrompt: String {
        get {
            UserDefaults.standard.string(forKey: "systemPrompt")
                ?? "续写用户正在输入的文字。直接输出续写内容，不要重复用户已输入的部分。只输出一种最可能的续写，不超过30个字。不要输出任何解释。"
        }
        set { UserDefaults.standard.set(newValue, forKey: "systemPrompt") }
    }

    var isConfigured: Bool {
        !apiKey.isEmpty && !endpointId.isEmpty
    }

    init() {
        loadFromEnvIfNeeded()
    }

    /// Load API credentials from .env file if UserDefaults has no values yet
    private func loadFromEnvIfNeeded() {
        guard apiKey.isEmpty || endpointId.isEmpty else { return }

        let env = Self.loadEnvFile()
        if apiKey.isEmpty, let key = env["DOUBAO_API_KEY"] {
            apiKey = key
        }
        if endpointId.isEmpty, let ep = env["DOUBAO_ENDPOINT_ID"] {
            endpointId = ep
        }
        if let url = env["DOUBAO_BASE_URL"] {
            baseURL = url
        }
    }

    private static func loadEnvFile() -> [String: String] {
        // Look for .env in the app bundle's parent directory, or in the working directory
        let candidates = [
            Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(".env"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(".env"),
        ]

        for url in candidates {
            guard let content = try? String(contentsOf: url, encoding: .utf8) else { continue }
            var env: [String: String] = [:]
            for line in content.split(separator: "\n") where !line.hasPrefix("#") {
                let parts = line.split(separator: "=", maxSplits: 1)
                if parts.count == 2 {
                    env[String(parts[0]).trimmingCharacters(in: .whitespaces)] =
                        String(parts[1]).trimmingCharacters(in: .whitespaces)
                }
            }
            return env
        }
        return [:]
    }
}

private extension Int {
    var nonZero: Int? {
        self == 0 ? nil : self
    }
}
