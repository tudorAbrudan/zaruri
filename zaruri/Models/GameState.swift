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
    
    init() {
        sumGameTarget = 10
        sumGameAttempts = 0
        sumGameBestScore = 0
        sumGameReachedTarget = false
        
        highestValueBestScore = 0
        highestValueAttempts = 0
        highestValueMaxReached = false
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
}



