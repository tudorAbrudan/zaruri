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
    @State private var showFeedbackSheet = false
    @State private var showFeedbackWebView = false
    
    var body: some View {
        Form {
            // Dice count section
            Section(header: Text("Număr zaruri")) {
                Stepper(
                    "\(viewModel.numberOfDice) \(viewModel.numberOfDice == 1 ? "zar" : "zaruri")",
                    value: Binding(
                        get: { viewModel.numberOfDice },
                        set: { viewModel.updateNumberOfDice($0) }
                    ),
                    in: 1...6
                )
            }
            
            // Dice type section
            Section(header: Text("Tip zaruri")) {
                Picker("Tip zaruri", selection: Binding(
                    get: { viewModel.settings.diceTypeValue },
                    set: { viewModel.updateDiceType($0) }
                )) {
                    ForEach(DiceType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
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
                
                Toggle("Anunță jucători (voce)", isOn: Binding(
                    get: { viewModel.settings.speechEnabledValue },
                    set: { newValue in
                        viewModel.settings.speechEnabled = newValue
                        viewModel.updateSettings(viewModel.settings)
                    }
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
            
            // Display section
            Section(header: Text("Afișare")) {
                Toggle("Afișează total", isOn: Binding(
                    get: { viewModel.settings.showTotalValue },
                    set: { newValue in
                        viewModel.settings.showTotal = newValue
                        viewModel.updateSettings(viewModel.settings)
                    }
                ))
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
            
            // Feedback section
            Section(header: Text("Despre")) {
                Button(action: {
                    FeedbackManager.shared.showFeedback()
                }) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Trimite Feedback")
                    }
                }
                
                Button(action: {
                    showFeedbackWebView = true
                }) {
                    HStack {
                        Image(systemName: "safari")
                            .foregroundColor(.blue)
                        Text("Sugestii, Bug-uri & Feedback")
                    }
                }
            }
        }
        .navigationBarTitle("Setări", displayMode: .inline)
        .sheet(isPresented: $showFeedbackSheet) {
            FeedbackView(feedbackManager: FeedbackManager.shared)
        }
        .sheet(isPresented: $showFeedbackWebView) {
            if let url = URL(string: "https://zarul.userjot.com/") {
                SafariView(url: url)
            }
        }
        .onReceive(FeedbackManager.shared.$showFeedbackView) { show in
            showFeedbackSheet = show
        }
    }
}

