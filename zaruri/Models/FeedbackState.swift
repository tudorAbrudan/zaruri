//
//  FeedbackState.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import Foundation

/// Model for feedback system state
struct FeedbackState: Codable {
    var firstLaunchDate: Date?
    var lastFeedbackShownDate: Date?
    var feedbackPostponedCount: Int
    var feedbackSubmitted: Bool
    var lastAppVersion: String?
    var lastBuildNumber: String?
    
    init() {
        firstLaunchDate = nil
        lastFeedbackShownDate = nil
        feedbackPostponedCount = 0
        feedbackSubmitted = false
        lastAppVersion = nil
        lastBuildNumber = nil
    }
}

