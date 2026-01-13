//
//  AppSettings.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import Foundation
import SwiftUI

/// Model representing app settings and preferences
struct AppSettings: Codable, Equatable {
    var numberOfDice: Int
    var soundEnabled: Bool
    var hapticEnabled: Bool
    var theme: AppTheme
    var keepHistory: Bool
    var maxHistoryItems: Int
    var selectedGameMode: String  // Store as String for Codable
    var showTotal: Bool?  // Show/hide total on main screen (optional for backward compatibility)
    var diceType: DiceType?  // Dice type (optional for backward compatibility)
    
    init() {
        numberOfDice = 2
        soundEnabled = true
        hapticEnabled = true
        theme = .standard
        keepHistory = true
        maxHistoryItems = 50
        selectedGameMode = GameMode.free.rawValue
        showTotal = true
        diceType = .d6  // Default to d6
    }
    
    // Computed property for easy access
    var showTotalValue: Bool {
        return showTotal ?? true  // Default to true if not set
    }
    
    // Computed property for easy access to dice type
    var diceTypeValue: DiceType {
        return diceType ?? .d6  // Default to d6 if not set
    }
}

/// Available app themes
enum AppTheme: String, Codable, CaseIterable {
    case standard = "standard"
    case dark = "dark"
    case colorful = "colorful"
    case classic = "classic"
    
    var displayName: String {
        switch self {
        case .standard:
            return "Standard"
        case .dark:
            return "Dark"
        case .colorful:
            return "Colorful"
        case .classic:
            return "Classic"
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .standard:
            return .blue
        case .dark:
            return .gray
        case .colorful:
            return .purple
        case .classic:
            return .orange
        }
    }
}

