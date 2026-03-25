//
//  GameModesView.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI

/// Game modes view for different dice games
struct GameModesView: View {
    var viewModel: DiceViewModel
    var turnBasedViewModel: TurnBasedViewModel

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var selectedMode: GameMode {
        GameMode(rawValue: viewModel.settings.selectedGameMode) ?? .free
    }

    var body: some View {
        Form {
            // Game modes – competitive / de joc
            Section(header: Text("MOD DE JOC")) {
                ForEach([GameMode.free, .sum, .highest, .turnBased], id: \.self) { mode in
                    Button(action: { selectMode(mode) }) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: selectedMode == mode ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(selectedMode == mode ? .accentColor : .secondary)
                                .font(.system(size: isIPad ? 22 : 18))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.displayName)
                                    .font(.body)
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Mode-specific information / settings for the selected game
            Section(header: Text("Informații / setări joc")) {
                switch selectedMode {
                case .free:
                    freeModeView
                case .sum:
                    sumModeView
                case .highest:
                    highestModeView
                case .turnBased:
                    turnBasedModeView
                case .coinFlip:
                    coinFlipModeView
                case .randomNumber:
                    randomNumberModeView
                }
            }

            // Dice configuration
            Section(header: Text("Configurație zar")) {
                Stepper(
                    "\(viewModel.numberOfDice) \(viewModel.numberOfDice == 1 ? "zar" : "zaruri")",
                    value: Binding(
                        get: { viewModel.numberOfDice },
                        set: { viewModel.updateNumberOfDice($0) }
                    ),
                    in: 1...6
                )
                
                NavigationLink {
                    CustomDiceView(viewModel: viewModel)
                } label: {
                    HStack {
                        Image(systemName: "dice.fill")
                            .foregroundStyle(.purple)
                        if let config = viewModel.settings.customDiceConfig {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Zar custom")
                                Text("\(config.geometryType.displayName) · \(config.useCustomLabels ? "text custom" : "numere") · \(config.name)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Zar custom")
                                Text("Configurează un zar personalizat")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Picker("Tip zaruri", selection: Binding(
                    get: {
                        viewModel.settings.useCustomDiceValue ? "custom" : viewModel.settings.diceTypeValue.rawValue
                    },
                    set: { selection in
                        if selection == "custom" {
                            viewModel.toggleCustomDice(true)
                        } else if let type = DiceType(rawValue: selection) {
                            viewModel.updateDiceType(type)
                        }
                    }
                )) {
                    ForEach(DiceType.allCases.filter { $0 != .d10 }, id: \.self) { type in
                        Text(type.displayName).tag(type.rawValue)
                    }
                    if let config = viewModel.settings.customDiceConfig {
                        Text("✦ \(config.name)").tag("custom")
                    }
                }
            }
            
            // Non-competitive tools – Coin Flip & Random Number
            Section(header: Text("Instrumente")) {
                Button(action: { selectMode(.coinFlip) }) {
                    HStack(spacing: 12) {
                        Image(systemName: selectedMode == .coinFlip ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(selectedMode == .coinFlip ? .accentColor : .secondary)
                            .font(.system(size: isIPad ? 22 : 18))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(GameMode.coinFlip.displayName)
                                .font(.body)
                            Text("Aruncă rapid moneda pentru decizii sau egalități.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { selectMode(.randomNumber) }) {
                    HStack(spacing: 12) {
                        Image(systemName: selectedMode == .randomNumber ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(selectedMode == .randomNumber ? .accentColor : .secondary)
                            .font(.system(size: isIPad ? 22 : 18))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(GameMode.randomNumber.displayName)
                                .font(.body)
                            Text("Generează un număr aleatoriu într-un interval ales.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }

        }
        .navigationBarTitle("Zaruri & Joc", displayMode: .inline)
    }

    private func selectMode(_ newMode: GameMode) {
        let oldMode = GameMode(rawValue: viewModel.settings.selectedGameMode) ?? .free
        viewModel.settings.selectedGameMode = newMode.rawValue
        viewModel.saveSettings()
        // În modul „Aruncă cu banul” forțăm 1× d2 ca să folosim moneda 3D.
        if newMode == .coinFlip {
            if viewModel.settings.diceTypeValue != .d2 {
                viewModel.updateDiceType(.d2)
            }
            if viewModel.numberOfDice != 1 {
                viewModel.updateNumberOfDice(1)
            }
        }
        if oldMode == .turnBased && newMode != .turnBased {
            turnBasedViewModel.waitingForNextPlayer = false
        }
    }

    // MARK: - Free Mode

    private var freeModeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aruncă zarurile liber, fără reguli.")
                .font(.body)
        }
    }

    // MARK: - Sum Mode

    private var sumModeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Joc cu sumă")
                .font(.headline)

            Text("Încearcă să obții suma țintă sau mai mult.")
                .font(.caption)
                .foregroundColor(.secondary)

            if viewModel.numberOfDice >= 2 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Sumă țintă:")
                            .font(.subheadline).foregroundColor(.secondary)
                        Spacer()
                        Stepper("\(viewModel.gameState.sumGameTarget)", value: Binding(
                            get: { viewModel.gameState.sumGameTarget },
                            set: { viewModel.setSumGameTarget($0) }
                        ), in: viewModel.numberOfDice...(viewModel.numberOfDice * 6))
                    }
                }
                .padding(.vertical, 8)

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Suma actuală").font(.caption).foregroundColor(.secondary)
                    Text("\(viewModel.total)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(viewModel.total >= viewModel.gameState.sumGameTarget ? .green : .primary)
                }

                if viewModel.gameState.sumGameReachedTarget {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        Text("Ai atins ținta!").font(.subheadline).foregroundColor(.green)
                    }
                    .padding(.top, 4)
                } else {
                    let diff = viewModel.gameState.sumGameTarget - viewModel.total
                    if diff > 0 {
                        Text("Mai ai nevoie de \(diff) pentru a atinge ținta")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Încercări:").font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Text("\(viewModel.gameState.sumGameAttempts)").font(.caption).fontWeight(.semibold)
                    }
                    HStack {
                        Text("Cel mai bun rezultat:").font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Text("\(viewModel.gameState.sumGameBestScore)").font(.caption).fontWeight(.semibold)
                    }
                }

                Button(action: { viewModel.resetGameState() }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Resetează progresul")
                    }
                    .font(.subheadline).foregroundColor(.blue)
                }
                .padding(.top, 8)
            } else {
                Text("Ai nevoie de cel puțin 2 zaruri pentru acest mod de joc.")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Highest Mode

    private var highestModeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Valoare maximă").font(.headline)
            Text("Încearcă să obții cea mai mare valoare posibilă.")
                .font(.caption).foregroundColor(.secondary)

            if viewModel.numberOfDice >= 3 {
                let maxPossible = viewModel.numberOfDice * 6

                VStack(alignment: .leading, spacing: 4) {
                    Text("Maxim posibil").font(.caption).foregroundColor(.secondary)
                    Text("\(maxPossible)").font(.system(size: 28, weight: .bold))
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Suma actuală").font(.caption).foregroundColor(.secondary)
                    Text("\(viewModel.total)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(viewModel.total == maxPossible ? .green : .primary)
                }

                if viewModel.gameState.highestValueMaxReached {
                    HStack {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                        Text("Felicitări! Ai obținut maximul!").font(.subheadline).foregroundColor(.green)
                    }
                    .padding(.top, 4)
                } else if viewModel.gameState.highestValueBestScore > 0 {
                    let diff = maxPossible - viewModel.total
                    if diff > 0 {
                        Text("Mai ai nevoie de \(diff) pentru maxim")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Încercări:").font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Text("\(viewModel.gameState.highestValueAttempts)").font(.caption).fontWeight(.semibold)
                    }
                    HStack {
                        Text("Cel mai bun rezultat:").font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Text("\(viewModel.gameState.highestValueBestScore)")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundColor(viewModel.gameState.highestValueBestScore == maxPossible ? .green : .primary)
                    }
                    if viewModel.gameState.highestValueBestScore > 0 {
                        let progress = Double(viewModel.gameState.highestValueBestScore) / Double(maxPossible)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 8).cornerRadius(4)
                                Rectangle().fill(Color.blue)
                                    .frame(width: geo.size.width * CGFloat(progress), height: 8).cornerRadius(4)
                            }
                        }
                        .frame(height: 8).padding(.top, 4)
                    }
                }

                Button(action: { viewModel.resetGameState() }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Resetează progresul")
                    }
                    .font(.subheadline).foregroundColor(.blue)
                }
                .padding(.top, 8)
            } else {
                Text("Ai nevoie de cel puțin 3 zaruri pentru acest mod de joc.")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Turn-based Mode

    @State private var newPlayerName: String = ""

    private var turnBasedModeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Joc cu jucători").font(.headline)
            Text("Configurează lista de jucători care vor arunca pe rând.")
                .font(.caption).foregroundColor(.secondary)

            Toggle(isOn: Binding(
                get: { viewModel.settings.showTurnBasedTimerValue },
                set: { viewModel.settings.turnBasedShowTimer = $0; viewModel.saveSettings() }
            )) {
                Text("Folosește timer").font(.subheadline)
            }

            Toggle(isOn: Binding(
                get: { viewModel.settings.showTurnBasedDiceValue },
                set: { viewModel.settings.turnBasedShowDice = $0; viewModel.saveSettings() }
            )) {
                Text("Folosește zaruri").font(.subheadline)
            }

            if viewModel.settings.showTurnBasedTimerValue {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Timp per jucător (la început)")
                        .font(.subheadline).foregroundColor(.secondary)
                    HStack {
                        Text("\(turnBasedViewModel.initialSeconds / 60) min")
                            .font(.body).fontWeight(.medium)
                        Stepper("", value: Binding(
                            get: { turnBasedViewModel.initialSeconds / 60 },
                            set: { turnBasedViewModel.setInitialSeconds($0 * 60) }
                        ), in: 1...60)
                        .labelsHidden()
                    }
                }
            }

            if let currentPlayer = turnBasedViewModel.currentPlayerName {
                HStack {
                    Image(systemName: "person.fill").foregroundColor(.blue)
                    Text("Jucător curent: \(currentPlayer)")
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(.blue)
                }
                .padding(.vertical, 8)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Jucători (\(turnBasedViewModel.players.count)/10)")
                    .font(.subheadline).foregroundColor(.secondary)

                if turnBasedViewModel.players.isEmpty {
                    Text("Nu există jucători. Adaugă cel puțin 2 jucători pentru a începe.")
                        .font(.caption).foregroundColor(.secondary).padding(.vertical, 8)
                } else {
                    ForEach(0..<turnBasedViewModel.players.count, id: \.self) { index in
                        let player = turnBasedViewModel.players[index]
                        let diceType = turnBasedViewModel.playerDiceType(at: index)
                        let usesCustom = turnBasedViewModel.playerUsesCustomDice(at: index)
                        HStack(spacing: 8) {
                            if index == turnBasedViewModel.currentPlayerIndex {
                                Image(systemName: "arrow.right.circle.fill").foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle").foregroundColor(.gray)
                            }
                            Text(player).font(.body).lineLimit(1)
                            Spacer()
                            Menu {
                                // Standard dice types
                                ForEach(DiceType.allCases, id: \.self) { type in
                                    Button(action: {
                                        turnBasedViewModel.setPlayerDiceType(at: index, diceType: type)
                                        turnBasedViewModel.setPlayerUseCustomDice(at: index, useCustom: false)
                                    }) {
                                        Label(type.displayName, systemImage: "dice")
                                    }
                                }
                                // Custom dice option, if a config exists
                                if let config = viewModel.settings.customDiceConfig {
                                    Button(action: {
                                        turnBasedViewModel.setPlayerDiceType(at: index, diceType: config.geometryType)
                                        turnBasedViewModel.setPlayerUseCustomDice(at: index, useCustom: true)
                                    }) {
                                        Label("Custom · \(config.name)", systemImage: "staroflife.fill")
                                    }
                                }
                            } label: {
                                Text(
                                    (usesCustom && viewModel.settings.customDiceConfig != nil)
                                    ? "✦ " + (viewModel.settings.customDiceConfig?.name ?? "")
                                    : diceType.displayName
                                )
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.blue.opacity(0.15)))
                                .foregroundColor(.blue)
                            }
                            Button(action: { turnBasedViewModel.removePlayer(at: index) }) {
                                Image(systemName: "trash").foregroundColor(.red).padding(4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Adaugă jucător").font(.subheadline).foregroundColor(.secondary)
                HStack {
                    TextField("Nume jucător", text: $newPlayerName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: {
                        turnBasedViewModel.addPlayer(newPlayerName)
                        newPlayerName = ""
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue).font(.system(size: 22))
                    }
                    .disabled(newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              turnBasedViewModel.players.count >= 10)
                }
                if turnBasedViewModel.players.count >= 10 {
                    Text("Ai atins limita de 10 jucători.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            Divider()

            if !turnBasedViewModel.players.isEmpty {
                HStack(spacing: 16) {
                    Button(action: { turnBasedViewModel.resetTurn() }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Resetează rândul")
                        }
                        .font(.subheadline).foregroundColor(.blue)
                    }
                    if viewModel.settings.showTurnBasedTimerValue {
                        Button(action: { turnBasedViewModel.resetTimers() }) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Resetează timere")
                            }
                            .font(.subheadline).foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Random Number Mode

    @State private var minInput: String = ""
    @State private var maxInput: String = ""

    private var randomNumberModeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Număr aleatoriu").font(.headline)
            Text("Generează un număr aleatoriu în intervalul setat.")
                .font(.caption).foregroundColor(.secondary)

            Divider()

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Minim").font(.subheadline).foregroundColor(.secondary)
                        TextField("1", text: $minInput)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
                            .onChange(of: minInput) { _, val in applyRangeInput(minText: val, maxText: maxInput) }
                    }

                    Text("—").foregroundColor(.secondary).padding(.top, 20)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Maxim").font(.subheadline).foregroundColor(.secondary)
                        TextField("100", text: $maxInput)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
                            .onChange(of: maxInput) { _, val in applyRangeInput(minText: minInput, maxText: val) }
                    }
                }

                if let minVal = Int(minInput), let maxVal = Int(maxInput), minVal >= maxVal {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        Text("Minimul trebuie să fie mai mic decât maximul.")
                            .font(.caption).foregroundColor(.orange)
                    }
                }
            }
            .onAppear {
                minInput = "\(viewModel.settings.randomNumberMinValue)"
                maxInput = "\(viewModel.settings.randomNumberMaxValue)"
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Ultimul rezultat").font(.caption).foregroundColor(.secondary)
                Text(!viewModel.isRolling ? "\(viewModel.randomNumberResult)" : "…")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.indigo)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.35), value: viewModel.randomNumberResult)
                Text("Interval: \(viewModel.settings.randomNumberMinValue) – \(viewModel.settings.randomNumberMaxValue)")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
    }

    private func applyRangeInput(minText: String, maxText: String) {
        guard let lo = Int(minText), let hi = Int(maxText), lo < hi else { return }
        viewModel.updateRandomNumberRange(min: lo, max: hi)
    }

    // MARK: - Coin Flip Mode

    private var coinFlipModeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aruncă cu banul").font(.headline)
            Text("Aruncă moneda pentru Cap sau Pajură. Moneda se va roti și va arăta rezultatul.")
                .font(.caption).foregroundColor(.secondary)
            Divider()
            if !viewModel.isRolling {
                HStack {
                    Image(systemName: viewModel.coinIsHeads ? "face.smiling" : "star.fill")
                        .foregroundColor(viewModel.coinIsHeads ? .green : .blue)
                    Text("Rezultat: \(viewModel.coinIsHeads ? "Cap" : "Pajură")")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(viewModel.coinIsHeads ? .green : .blue)
                }
                .padding(.vertical, 8)
            }
        }
    }
}
