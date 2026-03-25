//
//  DiceViewModel.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI
import Observation

/// ViewModel for dice rolling, history, settings, and sum/highest game modes.
@Observable
@MainActor
class DiceViewModel {

    // MARK: - State

    var dices: [Dice] = []
    var numberOfDice: Int = 2
    var total: Int = 0
    var isRolling: Bool = false
    /// Physics impulse multiplier set before each roll (1.0 = normal, până la ~6.0 pentru aruncări foarte puternice).
    var rollForce: Float = 1.0
    var history: [DiceRoll] = []
    var settings: AppSettings
    var gameState: GameState
    var showTargetReachedAlert: Bool = false
    var coinIsHeads: Bool = true
    /// Last generated random number result (Random Number mode).
    var randomNumberResult: Int = 1

    /// Set by ContentView to the current turn-based player name (for history saving).
    var currentTurnPlayerName: String? = nil

    // MARK: - Private

    private let hapticManager: HapticFeedbackManager
    private let soundManager: SoundManager
    private let userDefaultsManager: UserDefaultsManager
    private let reviewManager: ReviewRequestManager

    // MARK: - Init

    init(
        hapticManager: HapticFeedbackManager = .shared,
        soundManager: SoundManager = .shared,
        userDefaultsManager: UserDefaultsManager = .shared,
        reviewManager: ReviewRequestManager = .shared
    ) {
        self.hapticManager = hapticManager
        self.soundManager = soundManager
        self.userDefaultsManager = userDefaultsManager
        self.reviewManager = reviewManager

        let loadedSettings = userDefaultsManager.loadSettings()
        self.settings = loadedSettings
        self.numberOfDice = loadedSettings.numberOfDice

        self.history = userDefaultsManager.loadHistory()
        self.gameState = userDefaultsManager.loadGameState()

        setupDices()
        soundManager.setEnabled(loadedSettings.soundEnabled)
    }

    // MARK: - Dice Management

    func setupDices() {
        let diceType: DiceType
        if settings.useCustomDiceValue, let config = settings.customDiceConfig {
            diceType = config.geometryType
        } else {
            diceType = settings.diceTypeValue
        }
        dices = (0..<numberOfDice).map { _ in Dice(type: diceType) }
        if diceType == .d2, numberOfDice == 1, let first = dices.first {
            coinIsHeads = (first.value == 1)
        }
        updateTotal()
    }

    // MARK: - Custom Dice

    /// The custom config to use for 3D rendering; nil when standard dice are active.
    var activeCustomConfig: CustomDiceConfig? {
        guard settings.useCustomDiceValue else { return nil }
        return settings.customDiceConfig
    }

    func updateCustomDice(_ config: CustomDiceConfig) {
        settings.customDiceConfig = config
        settings.useCustomDice = true
        setupDices()
        saveSettings()
    }

    func toggleCustomDice(_ enabled: Bool) {
        settings.useCustomDice = enabled
        setupDices()
        saveSettings()
    }

    func updateNumberOfDice(_ count: Int) {
        guard count >= 1 && count <= 6 else { return }
        numberOfDice = count
        settings.numberOfDice = count
        setupDices()
        saveSettings()
    }

    // MARK: - Rolling

    func rollDices(force: Float = 1.0) {
        guard !isRolling else { return }
        // Acceptăm o forță mai mare (până la ~6×) pentru aruncări mai spectaculoase.
        rollForce = min(max(force, 1.0), 6.0)
        isRolling = true

        if settings.hapticEnabled { hapticManager.playRollStart() }
        if settings.soundEnabled { soundManager.playRollSound() }

        for index in dices.indices { dices[index].startRolling() }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            performRoll()
        }
    }

    func rollRandomNumber() {
        guard !isRolling else { return }
        isRolling = true
        if settings.hapticEnabled { hapticManager.playRollStart() }
        if settings.soundEnabled { soundManager.playRollSound() }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1500))
            let lo = settings.randomNumberMinValue
            let hi = settings.randomNumberMaxValue
            randomNumberResult = Int.random(in: lo...hi)
            isRolling = false
            if settings.keepHistory {
                saveToHistory(values: [randomNumberResult], playerName: currentTurnPlayerName)
            }
            if settings.hapticEnabled { hapticManager.playRollComplete() }
        }
    }

    func updateRandomNumberRange(min: Int, max: Int) {
        guard min < max else { return }
        settings.randomNumberMin = min
        settings.randomNumberMax = max
        // Clamp current result into the new range
        randomNumberResult = Swift.max(min, Swift.min(max, randomNumberResult))
        saveSettings()
    }

    func rollCoin() {
        guard !isRolling else { return }
        isRolling = true
        if settings.hapticEnabled { hapticManager.playRollStart() }
        if settings.soundEnabled { soundManager.playRollSound() }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(2000))
            coinIsHeads = Bool.random()
            isRolling = false
            saveToHistory(values: [coinIsHeads ? 1 : 0], playerName: currentTurnPlayerName)
            if settings.hapticEnabled { hapticManager.playRollComplete() }
        }
    }

    /// Called by Dice3DView after physics settles to update displayed values to match
    /// the face that is physically pointing upward. Does not affect history or game state
    /// (those were already recorded when the roll was performed).
    func updateDiceValuesFromPhysics(_ values: [Int]) {
        for (i, value) in values.enumerated() {
            guard i < dices.count else { break }
            dices[i].value = value
        }
        updateTotal()
        // Sincronizăm starea monedei pentru d2 sau când modul activ e coinFlip.
        let isCoinMode = GameMode(rawValue: settings.selectedGameMode) == .coinFlip
        if dices.count == 1, dices.first?.type == .d2 || isCoinMode {
            coinIsHeads = (dices.first?.value == 1)
        }
    }

    private func performRoll() {
        var rollValues: [Int] = []
        for index in dices.indices {
            dices[index].roll()
            rollValues.append(dices[index].value)
        }
        for index in dices.indices { dices[index].stopRolling() }

        isRolling = false
        updateTotal()
        updateGameState(total: total)

        if settings.hapticEnabled { hapticManager.playRollComplete() }
        if settings.keepHistory {
            saveToHistory(values: rollValues, playerName: currentTurnPlayerName)
        }
        reviewManager.trackRoll()
    }

    // MARK: - Game State

    private func updateGameState(total: Int) {
        let currentMode = GameMode(rawValue: settings.selectedGameMode) ?? .free
        switch currentMode {
        case .sum:
            let previousReached = gameState.sumGameReachedTarget
            gameState.updateSumGame(total: total, diceCount: numberOfDice)
            saveGameState()
            if gameState.sumGameReachedTarget && !previousReached {
                if settings.hapticEnabled { hapticManager.playRollComplete() }
                showTargetReachedAlert = true
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(3000))
                    showTargetReachedAlert = false
                }
            }
        case .highest:
            let previousMaxReached = gameState.highestValueMaxReached
            gameState.updateHighestValue(total: total, diceCount: numberOfDice)
            saveGameState()
            if gameState.highestValueMaxReached && !previousMaxReached {
                if settings.hapticEnabled { hapticManager.playRollComplete() }
                showTargetReachedAlert = true
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(3000))
                    showTargetReachedAlert = false
                }
            }
        case .free, .turnBased, .coinFlip, .randomNumber:
            break
        }
    }

    func saveGameState() {
        // Merge only sum/highest fields to avoid overwriting turn-based data
        var gs = userDefaultsManager.loadGameState()
        gs.sumGameTarget = gameState.sumGameTarget
        gs.sumGameAttempts = gameState.sumGameAttempts
        gs.sumGameBestScore = gameState.sumGameBestScore
        gs.sumGameReachedTarget = gameState.sumGameReachedTarget
        gs.highestValueBestScore = gameState.highestValueBestScore
        gs.highestValueAttempts = gameState.highestValueAttempts
        gs.highestValueMaxReached = gameState.highestValueMaxReached
        userDefaultsManager.saveGameState(gs)
    }

    func resetGameState() {
        let currentMode = GameMode(rawValue: settings.selectedGameMode) ?? .free
        switch currentMode {
        case .sum:
            gameState.resetSumGame()
            saveGameState()
        case .highest:
            gameState.resetHighestValue()
            saveGameState()
        case .free, .turnBased, .coinFlip, .randomNumber:
            break
        }
        showTargetReachedAlert = false
    }

    func setSumGameTarget(_ target: Int) {
        gameState.setSumGameTarget(target, diceCount: numberOfDice)
        saveGameState()
    }

    // MARK: - Total

    private func updateTotal() {
        total = dices.reduce(0) { $0 + $1.value }
    }

    // MARK: - History

    private func saveToHistory(values: [Int], playerName: String? = nil) {
        let roll = DiceRoll(values: values, playerName: playerName)
        history.insert(roll, at: 0)
        if history.count > settings.maxHistoryItems {
            history = Array(history.prefix(settings.maxHistoryItems))
        }
        userDefaultsManager.saveHistory(history)
    }

    func clearHistory() {
        history.removeAll()
        userDefaultsManager.clearHistory()
    }

    // MARK: - Settings

    func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings
        saveSettings()
        soundManager.setEnabled(settings.soundEnabled)
        numberOfDice = settings.numberOfDice
        setupDices()
    }

    func toggleSound() {
        settings.soundEnabled.toggle()
        soundManager.setEnabled(settings.soundEnabled)
        saveSettings()
    }

    func toggleHaptic() {
        settings.hapticEnabled.toggle()
        saveSettings()
    }

    func updateTheme(_ theme: AppTheme) {
        settings.theme = theme
        saveSettings()
    }

    func updateDiceType(_ type: DiceType) {
        settings.diceType = type
        settings.useCustomDice = false
        setupDices()
        saveSettings()
    }

    /// Applies dice configuration for the current turn-based player without persisting
    /// to user defaults. When `useCustom` is true and a custom config exists, the
    /// custom geometry + labels are used; otherwise a standard dice type is applied.
    func applyDiceTypeForCurrentPlayer(_ type: DiceType, useCustom: Bool) {
        if useCustom, let config = settings.customDiceConfig {
            settings.useCustomDice = true
            settings.diceType = config.geometryType
        } else {
            settings.useCustomDice = false
            settings.diceType = type
        }
        setupDices()
    }

    func saveSettings() {
        userDefaultsManager.saveSettings(settings)
    }

    // MARK: - Mode Helpers

    var isTurnBasedMode: Bool {
        GameMode(rawValue: settings.selectedGameMode) == .turnBased
    }
}
