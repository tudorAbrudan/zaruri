//
//  SettingsViewModel.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI
import Combine

/// ViewModel for managing app settings
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var settings: AppSettings
    
    // MARK: - Private Properties
    
    private let userDefaultsManager: UserDefaultsManager
    
    // MARK: - Initialization
    
    init(userDefaultsManager: UserDefaultsManager = .shared) {
        self.userDefaultsManager = userDefaultsManager
        self.settings = userDefaultsManager.loadSettings()
    }
    
    // MARK: - Settings Management
    
    /// Update settings
    func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings
        saveSettings()
    }
    
    /// Update number of dice
    func updateNumberOfDice(_ count: Int) {
        guard count >= 1 && count <= 3 else { return }
        settings.numberOfDice = count
        saveSettings()
    }
    
    /// Toggle sound
    func toggleSound() {
        settings.soundEnabled.toggle()
        SoundManager.shared.setEnabled(settings.soundEnabled)
        saveSettings()
    }
    
    /// Toggle haptic
    func toggleHaptic() {
        settings.hapticEnabled.toggle()
        saveSettings()
    }
    
    /// Update theme
    func updateTheme(_ theme: AppTheme) {
        settings.theme = theme
        saveSettings()
    }
    
    /// Toggle history keeping
    func toggleHistory() {
        settings.keepHistory.toggle()
        saveSettings()
    }
    
    /// Update max history items
    func updateMaxHistoryItems(_ count: Int) {
        guard count > 0 && count <= 100 else { return }
        settings.maxHistoryItems = count
        saveSettings()
    }
    
    /// Reset all settings to default
    func resetToDefaults() {
        settings = AppSettings()
        saveSettings()
    }
    
    // MARK: - Private Methods
    
    private func saveSettings() {
        userDefaultsManager.saveSettings(settings)
    }
}

