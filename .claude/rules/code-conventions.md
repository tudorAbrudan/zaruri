---
paths:
  - "**/*.swift"
---

# Convenții de Cod Swift / iOS

## Arhitectură MVVM

- Views în `zaruri/Views/` — **DOAR SwiftUI layout și UI interactions**
- ViewModels în `zaruri/ViewModels/` — **state + business logic**, `@MainActor ObservableObject`
- Models în `zaruri/Models/` — **date pure**, fără dependențe de UI
- Utilities în `zaruri/Utilities/` — **Managers** (Sound, Haptic, UserDefaults, etc.)
- 3D în `zaruri/3D/` — **SceneKit components** via `UIViewRepresentable`

## Reguli de Bază

- Deleghează ORICE acțiune din View la ViewModel: `viewModel.rollDice()` nu `dice.value = Int.random(in:1...6)`
- Fără force unwrap (`!`) — mereu `guard let`, `if let`, sau `??`
- `@MainActor` pe orice ViewModel care face update UI
- `[weak self]` obligatoriu în closures capturate async (Timer, DispatchQueue, SceneKit actions)
- Cleanup în `.onDisappear {}` și `deinit`

## Naming

- Clase/Structs/Enums: `PascalCase` — `DiceViewModel`, `GameState`, `DiceType`
- Funcții/Variabile: `camelCase` — `rollDice()`, `currentDiceValue`
- Constante: `static let camelCase` — `static let maxDiceCount = 6`
- Fișiere Views: `[Feature]View.swift`, ViewModels: `[Feature]ViewModel.swift`

## Property Wrappers

```swift
@StateObject private var vm: DiceViewModel      // owned ViewModel
@ObservedObject var vm: DiceViewModel           // passed ViewModel
@State private var isAnimating = false          // local UI state only
@Binding var value: Int                         // two-way binding
@Published var diceHistory: [DiceRoll] = []     // in ObservableObject
```

## Error Handling

```swift
// Mereu Result sau optional, nu force unwrap
func loadHistory() -> Result<[DiceRoll], DiceError>

// Custom errors cu LocalizedError
enum DiceError: LocalizedError {
    case invalidDiceCount
    case saveFailed
}
```

## Verificări Obligatorii Pre-Commit

1. Build fără warnings: `xcodebuild build` pe simulator
2. Teste trec: `xcodebuild test`
3. Nicio apariție de `!` (force unwrap) în cod nou
4. Orice text nou → adăugat în `Localizable.strings` (ro + en minim)
5. Invocă agentul `expert-code-reviewer` pe fișierele modificate

## Limbă

- UI text: română (primar)
- Cod + comentarii: engleză
- Commit messages: engleză, format `type(scope): description`
