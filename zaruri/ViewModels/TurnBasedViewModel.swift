//
//  TurnBasedViewModel.swift
//  zaruri
//

import Foundation
import Observation

/// ViewModel for turn-based mode: player management, async countdown timer.
@Observable
@MainActor
final class TurnBasedViewModel {

    // MARK: - State

    var players: [String] = []
    var currentPlayerIndex: Int = 0
    var playerRemainingSeconds: [Int] = []
    var playerIsOut: [Bool] = []
    /// Dice type per player. Index matches `players`. Defaults to `.d6` when not set.
    var playerDiceTypes: [DiceType] = []
    /// Whether each player uses the global custom dice configuration.
    /// Index matches `players`. Defaults to `false` when not set.
    var playerUsesCustomDice: [Bool] = []
    var isTurnBasedTimerPaused: Bool = false
    var initialSeconds: Int = 30 * 60
    var waitingForNextPlayer: Bool = false
    var showTimeUpAlert: Bool = false
    var timeUpPlayerName: String? = nil

    // MARK: - Private

    private var timerTask: Task<Void, Never>?
    private let soundManager: SoundManager
    private let hapticManager: HapticFeedbackManager
    private let speechManager: SpeechManager
    private let userDefaultsManager: UserDefaultsManager

    // MARK: - Init

    init(
        soundManager: SoundManager = .shared,
        hapticManager: HapticFeedbackManager = .shared,
        speechManager: SpeechManager = .shared,
        userDefaultsManager: UserDefaultsManager = .shared
    ) {
        self.soundManager = soundManager
        self.hapticManager = hapticManager
        self.speechManager = speechManager
        self.userDefaultsManager = userDefaultsManager
        loadState()
    }

    // MARK: - Computed

    var currentPlayerName: String? {
        guard !players.isEmpty, currentPlayerIndex < players.count else { return nil }
        return players[currentPlayerIndex]
    }

    var currentPlayerDiceType: DiceType? {
        guard !players.isEmpty, currentPlayerIndex < playerDiceTypes.count else { return nil }
        return playerDiceTypes[currentPlayerIndex]
    }

    var currentPlayerUsesCustomDice: Bool {
        guard !players.isEmpty,
              currentPlayerIndex >= 0,
              currentPlayerIndex < playerUsesCustomDice.count else { return false }
        return playerUsesCustomDice[currentPlayerIndex]
    }

    func playerDiceType(at index: Int) -> DiceType {
        guard index >= 0, index < playerDiceTypes.count else { return .d6 }
        return playerDiceTypes[index]
    }

    func playerUsesCustomDice(at index: Int) -> Bool {
        guard index >= 0, index < playerUsesCustomDice.count else { return false }
        return playerUsesCustomDice[index]
    }

    var nextPlayerName: String? {
        guard !players.isEmpty else { return nil }
        let n = players.count
        var idx = (currentPlayerIndex + 1) % n
        var steps = 0
        while steps < n && idx < playerIsOut.count && playerIsOut[idx] {
            idx = (idx + 1) % n
            steps += 1
        }
        return steps < n ? players[idx] : nil
    }

    var isTimerRunning: Bool { timerTask != nil }

    // MARK: - Timer

    func startTimer() {
        guard !players.isEmpty else { return }
        stopTimer()
        syncArraySizes()
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                tick()
            }
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func tick() {
        guard !players.isEmpty,
              !isTurnBasedTimerPaused,
              currentPlayerIndex >= 0 else { return }

        // Ensure all per-player arrays are in sync before indexing.
        syncArraySizes()

        guard currentPlayerIndex < players.count,
              currentPlayerIndex < playerRemainingSeconds.count else { return }

        let idx = currentPlayerIndex
        guard playerRemainingSeconds[idx] > 0 else { return }
        playerRemainingSeconds[idx] -= 1
        if playerRemainingSeconds[idx] == 0 {
            guard idx < players.count else { return }
            let name = players[idx]
            timeUpPlayerName = name
            showTimeUpAlert = true
            hapticManager.playRollComplete()
            soundManager.playRollSound()
            advanceToNextPlayer()
        }
        saveState()
    }

    // MARK: - Player Management

    func advanceToNextPlayer() {
        guard !players.isEmpty else { return }
        let n = players.count
        var nextIdx = (currentPlayerIndex + 1) % n
        var steps = 0
        while steps < n && nextIdx < playerIsOut.count && playerIsOut[nextIdx] {
            nextIdx = (nextIdx + 1) % n
            steps += 1
        }
        currentPlayerIndex = nextIdx
        waitingForNextPlayer = false
        saveState()
        if let name = currentPlayerName {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                speechManager.speak(name)
            }
        }
    }

    func setPlayers(_ newPlayers: [String]) {
        players = newPlayers
        currentPlayerIndex = 0
        playerRemainingSeconds = Array(repeating: initialSeconds, count: newPlayers.count)
        playerIsOut = Array(repeating: false, count: newPlayers.count)
        playerDiceTypes = Array(repeating: .d6, count: newPlayers.count)
        playerUsesCustomDice = Array(repeating: false, count: newPlayers.count)
        waitingForNextPlayer = false
        saveState()
    }

    func addPlayer(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, players.count < 10 else { return }
        players.append(trimmed)
        playerRemainingSeconds.append(initialSeconds)
        playerIsOut.append(false)
        playerDiceTypes.append(.d6)
        playerUsesCustomDice.append(false)
        waitingForNextPlayer = false
        saveState()
    }

    func removePlayer(at index: Int) {
        guard index >= 0, index < players.count else { return }

        // Align backing arrays with the current players list before removal
        syncArraySizes()

        players.remove(at: index)
        if playerRemainingSeconds.count > index { playerRemainingSeconds.remove(at: index) }
        if playerIsOut.count > index { playerIsOut.remove(at: index) }
        if playerDiceTypes.count > index { playerDiceTypes.remove(at: index) }
        if playerUsesCustomDice.count > index { playerUsesCustomDice.remove(at: index) }
        if players.count < 2 {
            players = []
            playerRemainingSeconds = []
            playerIsOut = []
            playerDiceTypes = []
            playerUsesCustomDice = []
        }

        if currentPlayerIndex >= players.count {
            currentPlayerIndex = players.isEmpty ? 0 : players.count - 1
        }

        // After structural change, ensure arrays stay consistent.
        syncArraySizes()

        if players.isEmpty {
            stopTimer()
        }

        waitingForNextPlayer = false
        saveState()
    }

    func setPlayerDiceType(at index: Int, diceType: DiceType) {
        guard index >= 0, index < players.count else { return }
        syncArraySizes()
        guard index < playerDiceTypes.count else { return }
        playerDiceTypes[index] = diceType
        saveState()
    }

    func setPlayerUseCustomDice(at index: Int, useCustom: Bool) {
        guard index >= 0, index < players.count else { return }
        syncArraySizes()
        guard index < playerUsesCustomDice.count else { return }
        playerUsesCustomDice[index] = useCustom
        saveState()
    }

    func togglePlayerOut(at index: Int) {
        guard index >= 0, index < players.count else { return }
        syncArraySizes()
        guard index < playerIsOut.count else { return }
        playerIsOut[index].toggle()
        saveState()
    }

    func addTime(for index: Int, seconds: Int) {
        guard index >= 0, index < playerRemainingSeconds.count else { return }
        playerRemainingSeconds[index] += seconds
        saveState()
    }

    func toggleTimerPaused() {
        isTurnBasedTimerPaused.toggle()
        saveState()
    }

    func setInitialSeconds(_ seconds: Int) {
        guard seconds > 0 else { return }
        initialSeconds = seconds
        saveState()
    }

    func resetTimers() {
        playerRemainingSeconds = Array(repeating: initialSeconds, count: players.count)
        saveState()
    }

    func resetTurn() {
        currentPlayerIndex = 0
        playerIsOut = Array(repeating: false, count: players.count)
        waitingForNextPlayer = false
        saveState()
    }

    func lastRollTotal(from history: [DiceRoll], forPlayerName name: String?) -> Int? {
        guard let name else { return nil }
        return history.first { $0.playerName == name }.map { $0.total }
    }

    // MARK: - Persistence

    private func loadState() {
        let gs = userDefaultsManager.loadGameState()
        players = gs.turnBasedPlayers
        currentPlayerIndex = gs.turnBasedCurrentPlayerIndex
        playerRemainingSeconds = gs.turnBasedPlayerRemainingSeconds
        playerIsOut = gs.turnBasedPlayerIsOut
        isTurnBasedTimerPaused = gs.isTurnBasedTimerPaused
        initialSeconds = gs.turnBasedInitialSeconds
        playerDiceTypes = gs.turnBasedPlayerDiceTypes.compactMap { DiceType(rawValue: $0) }
        playerUsesCustomDice = gs.turnBasedPlayerUseCustom
        syncArraySizes()
    }

    private func saveState() {
        var gs = userDefaultsManager.loadGameState()
        gs.turnBasedPlayers = players
        gs.turnBasedCurrentPlayerIndex = currentPlayerIndex
        gs.turnBasedPlayerRemainingSeconds = playerRemainingSeconds
        gs.turnBasedPlayerIsOut = playerIsOut
        gs.isTurnBasedTimerPaused = isTurnBasedTimerPaused
        gs.turnBasedInitialSeconds = initialSeconds
        gs.turnBasedPlayerDiceTypes = playerDiceTypes.map { $0.rawValue }
        gs.turnBasedPlayerUseCustom = playerUsesCustomDice
        userDefaultsManager.saveGameState(gs)
    }

    private func syncArraySizes() {
        if playerRemainingSeconds.count != players.count {
            while playerRemainingSeconds.count < players.count {
                playerRemainingSeconds.append(initialSeconds)
            }
            playerRemainingSeconds = Array(playerRemainingSeconds.prefix(players.count))
        }
        if playerIsOut.count != players.count {
            while playerIsOut.count < players.count {
                playerIsOut.append(false)
            }
            playerIsOut = Array(playerIsOut.prefix(players.count))
        }
        if playerDiceTypes.count != players.count {
            while playerDiceTypes.count < players.count {
                playerDiceTypes.append(.d6)
            }
            playerDiceTypes = Array(playerDiceTypes.prefix(players.count))
        }
        if playerUsesCustomDice.count != players.count {
            while playerUsesCustomDice.count < players.count {
                playerUsesCustomDice.append(false)
            }
            playerUsesCustomDice = Array(playerUsesCustomDice.prefix(players.count))
        }
    }
}
