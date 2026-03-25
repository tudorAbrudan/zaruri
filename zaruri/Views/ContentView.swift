//
//  ContentView.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI

/// Main content view — coordinates DiceViewModel and TurnBasedViewModel.
struct ContentView: View {
    @State private var viewModel = DiceViewModel()
    @State private var turnBasedViewModel = TurnBasedViewModel()
    /// Current visual scale of the roll button while pressed (drives throw strength).
    @State private var rollPressScale: CGFloat = 1.0
    @StateObject private var shakeManager = ShakeMotionManager()
    @StateObject private var reviewManager = ReviewRequestManager.shared
    @State private var isDiceFullScreen: Bool = false
    @State private var playerListContentHeight: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        viewModel.settings.theme.primaryColor.opacity(0.1),
                        Color(UIColor.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Full-screen dice backdrop
                if isDiceFullScreen {
                    let fsMode = GameMode(rawValue: viewModel.settings.selectedGameMode) ?? .free
                    if fsMode != .randomNumber && fsMode != .coinFlip {
                        Dice3DView(
                            dice: viewModel.dices,
                            isRolling: viewModel.isRolling,
                            rollForce: viewModel.rollForce,
                            theme: viewModel.settings.theme,
                            customConfig: viewModel.activeCustomConfig,
                            useCoinLookForD2: false,
                            onPhysicsSettled: { values in
                                viewModel.updateDiceValuesFromPhysics(values)
                            },
                            isFullScreen: true
                        )
                        .ignoresSafeArea()
                        .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                    }
                }

                VStack(spacing: 0) {
                    // Turn-based: list (full timer strip or compact list)
                    if viewModel.isTurnBasedMode, !turnBasedViewModel.players.isEmpty {
                        if viewModel.settings.showTurnBasedTimerValue {
                            turnBasedTimerStrip
                                .padding(.top, 8)
                        } else if viewModel.settings.showTurnBasedDiceValue {
                            turnBasedPlayerListCompact
                                .padding(.top, 8)
                        }
                    }

                    // Game mode banner (ascuns în modul cu jucători pentru a lăsa mai mult loc listei)
                    let currentMode = GameMode(rawValue: viewModel.settings.selectedGameMode) ?? .free
                    if currentMode != .turnBased {
                        gameModeBanner
                            .padding(.top, 8)
                    }

                    // Progress bar for "Valoare maximă" direct pe ecranul principal
                    if let progress = highestModeProgress() {
                        ProgressView(value: progress)
                            .tint(modeColor(for: .highest))
                            .padding(.horizontal, isIPad ? 20 : 16)
                            .padding(.top, 4)
                    }

                    // Target reached notification
                    if viewModel.showTargetReachedAlert {
                        targetReachedBanner
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.showTargetReachedAlert)
                    }

                    Spacer()

                    // Dice display area
                    let showDiceArea = currentMode != .turnBased || viewModel.settings.showTurnBasedDiceValue

                    if showDiceArea {
                        if currentMode == .randomNumber {
                            randomNumberDisplayArea
                                .padding(.horizontal, isIPad ? 40 : 20)
                        } else if !isDiceFullScreen {
                            Dice3DView(
                                    dice: viewModel.dices,
                                    isRolling: viewModel.isRolling,
                                    rollForce: viewModel.rollForce,
                                    theme: viewModel.settings.theme,
                                    customConfig: viewModel.activeCustomConfig,
                                    useCoinLookForD2: currentMode == .coinFlip,
                                    onPhysicsSettled: { values in
                                        viewModel.updateDiceValuesFromPhysics(values)
                                    }
                                )
                                .padding(.horizontal, isIPad ? 40 : 20)
                                .overlay(alignment: .bottomTrailing) {
                                    if currentMode != .coinFlip {
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                isDiceFullScreen = true
                                            }
                                        }) {
                                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.white.opacity(0.85))
                                                .padding(8)
                                                .background(.ultraThinMaterial, in: Circle())
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.bottom, 10)
                                        .padding(.trailing, isIPad ? 48 : 28)
                                    }
                                }
                        }
                    }

                    // Total display (multi-dice, non-coin, non-randomNumber modes)
                    let shouldShowTotal = viewModel.numberOfDice > 1
                        && viewModel.settings.showTotalValue
                        && currentMode != .coinFlip
                        && currentMode != .randomNumber
                        && !(currentMode == .turnBased && !viewModel.settings.showTurnBasedDiceValue)

                    if shouldShowTotal {
                        totalDisplay
                            .padding(.top, isIPad ? 24 : (isLandscape ? 6 : 14))
                    }

                    Spacer()

                    // Roll button
                    rollButton
                        .padding(.bottom, isIPad ? 60 : (isLandscape ? 20 : 40))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Floating collapse button (full-screen mode only, bottom-right)
                if isDiceFullScreen {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isDiceFullScreen = false
                                }
                            }) {
                                Image(systemName: "arrow.down.right.and.arrow.up.left")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                                    .padding(8)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.trailing, isIPad ? 24 : 20)
                        .padding(.bottom, isIPad ? 24 : 20)
                    }
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                }
            }
            .onAppear {
                if viewModel.dices.isEmpty { viewModel.setupDices() }
                syncCurrentPlayerName()
                if viewModel.isTurnBasedMode,
                   !turnBasedViewModel.players.isEmpty,
                   viewModel.settings.showTurnBasedTimerValue {
                    turnBasedViewModel.startTimer()
                }
                shakeManager.start()
                UIApplication.shared.isIdleTimerDisabled = true
            }
            .onDisappear {
                if viewModel.isTurnBasedMode { turnBasedViewModel.stopTimer() }
                shakeManager.stop()
                UIApplication.shared.isIdleTimerDisabled = false
            }
            .onChange(of: shakeManager.isShaking) { _, isShaking in
                if isShaking && !viewModel.isRolling {
                    viewModel.rollDices(force: 2.2)
                }
            }
            .onChange(of: viewModel.isRolling) { oldVal, newVal in
                // When rolling completes in turn-based mode, set waitingForNextPlayer
                if oldVal && !newVal && viewModel.isTurnBasedMode && !turnBasedViewModel.players.isEmpty {
                    turnBasedViewModel.waitingForNextPlayer = true
                }
            }
            .onChange(of: viewModel.settings.selectedGameMode) { _, _ in
                if isDiceFullScreen {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isDiceFullScreen = false
                    }
                }
            }
            .onChange(of: turnBasedViewModel.currentPlayerIndex) { _, _ in
                syncCurrentPlayerName()
            }
            .onChange(of: turnBasedViewModel.players) { _, _ in
                syncCurrentPlayerName()
            }
            .alert("Timp expirat", isPresented: $turnBasedViewModel.showTimeUpAlert) {
                Button("OK") {
                    turnBasedViewModel.showTimeUpAlert = false
                    turnBasedViewModel.timeUpPlayerName = nil
                }
            } message: {
                Text(turnBasedViewModel.timeUpPlayerName.map { "Timpul s-a terminat pentru \($0)." } ?? "Timpul s-a terminat.")
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    leadingToolbar
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    trailingToolbar
                }
            }
            .sheet(isPresented: $reviewManager.showReviewPrompt) {
                ReviewPromptView(reviewManager: reviewManager)
                    .presentationDetents([.height(380)])
                    .presentationDragIndicator(.hidden)
            }
        }
    }

    // MARK: - Toolbar

    private var leadingToolbar: some View {
        HStack(spacing: 16) {
            if viewModel.isTurnBasedMode && viewModel.settings.showTurnBasedTimerValue {
                Button(action: { turnBasedViewModel.toggleTimerPaused() }) {
                    Image(systemName: turnBasedViewModel.isTurnBasedTimerPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(turnBasedViewModel.isTurnBasedTimerPaused ? .green : .orange)
                }
            }
            if turnBasedViewModel.waitingForNextPlayer,
               GameMode(rawValue: viewModel.settings.selectedGameMode) == .turnBased,
               viewModel.settings.showTurnBasedDiceValue {
                Button(action: { viewModel.rollDices() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18))
                        Text("Aruncă iar")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(viewModel.settings.theme.primaryColor)
                }
                .disabled(viewModel.isRolling)
                .opacity(viewModel.isRolling ? 0.6 : 1.0)
            }
        }
    }

    private var trailingToolbar: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: SettingsView(viewModel: viewModel)) {
                Image(systemName: "gear")
            }
            NavigationLink(destination: StatisticsView(viewModel: viewModel)) {
                Image(systemName: "chart.bar")
            }
            NavigationLink(destination: GameModesView(viewModel: viewModel, turnBasedViewModel: turnBasedViewModel)) {
                Image(systemName: "gamecontroller")
            }
        }
    }

    // MARK: - Random Number Display

    @State private var rollingDisplayValue: Int = 0

    private var randomNumberDisplayArea: some View {
        GeometryReader { geo in
            VStack(spacing: 16) {
                Spacer()

                VStack(spacing: 8) {
                    // Large animated number
                    Text(viewModel.isRolling ? "\(rollingDisplayValue)" : "\(viewModel.randomNumberResult)")
                        .font(.system(size: min(geo.size.width * 0.32, isIPad ? 140 : 100), weight: .bold, design: .rounded))
                        .foregroundColor(.indigo)
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: viewModel.randomNumberResult)

                    // Range label
                    Text("\(viewModel.settings.randomNumberMinValue) – \(viewModel.settings.randomNumberMaxValue)")
                        .font(.system(size: isIPad ? 18 : 15, weight: .medium))
                        .foregroundColor(.indigo.opacity(0.6))
                        .padding(.horizontal, 16).padding(.vertical, 6)
                        .background(Capsule().fill(Color.indigo.opacity(0.10)))
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxHeight: isIPad ? 480 : (isLandscape ? 220 : 320))
        .onReceive(Timer.publish(every: 0.07, on: .main, in: .common).autoconnect()) { _ in
            guard viewModel.isRolling else { return }
            let lo = viewModel.settings.randomNumberMinValue
            let hi = viewModel.settings.randomNumberMaxValue
            rollingDisplayValue = Int.random(in: lo...hi)
        }
    }

    // MARK: - Total Display

    private var totalDisplay: some View {
        HStack(spacing: 8) {
            Text("TOTAL")
                .font(.system(size: isIPad ? 20 : 16, weight: .bold))
                .foregroundColor(.secondary)
            Text("\(viewModel.total)")
                .font(.system(size: isIPad ? 32 : 24, weight: .bold))
                .foregroundColor(viewModel.settings.theme.primaryColor)
        }
        .padding(.top, 4)
    }

    // MARK: - Turn-based Timer Strip

    private var turnBasedTimerStrip: some View {
        let maxH = UIScreen.main.bounds.height * 2 / 3
        let frameH = playerListContentHeight > 0
            ? min(playerListContentHeight, maxH)
            : maxH
        return VStack(spacing: 8) {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 6) {
                        ForEach(0..<turnBasedViewModel.players.count, id: \.self) { index in
                            turnBasedPlayerTimerRow(index: index)
                                .id(index)
                        }
                    }
                    .padding(.vertical, 4)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: PlayerListHeightKey.self, value: geo.size.height)
                        }
                    )
                }
                .onPreferenceChange(PlayerListHeightKey.self) { h in
                    playerListContentHeight = h
                }
                .onAppear { proxy.scrollTo(turnBasedViewModel.currentPlayerIndex, anchor: .center) }
                .onChange(of: turnBasedViewModel.currentPlayerIndex) { _, newIndex in
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
        .frame(height: frameH)
        .padding(.horizontal, isIPad ? 20 : 16)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.blue.opacity(0.2), lineWidth: 1))
        .padding(.horizontal, isIPad ? 20 : 16)
    }

    private func turnBasedPlayerTimerRow(index: Int) -> some View {
        let isCurrent = index == turnBasedViewModel.currentPlayerIndex
        let isOut = index < turnBasedViewModel.playerIsOut.count && turnBasedViewModel.playerIsOut[index]
        let name = turnBasedViewModel.players[index]
        let seconds = index < turnBasedViewModel.playerRemainingSeconds.count
            ? turnBasedViewModel.playerRemainingSeconds[index]
            : turnBasedViewModel.initialSeconds
        let lastRoll = turnBasedViewModel.lastRollTotal(from: viewModel.history, forPlayerName: name)

        return HStack(spacing: 8) {
            if isCurrent {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: isIPad ? 16 : 14))
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(name)
                        .font(.system(size: isIPad ? 15 : 14, weight: isCurrent ? .semibold : .regular))
                        .foregroundColor(isOut ? .secondary : (isCurrent ? .blue : .primary))
                        .lineLimit(1)
                    if isOut {
                        Text("(ieșit)")
                            .font(.system(size: isIPad ? 13 : 12))
                            .foregroundColor(.secondary)
                    }
                }
                Text(formatTimer(seconds: seconds))
                    .font(.system(size: isIPad ? 14 : 13, weight: .medium, design: .monospaced))
                    .foregroundColor(seconds <= 60 ? .red : .secondary)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            if let total = lastRoll {
                Text("\(total)")
                    .font(.system(size: isIPad ? 14 : 13, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
            }
            HStack(spacing: 8) {
                Button(action: { turnBasedViewModel.togglePlayerOut(at: index) }) {
                    Image(systemName: isOut ? "person.badge.plus" : "person.fill.xmark")
                        .font(.system(size: isIPad ? 16 : 14))
                        .foregroundColor(isOut ? .green : .orange)
                        .frame(minWidth: 36, minHeight: 36)
                }.buttonStyle(PlainButtonStyle())
                Button(action: { turnBasedViewModel.addTime(for: index, seconds: 30) }) {
                    Text("+30s")
                        .font(.system(size: isIPad ? 15 : 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(minWidth: 48, minHeight: 36)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
                }.buttonStyle(PlainButtonStyle())
                Button(action: { turnBasedViewModel.addTime(for: index, seconds: 60) }) {
                    Text("+1m")
                        .font(.system(size: isIPad ? 15 : 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(minWidth: 48, minHeight: 36)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
                }.buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(isCurrent ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.08)))
    }

    private func formatTimer(seconds: Int) -> String {
        let m = seconds / 60; let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    /// Compact player list (no timer) — shows who's next.
    private var turnBasedPlayerListCompact: some View {
        let maxH = UIScreen.main.bounds.height * 2 / 3
        let frameH = playerListContentHeight > 0
            ? min(playerListContentHeight, maxH)
            : maxH
        return ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 4) {
                    ForEach(0..<turnBasedViewModel.players.count, id: \.self) { index in
                        turnBasedPlayerNameRow(index: index).id(index)
                    }
                }
                .padding(.vertical, 4)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: PlayerListHeightKey.self, value: geo.size.height)
                    }
                )
            }
            .onPreferenceChange(PlayerListHeightKey.self) { h in
                playerListContentHeight = h
            }
            .onAppear { proxy.scrollTo(turnBasedViewModel.currentPlayerIndex, anchor: .center) }
            .onChange(of: turnBasedViewModel.currentPlayerIndex) { _, newIndex in
                proxy.scrollTo(newIndex, anchor: .center)
            }
        }
        .frame(height: frameH)
        .padding(.horizontal, isIPad ? 20 : 16).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.blue.opacity(0.2), lineWidth: 1))
        .padding(.horizontal, isIPad ? 20 : 16)
    }

    private func turnBasedPlayerNameRow(index: Int) -> some View {
        let isCurrent = index == turnBasedViewModel.currentPlayerIndex
        let name = turnBasedViewModel.players[index]
        let lastRoll = turnBasedViewModel.lastRollTotal(from: viewModel.history, forPlayerName: name)
        return HStack(spacing: 8) {
            if isCurrent {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: isIPad ? 15 : 13))
            }
            Text(name)
                .font(.system(size: isIPad ? 15 : 14, weight: isCurrent ? .semibold : .regular))
                .foregroundColor(isCurrent ? .blue : .primary).lineLimit(1)
            Spacer()
            if let total = lastRoll {
                Text("\(total)")
                    .font(.system(size: isIPad ? 13 : 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(isCurrent ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.08)))
    }

    // MARK: - Game Mode Banner

    private var gameModeBanner: some View {
        let currentMode = GameMode(rawValue: viewModel.settings.selectedGameMode) ?? .free
        return HStack {
            Image(systemName: modeIcon(for: currentMode))
                .foregroundColor(modeColor(for: currentMode))
                .font(.system(size: isIPad ? 20 : 18))
            VStack(alignment: .leading, spacing: 2) {
                Text(currentMode.displayName)
                    .font(.system(size: isIPad ? 18 : 15, weight: .semibold))
                    .foregroundColor(modeColor(for: currentMode))
                if currentMode == .sum {
                    Text("Țintă: \(viewModel.gameState.sumGameTarget)")
                        .font(.system(size: isIPad ? 14 : 12)).foregroundColor(.secondary)
                } else if currentMode == .highest {
                    let maxP = viewModel.numberOfDice * viewModel.settings.diceTypeValue.maxValue
                    Text("Maxim posibil: \(maxP)")
                        .font(.system(size: isIPad ? 14 : 12)).foregroundColor(.secondary)
                } else if currentMode == .coinFlip {
                    Text("Rezultat: \(viewModel.coinIsHeads ? "Cap" : "Pajură")")
                        .font(.system(size: isIPad ? 14 : 12)).foregroundColor(.secondary)
                } else if currentMode == .randomNumber {
                    Text("Rezultat: \(viewModel.randomNumberResult)")
                        .font(.system(size: isIPad ? 14 : 12)).foregroundColor(.secondary)
                }
            }
            Spacer()
            if currentMode == .sum {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(viewModel.total) / \(viewModel.gameState.sumGameTarget)")
                        .font(.system(size: isIPad ? 18 : 16, weight: .bold))
                        .foregroundColor(viewModel.total >= viewModel.gameState.sumGameTarget ? .green : modeColor(for: currentMode))
                    if viewModel.total < viewModel.gameState.sumGameTarget {
                        Text("Mai trebuie: \(viewModel.gameState.sumGameTarget - viewModel.total)")
                            .font(.system(size: isIPad ? 12 : 10)).foregroundColor(.secondary)
                    }
                }
            } else if currentMode == .highest {
                let maxP = viewModel.numberOfDice * viewModel.settings.diceTypeValue.maxValue
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(viewModel.total) / \(maxP)")
                        .font(.system(size: isIPad ? 18 : 16, weight: .bold))
                        .foregroundColor(viewModel.total == maxP ? .green : modeColor(for: currentMode))
                    if viewModel.total < maxP {
                        Text("Mai trebuie: \(maxP - viewModel.total)")
                            .font(.system(size: isIPad ? 12 : 10)).foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, isIPad ? 20 : 16).padding(.vertical, isIPad ? 12 : 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(modeColor(for: currentMode).opacity(0.1)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(modeColor(for: currentMode).opacity(0.3), lineWidth: 1))
        .padding(.horizontal, isIPad ? 20 : 16)
    }

    private func modeIcon(for mode: GameMode) -> String {
        switch mode {
        case .free: return "dice.fill"
        case .sum: return "target"
        case .highest: return "arrow.up.circle.fill"
        case .turnBased: return "person.2.fill"
        case .coinFlip: return "bitcoinsign.circle.fill"
        case .randomNumber: return "number.circle.fill"
        }
    }

    private func modeColor(for mode: GameMode) -> Color {
        switch mode {
        case .free: return .gray
        case .sum: return .orange
        case .highest: return .purple
        case .turnBased: return .blue
        case .coinFlip: return .yellow
        case .randomNumber: return .indigo
        }
    }

    // MARK: - Target Reached Banner

    private var targetReachedBanner: some View {
        let currentMode = GameMode(rawValue: viewModel.settings.selectedGameMode) ?? .free
        return HStack {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.system(size: isIPad ? 24 : 20))
            VStack(alignment: .leading, spacing: 2) {
                Text(currentMode == .sum ? "Ai atins ținta!" : "Ai atins maximul!")
                    .font(.system(size: isIPad ? 20 : 17, weight: .bold)).foregroundColor(.green)
                if currentMode == .sum {
                    Text("Suma: \(viewModel.total) / \(viewModel.gameState.sumGameTarget)")
                        .font(.system(size: isIPad ? 16 : 14)).foregroundColor(.green.opacity(0.8))
                } else if currentMode == .highest {
                    let maxP = viewModel.numberOfDice * viewModel.settings.diceTypeValue.maxValue
                    Text("Suma: \(viewModel.total) / \(maxP)")
                        .font(.system(size: isIPad ? 16 : 14)).foregroundColor(.green.opacity(0.8))
                }
            }
            Spacer()
        }
        .padding(.horizontal, isIPad ? 20 : 16).padding(.vertical, isIPad ? 14 : 12)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(LinearGradient(colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)], startPoint: .leading, endPoint: .trailing)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.5), lineWidth: 2))
        .padding(.horizontal, isIPad ? 20 : 16)
        .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    // MARK: - Roll Button

    private var rollButton: some View {
        let currentMode = GameMode(rawValue: viewModel.settings.selectedGameMode) ?? .free
        let turnBasedNoDice = currentMode == .turnBased && !viewModel.settings.showTurnBasedDiceValue
        let showAdvanceButton = turnBasedViewModel.waitingForNextPlayer || turnBasedNoDice
        let accentColor = showAdvanceButton ? Color.green : viewModel.settings.theme.primaryColor

        return HStack {
            if showAdvanceButton {
                Image(systemName: "arrow.right.circle.fill").font(.system(size: isIPad ? 24 : 20))
                if let nextPlayer = turnBasedViewModel.nextPlayerName {
                    Text("Treci la \(nextPlayer)").font(.system(size: isIPad ? 24 : 20, weight: .semibold))
                } else {
                    Text("Treci la următorul").font(.system(size: isIPad ? 24 : 20, weight: .semibold))
                }
            } else if currentMode == .coinFlip {
                Image(systemName: "bitcoinsign.circle.fill").font(.system(size: isIPad ? 24 : 20))
                Text("Aruncă moneda").font(.system(size: isIPad ? 24 : 20, weight: .semibold))
            } else if currentMode == .randomNumber {
                Image(systemName: "number.circle.fill").font(.system(size: isIPad ? 24 : 20))
                Text("Generează numărul").font(.system(size: isIPad ? 24 : 20, weight: .semibold))
            } else if currentMode == .turnBased, let currentPlayer = turnBasedViewModel.currentPlayerName {
                Image(systemName: "dice.fill").font(.system(size: isIPad ? 24 : 20))
                Text("Aruncă zarurile, \(currentPlayer)")
                    .font(.system(size: isIPad ? 24 : 20, weight: .semibold))
            } else {
                Image(systemName: "dice.fill").font(.system(size: isIPad ? 24 : 20))
                Text("Aruncă zarurile").font(.system(size: isIPad ? 24 : 20, weight: .semibold))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, isIPad ? 60 : 40).padding(.vertical, isIPad ? 24 : 18)
        .background(LinearGradient(
            colors: [accentColor, accentColor.opacity(0.8)],
            startPoint: .leading, endPoint: .trailing))
        .cornerRadius(isIPad ? 30 : 25)
        .shadow(color: accentColor.opacity(0.3), radius: isIPad ? 15 : 10, x: 0, y: isIPad ? 8 : 5)
        .scaleEffect(rollPressScale)
        .animation(.easeInOut(duration: 0.12), value: rollPressScale)
        .opacity(viewModel.isRolling ? 0.6 : 1.0)
        .padding(.horizontal)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { _ in
                    if rollPressScale == 1.0 {
                        // Animate the button growing while the user presses it.
                        let targetScale: CGFloat = isIPad ? 1.16 : 1.14
                        withAnimation(.easeInOut(duration: 0.6)) {
                            rollPressScale = targetScale
                        }
                    }
                }
                .onEnded { _ in
                    // Capture current scale (how "hard" the user pressed), then shrink back.
                    let currentScale = rollPressScale
                    withAnimation(.easeInOut(duration: 0.25)) {
                        rollPressScale = 1.0
                    }

                    guard !viewModel.isRolling else { return }

                    // Map scale -> normalized 0...1 strength, apoi la o forță mai moderată 1.0...3.5.
                    let maxVisualScale: CGFloat = isIPad ? 1.16 : 1.14
                    let clampedScale = min(max(currentScale, 1.0), maxVisualScale)
                    let normalized = Double((clampedScale - 1.0) / max(0.001, (maxVisualScale - 1.0)))
                    let force = Float(1.0 + normalized * 2.5)  // 1.0 (light tap) → ~3.5 (max throw)
                    if showAdvanceButton {
                        turnBasedViewModel.advanceToNextPlayer()
                    } else if currentMode == .coinFlip {
                        // Coin flip: reuse the same force mapping so a larger press spins the coin harder.
                        viewModel.rollDices(force: force)
                    } else if currentMode == .randomNumber {
                        viewModel.rollRandomNumber()
                    } else {
                        viewModel.rollDices(force: force)
                    }
                }
        )
        .allowsHitTesting(!viewModel.isRolling)
    }

    // MARK: - Helpers

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var isLandscape: Bool {
        UIScreen.main.bounds.width > UIScreen.main.bounds.height
    }

    /// Returns progress (0...1) for Highest mode, or nil if alt mod.
    private func highestModeProgress() -> Double? {
        let currentMode = GameMode(rawValue: viewModel.settings.selectedGameMode) ?? .free
        guard currentMode == .highest else { return nil }
        let maxP = viewModel.numberOfDice * viewModel.settings.diceTypeValue.maxValue
        guard maxP > 0 else { return nil }
        let ratio = Double(viewModel.total) / Double(maxP)
        return min(max(ratio, 0), 1)
    }

    private func syncCurrentPlayerName() {
        viewModel.currentTurnPlayerName = turnBasedViewModel.currentPlayerName
        if viewModel.isTurnBasedMode,
           viewModel.settings.showTurnBasedDiceValue,
           let diceType = turnBasedViewModel.currentPlayerDiceType {
            let useCustom = turnBasedViewModel.currentPlayerUsesCustomDice
            viewModel.applyDiceTypeForCurrentPlayer(diceType, useCustom: useCustom)
        }
    }
}

private struct PlayerListHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    ContentView()
}
