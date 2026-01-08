//
//  GameMode.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import Foundation

/// Model representing different game modes
enum GameMode: String, Codable, CaseIterable {
    case free = "free"
    case sum = "sum"
    case highest = "highest"
    
    var displayName: String {
        switch self {
        case .free:
            return "Aruncare liberă"
        case .sum:
            return "Joc cu sumă"
        case .highest:
            return "Valoare maximă"
        }
    }
    
    var description: String {
        switch self {
        case .free:
            return "Aruncă zarurile liber, fără reguli"
        case .sum:
            return "Încearcă să obții o sumă țintă"
        case .highest:
            return "Încearcă să obții cea mai mare valoare posibilă"
        }
    }
    
    var requiredDiceCount: Int {
        switch self {
        case .free:
            return 1  // Flexible
        case .sum:
            return 2
        case .highest:
            return 3
        }
    }
}

