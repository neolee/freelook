//
//  ContentView.swift
//  FreeLook
//
//  Created by Neo on 2026/3/16.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var settingsStore: SettingsStore
    private let sectionHorizontalPadding: CGFloat = 18
    private let rowLabelWidth: CGFloat = 116

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("FreeLook")
                        .font(.system(size: 26, weight: .semibold))
                    Text("Preview preferences")
                        .foregroundStyle(.secondary)
                }

                settingsSection("Theme") {
                    VStack(alignment: .leading, spacing: 16) {
                        segmentedRow(
                            title: "Theme Mode",
                            selection: $settingsStore.previewAppearanceMode,
                            options: SettingsStore.previewAppearanceModeOptions
                        )

                        pickerRow(
                            title: "Light Theme",
                            selection: $settingsStore.lightTheme,
                            options: SettingsStore.lightThemeOptions
                        )

                        pickerRow(
                            title: "Dark Theme",
                            selection: $settingsStore.darkTheme,
                            options: SettingsStore.darkThemeOptions
                        )
                    }
                }

                settingsSection("Typography") {
                    VStack(alignment: .leading, spacing: 16) {
                        pickerRow(
                            title: "Code Font",
                            selection: $settingsStore.selectedCodeFont,
                            options: SettingsStore.codeFontOptions
                        )

                        HStack(alignment: .center, spacing: 18) {
                            Text("Code Font Size")
                                .foregroundStyle(.secondary)
                                .frame(width: rowLabelWidth, alignment: .leading)

                            HStack(spacing: 12) {
                                Text("\(settingsStore.selectedCodeFontSize) pt")
                                    .font(.system(.body, design: .monospaced))
                                    .frame(width: 62, alignment: .leading)

                                Stepper(
                                    "Code Font Size",
                                    value: $settingsStore.selectedCodeFontSize,
                                    in: SettingsStore.minimumCodeFontSize...SettingsStore.maximumCodeFontSize
                                )
                                .labelsHidden()
                            }
                        }
                    }
                }

                HStack {
                    Spacer()
                    Button("Reset to Defaults") {
                        settingsStore.resetToDefaults()
                    }
                }
            }
            .padding(24)
        }
        .frame(minWidth: 560, minHeight: 500, alignment: .topLeading)
    }

    private func pickerRow(
        title: String,
        selection: Binding<String>,
        options: [String]
    ) -> some View {
        HStack(alignment: .center, spacing: 18) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: rowLabelWidth, alignment: .leading)

            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func segmentedRow(
        title: String,
        selection: Binding<String>,
        options: [String]
    ) -> some View {
        HStack(alignment: .center, spacing: 18) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: rowLabelWidth, alignment: .leading)

            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .fixedSize(horizontal: true, vertical: false)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .padding(.leading, sectionHorizontalPadding)

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(.horizontal, sectionHorizontalPadding)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
        }
    }
}

#Preview {
    ContentView(settingsStore: SettingsStore())
}
