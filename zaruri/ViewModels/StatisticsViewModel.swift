//
//  StatisticsViewModel.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI
import Combine

/// ViewModel for managing dice statistics
class StatisticsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var statistics: DiceStatistics
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    
    private let userDefaultsManager: UserDefaultsManager
    
    // MARK: - Initialization
    
    init(userDefaultsManager: UserDefaultsManager = .shared) {
        self.userDefaultsManager = userDefaultsManager
        self.statistics = userDefaultsManager.loadStatistics()
    }
    
    // MARK: - Statistics Management
    
    /// Update statistics with a new roll
    func updateStatistics(with roll: DiceRoll) {
        statistics.update(with: roll)
        saveStatistics()
    }
    
    /// Load statistics from history
    func loadStatisticsFromHistory(_ history: [DiceRoll]) {
        isLoading = true
        
        // Reset statistics
        statistics = DiceStatistics()
        
        // Update with all history
        for roll in history {
            statistics.update(with: roll)
        }
        
        saveStatistics()
        isLoading = false
    }
    
    /// Reset statistics
    func resetStatistics() {
        statistics = DiceStatistics()
        saveStatistics()
    }
    
    // MARK: - Computed Properties
    
    /// Formatted average roll
    var formattedAverage: String {
        String(format: "%.2f", statistics.averageRoll)
    }
    
    /// Total number of rolls
    var totalRolls: Int {
        statistics.totalRolls
    }
    
    /// Minimum roll
    var minRoll: Int {
        statistics.minRoll
    }
    
    /// Maximum roll
    var maxRoll: Int {
        statistics.maxRoll
    }
    
    /// Value distribution for chart
    var valueDistribution: [(value: Int, count: Int, percentage: Double)] {
        (1...6).map { value in
            let count = statistics.rollsByValue[value] ?? 0
            let percentage = statistics.percentage(for: value)
            return (value: value, count: count, percentage: percentage)
        }
    }
    
    // MARK: - Private Methods
    
    private func saveStatistics() {
        userDefaultsManager.saveStatistics(statistics)
    }
}

