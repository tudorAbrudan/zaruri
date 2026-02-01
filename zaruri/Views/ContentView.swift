//
//  ContentView.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI

/// Main content view with 2D dice
struct ContentView: View {
    @ObservedObject private var viewModel: DiceViewModel
    
    init() {
        // For iOS 13 compatibility, use ObservedObject with manual initialization
        let vm = DiceViewModel()
        _viewModel = ObservedObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        viewModel.settings.theme.primaryColor.opacity(0.1),
                        Color(UIColor.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Turn-based: list (full timer strip or compact list) + player banner
                    if viewModel.isTurnBasedMode, !viewModel.gameState.turnBasedPlayers.isEmpty {
                        if viewModel.settings.showTurnBasedTimerValue {
                            turnBasedTimerStrip
                                .padding(.top, 8)
                        } else if viewModel.settings.showTurnBasedDiceValue {
                            // Joc cu zaruri fără timer: listă compactă ca să vezi cine urmează
                            turnBasedPlayerListCompact
                                .padding(.top, 8)
                        }
                    }
                    
                    // Game mode banner
                    gameModeBanner
                        .padding(.top, viewModel.isTurnBasedMode ? 8 : 8)
                    
                    // Target reached notification
                    if viewModel.showTargetReachedAlert {
                        targetReachedBanner
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.showTargetReachedAlert)
                    }
                    
                    Spacer()
                    
                    // Dice display area - centered (hidden in turn-based if "zaruri" disabled)
                    let currentMode = GameMode(rawValue: viewModel.settings.selectedGameMode) ?? .free
                    let showDiceArea = currentMode != .turnBased || viewModel.settings.showTurnBasedDiceValue
                    if showDiceArea {
                        diceDisplayArea
                            .padding(.horizontal, isIPad ? 40 : 20)
                    }
                    
                    // Total display (if more than 1 dice and enabled, and not coin flip mode, and not turn-based without dice)
                    let shouldShowTotal = viewModel.numberOfDice > 1 
                        && viewModel.settings.showTotalValue 
                        && currentMode != .coinFlip
                        && !(currentMode == .turnBased && !viewModel.settings.showTurnBasedDiceValue)
                    
                    if shouldShowTotal {
                        totalDisplay
                            .padding(.top, isIPad ? 40 : 20)
                    }
                    
                    Spacer()
                    
                    // Roll button
                    rollButton
                        .padding(.bottom, isIPad ? 60 : 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onAppear {
                // Ensure dice are initialized
                if viewModel.dices.isEmpty {
                    viewModel.setupDices()
                }
                if viewModel.isTurnBasedMode, !viewModel.gameState.turnBasedPlayers.isEmpty, viewModel.settings.showTurnBasedTimerValue {
                    viewModel.startTurnBasedTimer()
                }
            }
            .onDisappear {
                if viewModel.isTurnBasedMode {
                    viewModel.stopTurnBasedTimer()
                }
            }
            .alert(isPresented: $viewModel.showTimeUpAlert) {
                Alert(
                    title: Text("Timp expirat"),
                    message: Text(viewModel.timeUpPlayerName.map { "Timpul s-a terminat pentru \($0)." } ?? "Timpul s-a terminat."),
                    dismissButton: .default(Text("OK")) {
                        viewModel.showTimeUpAlert = false
                        viewModel.timeUpPlayerName = nil
                    }
                )
            }
            .navigationBarTitle("")
            .navigationBarItems(
                leading: HStack(spacing: 16) {
                    if viewModel.isTurnBasedMode && viewModel.settings.showTurnBasedTimerValue {
                        Button(action: { viewModel.toggleTurnBasedTimerPaused() }) {
                            Image(systemName: viewModel.gameState.isTurnBasedTimerPaused ? "play.circle.fill" : "pause.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(viewModel.gameState.isTurnBasedTimerPaused ? .green : .orange)
                        }
                    }
                    if viewModel.waitingForNextPlayer,
                       GameMode(rawValue: viewModel.settings.selectedGameMode) == .turnBased,
                       viewModel.settings.showTurnBasedDiceValue {
                        Button(action: { viewModel.rollAgainForCurrentPlayer() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18))
                                Text("Aruncă iar")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(viewModel.settings.theme.primaryColor)
                        }
                        .disabled(viewModel.isRolling)
                        .opacity(viewModel.isRolling ? 0.6 : 1.0)
                    }
                },
                trailing: HStack(spacing: 12) {
                    NavigationLink(destination: SettingsView(viewModel: viewModel)) {
                        Image(systemName: "gear")
                    }
                    NavigationLink(destination: StatisticsView(viewModel: viewModel)) {
                        Image(systemName: "chart.bar")
                    }
                    NavigationLink(destination: GameModesView(viewModel: viewModel)) {
                        Image(systemName: "gamecontroller")
                    }
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Force stack navigation on iPad
    }
    
    // MARK: - Dice Display Area
    
    private var diceDisplayArea: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let availableHeight = geometry.size.height
            let currentMode = GameMode(rawValue: viewModel.settings.selectedGameMode) ?? .free
            let count = viewModel.numberOfDice
            
            // Calculate layout based on number of dice
            let (columns, rows): (Int, Int) = {
                switch count {
                case 1:
                    return (1, 1)
                case 2:
                    return (2, 1)
                case 3:
                    return (3, 1)
                case 4:
                    return (2, 2)
                case 5:
                    return (3, 2) // 3 on top, 2 on bottom
                case 6:
                    return (3, 2)
                default:
                    return (3, 2)
                }
            }()
            
            // Calculate spacing and size to fit screen
            let horizontalSpacing: CGFloat = isIPad ? 30 : 20
            let verticalSpacing: CGFloat = isIPad ? 20 : 15
            
            // Calculate max dice size that fits
            // Use the maximum items per row for width calculation
            let maxItemsPerRow = count <= 3 ? count : (count == 4 ? 2 : 3)
            // Leave some margin for centering (10% on each side)
            let availableWidthWithMargin = availableWidth * 0.9
            let maxWidthForDice = (availableWidthWithMargin - CGFloat(maxItemsPerRow - 1) * horizontalSpacing) / CGFloat(maxItemsPerRow)
            let maxHeightForDice = (availableHeight - CGFloat(rows - 1) * verticalSpacing) / CGFloat(rows)
            let calculatedSize = min(maxWidthForDice, maxHeightForDice, diceSize)
            
            // Check if coin flip mode or D2 (one die = coin)
            let showCoin = currentMode == .coinFlip || (viewModel.settings.diceTypeValue == .d2 && count == 1)
            Group {
                if showCoin {
                    // Display coin instead of dice (coin flip mode or Tip Zaruri D2)
                    VStack {
                        Spacer()
                        CoinView(
                            isHeads: viewModel.coinIsHeads,
                            isRolling: viewModel.isRolling,
                            size: min(availableWidth * 0.6, availableHeight * 0.6, isIPad ? 300 : 200)
                        )
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Display dice normally
                    VStack(spacing: verticalSpacing) {
                        if viewModel.dices.isEmpty {
                            // Show placeholder while loading
                            Text("Se încarcă...")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(0..<rows, id: \.self) { row in
                                // Calculate items in this row
                                let itemsInRow: Int = {
                                    switch count {
                                    case 1:
                                        return 1
                                    case 2:
                                        return 2
                                    case 3:
                                        return 3
                                    case 4:
                                        return 2
                                    case 5:
                                        return row == 0 ? 3 : 2
                                    case 6:
                                        return 3
                                    default:
                                        return columns
                                    }
                                }()
                                
                                // Calculate starting index for this row
                                let startIndex: Int = {
                                    switch count {
                                    case 1, 2, 3:
                                        return row * columns
                                    case 4:
                                        return row * 2
                                    case 5:
                                        return row == 0 ? 0 : 3
                                    case 6:
                                        return row * 3
                                    default:
                                        return row * columns
                                    }
                                }()
                                
                                HStack(alignment: .center, spacing: horizontalSpacing) {
                                    // Always add spacers to center the row
                                    Spacer()
                                    
                                    HStack(spacing: horizontalSpacing) {
                                        ForEach(0..<itemsInRow, id: \.self) { col in
                                            let index = startIndex + col
                                            if index < viewModel.dices.count {
                                                DiceSimpleView(
                                                    dice: viewModel.dices[index],
                                                    size: calculatedSize
                                                )
                                            }
                                        }
                                    }
                                    
                                    // Always add spacers to center the row
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(maxHeight: isIPad ? 600 : 400)
        .background(Color.clear) // Ensure transparent background
    }
    
    // MARK: - Total Display
    
    private var totalDisplay: some View {
        VStack(spacing: 8) {
            Text("Total")
                .font(.system(size: isIPad ? 22 : 17, weight: .bold))
                .foregroundColor(.secondary)
            Text("\(viewModel.total)")
                .font(.system(size: isIPad ? 72 : 48, weight: .bold))
                .foregroundColor(viewModel.settings.theme.primaryColor)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Turn-based Timer Strip
    
    private var turnBasedTimerStrip: some View {
        VStack(spacing: 8) {
            turnBasedPlayerListScrollContent
                .frame(maxHeight: isIPad ? 280 : 220)
        }
        .padding(.horizontal, isIPad ? 20 : 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.blue.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, isIPad ? 20 : 16)
    }
    
    private var turnBasedPlayerListScrollContent: some View {
        let currentIndex = viewModel.gameState.turnBasedCurrentPlayerIndex
        let count = viewModel.gameState.turnBasedPlayers.count
        return Group {
            if #available(iOS 14.0, *) {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 6) {
                            ForEach(0..<count, id: \.self) { index in
                                turnBasedPlayerTimerRow(index: index)
                                    .id(index)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onAppear {
                        proxy.scrollTo(currentIndex, anchor: .center)
                    }
                    .onChange(of: currentIndex) { newIndex in
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 6) {
                        ForEach(0..<count, id: \.self) { index in
                            turnBasedPlayerTimerRow(index: index)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private func turnBasedPlayerTimerRow(index: Int) -> some View {
        let isCurrent = index == viewModel.gameState.turnBasedCurrentPlayerIndex
        let isOut = index < viewModel.gameState.turnBasedPlayerIsOut.count && viewModel.gameState.turnBasedPlayerIsOut[index]
        let name = viewModel.gameState.turnBasedPlayers[index]
        let seconds = index < viewModel.gameState.turnBasedPlayerRemainingSeconds.count
            ? viewModel.gameState.turnBasedPlayerRemainingSeconds[index]
            : viewModel.gameState.turnBasedInitialSeconds
        let lastRoll = viewModel.lastRollTotal(forPlayerName: name)
        
        return HStack(spacing: 10) {
            if isCurrent {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(name)
                        .font(.system(size: isIPad ? 16 : 15, weight: isCurrent ? .semibold : .regular))
                        .foregroundColor(isOut ? .secondary : (isCurrent ? .blue : .primary))
                        .lineLimit(1)
                    if isOut {
                        Text("(ieșit)")
                            .font(.system(size: isIPad ? 13 : 12))
                            .foregroundColor(.secondary)
                    }
                }
                Text(formatTimer(seconds: seconds))
                    .font(.system(size: isIPad ? 15 : 14, weight: .medium, design: .monospaced))
                    .foregroundColor(seconds <= 60 ? .red : .secondary)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            
            if let total = lastRoll {
                Text("\(total)")
                    .font(.system(size: isIPad ? 15 : 14, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
            }
            
            HStack(spacing: 8) {
                Button(action: { viewModel.togglePlayerOut(at: index) }) {
                    Image(systemName: isOut ? "person.badge.plus" : "person.fill.xmark")
                        .font(.system(size: isIPad ? 18 : 16))
                        .foregroundColor(isOut ? .green : .orange)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(PlainButtonStyle())
                Button(action: { viewModel.addTimeForPlayer(at: index, seconds: 30) }) {
                    Text("+30s")
                        .font(.system(size: isIPad ? 16 : 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(minWidth: 52, minHeight: 44)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
                }
                .buttonStyle(PlainButtonStyle())
                Button(action: { viewModel.addTimeForPlayer(at: index, seconds: 60) }) {
                    Text("+1m")
                        .font(.system(size: isIPad ? 16 : 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(minWidth: 52, minHeight: 44)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrent ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.08))
        )
    }
    
    private func formatTimer(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
    
    /// Listă compactă de jucători (fără timer) — pentru joc cu zaruri, să vezi cine urmează.
    private var turnBasedPlayerListCompact: some View {
        let currentIndex = viewModel.gameState.turnBasedCurrentPlayerIndex
        let count = viewModel.gameState.turnBasedPlayers.count
        return VStack(spacing: 6) {
            if #available(iOS 14.0, *) {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 4) {
                            ForEach(0..<count, id: \.self) { index in
                                turnBasedPlayerNameRow(index: index)
                                    .id(index)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onAppear { proxy.scrollTo(currentIndex, anchor: .center) }
                    .onChange(of: currentIndex) { newIndex in
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 4) {
                        ForEach(0..<count, id: \.self) { index in
                            turnBasedPlayerNameRow(index: index)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxHeight: isIPad ? 200 : 160)
        .padding(.horizontal, isIPad ? 20 : 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.blue.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, isIPad ? 20 : 16)
    }
    
    private func turnBasedPlayerNameRow(index: Int) -> some View {
        let isCurrent = index == viewModel.gameState.turnBasedCurrentPlayerIndex
        let name = viewModel.gameState.turnBasedPlayers[index]
        let lastRoll = viewModel.lastRollTotal(forPlayerName: name)
        return HStack(spacing: 10) {
            if isCurrent {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
            }
            Text(name)
                .font(.system(size: isIPad ? 16 : 15, weight: isCurrent ? .semibold : .regular))
                .foregroundColor(isCurrent ? .blue : .primary)
                .lineLimit(1)
            Spacer()
            if let total = lastRoll {
                Text("\(total)")
                    .font(.system(size: isIPad ? 14 : 13, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isCurrent ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.08))
        )
    }
    
    // MARK: - Game Mode Banner
    
    private var gameModeBanner: some View {
        let currentMode = GameMode(rawValue: viewModel.settings.selectedGameMode) ?? .free
        
        return HStack {
            Image(systemName: modeIcon(for: currentMode))
                .foregroundColor(modeColor(for: currentMode))
                .font(.system(size: isIPad ? 20 : 18))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(currentMode.displayName)
                    .font(.system(size: isIPad ? 18 : 15, weight: .semibold))
                    .foregroundColor(modeColor(for: currentMode))
                
                if currentMode == .sum {
                    Text("Țintă: \(viewModel.gameState.sumGameTarget)")
                        .font(.system(size: isIPad ? 14 : 12))
                        .foregroundColor(.secondary)
                } else if currentMode == .highest {
                    let maxPossible = viewModel.numberOfDice * viewModel.settings.diceTypeValue.maxValue
                    Text("Maxim posibil: \(maxPossible)")
                        .font(.system(size: isIPad ? 14 : 12))
                        .foregroundColor(.secondary)
                } else if currentMode == .coinFlip && !viewModel.isRolling {
                    Text("Rezultat: \(viewModel.coinIsHeads ? "Cap" : "Pajură")")
                        .font(.system(size: isIPad ? 14 : 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Right side: progress (sum/highest) or "Joacă: [name]" (turn-based)
            if currentMode == .sum {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(viewModel.total) / \(viewModel.gameState.sumGameTarget)")
                        .font(.system(size: isIPad ? 18 : 16, weight: .bold))
                        .foregroundColor(viewModel.total >= viewModel.gameState.sumGameTarget ? .green : modeColor(for: currentMode))
                    if viewModel.total < viewModel.gameState.sumGameTarget {
                        Text("Mai trebuie: \(viewModel.gameState.sumGameTarget - viewModel.total)")
                            .font(.system(size: isIPad ? 12 : 10))
                            .foregroundColor(.secondary)
                    }
                }
            } else if currentMode == .highest {
                let maxPossible = viewModel.numberOfDice * viewModel.settings.diceTypeValue.maxValue
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(viewModel.total) / \(maxPossible)")
                        .font(.system(size: isIPad ? 18 : 16, weight: .bold))
                        .foregroundColor(viewModel.total == maxPossible ? .green : modeColor(for: currentMode))
                    if viewModel.total < maxPossible {
                        Text("Mai trebuie: \(maxPossible - viewModel.total)")
                            .font(.system(size: isIPad ? 12 : 10))
                            .foregroundColor(.secondary)
                    }
                }
            } else if currentMode == .turnBased, let currentPlayer = viewModel.currentPlayerName {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Joacă:")
                        .font(.system(size: isIPad ? 12 : 11))
                        .foregroundColor(.secondary)
                    Text(currentPlayer)
                        .font(.system(size: isIPad ? 18 : 16, weight: .bold))
                        .foregroundColor(modeColor(for: .turnBased))
                }
            }
        }
        .padding(.horizontal, isIPad ? 20 : 16)
        .padding(.vertical, isIPad ? 12 : 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(modeColor(for: currentMode).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(modeColor(for: currentMode).opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, isIPad ? 20 : 16)
    }
    
    // MARK: - Helper Functions for Game Mode
    
    private func modeIcon(for mode: GameMode) -> String {
        switch mode {
        case .free:
            return "dice.fill"
        case .sum:
            return "target"
        case .highest:
            return "arrow.up.circle.fill"
        case .turnBased:
            return "person.2.fill"
        case .coinFlip:
            return "bitcoinsign.circle.fill"
        }
    }
    
    private func modeColor(for mode: GameMode) -> Color {
        switch mode {
        case .free:
            return .gray
        case .sum:
            return .orange
        case .highest:
            return .purple
        case .turnBased:
            return .blue
        case .coinFlip:
            return .yellow
        }
    }
    
    // MARK: - Target Reached Banner
    
    private var targetReachedBanner: some View {
        let currentMode = GameMode(rawValue: viewModel.settings.selectedGameMode) ?? .free
        
        return HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: isIPad ? 24 : 20))
            VStack(alignment: .leading, spacing: 2) {
                Text(currentMode == .sum ? "Ai atins ținta!" : "Ai atins maximul!")
                    .font(.system(size: isIPad ? 20 : 17, weight: .bold))
                    .foregroundColor(.green)
                if currentMode == .sum {
                    Text("Suma: \(viewModel.total) / \(viewModel.gameState.sumGameTarget)")
                        .font(.system(size: isIPad ? 16 : 14))
                        .foregroundColor(.green.opacity(0.8))
                } else if currentMode == .highest {
                    let maxPossible = viewModel.numberOfDice * (viewModel.settings.diceTypeValue.maxValue)
                    Text("Suma: \(viewModel.total) / \(maxPossible)")
                        .font(.system(size: isIPad ? 16 : 14))
                        .foregroundColor(.green.opacity(0.8))
                }
            }
            Spacer()
        }
        .padding(.horizontal, isIPad ? 20 : 16)
        .padding(.vertical, isIPad ? 14 : 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0.2),
                            Color.green.opacity(0.1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.5), lineWidth: 2)
        )
        .padding(.horizontal, isIPad ? 20 : 16)
        .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Roll Button
    
    private var rollButton: some View {
        let currentMode = GameMode(rawValue: viewModel.settings.selectedGameMode) ?? .free
        let turnBasedNoDice = currentMode == .turnBased && !viewModel.settings.showTurnBasedDiceValue
        let showAdvanceButton = viewModel.waitingForNextPlayer || turnBasedNoDice
        
        return Button(action: {
            if showAdvanceButton {
                viewModel.advanceToNextPlayer()
            } else if currentMode == .coinFlip {
                viewModel.rollCoin()
            } else {
                viewModel.rollDices()
            }
        }) {
            HStack {
                if showAdvanceButton {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: isIPad ? 24 : 20))
                    if let nextPlayer = viewModel.nextPlayerName {
                        Text("Treci la \(nextPlayer)")
                            .font(.system(size: isIPad ? 24 : 20, weight: .semibold))
                    } else {
                        Text("Treci la următorul")
                            .font(.system(size: isIPad ? 24 : 20, weight: .semibold))
                    }
                } else {
                    if currentMode == .coinFlip {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.system(size: isIPad ? 24 : 20))
                        Text("Aruncă moneda")
                            .font(.system(size: isIPad ? 24 : 20, weight: .semibold))
                    } else {
                        Image(systemName: "dice.fill")
                            .font(.system(size: isIPad ? 24 : 20))
                        Text("Aruncă zarurile")
                            .font(.system(size: isIPad ? 24 : 20, weight: .semibold))
                    }
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, isIPad ? 60 : 40)
            .padding(.vertical, isIPad ? 24 : 18)
            .background(
                LinearGradient(
                    colors: showAdvanceButton ? [
                        Color.green,
                        Color.green.opacity(0.8)
                    ] : [
                        viewModel.settings.theme.primaryColor,
                        viewModel.settings.theme.primaryColor.opacity(0.8)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(isIPad ? 30 : 25)
            .shadow(
                color: showAdvanceButton ? 
                    Color.green.opacity(0.3) : 
                    viewModel.settings.theme.primaryColor.opacity(0.3),
                radius: isIPad ? 15 : 10,
                x: 0,
                y: isIPad ? 8 : 5
            )
        }
        .disabled(viewModel.isRolling)
        .opacity(viewModel.isRolling ? 0.6 : 1.0)
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var diceSize: CGFloat {
        let baseSize: CGFloat
        let count = viewModel.numberOfDice
        
        if count == 1 {
            baseSize = isIPad ? 250 : 150
        } else if count == 2 {
            baseSize = isIPad ? 200 : 120
        } else if count == 3 {
            baseSize = isIPad ? 160 : 100
        } else if count == 4 {
            baseSize = isIPad ? 140 : 85
        } else if count == 5 {
            baseSize = isIPad ? 120 : 75
        } else { // 6 dice
            baseSize = isIPad ? 110 : 70
        }
        return baseSize
    }
}

#Preview {
    ContentView()
}

