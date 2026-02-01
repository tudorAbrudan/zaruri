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
        Form {
            // Mode selection
            Section(header: Text("Mod de joc")) {
                Picker("Mod", selection: Binding(
                    get: { 
                        GameMode(rawValue: viewModel.settings.selectedGameMode) ?? .free
                    },
                    set: { newMode in
                        let oldMode = GameMode(rawValue: viewModel.settings.selectedGameMode) ?? .free
                        viewModel.settings.selectedGameMode = newMode.rawValue
                        viewModel.saveSettings()
                        // Reset waiting state if switching away from turn-based mode
                        if oldMode == .turnBased && newMode != .turnBased {
                            viewModel.waitingForNextPlayer = false
                        }
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
                case .turnBased:
                    turnBasedModeView
                case .coinFlip:
                    coinFlipModeView
                }
            }
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
    
    // MARK: - Turn-based Mode
    
    @State private var newPlayerName: String = ""
    
    private var turnBasedModeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Joc cu jucători")
                .font(.headline)
            
            Text("Configurează lista de jucători care vor arunca pe rând.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Optional: use timer
            Toggle(isOn: Binding(
                get: { viewModel.settings.showTurnBasedTimerValue },
                set: { viewModel.settings.turnBasedShowTimer = $0; viewModel.saveSettings() }
            )) {
                Text("Folosește timer")
                    .font(.subheadline)
            }
            
            // Optional: use dice
            Toggle(isOn: Binding(
                get: { viewModel.settings.showTurnBasedDiceValue },
                set: { viewModel.settings.turnBasedShowDice = $0; viewModel.saveSettings() }
            )) {
                Text("Folosește zaruri")
                    .font(.subheadline)
            }
            
            // Initial time per player (only when timer is on)
            if viewModel.settings.showTurnBasedTimerValue {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Timp per jucător (la început)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        Text("\(viewModel.gameState.turnBasedInitialSeconds / 60) min")
                            .font(.body)
                            .fontWeight(.medium)
                        Stepper("", value: Binding(
                            get: { viewModel.gameState.turnBasedInitialSeconds / 60 },
                            set: { viewModel.setTurnBasedInitialSeconds($0 * 60) }
                        ), in: 1...60)
                            .labelsHidden()
                    }
                }
            }
            
            // Current player indicator
            if let currentPlayer = viewModel.currentPlayerName {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                    Text("Jucător curent: \(currentPlayer)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
            }
            
            Divider()
            
            // Players list
            VStack(alignment: .leading, spacing: 8) {
                Text("Jucători (\(viewModel.gameState.turnBasedPlayers.count)/10)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if viewModel.gameState.turnBasedPlayers.isEmpty {
                    Text("Nu există jucători. Adaugă cel puțin 2 jucători pentru a începe.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(0..<viewModel.gameState.turnBasedPlayers.count, id: \.self) { index in
                        let player = viewModel.gameState.turnBasedPlayers[index]
                        ZStack(alignment: .trailing) {
                            // Background row - not clickable
                            HStack {
                                // Current player indicator
                                if index == viewModel.gameState.turnBasedCurrentPlayerIndex {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.blue)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                                
                                Text(player)
                                    .font(.body)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .allowsHitTesting(false)
                            
                            // Delete button - only clickable element
                            Button(action: {
                                viewModel.removeTurnBasedPlayer(at: index)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .padding(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .allowsHitTesting(true)
                        }
                    }
                }
            }
            
            Divider()
            
            // Add player section
            VStack(alignment: .leading, spacing: 8) {
                Text("Adaugă jucător")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Nume jucător", text: $newPlayerName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        viewModel.addTurnBasedPlayer(newPlayerName)
                        newPlayerName = ""
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 22, weight: .regular))
                    }
                    .disabled(newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                             viewModel.gameState.turnBasedPlayers.count >= 10)
                }
                
                if viewModel.gameState.turnBasedPlayers.count >= 10 {
                    Text("Ai atins limita de 10 jucători.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Reset turn and timers
            if !viewModel.gameState.turnBasedPlayers.isEmpty {
                HStack(spacing: 16) {
                    Button(action: {
                        viewModel.resetGameState()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Resetează rândul")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    if viewModel.settings.showTurnBasedTimerValue {
                        Button(action: {
                            viewModel.resetTurnBasedTimers()
                        }) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Resetează timere")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Coin Flip Mode
    
    private var coinFlipModeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aruncă cu banul")
                .font(.headline)
            
            Text("Aruncă moneda pentru Cap sau Pajură. Moneda se va roti și va arăta rezultatul.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            // Current result display
            if !viewModel.isRolling {
                HStack {
                    Image(systemName: viewModel.coinIsHeads ? "face.smiling" : "star.fill")
                        .foregroundColor(viewModel.coinIsHeads ? .green : .blue)
                    Text("Rezultat: \(viewModel.coinIsHeads ? "Cap" : "Pajură")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.coinIsHeads ? .green : .blue)
                }
                .padding(.vertical, 8)
            }
        }
    }
}

