//
//  ShareView.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI

/// Share view for sharing dice roll results
struct ShareView: UIViewControllerRepresentable {
    let items: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?
    
    init(items: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil) {
        self.items = items
        self.excludedActivityTypes = excludedActivityTypes
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

/// Helper for sharing dice results
struct DiceShareHelper {
    static func shareText(for roll: DiceRoll) -> String {
        if roll.numberOfDice == 1 {
            return "Am aruncat zarul și am obținut: \(roll.values[0]) 🎲"
        } else {
            return "Am aruncat \(roll.numberOfDice) zaruri: \(roll.formattedValues) = Total: \(roll.total) 🎲"
        }
    }
    
    static func shareText(for dices: [Dice]) -> String {
        let values = dices.map { String($0.value) }.joined(separator: ", ")
        if dices.count == 1 {
            return "Zar: \(values) 🎲"
        } else {
            let total = dices.reduce(0) { $0 + $1.value }
            return "Zaruri: \(values) = Total: \(total) 🎲"
        }
    }
}










