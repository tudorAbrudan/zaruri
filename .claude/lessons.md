# Lessons Learned — Zaruri

Greșeli identificate și regulile care le previn.
Format: **Greșeala** → **Regula**

---

## Arhitectură MVVM

**Greșeală (potențială):** Business logic pusă direct în View (calcule, salvare date, logică de joc).
**Regula:** Views conțin DOAR SwiftUI layout și deleghează orice acțiune la ViewModel. Dacă un View are `if/else` complex sau apeluri la UserDefaults, e greșit.

---

**Greșeală (potențială):** ViewModel cu 400+ linii care face totul (zaruri + statistici + turn-based + settings).
**Regula:** Max 300 linii per ViewModel. Dacă crește, separă: `DiceViewModel`, `StatisticsViewModel`, `SettingsViewModel` — fiecare cu responsabilitate unică.

---

## Memory Management

**Greșeală (potențială):** Timer sau NotificationCenter observer neeanulat → memory leak + comportament ciudat după navigare.
**Regula:** Orice Timer → `timer.invalidate()` în `.onDisappear` sau `deinit`. Orice observer NotificationCenter → `removeObserver` în `deinit`.

---

**Greșeală (potențială):** Closure capturat fără `[weak self]` în SceneKit actions sau DispatchQueue.
**Regula:** Orice closure async care referențiază `self` → `[weak self]`, apoi `guard let self = self else { return }`.

---

## SceneKit

**Greșeală (potențială):** Creare de scene/nodes noi la fiecare update al View-ului → performanță slabă.
**Regula:** Scene și nodes create O SINGURĂ DATĂ (lazy var sau static let). `updateUIView` doar actualizează, nu recreează.

---

**Greșeală (potențială):** `SCNView` nu eliberează memoria când View-ul dispare.
**Regula:** În `deinit` al UIViewRepresentable coordinator: `scnView.scene = nil`, `scnView.delegate = nil`.

---

## Localizare

**Greșeală (potențială):** String nou adăugat direct hardcodat în View (ex: `Text("Aruncă")`).
**Regula:** ORICE text vizibil utilizatorului → `Text("dice.roll.button".localized)`. Adaugă cheia în TOATE fișierele Localizable.strings înainte de commit.

---

**Greșeală (potențială):** Text Romanian rupt pe ecran pentru că în alte limbi e mai lung.
**Regula:** Pe texte scurte (butoane, labels): `.lineLimit(1).minimumScaleFactor(0.7)` sau testează explicit cu lb. bulgară/sârbă.

---

## SwiftUI

**Greșeală (potențială):** Calcul greu în `body` (parcurgere array, formatare date) → re-render lent.
**Regula:** Orice calcul care nu e trivial → computed property în ViewModel sau `let` înainte de `body`.

---

**Greșeală (potențială):** `@StateObject` folosit pe un ViewModel pasat din exterior → se recreează la re-render.
**Regula:** `@StateObject` = ViewModel creat de View. `@ObservedObject` = ViewModel primit ca parametru.

---

## Build & Deploy

**Greșeală (potențială):** Modificare în `zaruriWidget` fără test că widget-ul compilează separat.
**Regula:** Orice modificare în cod shared cu Widget → build explicit și schema zaruriWidget în Xcode.

---

**Greșeală (potențială):** Modificare în `project.pbxproj` fără să adaugi fișierul nou la target corect.
**Regula:** Orice fișier nou Swift → verifică în Xcode că e adăugat la target `zaruri` (și `zaruriWidget` dacă e shared).
