# 🕊️ Supabase Setup voor Duivenspel

## Stap-voor-stap instructies (minimale inspanning)

### 1. Ga naar je Supabase project
- Open je browser en ga naar [supabase.com](https://supabase.com)
- Log in en ga naar je project: `ltwolxjbmdopjslnlkcx`

### 2. Open de SQL Editor
- Klik in het linker menu op **"SQL Editor"**
- Klik op **"New query"** (nieuwe query)

### 3. Kopieer en plak het script
- Open het bestand `supabase_setup.sql` in je project
- Kopieer ALLE inhoud (Ctrl+A, Ctrl+C)
- Plak het in de SQL Editor van Supabase (Ctrl+V)

### 4. Voer het script uit
- Klik op de **"Run"** knop (of druk op Ctrl+Enter)
- Wacht tot het script klaar is (kan een paar seconden duren)

### 5. Controleer of alles werkt
- Ga naar **"Table Editor"** in het linker menu
- Je zou nu deze tabellen moeten zien:
  - `duiven` (met 4 voorbeeld duiven)
  - `kooien` (met 5 kooien)
  - `voeding` (met standaard voeding)
  - `wedstrijden` (leeg, voor later)
  - `wedstrijd_deelnames` (leeg, voor later)
  - `financien` (leeg, voor later)
  - `training` (leeg, voor later)

### 6. Test je applicatie
- Open `index.html` in je browser
- Ga naar "Duiven" - je zou de 4 voorbeeld duiven moeten zien
- Ga naar "Duiventil" - je zou de 5 kooien moeten zien

## ✅ Klaar!

Je database is nu volledig ingesteld en klaar voor gebruik. Alle bestaande code zou moeten werken zonder aanpassingen.

## Wat het script doet:

✅ **Maakt alle benodigde tabellen**  
✅ **Stelt relaties tussen tabellen in**  
✅ **Voegt indexen toe voor snelle queries**  
✅ **Stelt beveiliging in (RLS policies)**  
✅ **Voegt voorbeeld data toe**  
✅ **Maakt triggers voor automatische timestamps**  

## Troubleshooting

**Als er een fout optreedt:**
- Controleer of je de juiste Supabase URL en key gebruikt
- Zorg dat je alle code hebt gekopieerd
- Probeer het script opnieuw uit te voeren

**Als tabellen al bestaan:**
- Het script gebruikt `IF NOT EXISTS` dus het zal geen fouten geven
- Bestaande data blijft behouden

## Jouw bestaande configuratie blijft hetzelfde:

```javascript
const SUPABASE_URL = 'https://ltwolxjbmdopjslnlkcx.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx0d29seGpibWRvcGpzbG5sa2N4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI4MTg5MzYsImV4cCI6MjA2ODM5NDkzNn0.ajR0bqrAMYBYmJJXQQ2x2Ep9ciW_yXv7Gdp1DQ6F9VM';
```

Deze configuratie blijft exact hetzelfde - geen wijzigingen nodig in je code! 