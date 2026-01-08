//
//  GameModesView.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI
import Combine

/// Game modes view for different dice games
struct GameModesView: View {
    @ObservedObject var viewModel: DiceViewModel
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var selectedMode: GameMode {
        GameMode(rawValue: viewModel.settings.selectedGameMode) ?? .free
    }
    
    var body: some View {
        ScrollView {
            Form {
                // Mode selection
                Section(header: Text("Mod de joc")) {
                    Picker("Mod", selection: Binding(
                        get: { selectedMode },
                        set: { newMode in
                            viewModel.settings.selectedGameMode = newMode.rawValue
                            viewModel.saveSettings()
                        }
                    )) {
                        ForEach(GameMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    
                    Text(selectedMode.description)
                        .font(isIPad ? .body : .caption)
                        .foregroundColor(.secondary)
                }
                
                // Mode-specific content
                Section {
                    switch selectedMode {
                    case .free:
                        freeModeView
                    case .sum:
                        sumModeView
                    case .highest:
                        highestModeView
                    }
                }
            }
            .frame(maxWidth: isIPad ? 800 : .infinity)
            .frame(maxWidth: .infinity)
        }
        .navigationBarTitle("Moduri de joc", displayMode: .inline)
    }
    
    // MARK: - Free Mode
    
    private var freeModeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aruncă zarurile liber, fără reguli.")
                .font(.body)
        }
    }
    
    // MARK: - Sum Mode
    
    private var sumModeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Joc cu sumă")
                .font(.headline)
            
            Text("Încearcă să obții suma țintă sau mai mult.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if viewModel.numberOfDice >= 2 {
                // Target sum
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Sumă țintă:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Stepper("\(viewModel.gameState.sumGameTarget)", value: Binding(
                            get: { viewModel.gameState.sumGameTarget },
                            set: { newValue in
                                viewModel.setSumGameTarget(newValue)
                            }
                        ), in: viewModel.numberOfDice...(viewModel.numberOfDice * 6))
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // Current sum
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suma actuală")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.total)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(viewModel.total >= viewModel.gameState.sumGameTarget ? .green : .primary)
                }
                
                // Status
                if viewModel.gameState.sumGameReachedTarget {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Ai atins ținta!")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    .padding(.top, 4)
                } else {
                    let difference = viewModel.gameState.sumGameTarget - viewModel.total
                    if difference > 0 {
                        Text("Mai ai nevoie de \(difference) pentru a atinge ținta")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Statistics
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Încercări:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(viewModel.gameState.sumGameAttempts)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Cel mai bun rezultat:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(viewModel.gameState.sumGameBestScore)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                
                // Reset button
                Button(action: {
                    viewModel.resetGameState()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Resetează progresul")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding(.top, 8)
            } else {
                Text("Ai nevoie de cel puțin 2 zaruri pentru acest mod de joc.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Highest Mode
    
    private var highestModeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Valoare maximă")
                .font(.headline)
            
            Text("Încearcă să obții cea mai mare valoare posibilă.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if viewModel.numberOfDice >= 3 {
                let maxPossible = viewModel.numberOfDice * 6
                
                // Maximum possible
                VStack(alignment: .leading, spacing: 4) {
                    Text("Maxim posibil")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(maxPossible)")
                        .font(.system(size: 28, weight: .bold))
                }
                
                Divider()
                
                // Current sum
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suma actuală")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.total)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(viewModel.total == maxPossible ? .green : .primary)
                }
                
                // Status
                if viewModel.gameState.highestValueMaxReached {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Felicitări! Ai obținut maximul!")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    .padding(.top, 4)
                } else if viewModel.gameState.highestValueBestScore > 0 {
                    let difference = maxPossible - viewModel.total
                    if difference > 0 {
                        Text("Mai ai nevoie de \(difference) pentru maxim")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Statistics
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Încercări:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(viewModel.gameState.highestValueAttempts)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Cel mai bun rezultat:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(viewModel.gameState.highestValueBestScore)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.gameState.highestValueBestScore == maxPossible ? .green : .primary)
                    }
                    
                    if viewModel.gameState.highestValueBestScore > 0 {
                        let progress = Double(viewModel.gameState.highestValueBestScore) / Double(maxPossible)
                        // Custom progress bar for iOS 13 compatibility
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                        .padding(.top, 4)
                    }
                }
                
                // Reset button
                Button(action: {
                    viewModel.resetGameState()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Resetează progresul")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding(.top, 8)
            } else {
                Text("Ai nevoie de cel puțin 3 zaruri pentru acest mod de joc.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

