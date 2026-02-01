//
//  UserDefaultsManager.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import Foundation

/// Manager for UserDefaults persistence
class UserDefaultsManager {
    // MARK: - Properties
    
    static let shared = UserDefaultsManager()
    
    private let userDefaults: UserDefaults
    private let historyKey = "diceHistory"
    private let settingsKey = "appSettings"
    private let statisticsKey = "diceStatistics"
    private let gameStateKey = "gameState"
    
    // MARK: - Initialization
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - History Management
    
    /// Save dice roll history
    func saveHistory(_ history: [DiceRoll]) {
        guard let encoded = try? JSONEncoder().encode(history) else {
            return
        }
        userDefaults.set(encoded, forKey: historyKey)
    }
    
    /// Load dice roll history
    func loadHistory() -> [DiceRoll] {
        guard let data = userDefaults.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([DiceRoll].self, from: data) else {
            return []
        }
        return history
    }
    
    /// Clear history
    func clearHistory() {
        userDefaults.removeObject(forKey: historyKey)
    }
    
    // MARK: - Settings Management
    
    /// Save app settings
    func saveSettings(_ settings: AppSettings) {
        guard let encoded = try? JSONEncoder().encode(settings) else {
            return
        }
        userDefaults.set(encoded, forKey: settingsKey)
    }
    
    /// Load app settings
    func loadSettings() -> AppSettings {
        guard let data = userDefaults.data(forKey: settingsKey),
              var settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()  // Return default settings
        }
        
        // Ensure showTotal is set (for backward compatibility with old settings)
        if settings.showTotal == nil {
            settings.showTotal = true  // Default to true
        }
        
        // Ensure diceType is set (for backward compatibility with old settings)
        if settings.diceType == nil {
            settings.diceType = .d6  // Default to d6
        }
        
        if settings.turnBasedShowTimer == nil {
            settings.turnBasedShowTimer = true
        }
        if settings.turnBasedShowDice == nil {
            settings.turnBasedShowDice = true
        }
        
        // Note: use3DDice and animation3DType are ignored (3D removed)
        // They may exist in old settings but won't cause errors
        
        return settings
    }
    
    // MARK: - Statistics Management
    
    /// Save statistics
    func saveStatistics(_ statistics: DiceStatistics) {
        guard let encoded = try? JSONEncoder().encode(statistics) else {
            return
        }
        userDefaults.set(encoded, forKey: statisticsKey)
    }
    
    /// Load statistics
    func loadStatistics() -> DiceStatistics {
        guard let data = userDefaults.data(forKey: statisticsKey),
              let statistics = try? JSONDecoder().decode(DiceStatistics.self, from: data) else {
            return DiceStatistics()  // Return empty statistics
        }
        return statistics
    }
    
    // MARK: - Game State Management
    
    /// Save game state
    func saveGameState(_ gameState: GameState) {
        guard let encoded = try? JSONEncoder().encode(gameState) else {
            return
        }
        userDefaults.set(encoded, forKey: gameStateKey)
    }
    
    /// Load game state
    func loadGameState() -> GameState {
        guard let data = userDefaults.data(forKey: gameStateKey),
              let gameState = try? JSONDecoder().decode(GameState.self, from: data) else {
            return GameState()  // Return default game state
        }
        return gameState
    }
    
    /// Clear game state
    func clearGameState() {
        userDefaults.removeObject(forKey: gameStateKey)
    }
    
    /// Clear all data
    func clearAllData() {
        clearHistory()
        userDefaults.removeObject(forKey: settingsKey)
        userDefaults.removeObject(forKey: statisticsKey)
        clearGameState()
    }
}

