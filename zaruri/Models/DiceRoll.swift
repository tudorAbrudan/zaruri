//
//  DiceRoll.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import Foundation

/// Model representing a single dice roll with values and timestamp
struct DiceRoll: Identifiable, Codable, Equatable {
    let id: UUID
    let values: [Int]
    let total: Int
    let timestamp: Date
    let numberOfDice: Int
    
    init(id: UUID = UUID(), values: [Int], timestamp: Date = Date()) {
        self.id = id
        self.values = values
        self.total = values.reduce(0, +)
        self.timestamp = timestamp
        self.numberOfDice = values.count
    }
    
    /// Formatted date string for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Formatted values string for display
    var formattedValues: String {
        values.map { String($0) }.joined(separator: ", ")
    }
}



