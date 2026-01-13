//
//  HapticFeedbackManager.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import UIKit

/// Manager for haptic feedback (vibrations)
class HapticFeedbackManager {
    // MARK: - Properties
    
    static let shared = HapticFeedbackManager()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Haptic Feedback Methods
    
    /// Play impact haptic feedback
    func play(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Play notification haptic feedback
    func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    /// Play selection haptic feedback
    func playSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    /// Play haptic for dice roll start
    func playRollStart() {
        play(.medium)
    }
    
    /// Play haptic for dice roll completion
    func playRollComplete() {
        playNotification(.success)
    }
}










