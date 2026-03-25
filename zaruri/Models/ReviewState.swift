//
//  ReviewState.swift
//  zaruri
//

import Foundation

/// Persistent state for the App Store review request system.
struct ReviewState: Codable {
    /// Calendar days ("yyyy-MM-dd") on which the user completed at least one roll.
    var activeDays: Set<String>
    /// Number of times SKStoreReviewController has been called.
    var requestCount: Int
    /// Date of the last review request, used for cooldown enforcement.
    var lastRequestDate: Date?
    /// Total rolls tracked by this manager (independent of history setting).
    var totalRolls: Int

    init() {
        activeDays = []
        requestCount = 0
        totalRolls = 0
    }
}
