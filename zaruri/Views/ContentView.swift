//
//  ContentView.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI

/// Main content view with 2D dice
struct ContentView: View {
    @ObservedObject private var viewModel: DiceViewModel
    @State private var showDiceCountSheet = false
    
    init() {
        // For iOS 13 compatibility, use ObservedObject with manual initialization
        let vm = DiceViewModel()
        _viewModel = ObservedObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationView {
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
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Dice display area - centered
                    diceDisplayArea
                        .padding(.horizontal, isIPad ? 40 : 20)
                    
                    // Total display (if more than 1 dice)
                    if viewModel.numberOfDice > 1 {
                        totalDisplay
                            .padding(.top, isIPad ? 40 : 20)
                    }
                    
                    Spacer()
                    
                    // Roll button
                    rollButton
                        .padding(.bottom, isIPad ? 60 : 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onAppear {
                // Ensure dice are initialized
                if viewModel.dices.isEmpty {
                    viewModel.setupDices()
                }
            }
            .navigationBarTitle("ZARURI")
            .navigationBarItems(trailing:
                HStack(spacing: 12) {
                    Button(action: {
                        showDiceCountSheet = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .actionSheet(isPresented: $showDiceCountSheet) {
                        ActionSheet(
                            title: Text("Număr zaruri"),
                            buttons: [
                                .default(Text("1 zar")) {
                                    viewModel.updateNumberOfDice(1)
                                },
                                .default(Text("2 zaruri")) {
                                    viewModel.updateNumberOfDice(2)
                                },
                                .default(Text("3 zaruri")) {
                                    viewModel.updateNumberOfDice(3)
                                },
                                .cancel()
                            ]
                        )
                    }
                    
                    NavigationLink(destination: SettingsView(viewModel: viewModel)) {
                        Image(systemName: "gear")
                    }
                    NavigationLink(destination: HistoryView(viewModel: viewModel)) {
                        Image(systemName: "clock")
                    }
                    NavigationLink(destination: StatisticsView(viewModel: viewModel)) {
                        Image(systemName: "chart.bar")
                    }
                    NavigationLink(destination: GameModesView(viewModel: viewModel)) {
                        Image(systemName: "gamecontroller")
                    }
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Force stack navigation on iPad
    }
    
    // MARK: - Dice Display Area
    
    private var diceDisplayArea: some View {
        HStack(spacing: isIPad ? 50 : 30) {
            if viewModel.dices.isEmpty {
                // Show placeholder while loading
                Text("Se încarcă...")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.dices) { dice in
                    DiceSimpleView(
                        dice: dice,
                        size: diceSize
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Total Display
    
    private var totalDisplay: some View {
        VStack(spacing: 8) {
            Text("Total")
                .font(.system(size: isIPad ? 22 : 17, weight: .bold))
                .foregroundColor(.secondary)
            Text("\(viewModel.total)")
                .font(.system(size: isIPad ? 72 : 48, weight: .bold))
                .foregroundColor(viewModel.settings.theme.primaryColor)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Roll Button
    
    private var rollButton: some View {
        Button(action: {
            viewModel.rollDices()
        }) {
            HStack {
                Image(systemName: "dice.fill")
                    .font(.system(size: isIPad ? 24 : 20))
                Text("Aruncă zarurile")
                    .font(.system(size: isIPad ? 24 : 20, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, isIPad ? 60 : 40)
            .padding(.vertical, isIPad ? 24 : 18)
            .background(
                LinearGradient(
                    colors: [
                        viewModel.settings.theme.primaryColor,
                        viewModel.settings.theme.primaryColor.opacity(0.8)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(isIPad ? 30 : 25)
            .shadow(
                color: viewModel.settings.theme.primaryColor.opacity(0.3),
                radius: isIPad ? 15 : 10,
                x: 0,
                y: isIPad ? 8 : 5
            )
        }
        .disabled(viewModel.isRolling)
        .opacity(viewModel.isRolling ? 0.6 : 1.0)
        .padding(.horizontal)
    }
    
    // MARK: - Dice Count Menu (iOS 13 compatible)
    
    private var diceCountMenu: some View {
        Group {
            Button(action: {
                viewModel.updateNumberOfDice(1)
            }) {
                HStack {
                    if viewModel.numberOfDice == 1 {
                        Image(systemName: "checkmark")
                    }
                    Text("1 zar")
                }
            }
            Button(action: {
                viewModel.updateNumberOfDice(2)
            }) {
                HStack {
                    if viewModel.numberOfDice == 2 {
                        Image(systemName: "checkmark")
                    }
                    Text("2 zaruri")
                }
            }
            Button(action: {
                viewModel.updateNumberOfDice(3)
            }) {
                HStack {
                    if viewModel.numberOfDice == 3 {
                        Image(systemName: "checkmark")
                    }
                    Text("3 zaruri")
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var diceSize: CGFloat {
        let baseSize: CGFloat
        switch viewModel.numberOfDice {
        case 1:
            baseSize = isIPad ? 250 : 150
        case 2:
            baseSize = isIPad ? 200 : 120
        case 3:
            baseSize = isIPad ? 160 : 100
        default:
            baseSize = isIPad ? 200 : 120
        }
        return baseSize
    }
}

#Preview {
    ContentView()
}

