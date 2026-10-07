---
name: gen-test
description: Generate unit tests for a Model or ViewModel in zaruriTests using Swift Testing
disable-model-invocation: true
argument-hint: <path to Swift file, e.g. zaruri/Models/DiceRoll.swift>
---

Write unit tests for the file given in `$ARGUMENTS`.

1. Read the file and list its public/internal behavior: pure logic, state transitions, edge cases (empty, min/max, invalid input).
2. Create `zaruriTests/<TypeName>Tests.swift`. The project uses **Swift Testing** (`import Testing`, `@Test`, `#expect`), not XCTest.
3. ViewModels are `@MainActor`: mark the test struct or functions `@MainActor`.
4. Cover: happy path, boundaries (e.g. D2/D20 value ranges), error cases (`Result<_, DiceError>`), and any bug-prone branch.
5. No force unwrap (`!`): use `try #require(...)` or `guard let`.
6. No dependency on real sound, haptics, UserDefaults or timers. Inject or skip them.

Template:

```swift
import Testing
@testable import zaruri

@MainActor
struct DiceViewModelTests {

    @Test func rollProducesValueInRange() throws {
        let vm = DiceViewModel()
        vm.rollDice()
        let value = try #require(vm.dice.first?.value)
        #expect((1...6).contains(value))
    }
}
```

Adapt names to the real API (read it first, never guess signatures). Then run:

```bash
xcodebuild test -scheme zaruri -destination 'platform=iOS Simulator,name=iPhone 15' 2>&1 | xcbeautify --quiet
```

Report which tests pass and which fail. Do not weaken a test to make it pass.
