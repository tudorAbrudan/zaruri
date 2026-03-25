//
//  CustomDiceView.swift
//  zaruri
//

import SwiftUI

/// UI for configuring a custom die: geometry shape, colour, and optional per-face labels.
struct CustomDiceView: View {

    var viewModel: DiceViewModel
    @Environment(\.dismiss) private var dismiss

    // Local editable state — loaded from existing config if one exists.
    @State private var geometryType: DiceType = .d6
    @State private var color: Color = Color(UIColor(red: 0.23, green: 0.48, blue: 1.0, alpha: 1))
    @State private var useCustomLabels: Bool = false
    @State private var faceLabels: [String] = Array(repeating: "", count: 6)

    // MARK: - Body

    var body: some View {
        Form {
            geometrySection
            colorSection
            labelsSection
            actionSection
        }
        .navigationTitle("Zar Custom")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadExistingConfig)
    }

    // MARK: - Sections

    private var geometrySection: some View {
        Section(header: Text("Formă")) {
            Picker("Tip geometrie", selection: $geometryType) {
                ForEach(supportedTypes, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: geometryType) { _, newType in
                resizeFaceLabels(to: newType.maxValue)
            }

            Text("\(geometryType.maxValue) fețe")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var colorSection: some View {
        Section(header: Text("Culoare")) {
            ColorPicker("Culoare zar", selection: $color)
        }
    }

    private var labelsSection: some View {
        Section(header: Text("Etichete fețe")) {
            Toggle("Text personalizat pe fețe", isOn: $useCustomLabels)

            if useCustomLabels {
                ForEach(0..<geometryType.maxValue, id: \.self) { i in
                    HStack {
                        Text("Față \(i + 1)")
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 60, alignment: .leading)
                        TextField("implicit: \(i + 1)", text: Binding(
                            get: { i < faceLabels.count ? faceLabels[i] : "" },
                            set: { newVal in
                                while faceLabels.count <= i { faceLabels.append("") }
                                faceLabels[i] = newVal
                            }
                        ))
                        .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
    }

    private var actionSection: some View {
        Section {
            Button {
                applyConfig()
                dismiss()
            } label: {
                Text("Activează zarul custom")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .listRowBackground(Color.accentColor)
            .foregroundStyle(.white)

            if viewModel.settings.useCustomDiceValue {
                Button(role: .destructive) {
                    viewModel.toggleCustomDice(false)
                    // Defer dismiss to next run-loop so the ViewModel update
                    // (which triggers RealityView rebuild) completes first.
                    Task { @MainActor in dismiss() }
                } label: {
                    Text("Dezactivează zarul custom")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    // MARK: - Helpers

    /// DiceTypes supported for custom dice (d2/d3 don't have numbered faces).
    private var supportedTypes: [DiceType] {
        DiceType.allCases.filter { $0 != .d2 && $0 != .d3 }
    }

    private func loadExistingConfig() {
        guard let config = viewModel.settings.customDiceConfig else { return }
        geometryType = config.geometryType
        color = config.color
        useCustomLabels = config.useCustomLabels
        faceLabels = config.faceLabels
        resizeFaceLabels(to: config.geometryType.maxValue)
    }

    private func resizeFaceLabels(to count: Int) {
        if faceLabels.count < count {
            faceLabels.append(contentsOf: Array(repeating: "", count: count - faceLabels.count))
        } else if faceLabels.count > count {
            faceLabels = Array(faceLabels.prefix(count))
        }
    }

    private func applyConfig() {
        let uiColor = UIColor(color)
        var config = CustomDiceConfig(geometryType: geometryType, colorHex: uiColor.toHexString())
        config.useCustomLabels = useCustomLabels

        // Pad/trim labels and replace blanks with their numeric default.
        var labels = faceLabels
        resizeFaceLabels(to: geometryType.maxValue)
        labels = Array(faceLabels.prefix(geometryType.maxValue))
        config.faceLabels = labels.enumerated().map { i, l in
            l.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "\(i + 1)" : l
        }
        config.name = "Custom \(geometryType.displayName)"
        viewModel.updateCustomDice(config)
    }
}
