# 🕊️ VLIEGSIMULATIE DOCUMENTATIE
## Pigeon Legends - Geavanceerd Vliegsimulatie Algoritme

---

## 📋 **INHOUDSOPGAVE**

1. [Algemene Principes](#algemene-principes)
2. [Afstand Types](#afstand-types)
3. [Basis Snelheid Berekening](#basis-snelheid-berekening)
4. [Eigenschap Gewichten](#eigenschap-gewichten)
5. [Eigenschap Bonus Berekening](#eigenschap-bonus-berekening)
6. [Vermoeidheid Factor](#vermoeidheid-factor)
7. [Realistische Snelheid Berekening](#realistische-snelheid-berekening)
8. [Positie Updates](#positie-updates)
9. [Nachtvliegen Mechanisme](#nachtvliegen-mechanisme)
10. [Praktische Voorbeelden](#praktische-voorbeelden)
11. [Formules Overzicht](#formules-overzicht)

---

## 🎯 **ALGEMENE PRINCIPES**

### **Doel van de Simulatie**
De vliegsimulatie simuleert realistische duivenvluchten op basis van:
- **Afstand** (kort, middellang, lang)
- **Duif eigenschappen** (snelheid, conditie, etc.)
- **Vermoeidheid** (hoe verder, hoe langzamer)
- **Tijd van dag** (nachtvliegen bonus)
- **Willekeurige variatie** (realistische onvoorspelbaarheid)

### **Kern Concepten**
1. **Basis snelheid** per afstand type
2. **Eigenschap gewichten** bepalen welke eigenschappen belangrijk zijn
3. **Vermoeidheid** neemt toe tijdens de vlucht
4. **Nachtvliegen** geeft bonus tijdens nachtelijke uren
5. **Willekeurige variatie** (±10%) voor realisme

---

## 📏 **AFSTAND TYPES**

### **Definitie**
```javascript
getDistanceType(distance) {
  if (distance <= 200) return 'short';    // 0-200km
  if (distance <= 500) return 'medium';   // 201-500km  
  return 'long';                          // 500km+
}
```

### **Karakteristieken**
| Type | Afstand | Karakteristiek | Belangrijke Eigenschappen |
|------|---------|----------------|---------------------------|
| **Short** | 0-200km | Sprint vluchten | Snelheid, Aerodynamica, Intelligentie |
| **Medium** | 201-500km | Middellange vluchten | Snelheid, Conditie, Ervaring |
| **Long** | 500km+ | Lange afstand vluchten | Conditie, Oriëntatie, Ervaring |

---

## ⚡ **BASIS SNELHEID BEREKENING**

### **Formule**
```javascript
calculateBaseSpeed(distance) {
  const type = this.getDistanceType(distance);
  const { min, max } = this.baseSpeeds[type];
  
  // Afstand factor: langere afstanden = lagere snelheid
  const distanceFactor = Math.max(0.8, 1 - (distance / 1000));
  const adjustedMin = min * distanceFactor;
  const adjustedMax = max * distanceFactor;
  
  return { min: adjustedMin, max: adjustedMax, type: type };
}
```

### **Basis Snelheden**
| Type | Min Snelheid | Max Snelheid | Afstand Factor |
|------|--------------|--------------|----------------|
| **Short** | 80 km/u | 120 km/u | 1.0 - 0.8 |
| **Medium** | 70 km/u | 100 km/u | 0.9 - 0.7 |
| **Long** | 60 km/u | 90 km/u | 0.8 - 0.6 |

### **Afstand Factor Berekening**
```
distanceFactor = Math.max(0.8, 1 - (distance / 1000))
```

**Voorbeelden:**
- 100km: `1 - (100/1000) = 0.9`
- 500km: `1 - (500/1000) = 0.5` → `0.8` (minimum)
- 800km: `1 - (800/1000) = 0.2` → `0.8` (minimum)

---

## ⚖️ **EIGENSCHAP GEWICHTEN**

### **Gewicht Systeem**
- **0 sterren** = Niet relevant voor dit afstand type
- **1 ster** = Licht relevant
- **2 sterren** = Gemiddeld relevant  
- **3 sterren** = Zeer relevant
- **4 sterren** = Kritiek belangrijk

### **Gewichten per Afstand Type**

#### **Short Distance (0-200km)**
```javascript
short: {
  snelheid: 4,        // **** Kritiek
  conditie: 1,        // * Licht relevant
  oriëntatie: 1,      // * Licht relevant
  techniek: 2,        // ** Gemiddeld
  ervaring: 1,        // * Licht relevant
  aerodynamica: 4,    // **** Kritiek
  intelligentie: 4    // **** Kritiek
}
```

#### **Medium Distance (201-500km)**
```javascript
medium: {
  snelheid: 4,        // **** Kritiek
  conditie: 4,        // **** Kritiek
  oriëntatie: 2,      // ** Gemiddeld
  ervaring: 2,        // ** Gemiddeld
  intelligentie: 2    // ** Gemiddeld
}
```

#### **Long Distance (500km+)**
```javascript
long: {
  snelheid: 2,        // ** Gemiddeld
  conditie: 4,        // **** Kritiek
  oriëntatie: 4,      // **** Kritiek
  techniek: 2,        // ** Gemiddeld
  ervaring: 4,        // **** Kritiek
  aerodynamica: 2,    // ** Gemiddeld
  intelligentie: 4    // **** Kritiek
}
```

---

## 🎯 **EIGENSCHAP BONUS BEREKENING**

### **Formule**
```javascript
calculatePropertyBonus(duif, distance) {
  const type = this.getDistanceType(distance);
  const weights = this.propertyWeights[type];
  
  let totalBonus = 0;
  let totalWeight = 0;
  
  // Loop door alle eigenschappen
  Object.keys(weights).forEach(property => {
    if (duif[property] !== undefined) {
      const weight = weights[property];
      const value = parseFloat(duif[property]) || 0;
      
      // Eigenschap bonus = (waarde / 10) * gewicht
      const bonus = (value / 10) * weight;
      totalBonus += bonus;
      totalWeight += weight;
    }
  });
  
  // Gemiddelde bonus per gewicht
  return totalWeight > 0 ? totalBonus / totalWeight : 0;
}
```

### **Berekening Stap voor Stap**

#### **Stap 1: Eigenschap Normalisatie**
```
eigenschap_waarde_normalized = eigenschap_waarde / 10
```
- Eigenschap waarde: 0-10
- Genormaliseerd: 0-1

#### **Stap 2: Gewogen Bonus**
```
eigenschap_bonus = eigenschap_waarde_normalized × gewicht
```

#### **Stap 3: Totaal Bonus**
```
totaal_bonus = Σ(eigenschap_bonus) / Σ(gewichten)
```

### **Voorbeeld Berekening**

**Duif eigenschappen:**
- Snelheid: 8/10
- Conditie: 7/10
- Oriëntatie: 6/10
- Techniek: 9/10
- Ervaring: 5/10
- Aerodynamica: 8/10
- Intelligentie: 7/10

**Short Distance (200km):**
```
Snelheid: (8/10) × 4 = 3.2
Conditie: (7/10) × 1 = 0.7
Oriëntatie: (6/10) × 1 = 0.6
Techniek: (9/10) × 2 = 1.8
Ervaring: (5/10) × 1 = 0.5
Aerodynamica: (8/10) × 4 = 3.2
Intelligentie: (7/10) × 4 = 2.8

Totaal Bonus: (3.2 + 0.7 + 0.6 + 1.8 + 0.5 + 3.2 + 2.8) / (4+1+1+2+1+4+4) = 12.8 / 17 = 0.75
```

---

## 😴 **VERMOEIDHEID FACTOR**

### **Formule**
```javascript
calculateFatigueFactor(currentDistance, totalDistance, distanceType) {
  const progress = currentDistance / totalDistance;
  
  switch (distanceType) {
    case 'short': return 1 - (progress * 0.1);   // 10% vermoeidheid
    case 'medium': return 1 - (progress * 0.2);  // 20% vermoeidheid
    case 'long': return 1 - (progress * 0.3);    // 30% vermoeidheid
    default: return 1;
  }
}
```

### **Vermoeidheid per Afstand Type**

| Afstand Type | Max Vermoeidheid | Voorbeeld bij 50% Progress |
|--------------|------------------|----------------------------|
| **Short** | 10% | `1 - (0.5 × 0.1) = 0.95` |
| **Medium** | 20% | `1 - (0.5 × 0.2) = 0.90` |
| **Long** | 30% | `1 - (0.5 × 0.3) = 0.85` |

### **Vermoeidheid Curve**
```
Progress: 0% → 25% → 50% → 75% → 100%
Short:    1.0 → 0.975 → 0.95 → 0.925 → 0.9
Medium:   1.0 → 0.95  → 0.90 → 0.85  → 0.8
Long:     1.0 → 0.925 → 0.85 → 0.775 → 0.7
```

---

## 🚀 **REALISTISCHE SNELHEID BEREKENING**

### **Formule**
```javascript
calculateRealisticSpeed(duif, distance, currentDistance, totalDistance) {
  const baseSpeed = this.calculateBaseSpeed(distance);
  const propertyBonus = this.calculatePropertyBonus(duif, distance);
  
  // Basis snelheid met eigenschap bonus
  let speed = baseSpeed.min + (baseSpeed.max - baseSpeed.min) * propertyBonus;
  
  // Vermoeidheid factor
  const fatigueFactor = this.calculateFatigueFactor(currentDistance, totalDistance, baseSpeed.type);
  speed *= fatigueFactor;
  
  // Willekeurige variatie (±10%)
  const variation = 0.9 + (Math.random() * 0.2);
  speed *= variation;
  
  return Math.max(30, Math.min(150, speed)); // Min 30, max 150 km/u
}
```

### **Berekening Stap voor Stap**

#### **Stap 1: Basis Snelheid met Bonus**
```
snelheid = min_snelheid + (max_snelheid - min_snelheid) × eigenschap_bonus
```

#### **Stap 2: Vermoeidheid Toepassing**
```
snelheid = snelheid × vermoeidheid_factor
```

#### **Stap 3: Willekeurige Variatie**
```
variatie = 0.9 + (willekeurig_getal × 0.2)  // 0.9 - 1.1
snelheid = snelheid × variatie
```

#### **Stap 4: Limieten Toepassing**
```
snelheid = Math.max(30, Math.min(150, snelheid))
```

### **Voorbeeld Berekening**

**Scenario:**
- Afstand: 300km (Medium)
- Duif eigenschap bonus: 0.75
- Progress: 50% (150km van 300km)
- Willekeurige variatie: 1.05

**Berekening:**
```
1. Basis snelheid: 70 + (100-70) × 0.75 = 70 + 22.5 = 92.5 km/u
2. Vermoeidheid: 92.5 × 0.90 = 83.25 km/u
3. Variatie: 83.25 × 1.05 = 87.41 km/u
4. Resultaat: 87.41 km/u (binnen limieten)
```

---

## 📍 **POSITIE UPDATES**

### **Afstand per Interval**
```javascript
calculateDistancePerInterval(speed, intervalSeconds = 5) {
  return (speed / 3600) * intervalSeconds;
}
```

**Formule:**
```
afstand_per_interval = (snelheid_km_u / 3600) × interval_seconden
```

### **Nieuwe Positie Berekening**
```javascript
calculateNewPosition(duif, currentDistance, totalDistance, intervalSeconds = 5) {
  const speed = this.calculateRealisticSpeed(duif, totalDistance, currentDistance, totalDistance);
  const distancePerInterval = this.calculateDistancePerInterval(speed, intervalSeconds);
  
  const newDistance = Math.min(totalDistance, currentDistance + distancePerInterval);
  const isFinished = newDistance >= totalDistance;
  
  return {
    newDistance: newDistance,
    currentSpeed: speed,
    distancePerInterval: distancePerInterval,
    isFinished: isFinished,
    remainingDistance: totalDistance - newDistance
  };
}
```

### **Voorbeeld Positie Update**

**Scenario:**
- Huidige afstand: 150km
- Totale afstand: 300km
- Snelheid: 87.41 km/u
- Interval: 5 seconden

**Berekening:**
```
1. Afstand per interval: (87.41 / 3600) × 5 = 0.121 km
2. Nieuwe afstand: 150 + 0.121 = 150.121 km
3. Resterende afstand: 300 - 150.121 = 149.879 km
4. Voltooid: Nee (150.121 < 300)
```

---

## 🌙 **NACHTVLIEGEN MECHANISME**

### **Tijd Check**
```javascript
const currentHour = new Date().getHours();
if (currentHour >= 21 || currentHour <= 6) {
  // Nachtvliegen bonus toepassen
}
```

### **Nachtvliegen Bonus**
```javascript
if (duif.nachtvliegen !== undefined) {
  const nachtvliegenBonus = (parseFloat(duif.nachtvliegen) || 0) / 10 * 4;
  totalBonus += nachtvliegenBonus;
  totalWeight += 4;
}
```

### **Nachtvliegen Tijden**
- **Nacht:** 21:00 - 06:00 (9 uur)
- **Dag:** 06:00 - 21:00 (15 uur)
- **Bonus gewicht:** 4 sterren (kritiek belangrijk)

### **Voorbeeld Nachtvliegen**
**Duif met nachtvliegen: 8/10**
```
Nachtvliegen bonus: (8/10) × 4 = 3.2
Extra gewicht: 4
```

---

## 📊 **PRAKTISCHE VOORBEELDEN**

### **Voorbeeld 1: Korte Vlucht (150km)**

**Duif eigenschappen:**
- Snelheid: 9/10
- Aerodynamica: 8/10
- Intelligentie: 7/10
- Overige: 5/10

**Berekening:**
```
1. Afstand type: Short
2. Basis snelheid: 80-120 km/u
3. Eigenschap bonus: 0.82
4. Snelheid: 80 + (120-80) × 0.82 = 112.8 km/u
5. Vermoeidheid (50%): 112.8 × 0.95 = 107.16 km/u
6. Variatie (±10%): 107.16 × 1.02 = 109.3 km/u
```

### **Voorbeeld 2: Lange Vlucht (800km)**

**Duif eigenschappen:**
- Conditie: 9/10
- Oriëntatie: 8/10
- Ervaring: 7/10
- Overige: 5/10

**Berekening:**
```
1. Afstand type: Long
2. Basis snelheid: 60-90 km/u (met afstand factor 0.8)
3. Eigenschap bonus: 0.78
4. Snelheid: 48 + (72-48) × 0.78 = 66.72 km/u
5. Vermoeidheid (75%): 66.72 × 0.775 = 51.71 km/u
6. Variatie (±10%): 51.71 × 0.95 = 49.12 km/u
```

---

## 📋 **FORMULES OVERZICHT**

### **1. Afstand Type**
```
if (distance ≤ 200) return 'short'
if (distance ≤ 500) return 'medium'
return 'long'
```

### **2. Afstand Factor**
```
distanceFactor = Math.max(0.8, 1 - (distance / 1000))
```

### **3. Eigenschap Bonus**
```
eigenschap_bonus = (eigenschap_waarde / 10) × gewicht
totaal_bonus = Σ(eigenschap_bonus) / Σ(gewichten)
```

### **4. Vermoeidheid Factor**
```
short: 1 - (progress × 0.1)
medium: 1 - (progress × 0.2)
long: 1 - (progress × 0.3)
```

### **5. Realistische Snelheid**
```
snelheid = min + (max - min) × eigenschap_bonus
snelheid = snelheid × vermoeidheid_factor
snelheid = snelheid × (0.9 + random × 0.2)
snelheid = Math.max(30, Math.min(150, snelheid))
```

### **6. Afstand per Interval**
```
afstand_per_interval = (snelheid / 3600) × interval_seconden
```

### **7. Nachtvliegen Bonus**
```
if (21:00 ≤ tijd ≤ 06:00):
  nachtvliegen_bonus = (nachtvliegen_waarde / 10) × 4
```

---

## 🔧 **TECHNISCHE DETAILS**

### **Update Frequentie**
- **Training:** Elke 5 seconden
- **Wedstrijden:** Elke 5 seconden
- **Database updates:** Elke 3-5 seconden

### **Snelheid Limieten**
- **Minimum:** 30 km/u
- **Maximum:** 150 km/u
- **Realistische range:** 40-130 km/u

### **Precisie**
- **Afstand:** 3 decimalen (meters)
- **Snelheid:** 2 decimalen (km/u)
- **Tijd:** Milliseconden

### **Performance**
- **Berekening tijd:** < 1ms per duif
- **Memory usage:** < 1MB voor 100 duiven
- **Database load:** Geoptimaliseerd voor real-time updates

---

## 📈 **SIMULATIE VOORDELEN**

### **Realisme**
- ✅ **Vermoeidheid** tijdens vlucht
- ✅ **Afstand-specifieke** eigenschappen
- ✅ **Nachtvliegen** mechanisme
- ✅ **Willekeurige variatie** voor onvoorspelbaarheid

### **Balans**
- ✅ **Korte vluchten:** Snelheid en aerodynamica belangrijk
- ✅ **Middellange vluchten:** Balans tussen snelheid en conditie
- ✅ **Lange vluchten:** Conditie en oriëntatie kritiek

### **Flexibiliteit**
- ✅ **Aanpasbare gewichten** per afstand type
- ✅ **Uitbreidbare eigenschappen**
- ✅ **Configuratie via code**

---

## 🎮 **GEBRUIK IN SPEL**

### **Training Vluchten**
- **Automatische updates** elke 5 seconden
- **Real-time progress** voor alle gebruikers
- **Individuele start tijden** voor realisme

### **Wedstrijden**
- **Competitieve element** met posities
- **Prijsgeld berekening** op basis van resultaten
- **Medailles en trofeeën** voor top 3

### **Database Integratie**
- **Supabase real-time** updates
- **Persistente data** opslag
- **Multi-user synchronisatie**

---

*Dit document beschrijft de volledige vliegsimulatie algoritme zoals geïmplementeerd in Pigeon Legends. Voor vragen of suggesties, neem contact op met het development team.* 