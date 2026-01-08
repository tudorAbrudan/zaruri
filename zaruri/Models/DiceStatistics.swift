//
//  DiceStatistics.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import Foundation

/// Model representing statistics for dice rolls
struct DiceStatistics: Codable, Equatable {
    var totalRolls: Int
    var totalDiceRolled: Int
    var averageRoll: Double
    var minRoll: Int
    var maxRoll: Int
    var rollsByValue: [Int: Int]  // Value -> Count
    
    init() {
        totalRolls = 0
        totalDiceRolled = 0
        averageRoll = 0.0
        minRoll = 0
        maxRoll = 0
        rollsByValue = [:]
    }
    
    /// Update statistics with a new dice roll
    mutating func update(with roll: DiceRoll) {
        totalRolls += 1
        totalDiceRolled += roll.numberOfDice
        
        // Update min/max
        if minRoll == 0 || roll.total < minRoll {
            minRoll = roll.total
        }
        if roll.total > maxRoll {
            maxRoll = roll.total
        }
        
        // Update average
        let previousTotal = averageRoll * Double(totalRolls - 1)
        averageRoll = (previousTotal + Double(roll.total)) / Double(totalRolls)
        
        // Update value distribution
        for value in roll.values {
            rollsByValue[value, default: 0] += 1
        }
    }
    
    /// Reset all statistics
    mutating func reset() {
        totalRolls = 0
        totalDiceRolled = 0
        averageRoll = 0.0
        minRoll = 0
        maxRoll = 0
        rollsByValue = [:]
    }
    
    /// Get percentage for a specific dice value
    func percentage(for value: Int) -> Double {
        guard totalDiceRolled > 0 else { return 0.0 }
        let count = rollsByValue[value] ?? 0
        return Double(count) / Double(totalDiceRolled) * 100.0
    }
}



