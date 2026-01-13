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
                    // Turn-based player banner
                    if viewModel.isTurnBasedMode, let currentPlayer = viewModel.currentPlayerName {
                        playerBanner(playerName: currentPlayer)
                            .padding(.top, 8)
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
                    
                    // Dice display area - centered
                    diceDisplayArea
                        .padding(.horizontal, isIPad ? 40 : 20)
                    
                    // Total display (if more than 1 dice and enabled)
                    if viewModel.numberOfDice > 1 && viewModel.settings.showTotalValue {
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
            }
            .navigationBarTitle("ZARURI")
            .navigationBarItems(trailing:
                HStack(spacing: 12) {
                    NavigationLink(destination: SettingsView(viewModel: viewModel)) {
                        Image(systemName: "gear")
                    }
                    NavigationLink(destination: HistoryView(viewModel: viewModel)) {
                        Image(systemName: "clock")
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
        .frame(maxHeight: isIPad ? 600 : 400)
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
    
    // MARK: - Player Banner
    
    private func playerBanner(playerName: String) -> some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundColor(.blue)
            Text("Rândul: \(playerName)")
                .font(.system(size: isIPad ? 20 : 17, weight: .semibold))
                .foregroundColor(.blue)
        }
        .padding(.horizontal, isIPad ? 20 : 16)
        .padding(.vertical, isIPad ? 12 : 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
        .padding(.horizontal, isIPad ? 20 : 16)
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
                }
            }
            
            Spacer()
            
            // Progress display for sum and highest modes
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
        Button(action: {
            if viewModel.waitingForNextPlayer {
                viewModel.advanceToNextPlayer()
            } else {
                viewModel.rollDices()
            }
        }) {
            HStack {
                if viewModel.waitingForNextPlayer {
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
                    Image(systemName: "dice.fill")
                        .font(.system(size: isIPad ? 24 : 20))
                    Text("Aruncă zarurile")
                        .font(.system(size: isIPad ? 24 : 20, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, isIPad ? 60 : 40)
            .padding(.vertical, isIPad ? 24 : 18)
            .background(
                LinearGradient(
                    colors: viewModel.waitingForNextPlayer ? [
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
                color: viewModel.waitingForNextPlayer ? 
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

