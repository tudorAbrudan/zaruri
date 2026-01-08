# Contribuții

Mulțumim pentru interesul tău de a contribui la Zaruri! 🎲

## Cum să contribui

### Raportare Bug-uri

Dacă găsești un bug:
1. Verifică dacă bug-ul nu a fost deja raportat în Issues
2. Creează un issue nou cu:
   - Descriere clară a bug-ului
   - Pași pentru reproducere
   - Versiunea iOS
   - Device-ul folosit
   - Screenshots (dacă e relevant)

### Sugestii de Funcționalități

Pentru sugestii de funcționalități noi:
1. Verifică dacă funcționalitatea nu a fost deja sugerată
2. Creează un issue cu label "enhancement"
3. Descrie funcționalitatea și de ce ar fi utilă

### Contribuții de Cod

1. **Fork** repository-ul
2. **Creează un branch** pentru feature-ul tău (`git checkout -b feature/AmazingFeature`)
3. **Urmează standardele de cod** - vezi [CODING_STANDARDS.md](CODING_STANDARDS.md)
4. **Commit** modificările (`git commit -m 'feat: Add some AmazingFeature'`)
5. **Push** la branch (`git push origin feature/AmazingFeature`)
6. **Deschide un Pull Request**

### Standarde de Commit

Folosește formatul:
```
type(scope): description
```

Tipuri:
- `feat`: Nouă funcționalitate
- `fix`: Bug fix
- `docs`: Documentație
- `style`: Formatare cod
- `refactor`: Refactorizare
- `test`: Teste
- `chore`: Alte modificări

Exemple:
- `feat(dice): add 3D SceneKit rendering`
- `fix(animation): resolve dice rolling lag`
- `docs(readme): update installation instructions`

### Standarde de Cod

- Urmează [CODING_STANDARDS.md](CODING_STANDARDS.md)
- Folosește SwiftLint (dacă e configurat)
- Scrie teste pentru funcționalități noi
- Adaugă comentarii pentru cod complex
- Asigură-te că codul compilează fără warning-uri

### Testare

Înainte de a trimite un PR:
- Testează pe iOS 13.0+
- Testează pe iPhone și iPad
- Testează în portrait și landscape
- Testează Dark Mode
- Verifică accessibility (VoiceOver)

### Localizare

Dacă adaugi text nou:
- Adaugă string-uri în toate limbile suportate
- Folosește `NSLocalizedString` sau extension-ul `.localized`
- Verifică că toate traducerile sunt complete

## Întrebări?

Dacă ai întrebări, deschide un issue cu label "question".

Mulțumim pentru contribuții! 🎉



