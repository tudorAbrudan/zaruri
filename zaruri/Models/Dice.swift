//
//  Dice.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import Foundation

/// Available dice types
enum DiceType: String, Codable, CaseIterable {
    case d2 = "d2"
    case d3 = "d3"
    case d4 = "d4"
    case d6 = "d6"
    case d8 = "d8"
    case d10 = "d10"
    case d12 = "d12"
    case d20 = "d20"
    
    var maxValue: Int {
        switch self {
        case .d2: return 2
        case .d3: return 3
        case .d4: return 4
        case .d6: return 6
        case .d8: return 8
        case .d10: return 10
        case .d12: return 12
        case .d20: return 20
        }
    }
    
    var displayName: String {
        return rawValue.uppercased()
    }
}

/// Model representing a single dice with value and state
struct Dice: Identifiable, Codable, Equatable {
    let id: UUID
    var value: Int
    var isRolling: Bool
    var type: DiceType
    
    init(id: UUID = UUID(), value: Int = 1, isRolling: Bool = false, type: DiceType = .d6) {
        self.id = id
        self.value = value
        self.isRolling = isRolling
        self.type = type
    }
    
    /// Roll the dice to get a random value between 1 and maxValue for the dice type
    mutating func roll() {
        value = Int.random(in: 1...type.maxValue)
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










