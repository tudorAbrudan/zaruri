# 📸 Ghid pentru Screenshots App Store

## Pași pentru a crea screenshots-uri

### 1. Fă screenshots-uri din aplicație

Poți face screenshots-uri în două moduri:

#### Opțiunea A: Din Simulator (recomandat)
1. Deschide aplicația în Xcode Simulator
2. Navighează la fiecare ecran important:
   - Ecran principal (cu zaruri)
   - Settings
   - History
   - Statistics
   - Game Modes
3. Apasă `Cmd + S` în simulator pentru a salva screenshot-ul
4. Screenshots-urile se salvează automat pe Desktop

#### Opțiunea B: Din Device fizic
1. Rulează aplicația pe iPhone/iPad
2. Navighează la fiecare ecran important
3. Apasă `Power + Volume Up` pentru screenshot
4. Screenshots-urile se salvează în Camera Roll

### 2. Copiază screenshots-urile în proiect

```bash
# Creează folderul screenshots (dacă nu există)
mkdir -p screenshots

# Copiază screenshots-urile din Desktop sau altă locație
# Exemplu:
cp ~/Desktop/*.png screenshots/
```

### 3. Redimensionează screenshots-urile

Rulează scriptul Python pentru a crea versiunile redimensionate:

```bash
python3 resize_screenshots.py
```

Scriptul va:
- Căuta toate imaginile din folderul `screenshots/`
- Crea versiuni redimensionate pentru toate dimensiunile necesare
- Salva rezultatele în `screenshots/appstore/`

### 4. Dimensiuni create

Scriptul va crea automat următoarele dimensiuni:

- **iPhone 6.5" Portrait**: 1242 × 2688px
- **iPhone 6.5" Landscape**: 2688 × 1242px  
- **iPhone 6.7" Portrait**: 1284 × 2778px
- **iPhone 6.7" Landscape**: 2778 × 1284px

### 5. Upload în App Store Connect

1. Mergi la App Store Connect → Aplicația ta → Versiunea 1.0
2. Scroll la secțiunea **Screenshots**
3. Upload screenshots-urile din `screenshots/appstore/` pentru fiecare dimensiune necesară

## Ecrane recomandate pentru screenshots

1. **Ecran principal** - Zaruri + buton "Aruncă zarurile"
2. **Game Modes** - Arată modurile de joc disponibile
3. **Statistics** - Arată statisticile și distribuția
4. **History** - Arată istoricul aruncărilor
5. **Settings** - Arată opțiunile de personalizare

## Note importante

- Screenshots-urile trebuie să fie în format PNG
- Dimensiunile exacte sunt importante pentru App Store
- Scriptul păstrează aspect ratio-ul și adaugă padding alb dacă e necesar
- Poți procesa multiple screenshots-uri odată



