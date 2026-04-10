import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section("Doubao API") {
                TextField("API Key", text: $settings.apiKey)
                    .textFieldStyle(.roundedBorder)
                TextField("Endpoint ID", text: $settings.endpointId)
                    .textFieldStyle(.roundedBorder)
                TextField("Base URL", text: $settings.baseURL)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Completion") {
                Stepper("Max Tokens: \(settings.maxTokens)", value: $settings.maxTokens, in: 16...256, step: 16)
                HStack {
                    Text("Temperature: \(settings.temperature, specifier: "%.1f")")
                    Slider(value: $settings.temperature, in: 0...1, step: 0.1)
                }
                Stepper("Debounce (ms): \(settings.debounceMs)", value: $settings.debounceMs, in: 100...1000, step: 100)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 350)
        .padding()
    }
}
