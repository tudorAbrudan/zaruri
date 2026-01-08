//
//  Dice.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import Foundation

/// Model representing a single dice with value and state
struct Dice: Identifiable, Codable, Equatable {
    let id: UUID
    var value: Int
    var isRolling: Bool
    
    init(id: UUID = UUID(), value: Int = 1, isRolling: Bool = false) {
        self.id = id
        self.value = value
        self.isRolling = isRolling
    }
    
    /// Roll the dice to get a random value between 1 and 6
    mutating func roll() {
        value = Int.random(in: 1...6)
        isRolling = false
    }
    
    /// Start rolling animation
    mutating func startRolling() {
        isRolling = true
    }
    
    /// Stop rolling animation
    mutating func stopRolling() {
        isRolling = false
    }
}



