//
//  GameState.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import Foundation

/// Game state for different game modes
struct GameState: Codable, Equatable {
    // Sum Game state
    var sumGameTarget: Int
    var sumGameAttempts: Int
    var sumGameBestScore: Int
    var sumGameReachedTarget: Bool
    
    // Highest Value state
    var highestValueBestScore: Int
    var highestValueAttempts: Int
    var highestValueMaxReached: Bool
    
    // Turn-based state
    var turnBasedPlayers: [String]
    var turnBasedCurrentPlayerIndex: Int
    
    init() {
        sumGameTarget = 10
        sumGameAttempts = 0
        sumGameBestScore = 0
        sumGameReachedTarget = false
        
        highestValueBestScore = 0
        highestValueAttempts = 0
        highestValueMaxReached = false
        
        turnBasedPlayers = []
        turnBasedCurrentPlayerIndex = 0
    }
    
    // MARK: - Sum Game
    
    mutating func updateSumGame(total: Int, diceCount: Int) {
        sumGameAttempts += 1
        
        if total > sumGameBestScore {
            sumGameBestScore = total
        }
        
        sumGameReachedTarget = total >= sumGameTarget
    }
    
    mutating func resetSumGame() {
        sumGameAttempts = 0
        sumGameBestScore = 0
        sumGameReachedTarget = false
    }
    
    mutating func setSumGameTarget(_ target: Int, diceCount: Int) {
        let minPossible = diceCount
        let maxPossible = diceCount * 6
        sumGameTarget = max(minPossible, min(maxPossible, target))
    }
    
    // MARK: - Highest Value
    
    mutating func updateHighestValue(total: Int, diceCount: Int) {
        highestValueAttempts += 1
        
        if total > highestValueBestScore {
            highestValueBestScore = total
        }
        
        let maxPossible = diceCount * 6
        highestValueMaxReached = total == maxPossible
    }
    
    mutating func resetHighestValue() {
        highestValueBestScore = 0
        highestValueAttempts = 0
        highestValueMaxReached = false
    }
    
    // MARK: - Turn-based
    
    func getCurrentPlayerName() -> String? {
        guard !turnBasedPlayers.isEmpty,
              turnBasedCurrentPlayerIndex >= 0,
              turnBasedCurrentPlayerIndex < turnBasedPlayers.count else {
            return nil
        }
        return turnBasedPlayers[turnBasedCurrentPlayerIndex]
    }
    
    func getNextPlayerName() -> String? {
        guard !turnBasedPlayers.isEmpty else {
            return nil
        }
        let nextIndex = (turnBasedCurrentPlayerIndex + 1) % turnBasedPlayers.count
        return turnBasedPlayers[nextIndex]
    }
    
    mutating func advanceToNextPlayer() {
        guard !turnBasedPlayers.isEmpty else {
            return
        }
        turnBasedCurrentPlayerIndex = (turnBasedCurrentPlayerIndex + 1) % turnBasedPlayers.count
    }
    
    mutating func resetTurnBased() {
        turnBasedCurrentPlayerIndex = 0
    }
    
    mutating func setTurnBasedPlayers(_ players: [String]) {
        turnBasedPlayers = players
        // Ensure current index is valid
        if turnBasedCurrentPlayerIndex >= players.count {
            turnBasedCurrentPlayerIndex = 0
        }
    }
}





