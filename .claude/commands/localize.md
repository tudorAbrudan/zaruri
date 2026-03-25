Adaugă o cheie de localizare nouă în toate fișierele Localizable.strings din proiect.

Argumentul comenzii este: `"cheie" "text în română"`
Exemplu: /localize "dice.roll.shake" "Scutură telefonul"

Pași:
1. Identifică toate fișierele Localizable.strings din `zaruri/Localizations/` (ro, en, bg, sr, hr, bs, mk, sq)
2. Adaugă cheia în fiecare fișier:
   - ro.lproj: folosește textul românesc furnizat
   - en.lproj: traduce textul în engleză
   - bg, sr, hr, bs, mk, sq: adaugă textul românesc cu prefixul `/* TODO: translate */ ` ca valoare temporară
3. Respectă formatul existent: `"cheie" = "valoare";`
4. Adaugă cheia alfabetic sau la sfârșitul secțiunii relevante
5. Confirmă câte fișiere au fost actualizate
