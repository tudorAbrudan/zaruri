//
//  Dice3DView.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI

/// SwiftUI view wrapper for 3D dice SceneKit view
struct Dice3DView: View {
    let dice: Dice
    let size: CGFloat
    
    var body: some View {
        DiceSceneKitView(
            dice: dice,
            size: size,
            isRolling: dice.isRolling
        )
        .frame(width: size, height: size)
    }
}

#Preview {
    Dice3DView(dice: Dice(value: 4), size: 120)
}



