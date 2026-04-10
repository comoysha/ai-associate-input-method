import SwiftUI

struct MenuBarView: View {
    @Bindable var appState: AppState
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showSettings {
                settingsContent
            } else {
                mainContent
            }
        }
        .padding(12)
        .frame(width: 280)
    }

    @ViewBuilder
    private var mainContent: some View {
        // Status
        HStack(spacing: 6) {
            Circle()
                .fill(appState.isEnabled ? .green : .gray)
                .frame(width: 8, height: 8)
            Text(appState.statusMessage)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }

        Divider()

        Toggle("AI Completion", isOn: $appState.isEnabled)
            .toggleStyle(.switch)
            .font(.system(size: 13))

        if !appState.accessibilityPermission.isTrusted {
            Button {
                appState.accessibilityPermission.requestPermission()
            } label: {
                Label("Grant Accessibility", systemImage: "lock.shield")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.orange)
        }

        if !appState.settings.isConfigured {
            Label("API not configured", systemImage: "exclamationmark.triangle")
                .font(.system(size: 11))
                .foregroundStyle(.orange)
        }

        Divider()

        Button {
            showSettings = true
        } label: {
            Text("Settings...")
                .font(.system(size: 13))
        }
        .buttonStyle(.plain)

        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Text("Quit")
                .font(.system(size: 13))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var settingsContent: some View {
        HStack {
            Button {
                showSettings = false
            } label: {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))

            Spacer()
            Text("Settings")
                .font(.system(size: 13, weight: .medium))
            Spacer()
        }

        Divider()

        VStack(alignment: .leading, spacing: 6) {
            Text("API Key")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            SecureField("sk-...", text: $appState.settings.apiKey)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
        }

        VStack(alignment: .leading, spacing: 6) {
            Text("Endpoint ID")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            TextField("ep-...", text: $appState.settings.endpointId)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
        }

        VStack(alignment: .leading, spacing: 6) {
            Text("Base URL")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            TextField("https://...", text: $appState.settings.baseURL)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
        }

        Divider()

        HStack {
            Text("Max Tokens")
                .font(.system(size: 11))
            Spacer()
            Stepper("\(appState.settings.maxTokens)", value: $appState.settings.maxTokens, in: 16...256, step: 16)
                .font(.system(size: 11))
        }

        HStack {
            Text("Debounce")
                .font(.system(size: 11))
            Spacer()
            Stepper("\(appState.settings.debounceMs)ms", value: $appState.settings.debounceMs, in: 100...1000, step: 100)
                .font(.system(size: 11))
        }
    }
}
