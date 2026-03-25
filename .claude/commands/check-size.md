Scanează toate fișierele Swift din proiect și raportează pe cele care depășesc limitele arhitecturale:
- Views/ → maxim 500 linii
- ViewModels/ → maxim 300 linii
- Models/ → maxim 200 linii

Folosește comanda `wc -l` pe fișierele din `zaruri/Views/`, `zaruri/ViewModels/`, `zaruri/Models/`.
Afișează un tabel cu: fișier | linii | limită | depășire (%).
Sortează descrescător după depășire.
La final, dă o recomandare concretă pentru fișierele cele mai critice (cum să le spargi).
