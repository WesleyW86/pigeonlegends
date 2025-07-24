# 🕊️ Duivenspel - Professioneel Duivenbeheer Systeem

Een moderne web-applicatie voor het beheren van duiven, trainingen, wedstrijden en financiën.

## 🌟 Functies

- **Duivenbeheer**: Persoonlijke duiven collectie per gebruiker
- **Trainingen**: Plan en volg trainingsvluchten in real-time
- **Wedstrijden**: Deelname aan wedstrijden en resultaten tracking
- **Duiventil**: Beheer van hokken en leefomstandigheden
- **Financiën**: Inkomsten, uitgaven en winstgevendheid analyse
- **Weerbericht**: Real-time weer informatie voor Gent
- **Multi-user**: 3 vaste test accounts met gedeelde trainingen/wedstrijden

## 🚀 Live Demo

**Status**: In Ontwikkeling
- **URL**: [https://wesleyw86.github.io/pigeonlegends](https://wesleyw86.github.io/pigeonlegends)
- **Registratie**: Uitgeschakeld (alleen 3 test accounts)
- **Contact**: wesley.wyngaerd@outlook.com

## 👥 Test Accounts

De applicatie is momenteel in ontwikkeling en alleen beschikbaar voor 3 vaste test accounts:

1. **wesley.wyngaerd@outlook.com** - Hoofdaccount
2. **maximeboelaert@hotmail.be** - Test account 2
3. **degraevetomas@gmail.com** - Test account 3

## 🛠️ Technologieën

- **Frontend**: HTML5, CSS3, JavaScript (ES6+)
- **Backend**: Supabase (PostgreSQL database)
- **Authenticatie**: Supabase Auth
- **Hosting**: GitHub Pages
- **Icons**: Font Awesome
- **Styling**: Custom CSS met moderne design patterns

## 📁 Project Structuur

 ```
 pigeonlegends/
├── index.html          # Hoofdpagina (in ontwikkeling melding)
├── login.html          # Login pagina voor test accounts
├── dashboard.html      # Dashboard voor ingelogde gebruikers
├── duiven.html         # Duivenbeheer pagina
├── duiventil.html      # Duiventil management
├── training.html       # Trainingen en simulaties
├── wedstrijden.html    # Wedstrijden beheer
├── financien.html      # Financiële tracking
├── weather.js          # Weerbericht module
├── supabase_setup.sql  # Database schema en RLS policies
└── README.md           # Deze file
```

## 🔧 Database Schema

### Hoofdtabellen:
- **duiven**: Duif eigenschappen en informatie
- **trainingsvluchten**: Training sessies
- **trainingsvlucht_deelnames**: Deelname aan trainingen
- **wedstrijden**: Wedstrijd informatie
- **wedstrijd_deelnames**: Deelname aan wedstrijden
- **medailles**: Gewonnen prijzen
- **kooien**: Duiventil hokken

### Belangrijke Features:
- **Row Level Security (RLS)**: Data isolatie per gebruiker
- **Real-time simulaties**: Offline training berekeningen
- **Gedeelde trainingen**: Alle gebruikers kunnen deelnemen
- **Privé duiven**: Elke gebruiker heeft eigen duiven

## 🚀 Installatie & Setup

### Lokale Ontwikkeling

1. **Clone repository**:
   ```bash
   git clone https://github.com/wesleyw86/pigeonlegends.git
   cd pigeonlegends
   ```

2. **Supabase Setup**:
   - Maak een Supabase project aan
   - Voer `supabase_setup.sql` uit in de SQL editor
   - Update Supabase URL en key in alle HTML bestanden

3. **Test Accounts Aanmaken**:
   ```sql
   -- Voer dit uit in Supabase Auth
   INSERT INTO auth.users (email, encrypted_password, email_confirmed_at)
   VALUES 
     ('wesley.wyngaerd@outlook.com', crypt('TestTest1.2.3', gen_salt('bf')), now()),
     ('maximeboelaert@hotmail.be', crypt('Test.Test.123', gen_salt('bf')), now()),
     ('degraevetomas@gmail.com', crypt('IkbenHOMO.123', gen_salt('bf')), now());
   ```

4. **Start lokale server**:
   ```bash
   # Python 3
   python -m http.server 8000
   
   # Node.js
   npx serve .
   
   # PHP
   php -S localhost:8000
   ```

### GitHub Pages Deployment

1. **Repository instellen**:
   - Ga naar Settings > Pages
   - Source: Deploy from a branch
   - Branch: main
   - Folder: / (root)

2. **Automatische deployment**:
   - Elke push naar main branch wordt automatisch gedeployed
   - URL: `https://[username].github.io/pigeonlegends`

## 🔐 Beveiliging

- **Row Level Security**: Database policies per gebruiker
- **Email validatie**: Alleen toegestane test accounts
- **Input sanitization**: Alle gebruikersinvoer wordt gevalideerd
- **HTTPS**: Automatisch via GitHub Pages

## 📱 Responsive Design

De applicatie is volledig responsive en werkt op:
- Desktop computers
- Tablets
- Smartphones
- Alle moderne browsers

## 🎯 Roadmap

### V1.0 (Huidig)
- ✅ Basis duivenbeheer
- ✅ Training simulaties
- ✅ Wedstrijd management
- ✅ Multi-user support
- ✅ Weerbericht integratie

### V1.1 (Gepland)
- [ ] Uitgebreide statistieken
- [ ] Export functionaliteit
- [ ] Notificaties
- [ ] Dark mode

### V2.0 (Toekomst)
- [ ] Open registratie
- [ ] Premium features
- [ ] Mobile app
- [ ] API voor externe integraties

## 🤝 Bijdragen

Momenteel is dit een privé project in ontwikkeling. Voor vragen of toegang, neem contact op via wesley.wyngaerd@outlook.com.

## 📄 Licentie

Dit project is privé eigendom. Alle rechten voorbehouden.

## 📞 Contact

- **Email**: wesley.wyngaerd@outlook.com
- **Project**: [GitHub Repository](https://github.com/wesleyw86/pigeonlegends)
- **Live Demo**: [https://wesleyw86.github.io/pigeonlegends](https://wesleyw86.github.io/pigeonlegends)

---

**🕊️ Duivenspel** - Professioneel duivenbeheer voor de moderne duivenliefhebber 