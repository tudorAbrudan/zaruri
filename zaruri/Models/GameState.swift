//
//  GameState.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import Foundation

/// Game state for different game modes
struct GameState: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case sumGameTarget, sumGameAttempts, sumGameBestScore, sumGameReachedTarget
        case highestValueBestScore, highestValueAttempts, highestValueMaxReached
        case turnBasedPlayers, turnBasedCurrentPlayerIndex
        case turnBasedPlayerRemainingSeconds, isTurnBasedTimerPaused, turnBasedInitialSeconds
    }
    
    // Sum Game state
    var sumGameTarget: Int
    var sumGameAttempts: Int
    var sumGameBestScore: Int
    var sumGameReachedTarget: Bool
    
    // Highest Value state
    var highestValueBestScore: Int
    var highestValueAttempts: Int
    var highestValueMaxReached: Bool
    
    // Turn-based state
    var turnBasedPlayers: [String]
    var turnBasedCurrentPlayerIndex: Int
    /// Remaining seconds per player (same order as turnBasedPlayers). Empty if timers not used.
    var turnBasedPlayerRemainingSeconds: [Int]
    /// When true, no player's timer counts down.
    var isTurnBasedTimerPaused: Bool
    /// Initial time per player in seconds (e.g. 30 min = 1800). Used when adding players and when resetting timers.
    var turnBasedInitialSeconds: Int
    
    init() {
        sumGameTarget = 10
        sumGameAttempts = 0
        sumGameBestScore = 0
        sumGameReachedTarget = false
        
        highestValueBestScore = 0
        highestValueAttempts = 0
        highestValueMaxReached = false
        
        turnBasedPlayers = []
        turnBasedCurrentPlayerIndex = 0
        turnBasedPlayerRemainingSeconds = []
        isTurnBasedTimerPaused = false
        turnBasedInitialSeconds = 30 * 60  // 30 minutes
    }
    
    // MARK: - Sum Game
    
    mutating func updateSumGame(total: Int, diceCount: Int) {
        sumGameAttempts += 1
        
        if total > sumGameBestScore {
            sumGameBestScore = total
        }
        
        sumGameReachedTarget = total >= sumGameTarget
    }
    
    mutating func resetSumGame() {
        sumGameAttempts = 0
        sumGameBestScore = 0
        sumGameReachedTarget = false
    }
    
    mutating func setSumGameTarget(_ target: Int, diceCount: Int) {
        let minPossible = diceCount
        let maxPossible = diceCount * 6
        sumGameTarget = max(minPossible, min(maxPossible, target))
    }
    
    // MARK: - Highest Value
    
    mutating func updateHighestValue(total: Int, diceCount: Int) {
        highestValueAttempts += 1
        
        if total > highestValueBestScore {
            highestValueBestScore = total
        }
        
        let maxPossible = diceCount * 6
        highestValueMaxReached = total == maxPossible
    }
    
    mutating func resetHighestValue() {
        highestValueBestScore = 0
        highestValueAttempts = 0
        highestValueMaxReached = false
    }
    
    // MARK: - Turn-based
    
    func getCurrentPlayerName() -> String? {
        guard !turnBasedPlayers.isEmpty,
              turnBasedCurrentPlayerIndex >= 0,
              turnBasedCurrentPlayerIndex < turnBasedPlayers.count else {
            return nil
        }
        return turnBasedPlayers[turnBasedCurrentPlayerIndex]
    }
    
    func getNextPlayerName() -> String? {
        guard !turnBasedPlayers.isEmpty else {
            return nil
        }
        let nextIndex = (turnBasedCurrentPlayerIndex + 1) % turnBasedPlayers.count
        return turnBasedPlayers[nextIndex]
    }
    
    mutating func advanceToNextPlayer() {
        guard !turnBasedPlayers.isEmpty else {
            return
        }
        turnBasedCurrentPlayerIndex = (turnBasedCurrentPlayerIndex + 1) % turnBasedPlayers.count
    }
    
    mutating func resetTurnBased() {
        turnBasedCurrentPlayerIndex = 0
    }
    
    mutating func setTurnBasedPlayers(_ players: [String]) {
        turnBasedPlayers = players
        // Ensure current index is valid
        if turnBasedCurrentPlayerIndex >= players.count {
            turnBasedCurrentPlayerIndex = 0
        }
        // Sync remaining seconds: keep existing or pad with initial
        if turnBasedPlayerRemainingSeconds.count < players.count {
            let toAdd = players.count - turnBasedPlayerRemainingSeconds.count
            turnBasedPlayerRemainingSeconds.append(contentsOf: (0..<toAdd).map { _ in turnBasedInitialSeconds })
        } else if turnBasedPlayerRemainingSeconds.count > players.count {
            turnBasedPlayerRemainingSeconds = Array(turnBasedPlayerRemainingSeconds.prefix(players.count))
        }
    }
    
    /// Reset all players' remaining time to initial.
    mutating func resetTurnBasedTimers() {
        turnBasedPlayerRemainingSeconds = turnBasedPlayers.map { _ in turnBasedInitialSeconds }
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sumGameTarget = try c.decode(Int.self, forKey: .sumGameTarget)
        sumGameAttempts = try c.decode(Int.self, forKey: .sumGameAttempts)
        sumGameBestScore = try c.decode(Int.self, forKey: .sumGameBestScore)
        sumGameReachedTarget = try c.decode(Bool.self, forKey: .sumGameReachedTarget)
        highestValueBestScore = try c.decode(Int.self, forKey: .highestValueBestScore)
        highestValueAttempts = try c.decode(Int.self, forKey: .highestValueAttempts)
        highestValueMaxReached = try c.decode(Bool.self, forKey: .highestValueMaxReached)
        turnBasedPlayers = try c.decode([String].self, forKey: .turnBasedPlayers)
        turnBasedCurrentPlayerIndex = try c.decode(Int.self, forKey: .turnBasedCurrentPlayerIndex)
        turnBasedPlayerRemainingSeconds = try c.decodeIfPresent([Int].self, forKey: .turnBasedPlayerRemainingSeconds) ?? []
        isTurnBasedTimerPaused = try c.decodeIfPresent(Bool.self, forKey: .isTurnBasedTimerPaused) ?? false
        turnBasedInitialSeconds = try c.decodeIfPresent(Int.self, forKey: .turnBasedInitialSeconds) ?? (30 * 60)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(sumGameTarget, forKey: .sumGameTarget)
        try c.encode(sumGameAttempts, forKey: .sumGameAttempts)
        try c.encode(sumGameBestScore, forKey: .sumGameBestScore)
        try c.encode(sumGameReachedTarget, forKey: .sumGameReachedTarget)
        try c.encode(highestValueBestScore, forKey: .highestValueBestScore)
        try c.encode(highestValueAttempts, forKey: .highestValueAttempts)
        try c.encode(highestValueMaxReached, forKey: .highestValueMaxReached)
        try c.encode(turnBasedPlayers, forKey: .turnBasedPlayers)
        try c.encode(turnBasedCurrentPlayerIndex, forKey: .turnBasedCurrentPlayerIndex)
        try c.encode(turnBasedPlayerRemainingSeconds, forKey: .turnBasedPlayerRemainingSeconds)
        try c.encode(isTurnBasedTimerPaused, forKey: .isTurnBasedTimerPaused)
        try c.encode(turnBasedInitialSeconds, forKey: .turnBasedInitialSeconds)
    }
}





