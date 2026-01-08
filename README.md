# 🎲 Zaruri - 3D Dice App

Aplicatie iOS modernă și elegantă pentru aruncarea zarurilor 3D, destinată piețelor din România, Moldova, Bulgaria, Serbia, Croația, Bosnia, Macedonia și Albania.

## ✨ Funcționalități

### 🎯 Aruncare Zaruri
- **1-3 zaruri**: Alege numărul de zaruri (1, 2 sau 3)
- **Zaruri 3D realiste**: Renderizare 3D cu SceneKit, texturi și iluminare
- **Animații fluide**: Animații fizice realiste la aruncare
- **Feedback haptic**: Vibrații la aruncare
- **Sunete**: Efecte sonore opționale

### 📊 Statistici și Istoric
- **Istoric aruncări**: Păstrează ultimele 50 aruncări (configurabil)
- **Statistici detaliate**: Medie, minim, maxim, distribuție valori
- **Grafice**: Vizualizare distribuție valori
- **Căutare**: Caută în istoric

### 🎮 Moduri de Joc
- **Aruncare liberă**: Aruncă zarurile fără reguli
- **Yahtzee Helper**: Ajutor pentru jocul Yahtzee
- **Sum Game**: Încearcă să obții o sumă țintă
- **Highest Value**: Încearcă să obții cea mai mare valoare

### 🎨 Personalizare
- **Teme**: Standard, Dark, Colorful, Classic
- **Setări**: Sunet, vibrații, istoric configurabil
- **Interfață modernă**: Design SwiftUI curat și intuitiv

### 📱 Widget (iOS 14+)
- **Home Screen Widget**: Aruncare rapidă și ultimul rezultat
- **Dimensiuni**: Small și Medium

### 🌍 Localizare
- **8 limbi suportate**: Română, Bulgară, Sârbă, Croată, Bosniacă, Macedoneană, Albaneză, Engleză
- **Terminologie corectă**: "zar" pentru română, "зар" pentru bulgară, etc.

## 🚀 Tehnologii

- **SwiftUI**: Interfață modernă
- **SceneKit**: Renderizare 3D pentru zaruri
- **Combine**: Programare reactivă
- **WidgetKit**: Widget pentru Home Screen (iOS 14+)
- **UserDefaults**: Persistență date
- **AVFoundation**: Sunete

## 📱 Compatibilitate

- **iOS 13.0+**: Versiune minimă
- **iPhone și iPad**: Optimizat pentru ambele
- **Orientare**: Suportă portrait și landscape
- **Dark Mode**: Suport complet
- **Accessibility**: Compatibil cu VoiceOver

## 🎨 App Icon

Aplicația necesită o icoană de 1024x1024px pentru App Store.

**Design recomandat:**
- **Fundal**: Gradient vibrant albastru-violet (#3366E6 → #9933E6)
- **Elemente**: Două zaruri albe cu puncte negre (valori 5 și 3)
- **Stil**: Modern, simplu, memorabil, cu umbre subtile pentru efect 3D

Pentru detalii complete, vezi [ICON_DESIGN.md](ICON_DESIGN.md) sau [ICON_QUICK_GUIDE.md](ICON_QUICK_GUIDE.md).

**Cum să adaugi icoana:**
1. Creează o imagine de 1024x1024px conform design-ului
2. Deschide `zaruri/Assets.xcassets/AppIcon.appiconset/` în Xcode
3. Drag & drop imaginea în slot-ul "1024pt"
4. Xcode va genera automat toate dimensiunile necesare

## 🔧 Instalare

### Cerințe
- Xcode 14.0+
- iOS 13.0+ SDK
- Swift 5.0+

### Pași
1. Clonează repository-ul
2. Deschide `zaruri.xcodeproj` în Xcode
3. Selectează target-ul "zaruri"
4. Adaugă icoana aplicației (vezi secțiunea App Icon de mai sus)
5. Rulează pe simulator sau device

## 📁 Structura Proiectului

```
zaruri/
├── Models/              # Modele de date
├── Views/               # SwiftUI Views
├── ViewModels/          # Business logic
├── 3D/                  # Componente SceneKit
├── Utilities/           # Helpers și managers
├── Resources/           # Assets
│   ├── Sounds/
│   ├── Textures/
│   └── Localizations/
└── zaruriWidget/        # Widget (iOS 14+)
```

## 🎨 Design

- **Interfață curată**: Fără distrageri
- **Culori calme**: Pentru o experiență plăcută
- **Animații fluide**: Feedback vizual plăcut
- **Tipografie clară**: Text ușor de citit

## 📱 Publicare App Store

Pentru instrucțiuni detaliate despre publicarea aplicației în App Store, vezi [APP_STORE_PUBLICATION.md](APP_STORE_PUBLICATION.md).

## 📄 Licență

MIT License - vezi [LICENSE](LICENSE) pentru detalii.

## 👤 Autor

Creat de ax

## 🤝 Contribuții

Contribuțiile sunt binevenite! Vezi [CONTRIBUTING.md](CONTRIBUTING.md) pentru ghidul de contribuții.

## 📝 Standarde de Cod

Vezi [CODING_STANDARDS.md](CODING_STANDARDS.md) pentru standardele de cod și best practices.

## 🐛 Probleme

Dacă găsești bug-uri sau ai sugestii, te rugăm să deschizi un issue.

---

**Zaruri** - Transformă aruncarea zarurilor într-o experiență 3D plăcută! 🌟

