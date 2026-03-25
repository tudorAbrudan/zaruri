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
    /// Show timer strip in "Cu jucători" mode (optional: some games don't use timer).
    var turnBasedShowTimer: Bool?
    /// Show dice area in "Cu jucători" mode (optional: some timed games don't use dice).
    var turnBasedShowDice: Bool?
    /// Enable text-to-speech announcements (e.g. player names)
    var speechEnabled: Bool?
    /// Whether to use the custom dice configuration instead of the standard one.
    var useCustomDice: Bool?
    /// The active custom dice configuration (optional for backward compatibility).
    var customDiceConfig: CustomDiceConfig?
    /// Lower bound for Random Number mode (optional for backward compatibility, default 1).
    var randomNumberMin: Int?
    /// Upper bound for Random Number mode (optional for backward compatibility, default 100).
    var randomNumberMax: Int?

    init() {
        numberOfDice = 2
        soundEnabled = true
        hapticEnabled = true
        theme = .classic
        keepHistory = true
        maxHistoryItems = 50
        selectedGameMode = GameMode.free.rawValue
        showTotal = true
        diceType = .d6  // Default to d6
        turnBasedShowTimer = true
        turnBasedShowDice = true
        speechEnabled = true  // Enable by default
    }
    
    // Computed property for easy access
    var showTotalValue: Bool {
        return showTotal ?? true  // Default to true if not set
    }
    
    // Computed property for easy access to dice type
    var diceTypeValue: DiceType {
        return diceType ?? .d6  // Default to d6 if not set
    }
    
    var showTurnBasedTimerValue: Bool {
        return turnBasedShowTimer ?? true
    }
    
    var showTurnBasedDiceValue: Bool {
        return turnBasedShowDice ?? true
    }
    
    var speechEnabledValue: Bool {
        return speechEnabled ?? true
    }

    var useCustomDiceValue: Bool {
        return useCustomDice ?? false
    }

    var randomNumberMinValue: Int { randomNumberMin ?? 1 }
    var randomNumberMaxValue: Int { randomNumberMax ?? 100 }
}

/// Available app themes
enum AppTheme: String, Codable, CaseIterable {
    case classic = "classic"
    case standard = "standard"
    case dark = "dark"
    case colorful = "colorful"
    
    var displayName: String {
        switch self {
        case .classic:
            return "Classic"
        case .standard:
            return "Standard"
        case .dark:
            return "Dark"
        case .colorful:
            return "Colorful"
        }
    }
    
    /// Accent color used across the app (buttons, highlights, etc.).
    var primaryColor: Color {
        switch self {
        case .classic:
            return .orange
        case .standard:
            return .blue
        case .dark:
            return .gray
        case .colorful:
            return .purple
        }
    }

    /// Base colour for standard numeric dice when no custom dice are active.
    /// This is passed down into the 3D materials so that dice respond to the selected theme.
    var diceBaseUIColor: UIColor {
        switch self {
        case .classic:
            // Neutral white dice in classic mode (numbers/pips colour adapt automatically).
            return UIColor.white
        case .standard:
            // Vibrant casino-style green dice
            return UIColor(red: 0.08, green: 0.62, blue: 0.38, alpha: 1.0)
        case .dark:
            // Cool desaturated teal/blue for dark mode
            return UIColor(red: 0.20, green: 0.60, blue: 0.75, alpha: 1.0)
        case .colorful:
            // Punchy magenta
            return UIColor(red: 0.82, green: 0.22, blue: 0.76, alpha: 1.0)
        }
    }

    /// SwiftUI wrapper around `diceBaseUIColor` for convenience.
    var diceBaseColor: Color {
        Color(diceBaseUIColor)
    }

    /// Background colours for the dice table area.
    /// These drive the gradients in `Dice3DView` so each theme feels distinct.
    var tableBackgroundColors: [Color] {
        switch self {
        case .classic:
            // Warm wooden table tones
            return [
                Color(red: 0.22, green: 0.12, blue: 0.06),
                Color(red: 0.08, green: 0.04, blue: 0.02)
            ]
        case .standard:
            // Poker-style felt table
            return [
                Color(red: 0.03, green: 0.25, blue: 0.12),
                Color(red: 0.01, green: 0.14, blue: 0.06)
            ]
        case .dark:
            // Deep, moody blue/indigo
            return [
                Color(red: 0.02, green: 0.03, blue: 0.10),
                Color(red: 0.05, green: 0.07, blue: 0.18)
            ]
        case .colorful:
            // Neon-like purple/blue blend
            return [
                Color(red: 0.23, green: 0.09, blue: 0.40),
                Color(red: 0.05, green: 0.20, blue: 0.55)
            ]
        }
    }

    /// Colour used for the "lamp" glow above the table.
    /// Only some themes make this very visible; others keep it subtle.
    var tableLampHighlightColor: Color {
        switch self {
        case .classic:
            return Color(red: 1.0, green: 0.95, blue: 0.80)
        case .standard:
            return Color.white
        case .dark:
            return Color(red: 0.80, green: 0.88, blue: 1.0)
        case .colorful:
            return Color(red: 1.0, green: 0.85, blue: 1.0)
        }
    }

    /// Controls how strong the lamp glow is for each theme.
    var tableLampIntensity: Double {
        switch self {
        case .classic:
            return 0.60
        case .standard:
            return 0.40
        case .dark:
            return 0.55
        case .colorful:
            return 0.50
        }
    }

    /// Whether the soft "lamp" glow overlay should be shown.
    /// This allows some themes (e.g. classic wood, dark) to use a cleaner look.
    var showsTableLamp: Bool {
        switch self {
        case .standard, .colorful:
            return true
        case .dark, .classic:
            return false
        }
    }
}

