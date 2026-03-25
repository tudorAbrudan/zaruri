//
//  HistoryView.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI

/// History view showing past dice rolls
struct HistoryView: View {
    var viewModel: DiceViewModel
    @State private var searchText: String = ""
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar for iOS 13 compatibility
            if !viewModel.history.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Caută în istoric", text: $searchText)
                }
                .padding(8)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            if viewModel.history.isEmpty {
                emptyStateView
            } else {
                historyList
            }
        }
        .navigationBarTitle("Istoric", displayMode: .inline)
        .navigationBarItems(trailing: 
            viewModel.history.isEmpty ? nil : 
            Button("Șterge") {
                viewModel.clearHistory()
            }
        )
    }
    
    // MARK: - History List
    
    private var historyList: some View {
        List {
            ForEach(filteredHistory) { roll in
                HistoryRow(roll: roll)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: isIPad ? 30 : 20) {
            Image(systemName: "clock")
                .font(.system(size: isIPad ? 80 : 60))
                .foregroundColor(.secondary)
            Text("Nu există istoric")
                .font(.system(size: isIPad ? 28 : 22, weight: .bold))
                .foregroundColor(.secondary)
            Text("Aruncă zarurile pentru a începe")
                .font(isIPad ? .body : .subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Filtered History
    
    private var filteredHistory: [DiceRoll] {
        if searchText.isEmpty {
            return viewModel.history
        }
        
        return viewModel.history.filter { roll in
            roll.formattedValues.localizedCaseInsensitiveContains(searchText) ||
            String(roll.total).contains(searchText) ||
            roll.formattedDate.localizedCaseInsensitiveContains(searchText) ||
            (roll.playerName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
}

// MARK: - History Row

struct HistoryRow: View {
    let roll: DiceRoll
    
    var body: some View {
        HStack {
            // Dice values with player name
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    if let playerName = roll.playerName, !playerName.isEmpty {
                        Text("\(playerName):")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    Text(roll.formattedValues)
                        .font(.headline)
                }
                Text(roll.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Total
            if roll.numberOfDice > 1 {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(roll.total)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

