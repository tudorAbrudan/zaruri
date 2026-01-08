//
//  SettingsView.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI

/// Settings view for app configuration
struct SettingsView: View {
    @ObservedObject var viewModel: DiceViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            // Dice count section
            Section(header: Text("Număr zaruri")) {
                Stepper(
                    "\(viewModel.numberOfDice) zaruri",
                    value: Binding(
                        get: { viewModel.numberOfDice },
                        set: { viewModel.updateNumberOfDice($0) }
                    ),
                    in: 1...3
                )
            }
            
            // Sound and haptic section
            Section(header: Text("Feedback")) {
                Toggle("Sunet", isOn: Binding(
                    get: { viewModel.settings.soundEnabled },
                    set: { _ in viewModel.toggleSound() }
                ))
                
                Toggle("Vibrații", isOn: Binding(
                    get: { viewModel.settings.hapticEnabled },
                    set: { _ in viewModel.toggleHaptic() }
                ))
            }
            
            // Theme section
            Section(header: Text("Temă")) {
                Picker("Temă", selection: Binding(
                    get: { viewModel.settings.theme },
                    set: { viewModel.updateTheme($0) }
                )) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
            }
            
            // History section
            Section(header: Text("Istoric")) {
                Toggle("Păstrează istoric", isOn: Binding(
                    get: { viewModel.settings.keepHistory },
                    set: { newValue in
                        viewModel.settings.keepHistory = newValue
                        viewModel.updateSettings(viewModel.settings)
                    }
                ))
                
                if viewModel.settings.keepHistory {
                    Stepper(
                        "Maxim \(viewModel.settings.maxHistoryItems) înregistrări",
                        value: Binding(
                            get: { viewModel.settings.maxHistoryItems },
                            set: { newValue in
                                viewModel.settings.maxHistoryItems = newValue
                                viewModel.updateSettings(viewModel.settings)
                            }
                        ),
                        in: 10...100,
                        step: 10
                    )
                }
            }
            
            // Data management section
            Section(header: Text("Date")) {
                Button("Șterge istoricul") {
                    viewModel.clearHistory()
                }
                .foregroundColor(.red)
                
                Button("Resetează setările") {
                    viewModel.settings = AppSettings()
                    viewModel.updateSettings(viewModel.settings)
                }
                .foregroundColor(.orange)
            }
        }
        .navigationBarTitle("Setări", displayMode: .inline)
        .navigationBarBackButtonHidden(false)
    }
}

