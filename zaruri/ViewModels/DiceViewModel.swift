//
//  DiceViewModel.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI
import Combine

/// ViewModel for managing dice rolling logic and state
class DiceViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var dices: [Dice] = []
    @Published var numberOfDice: Int = 2
    @Published var total: Int = 0
    @Published var isRolling: Bool = false
    @Published var history: [DiceRoll] = []
    @Published var settings: AppSettings
    @Published var gameState: GameState
    
    // MARK: - Private Properties
    
    private let hapticManager: HapticFeedbackManager
    private let soundManager: SoundManager
    private let userDefaultsManager: UserDefaultsManager
    
    // MARK: - Initialization
    
    init(
        hapticManager: HapticFeedbackManager = .shared,
        soundManager: SoundManager = .shared,
        userDefaultsManager: UserDefaultsManager = .shared
    ) {
        self.hapticManager = hapticManager
        self.soundManager = soundManager
        self.userDefaultsManager = userDefaultsManager
        
        // Load settings
        let loadedSettings = userDefaultsManager.loadSettings()
        self.settings = loadedSettings
        let loadedNumberOfDice = loadedSettings.numberOfDice
        self.numberOfDice = loadedNumberOfDice
        
        // Load history
        let loadedHistory = userDefaultsManager.loadHistory()
        self.history = loadedHistory
        
        // Load game state
        let loadedGameState = userDefaultsManager.loadGameState()
        self.gameState = loadedGameState
        
        // Setup initial dice
        setupDices()
        
        // Configure sound/haptic based on settings
        soundManager.setEnabled(settings.soundEnabled)
    }
    
    // MARK: - Dice Management
    
    /// Setup dice based on current count
    func setupDices() {
        dices = (0..<numberOfDice).map { _ in Dice() }
        updateTotal()
    }
    
    /// Update number of dice
    func updateNumberOfDice(_ count: Int) {
        guard count >= 1 && count <= 3 else { return }
        numberOfDice = count
        settings.numberOfDice = count
        setupDices()
        saveSettings()
    }
    
    // MARK: - Rolling
    
    /// Roll all dice
    func rollDices() {
        guard !isRolling else { return }
        
        isRolling = true
        
        // Play haptic feedback
        if settings.hapticEnabled {
            hapticManager.playRollStart()
        }
        
        // Play sound
        if settings.soundEnabled {
            soundManager.playRollSound()
        }
        
        // Start rolling animation for all dice
        for index in dices.indices {
            dices[index].startRolling()
        }
        
        // Roll after animation delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.performRoll()
        }
    }
    
    /// Perform the actual roll
    private func performRoll() {
        var rollValues: [Int] = []
        
        // Roll each dice
        for index in dices.indices {
            dices[index].roll()
            rollValues.append(dices[index].value)
        }
        
        // Stop rolling animation
        for index in dices.indices {
            dices[index].stopRolling()
        }
        
        isRolling = false
        updateTotal()
        
        // Update game state based on current mode
        updateGameState(total: total)
        
        // Play completion feedback
        if settings.hapticEnabled {
            hapticManager.playRollComplete()
        }
        
        // Save to history
        if settings.keepHistory {
            saveToHistory(values: rollValues)
        }
    }
    
    // MARK: - Game State Management
    
    private func updateGameState(total: Int) {
        let currentMode = GameMode(rawValue: settings.selectedGameMode) ?? .free
        
        switch currentMode {
        case .sum:
            gameState.updateSumGame(total: total, diceCount: numberOfDice)
            saveGameState()
            
            // Special feedback if target reached
            if gameState.sumGameReachedTarget {
                if settings.hapticEnabled {
                    hapticManager.playRollComplete()
                }
            }
            
        case .highest:
            gameState.updateHighestValue(total: total, diceCount: numberOfDice)
            saveGameState()
            
            // Special feedback if max reached
            if gameState.highestValueMaxReached {
                if settings.hapticEnabled {
                    hapticManager.playRollComplete()
                }
            }
            
        case .free:
            // No special tracking for free mode
            break
        }
    }
    
    func saveGameState() {
        userDefaultsManager.saveGameState(gameState)
    }
    
    func resetGameState() {
        let currentMode = GameMode(rawValue: settings.selectedGameMode) ?? .free
        
        switch currentMode {
        case .sum:
            gameState.resetSumGame()
        case .highest:
            gameState.resetHighestValue()
        case .free:
            break
        }
        
        saveGameState()
    }
    
    func setSumGameTarget(_ target: Int) {
        gameState.setSumGameTarget(target, diceCount: numberOfDice)
        saveGameState()
    }
    
    // MARK: - Total Calculation
    
    private func updateTotal() {
        total = dices.reduce(0) { $0 + $1.value }
    }
    
    // MARK: - History Management
    
    private func saveToHistory(values: [Int]) {
        let roll = DiceRoll(values: values)
        history.insert(roll, at: 0)
        
        // Limit history size
        if history.count > settings.maxHistoryItems {
            history = Array(history.prefix(settings.maxHistoryItems))
        }
        
        // Save to UserDefaults
        userDefaultsManager.saveHistory(history)
    }
    
    func clearHistory() {
        history.removeAll()
        userDefaultsManager.clearHistory()
    }
    
    // MARK: - Settings Management
    
    func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings
        saveSettings()
        
        // Apply settings
        soundManager.setEnabled(settings.soundEnabled)
        numberOfDice = settings.numberOfDice
        setupDices()
    }
    
    func toggleSound() {
        settings.soundEnabled.toggle()
        soundManager.setEnabled(settings.soundEnabled)
        saveSettings()
    }
    
    func toggleHaptic() {
        settings.hapticEnabled.toggle()
        saveSettings()
    }
    
    func updateTheme(_ theme: AppTheme) {
        settings.theme = theme
        saveSettings()
    }
    
    func saveSettings() {
        userDefaultsManager.saveSettings(settings)
    }
}

