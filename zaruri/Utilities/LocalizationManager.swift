//
//  LocalizationManager.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import Foundation

/// Manager for localization
class LocalizationManager {
    // MARK: - Properties
    
    static let shared = LocalizationManager()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Localization Methods
    
    /// Get localized string
    func localizedString(for key: String, comment: String = "") -> String {
        return NSLocalizedString(key, comment: comment)
    }
    
    /// Get localized string with arguments
    func localizedString(for key: String, arguments: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return String(format: format, arguments: arguments)
    }
}

// MARK: - String Extension

extension String {
    /// Localized string
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Localized string with format arguments
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}



