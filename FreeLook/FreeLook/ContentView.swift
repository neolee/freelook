//
//  ContentView.swift
//  FreeLook
//
//  Created by Neo on 2026/3/16.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var settingsStore: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("FreeLook")
                    .font(.system(size: 28, weight: .semibold))
                Text("Phase 1.5 persistence scaffold")
                    .foregroundStyle(.secondary)
            }

            GroupBox("Light Theme") {
                Picker("Light Theme", selection: $settingsStore.lightTheme) {
                    ForEach(SettingsStore.lightThemeOptions, id: \.self) { theme in
                        Text(theme).tag(theme)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            GroupBox("Dark Theme") {
                Picker("Dark Theme", selection: $settingsStore.darkTheme) {
                    ForEach(SettingsStore.darkThemeOptions, id: \.self) { theme in
                        Text(theme).tag(theme)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            Toggle("Quit after closing last window", isOn: $settingsStore.quitAfterLastWindowClosed)

            VStack(alignment: .leading, spacing: 6) {
                Text("Stored in App Group defaults")
                    .font(.headline)
                Text("Suite: `group.net.paradigmx.FreeLook`")
                Text("Light: `\(settingsStore.lightTheme)`")
                Text("Dark: `\(settingsStore.darkTheme)`")
                Text("Quit After Close: `\(settingsStore.quitAfterLastWindowClosed ? "true" : "false")`")
            }
            .font(.system(.body, design: .monospaced))

            Button("Reset to Defaults") {
                settingsStore.resetToDefaults()
            }
        }
        .padding(28)
        .frame(minWidth: 420, minHeight: 320, alignment: .topLeading)
    }
}

#Preview {
    ContentView(settingsStore: SettingsStore())
}
