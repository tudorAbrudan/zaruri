//
//  DiceViewModel.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI
import Combine

/// ViewModel for managing dice rolling logic and state
class DiceViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var dices: [Dice] = []
    @Published var numberOfDice: Int = 2
    @Published var total: Int = 0
    @Published var isRolling: Bool = false
    @Published var history: [DiceRoll] = []
    @Published var settings: AppSettings
    @Published var gameState: GameState
    @Published var waitingForNextPlayer: Bool = false
    @Published var showTargetReachedAlert: Bool = false
    @Published var coinIsHeads: Bool = true  // true = Cap (50 BANI), false = Pajură (Stema)
    /// When true, show alert that a player's time ran out.
    @Published var showTimeUpAlert: Bool = false
    @Published var timeUpPlayerName: String? = nil
    
    // MARK: - Private Properties
    
    private let hapticManager: HapticFeedbackManager
    private var turnBasedCountdownTimer: Timer?
    private let soundManager: SoundManager
    private let speechManager: SpeechManager
    private let userDefaultsManager: UserDefaultsManager
    
    // MARK: - Initialization
    
    init(
        hapticManager: HapticFeedbackManager = .shared,
        soundManager: SoundManager = .shared,
        speechManager: SpeechManager = .shared,
        userDefaultsManager: UserDefaultsManager = .shared
    ) {
        self.hapticManager = hapticManager
        self.soundManager = soundManager
        self.speechManager = speechManager
        self.userDefaultsManager = userDefaultsManager
        
        // Load settings
        let loadedSettings = userDefaultsManager.loadSettings()
        self.settings = loadedSettings
        let loadedNumberOfDice = loadedSettings.numberOfDice
        self.numberOfDice = loadedNumberOfDice
        
        // Load history
        let loadedHistory = userDefaultsManager.loadHistory()
        self.history = loadedHistory
        
        // Load game state
        let loadedGameState = userDefaultsManager.loadGameState()
        self.gameState = loadedGameState
        
        // Setup initial dice
        setupDices()
        
        // Configure sound/haptic based on settings
        soundManager.setEnabled(settings.soundEnabled)
    }
    
    // MARK: - Dice Management
    
    /// Setup dice based on current count and type
    func setupDices() {
        let diceType = settings.diceTypeValue
        dices = (0..<numberOfDice).map { _ in Dice(type: diceType) }
        if diceType == .d2 && numberOfDice == 1, let first = dices.first {
            coinIsHeads = (first.value == 1)
        }
        updateTotal()
    }
    
    /// Update number of dice
    func updateNumberOfDice(_ count: Int) {
        guard count >= 1 && count <= 6 else { return }
        numberOfDice = count
        settings.numberOfDice = count
        setupDices()
        saveSettings()
    }
    
    // MARK: - Rolling
    
    /// Roll all dice
    func rollDices() {
        guard !isRolling else { return }
        
        let diceType = settings.diceTypeValue
        let useCoinForD2 = (diceType == .d2 && numberOfDice == 1)
        
        isRolling = true
        
        // Play haptic feedback
        if settings.hapticEnabled {
            hapticManager.playRollStart()
        }
        
        if settings.soundEnabled {
            soundManager.playRollSound()
        }
        
        if useCoinForD2 {
            // D2 with one "die" = show coin animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.coinIsHeads = Bool.random()
                if !self.dices.isEmpty {
                    self.dices[0].value = self.coinIsHeads ? 1 : 2
                    self.dices[0].stopRolling()
                }
                self.isRolling = false
                self.updateTotal()
                self.updateGameState(total: self.total)
                if self.settings.keepHistory {
                    let values = [self.coinIsHeads ? 1 : 2]
                    self.saveToHistory(values: values, playerName: self.currentPlayerName)
                }
                if self.settings.hapticEnabled {
                    self.hapticManager.playRollComplete()
                }
            }
            return
        }
        
        // Start rolling animation for all dice
        for index in dices.indices {
            dices[index].startRolling()
        }
        
        // Roll after animation delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.performRoll()
        }
    }
    
    /// Roll the coin (for coin flip mode)
    func rollCoin() {
        guard !isRolling else { return }
        
        isRolling = true
        
        // Play haptic feedback
        if settings.hapticEnabled {
            hapticManager.playRollStart()
        }
        
        // Play sound
        if settings.soundEnabled {
            soundManager.playRollSound()
        }
        
        // After animation, determine result (slower animation = longer delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Random: true = Cap, false = Pajură
            self.coinIsHeads = Bool.random()
            self.isRolling = false
            
            // Save to history
            let values = [self.coinIsHeads ? 1 : 0]
            self.saveToHistory(values: values, playerName: self.currentPlayerName)
            
            // Haptic feedback
            if self.settings.hapticEnabled {
                self.hapticManager.playRollComplete()
            }
        }
    }
    
    /// Perform the actual roll
    private func performRoll() {
        var rollValues: [Int] = []
        
        // Roll each dice
        for index in dices.indices {
            dices[index].roll()
            rollValues.append(dices[index].value)
        }
        
        // Stop rolling animation
        for index in dices.indices {
            dices[index].stopRolling()
        }
        
        isRolling = false
        updateTotal()
        
        // Update game state based on current mode
        updateGameState(total: total)
        
        // Play completion feedback
        if settings.hapticEnabled {
            hapticManager.playRollComplete()
        }
        
        // Save to history
        if settings.keepHistory {
            // Get current player name if in turn-based mode
            let currentMode = GameMode(rawValue: settings.selectedGameMode) ?? .free
            let playerName: String? = (currentMode == .turnBased) ? gameState.getCurrentPlayerName() : nil
            saveToHistory(values: rollValues, playerName: playerName)
        }
    }
    
    // MARK: - Game State Management
    
    private func updateGameState(total: Int) {
        let currentMode = GameMode(rawValue: settings.selectedGameMode) ?? .free
        
        switch currentMode {
        case .sum:
            let previousReached = gameState.sumGameReachedTarget
            gameState.updateSumGame(total: total, diceCount: numberOfDice)
            saveGameState()
            
            // Special feedback if target reached
            if gameState.sumGameReachedTarget && !previousReached {
                // Target just reached (wasn't reached before)
                if settings.hapticEnabled {
                    hapticManager.playRollComplete()
                }
                // Show alert on main screen
                showTargetReachedAlert = true
                // Auto-hide after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.showTargetReachedAlert = false
                }
            }
            
        case .highest:
            let previousMaxReached = gameState.highestValueMaxReached
            gameState.updateHighestValue(total: total, diceCount: numberOfDice)
            saveGameState()
            
            // Special feedback if max reached
            if gameState.highestValueMaxReached && !previousMaxReached {
                // Max just reached (wasn't reached before)
                if settings.hapticEnabled {
                    hapticManager.playRollComplete()
                }
                // Show alert on main screen
                showTargetReachedAlert = true
                // Auto-hide after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.showTargetReachedAlert = false
                }
            }
            
        case .free:
            // No special tracking for free mode
            break
            
        case .turnBased:
            // For turn-based mode, set waiting state after roll
            if !gameState.turnBasedPlayers.isEmpty {
                waitingForNextPlayer = true
            }
            saveGameState()
        case .coinFlip:
            // No special tracking for coin flip mode
            break
        }
    }
    
    func saveGameState() {
        userDefaultsManager.saveGameState(gameState)
    }
    
    func resetGameState() {
        let currentMode = GameMode(rawValue: settings.selectedGameMode) ?? .free
        
        switch currentMode {
        case .sum:
            gameState.resetSumGame()
        case .highest:
            gameState.resetHighestValue()
        case .free:
            break
        case .turnBased:
            gameState.resetTurnBased()
            waitingForNextPlayer = false
        case .coinFlip:
            // No special reset needed for coin flip mode
            break
        }
        
        // Hide any active alerts
        showTargetReachedAlert = false
        
        saveGameState()
    }
    
    func setSumGameTarget(_ target: Int) {
        gameState.setSumGameTarget(target, diceCount: numberOfDice)
        saveGameState()
    }
    
    // MARK: - Total Calculation
    
    private func updateTotal() {
        total = dices.reduce(0) { $0 + $1.value }
    }
    
    // MARK: - History Management
    
    private func saveToHistory(values: [Int], playerName: String? = nil) {
        let roll = DiceRoll(values: values, playerName: playerName)
        history.insert(roll, at: 0)
        
        // Limit history size
        if history.count > settings.maxHistoryItems {
            history = Array(history.prefix(settings.maxHistoryItems))
        }
        
        // Save to UserDefaults
        userDefaultsManager.saveHistory(history)
    }
    
    func clearHistory() {
        history.removeAll()
        userDefaultsManager.clearHistory()
    }
    
    // MARK: - Settings Management
    
    func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings
        saveSettings()
        
        // Apply settings
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
        setupDices()  // Recreate dice with new type
        saveSettings()
    }
    
    func saveSettings() {
        userDefaultsManager.saveSettings(settings)
    }
    
    // MARK: - Turn-based Mode
    
    var isTurnBasedMode: Bool {
        let currentMode = GameMode(rawValue: settings.selectedGameMode) ?? .free
        return currentMode == .turnBased
    }
    
    var currentPlayerName: String? {
        return gameState.getCurrentPlayerName()
    }
    
    var nextPlayerName: String? {
        return gameState.getNextPlayerName()
    }
    
    func advanceToNextPlayer() {
        gameState.advanceToNextPlayer()
        waitingForNextPlayer = false
        saveGameState()
        
        // Announce next player's name if TTS enabled and in turn-based mode
        if isTurnBasedMode, settings.speechEnabledValue, let playerName = gameState.getCurrentPlayerName() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.speechManager.speak(playerName)
            }
        }
    }
    
    func setTurnBasedPlayers(_ players: [String]) {
        var newState = gameState
        newState.setTurnBasedPlayers(players)
        gameState = newState
        // Reset waiting state when players are changed
        waitingForNextPlayer = false
        saveGameState()
    }
    
    func addTurnBasedPlayer(_ playerName: String) {
        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        guard gameState.turnBasedPlayers.count < 10 else { return }
        
        var players = gameState.turnBasedPlayers
        players.append(trimmedName)
        var newState = gameState
        newState.setTurnBasedPlayers(players)
        gameState = newState
        waitingForNextPlayer = false
        saveGameState()
    }
    
    /// Re-roll for the current player (turn-based, when waiting for next). Does not advance turn.
    func rollAgainForCurrentPlayer() {
        guard isTurnBasedMode, waitingForNextPlayer else { return }
        let currentMode = GameMode(rawValue: settings.selectedGameMode) ?? .free
        if currentMode == .coinFlip {
            rollCoin()
        } else {
            rollDices()
        }
    }
    
    /// Toggle "out of game" for player at index. Out players are skipped when advancing turn until round reset.
    func togglePlayerOut(at index: Int) {
        guard isTurnBasedMode,
              index >= 0,
              index < gameState.turnBasedPlayers.count else { return }
        // Ensure isOut array is synced
        if gameState.turnBasedPlayerIsOut.count != gameState.turnBasedPlayers.count {
            var newState = gameState
            newState.setTurnBasedPlayers(gameState.turnBasedPlayers)
            gameState = newState
        }
        guard index < gameState.turnBasedPlayerIsOut.count else { return }
        gameState.turnBasedPlayerIsOut[index].toggle()
        saveGameState()
    }
    
    func removeTurnBasedPlayer(at index: Int) {
        guard index >= 0 && index < gameState.turnBasedPlayers.count else { return }
        
        var players = gameState.turnBasedPlayers
        players.remove(at: index)
        var newState = gameState
        if players.count >= 2 {
            newState.setTurnBasedPlayers(players)
        } else {
            // Need at least 2 players
            newState.setTurnBasedPlayers([])
        }
        gameState = newState
        waitingForNextPlayer = false
        saveGameState()
    }
    
    func switchGameMode() {
        // Reset waiting state and stop timer when switching modes
        let currentMode = GameMode(rawValue: settings.selectedGameMode) ?? .free
        if currentMode != .turnBased {
            waitingForNextPlayer = false
            stopTurnBasedTimer()
        }
    }
    
    // MARK: - Turn-based Timer
    
    /// Start the countdown timer when in turn-based mode. Call from ContentView.onAppear when isTurnBasedMode.
    func startTurnBasedTimer() {
        guard isTurnBasedMode, !gameState.turnBasedPlayers.isEmpty else { return }
        stopTurnBasedTimer()
        // Sync remaining seconds if count mismatch (e.g. loaded old state)
        if gameState.turnBasedPlayerRemainingSeconds.count != gameState.turnBasedPlayers.count {
            var newState = gameState
            newState.setTurnBasedPlayers(gameState.turnBasedPlayers)
            gameState = newState
            saveGameState()
        }
        turnBasedCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.turnBasedTimerTick()
        }
        RunLoop.main.add(turnBasedCountdownTimer!, forMode: .common)
    }
    
    /// Stop the turn-based countdown timer.
    func stopTurnBasedTimer() {
        turnBasedCountdownTimer?.invalidate()
        turnBasedCountdownTimer = nil
    }
    
    private func turnBasedTimerTick() {
        guard isTurnBasedMode,
              !gameState.turnBasedPlayers.isEmpty,
              !gameState.isTurnBasedTimerPaused,
              gameState.turnBasedCurrentPlayerIndex >= 0,
              gameState.turnBasedCurrentPlayerIndex < gameState.turnBasedPlayerRemainingSeconds.count else {
            return
        }
        let idx = gameState.turnBasedCurrentPlayerIndex
        guard gameState.turnBasedPlayerRemainingSeconds[idx] > 0 else { return }
        gameState.turnBasedPlayerRemainingSeconds[idx] -= 1
        if gameState.turnBasedPlayerRemainingSeconds[idx] == 0 {
            let name = gameState.turnBasedPlayers[idx]
            timeUpPlayerName = name
            showTimeUpAlert = true
            if settings.hapticEnabled {
                hapticManager.playRollComplete()
            }
            if settings.soundEnabled {
                soundManager.playRollSound()
            }
            advanceToNextPlayer()
        }
        saveGameState()
    }
    
    /// Pause or resume all turn-based timers.
    func toggleTurnBasedTimerPaused() {
        guard isTurnBasedMode else { return }
        gameState.isTurnBasedTimerPaused.toggle()
        saveGameState()
    }
    
    /// Add bonus time (seconds) for the player at the given index.
    func addTimeForPlayer(at index: Int, seconds: Int) {
        guard isTurnBasedMode,
              index >= 0,
              index < gameState.turnBasedPlayerRemainingSeconds.count else { return }
        gameState.turnBasedPlayerRemainingSeconds[index] += seconds
        saveGameState()
    }
    
    /// Set initial time per player (used when adding new players and when resetting timers).
    func setTurnBasedInitialSeconds(_ seconds: Int) {
        guard isTurnBasedMode, seconds > 0 else { return }
        gameState.turnBasedInitialSeconds = seconds
        saveGameState()
    }
    
    /// Reset all players' remaining time to the initial value.
    func resetTurnBasedTimers() {
        guard isTurnBasedMode else { return }
        var newState = gameState
        newState.resetTurnBasedTimers()
        gameState = newState
        saveGameState()
    }
    
    /// Last roll total for a player (from history). Nil if no roll for that name.
    func lastRollTotal(forPlayerName name: String?) -> Int? {
        guard let name = name else { return nil }
        return history.first { $0.playerName == name }.map { $0.total }
    }
}

