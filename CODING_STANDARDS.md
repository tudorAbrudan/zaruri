# Zaruri - Coding Standards

## Quick Reference

### Architecture
- **Pattern**: MVVM (Model-View-ViewModel)
- **Separation**: Views → ViewModels → Models/Utilities
- **3D Rendering**: SceneKit wrapped in SwiftUI via UIViewRepresentable
- **Testing**: Unit tests for ViewModels and Utilities

### File Organization
```
zaruri/
├── Models/              # Data models (max 200 lines per model)
│   ├── Dice.swift
│   ├── DiceRoll.swift
│   ├── DiceStatistics.swift
│   ├── AppSettings.swift
│   └── GameMode.swift
├── Views/               # SwiftUI Views (max 500 lines)
│   ├── ContentView.swift
│   ├── SettingsView.swift
│   ├── HistoryView.swift
│   ├── StatisticsView.swift
│   ├── GameModesView.swift
│   └── ShareView.swift
├── ViewModels/          # Business logic (max 300 lines)
│   ├── DiceViewModel.swift
│   ├── StatisticsViewModel.swift
│   └── SettingsViewModel.swift
├── 3D/                  # SceneKit 3D components
│   ├── DiceSceneKitView.swift
│   ├── Dice3DNode.swift
│   ├── DiceAnimationController.swift
│   └── DiceMaterialManager.swift
├── Utilities/           # Helpers and managers
│   ├── HapticFeedbackManager.swift
│   ├── SoundManager.swift
│   ├── UserDefaultsManager.swift
│   └── LocalizationManager.swift
└── Resources/           # Assets
    ├── Sounds/
    ├── Textures/
    └── Localizations/
```

### Naming Conventions

#### Files
- **Views**: `[Feature]View.swift` (e.g., `DiceView.swift`, `HistoryView.swift`)
- **ViewModels**: `[Feature]ViewModel.swift` (e.g., `DiceViewModel.swift`)
- **Models**: `[Domain].swift` (e.g., `Dice.swift`, `DiceRoll.swift`)
- **3D Components**: `[Component]3D[Type].swift` (e.g., `Dice3DNode.swift`)
- **Utilities**: `[Purpose]Manager.swift` (e.g., `SoundManager.swift`)

#### Code Elements
- **Classes/Structs**: `PascalCase` (e.g., `DiceViewModel`, `Dice3DNode`)
- **Variables/Functions**: `camelCase` (e.g., `currentDice`, `rollDice()`)
- **Constants**: `camelCase` with `static let` (e.g., `static let maxDiceCount = 3`)
- **Enums**: `PascalCase` with `camelCase` cases (e.g., `DiceState.rolling`)
- **Private properties**: Prefix with `_` only if needed for property wrappers

### Swift Style Guide

#### Indentation & Formatting
```swift
// ✅ 4 spaces indentation (Xcode default)
struct DiceView: View {
    @StateObject private var viewModel: DiceViewModel
    
    var body: some View {
        VStack {
            // Implementation
        }
    }
}

// ✅ Trailing commas in multi-line collections
let diceValues = [
    1,
    2,
    3,
    4,
    5,
    6,
]

// ✅ Guard statements for early returns
func rollDice() {
    guard !isRolling else { return }
    guard numberOfDices > 0 else { return }
    
    // Roll dice
}
```

#### Property Wrappers
```swift
// ✅ Correct usage
@StateObject private var viewModel: DiceViewModel      // For owned objects
@ObservedObject var sharedViewModel: DiceViewModel     // For passed objects
@State private var isAnimating: Bool = false           // For local UI state
@Binding var diceValue: Int                            // For two-way binding
@Published var diceHistory: [DiceRoll] = []            // In ObservableObject
```

#### Error Handling
```swift
// ✅ Result types for operations that can fail
func loadHistory() -> Result<[DiceRoll], DiceError> {
    // Implementation
}

// ✅ Custom error types
enum DiceError: LocalizedError {
    case invalidDiceCount
    case loadFailed
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidDiceCount:
            return "Invalid dice count"
        case .loadFailed:
            return "Failed to load dice history"
        case .saveFailed:
            return "Failed to save dice history"
        }
    }
}
```

### MVVM Implementation

#### View Layer
```swift
struct DiceView: View {
    @StateObject private var viewModel: DiceViewModel
    
    var body: some View {
        VStack {
            Dice3DView(dice: viewModel.dice)
            Button("Roll") {
                viewModel.rollDice()
            }
        }
    }
}
```

#### ViewModel Layer
```swift
@MainActor
class DiceViewModel: ObservableObject {
    @Published var dice: Dice = Dice()
    @Published var isRolling: Bool = false
    
    private let hapticManager: HapticFeedbackManager
    private let soundManager: SoundManager
    
    init(
        hapticManager: HapticFeedbackManager = .shared,
        soundManager: SoundManager = .shared
    ) {
        self.hapticManager = hapticManager
        self.soundManager = soundManager
    }
    
    func rollDice() {
        guard !isRolling else { return }
        
        isRolling = true
        hapticManager.play(.medium)
        soundManager.playRollSound()
        
        // Roll logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.dice.roll()
            self.isRolling = false
        }
    }
}
```

### 3D SceneKit Integration

#### UIViewRepresentable Pattern
```swift
struct DiceSceneKitView: UIViewRepresentable {
    let dice: Dice
    let isRolling: Bool
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = createScene()
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = true
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update dice node
    }
    
    private func createScene() -> SCNScene {
        let scene = SCNScene()
        // Scene setup
        return scene
    }
}
```

#### 3D Node Creation
```swift
class Dice3DNode: SCNNode {
    var diceValue: Int = 1 {
        didSet {
            updateDiceFaces()
        }
    }
    
    init(size: CGFloat = 1.0) {
        super.init()
        setupDice()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupDice() {
        let box = SCNBox(width: size, height: size, length: size, chamferRadius: size * 0.1)
        geometry = box
        setupMaterials()
    }
    
    private func setupMaterials() {
        // Material setup
    }
    
    private func updateDiceFaces() {
        // Update face textures based on diceValue
    }
}
```

### Performance Guidelines

#### SwiftUI Best Practices
- Use `LazyVStack`/`LazyHStack` for large lists (history)
- Avoid complex computations in `body` - extract to computed properties
- Use `@State` for local UI state only
- Extract complex views into separate components
- Use `@MainActor` for ViewModels that update UI

#### SceneKit Optimization
```swift
// ✅ Reuse scene and nodes
private let scene: SCNScene = {
    let scene = SCNScene()
    // Setup once
    return scene
}()

// ✅ Limit polygon count for performance
let box = SCNBox(
    width: 1.0,
    height: 1.0,
    length: 1.0,
    chamferRadius: 0.1
)

// ✅ Use simple materials for older devices
if #available(iOS 13.0, *) {
    material.metalness.contents = 0.5
} else {
    // Fallback for iOS 13
}
```

#### Memory Management
```swift
// ✅ Weak references in closures
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
    self?.updateDice()
}

// ✅ Proper cleanup
.onDisappear {
    viewModel.cleanup()
}

// ✅ Dispose of SceneKit resources
deinit {
    sceneView.scene = nil
}
```

### Testing Standards

#### Unit Test Structure
```swift
@MainActor
class DiceViewModelTests: XCTestCase {
    var viewModel: DiceViewModel!
    var mockHapticManager: MockHapticFeedbackManager!
    var mockSoundManager: MockSoundManager!
    
    override func setUp() {
        mockHapticManager = MockHapticFeedbackManager()
        mockSoundManager = MockSoundManager()
        viewModel = DiceViewModel(
            hapticManager: mockHapticManager,
            soundManager: mockSoundManager
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockHapticManager = nil
        mockSoundManager = nil
    }
    
    func testRollDice() {
        // Given
        let initialValue = viewModel.dice.value
        
        // When
        viewModel.rollDice()
        
        // Then
        XCTAssertTrue(viewModel.isRolling)
        XCTAssertTrue(mockHapticManager.playCalled)
        XCTAssertTrue(mockSoundManager.playRollSoundCalled)
    }
}
```

### Localization

#### String Keys Format
```swift
// ✅ Format: feature.element.description
"dice.roll.button"
"dice.total.label"
"settings.dice.count.title"
"history.empty.message"

// ✅ Usage
Text("dice.roll.button".localized)
```

#### Implementation
```swift
extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}
```

#### Localization Files
- `Localizable.strings` for each language (ro, bg, sr, hr, bs, mk, sq, en)
- Use proper terminology: "zar" for Romanian, "зар" for Bulgarian, etc.

### Git Standards

#### Commit Message Format
```
type(scope): description

Types: feat, fix, refactor, docs, test, chore, style
Examples:
- feat(dice): add 3D SceneKit dice rendering
- fix(animation): resolve dice rolling animation lag
- refactor(viewmodel): extract dice logic to separate service
- docs(readme): update installation instructions
```

#### Branch Naming
- **Feature**: `feature/3d-dice-rendering`
- **Bugfix**: `bugfix/dice-animation-lag`
- **Refactor**: `refactor/viewmodel-separation`
- **Hotfix**: `hotfix/crash-on-roll`

### Code Quality Checklist

#### Before Committing
- [ ] Code follows naming conventions
- [ ] Files are under size limits (Models: 200, Views: 500, ViewModels: 300)
- [ ] MVVM pattern is followed
- [ ] No business logic in Views
- [ ] Error handling is implemented
- [ ] Memory leaks are prevented (weak references, cleanup)
- [ ] Performance is optimized (lazy loading, efficient 3D rendering)
- [ ] Accessibility is supported (VoiceOver labels)
- [ ] Dark mode is supported
- [ ] Localization strings are added
- [ ] Code is commented for complex logic

#### Code Review Checklist
- [ ] Architecture patterns are followed (MVVM)
- [ ] Views are simple and delegate to ViewModels
- [ ] ViewModels are testable and focused
- [ ] 3D rendering is optimized for performance
- [ ] No force unwraps (use guard/if let)
- [ ] Error cases are handled gracefully
- [ ] UI is responsive and doesn't block main thread
- [ ] Memory management is correct (no retain cycles)

### Common Anti-Patterns to Avoid

#### ❌ Don't Do This
```swift
// Business logic in View
struct DiceView: View {
    var body: some View {
        Button("Roll") {
            // ❌ Don't put business logic here
            let randomValue = Int.random(in: 1...6)
            dice.value = randomValue
            saveToUserDefaults()
            updateStatistics()
        }
    }
}

// Massive ViewModels
class DiceViewModel: ObservableObject {
    // ❌ Don't put 500+ lines in one ViewModel
    // Split by feature instead
}

// Force unwraps
let value = dice!.value  // ❌ Never force unwrap

// Complex computations in body
var body: some View {
    VStack {
        // ❌ Don't do heavy work here
        ForEach(0..<10000) { _ in
            Text("Item")
        }
    }
}
```

#### ✅ Do This Instead
```swift
// Clean View with ViewModel
struct DiceView: View {
    @StateObject private var viewModel: DiceViewModel
    
    var body: some View {
        Button("Roll") {
            viewModel.rollDice()  // ✅ Delegate to ViewModel
        }
    }
}

// Focused ViewModels
class DiceViewModel: ObservableObject {
    // ✅ Single responsibility
}

class StatisticsViewModel: ObservableObject {
    // ✅ Separate concerns
}

// Safe unwrapping
guard let dice = dice else { return }
let value = dice.value  // ✅ Safe

// Lazy loading
var body: some View {
    ScrollView {
        LazyVStack {  // ✅ Lazy loading
            ForEach(items) { item in
                ItemView(item: item)
            }
        }
    }
}
```

### iOS Version Compatibility

#### Deployment Target: iOS 13.0
- Use `@available` checks for newer APIs
- Provide fallbacks for older iOS versions
- Test on iOS 13.0+ devices/simulators

```swift
// ✅ Version checks
if #available(iOS 14.0, *) {
    // Use WidgetKit
} else {
    // Fallback
}

// ✅ Availability attributes
@available(iOS 14.0, *)
struct DiceWidget: Widget {
    // Widget implementation
}
```

### SceneKit Best Practices

#### Performance
- Limit number of dice nodes (max 3)
- Use simple materials for older devices
- Reuse scene and nodes when possible
- Disable unnecessary features (camera control, etc.)

#### Animation
- Use physics-based animations for realistic rolling
- Limit animation duration (0.5-1.0 seconds)
- Stop animations when view disappears

---

## Quick Commands

### Code Formatting
```bash
# Format Swift code (if using swift-format)
swift-format --in-place --recursive zaruri/

# Check for SwiftLint issues (if configured)
swiftlint lint zaruri/
```

### Testing
```bash
# Run unit tests
xcodebuild test -scheme zaruri -destination 'platform=iOS Simulator,name=iPhone 15'

# Run with coverage
xcodebuild test -scheme zaruri -destination 'platform=iOS Simulator,name=iPhone 15' -enableCodeCoverage YES
```

### Build
```bash
# Build for simulator
xcodebuild -project zaruri.xcodeproj -scheme zaruri -configuration Release -destination 'platform=iOS Simulator,name=iPhone 15' build

# Build for device
xcodebuild -project zaruri.xcodeproj -scheme zaruri -configuration Release -destination 'generic/platform=iOS' build
```

---

*For detailed architecture information, see project documentation*  
*For contribution guidelines, see `CONTRIBUTING.md`*



