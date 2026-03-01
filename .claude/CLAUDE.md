# CLAUDE.md

Acest fișier oferă instrucțiuni pentru Claude Code când lucrează cu codul din acest repository.

## Prezentare Proiect

**Zaruri** este o aplicație iOS nativă pentru aruncarea zarurilor. Suportă D4, D6, D8, D10, D12, D20 cu animații 2D, sunete, haptic feedback, statistici, istoric, moduri de joc turn-based și widget.

- **Platformă**: iOS 13.0+, iPadOS
- **Limbaj**: Swift 5.x
- **UI**: SwiftUI
- **Arhitectură**: MVVM
- **3D/2D**: SceneKit (wrapped în SwiftUI)
- **Extras**: WidgetKit, AVFoundation (sunet), CoreHaptics, SafariServices
- **Limbă UI**: Română (ro), cu suport multilingv (bg, sr, hr, bs, mk, sq, en)

---

## Comenzi de Dezvoltare

### Build & Run
```bash
# Build pentru simulator
xcodebuild -project zaruri.xcodeproj -scheme zaruri \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build

# Build pentru device
xcodebuild -project zaruri.xcodeproj -scheme zaruri \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  build
```

### Teste
```bash
# Rulează unit tests
xcodebuild test -scheme zaruri \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Cu coverage
xcodebuild test -scheme zaruri \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES
```

### Linting / Formatting
```bash
# SwiftLint (dacă e instalat)
swiftlint lint zaruri/

# Swift Format (dacă e instalat)
swift-format --in-place --recursive zaruri/
```

---

## Arhitectură

### Pattern: MVVM strict

```
Views       →  SwiftUI Views (UI only, no business logic)
ViewModels  →  @MainActor ObservableObject (state + business logic)
Models      →  Swift structs/enums (data, pure logic)
Utilities   →  Managers (SoundManager, HapticFeedbackManager, etc.)
3D          →  SceneKit components (UIViewRepresentable)
```

### Structura fișierelor

```
zaruri/
├── Models/          # max 200 linii/fișier
├── Views/           # max 500 linii/fișier
├── ViewModels/      # max 300 linii/fișier
├── 3D/              # SceneKit
├── Utilities/       # Managers
└── Resources/       # Assets, Sounds, Localizations
```

### Fișiere cheie
- `zaruri/Views/ContentView.swift` — View principal
- `zaruri/ViewModels/DiceViewModel.swift` — ViewModel principal
- `zaruri/Models/Dice.swift`, `DiceRoll.swift`, `GameState.swift` — modele core
- `zaruri/Utilities/SoundManager.swift`, `HapticFeedbackManager.swift`
- `zaruriWidget/` — WidgetKit extension

---

## Convenții de Cod

Detalii complete în `CODING_STANDARDS.md`. Rezumat:

- **Naming**: `PascalCase` clase/struct, `camelCase` variabile/funcții, `camelCase` constante cu `static let`
- **Views**: doar UI, zero business logic — delega TOTUL la ViewModel
- **ViewModels**: `@MainActor`, `ObservableObject`, `@Published` pentru state
- **Property wrappers**: `@StateObject` (owned), `@ObservedObject` (passed), `@State` (local UI), `@Binding` (two-way)
- **Error handling**: `Result<T, DiceError>`, fără force unwrap (`!`), mereu `guard let` / `if let`
- **Memory**: `[weak self]` în closures, cleanup în `.onDisappear`, `deinit` pentru SceneKit

---

## Workflow Agent

### Înainte de orice modificare
1. Citește fișierele afectate (nu ghici structura)
2. Verifică că MVVM e respectat: Views nu au business logic
3. Verifică că nu există force unwrap (`!`) sau `fatalError` necesar
4. Verifică localizare: orice text nou → adăugat în toate fișierele `.strings`

### Checklist pre-commit (agent)
- [ ] Architectură MVVM respectată
- [ ] Fără force unwrap
- [ ] Error handling implementat
- [ ] `[weak self]` unde e nevoie
- [ ] Dark Mode funcțional
- [ ] Localizare completă (ro + celelalte limbi)
- [ ] Accessibility: VoiceOver labels adăugate
- [ ] Teste scrise pentru logică nouă în ViewModel/Models

### Invocare agenți specializați
- **`expert-code-reviewer`** — după orice feature/fix, pe fișierele modificate
- **`swift-architect`** — la planificarea unei funcționalități noi
- **`ui-ux-expert`** — la modificări de UI/SwiftUI

---

## Reguli Stricte

1. **Nu pune business logic în Views** — dacă un View face calcule, e greșit
2. **Nu force unwrap** — niciodată `value!` fără guard anterior
3. **Nu bloca main thread** — async/await sau `DispatchQueue.main.async` pentru UI updates
4. **Nu hardcoda string-uri** — orice text vizibil utilizatorului merge în `Localizable.strings`
5. **Nu uita cleanup** — SceneKit nodes, Timers, NotificationCenter observers

---

## Context Lingvistic

- Textele din UI: **română** (primar), cu localizare multilingvă
- Cod, comentarii, variabile: **engleză**
- Commit messages: **engleză** (conventional commits)
