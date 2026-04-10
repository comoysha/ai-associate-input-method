#!/usr/bin/env swift

import Foundation

// Read .env file
func loadEnv() -> [String: String] {
    let path = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent(".env").path
    guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
        print("ERROR: .env file not found")
        exit(1)
    }
    var env: [String: String] = [:]
    for line in content.split(separator: "\n") {
        let parts = line.split(separator: "=", maxSplits: 1)
        if parts.count == 2 {
            env[String(parts[0])] = String(parts[1])
        }
    }
    return env
}

let env = loadEnv()
let apiKey = env["DOUBAO_API_KEY"]!
let endpointId = env["DOUBAO_ENDPOINT_ID"]!
let baseURL = env["DOUBAO_BASE_URL"] ?? "https://ark.cn-beijing.volces.com/api/v3"

struct TestCase {
    let name: String
    let messages: [[String: String]]
}

let testCases: [TestCase] = [
    TestCase(
        name: "Test 1: Simple Chinese completion",
        messages: [
            ["role": "system", "content": "续写用户正在输入的文字。直接输出续写内容，不要重复已输入部分。只输出一种最可能的续写，不超过20个字。"],
            ["role": "user", "content": "用户正在输入：帮我写一个"]
        ]
    ),
    TestCase(
        name: "Test 2: With conversation context",
        messages: [
            ["role": "system", "content": "续写用户正在输入的文字。直接输出续写内容，不要重复已输入部分。只输出一种最可能的续写，不超过20个字。"],
            ["role": "user", "content": "对话上下文：用户问AI帮写Python读CSV，AI给了代码。\n用户正在输入：不错，但我还需要"]
        ]
    ),
    TestCase(
        name: "Test 3: Short input (2 chars)",
        messages: [
            ["role": "system", "content": "续写用户正在输入的文字。直接输出续写内容，不要重复已输入部分。只输出一种最可能的续写，不超过20个字。"],
            ["role": "user", "content": "用户正在输入：帮我"]
        ]
    ),
    TestCase(
        name: "Test 4: English input",
        messages: [
            ["role": "system", "content": "续写用户正在输入的文字。直接输出续写内容，不要重复已输入部分。只输出一种最可能的续写，不超过20个字。"],
            ["role": "user", "content": "用户正在输入：Can you help me"]
        ]
    ),
    TestCase(
        name: "Test 5: Instruction with context",
        messages: [
            ["role": "system", "content": "续写用户正在输入的文字。直接输出续写内容，不要重复已输入部分。只输出一种最可能的续写，不超过20个字。"],
            ["role": "user", "content": "对话上下文：用户说代码有bug报空指针，AI说第15行变量没初始化。\n用户正在输入：改成"]
        ]
    ),
]

func runTest(_ test: TestCase) async {
    print("\n=== \(test.name) ===")

    let url = URL(string: "\(baseURL)/chat/completions")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.timeoutInterval = 30

    let body: [String: Any] = [
        "model": endpointId,
        "messages": test.messages,
        "stream": false,
        "max_tokens": 32,
        "temperature": 0.3,
        "thinking": ["type": "disabled"],
    ]
    request.httpBody = try! JSONSerialization.data(withJSONObject: body)

    do {
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let choices = json["choices"] as! [[String: Any]]
        let message = choices[0]["message"] as! [String: Any]
        let content = message["content"] as? String ?? "(empty)"
        print("  Output: \(content)")
    } catch {
        print("  ERROR: \(error)")
    }
}

let semaphore = DispatchSemaphore(value: 0)
Task {
    for test in testCases {
        await runTest(test)
    }
    semaphore.signal()
}
semaphore.wait()
