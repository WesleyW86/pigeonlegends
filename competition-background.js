// Wedstrijd Background Script
// Dit script draait in de achtergrond om wedstrijd updates te blijven doen voor ALLE gebruikers

// Geavanceerd vliegsimulatie algoritme (inline voor betere compatibiliteit)
class FlightSimulationAlgorithm {
  constructor() {
    // Basis snelheid per afstand type (km/u)
    this.baseSpeeds = {
      short: { min: 80, max: 120 },    // 0-200km
      medium: { min: 70, max: 100 },   // 201-500km  
      long: { min: 60, max: 90 }       // 500km+
    };
    
    // Eigenschap gewichten per afstand type (0-4 sterren)
    this.propertyWeights = {
      short: {
        snelheid: 4,        // ****
        conditie: 1,        // *
        oriÃ«ntatie: 1,      // *
        techniek: 2,        // **
        ervaring: 1,        // *
        aerodynamica: 4,    // ****
        intelligentie: 4    // ****
      },
      medium: {
        snelheid: 4,        // ****
        conditie: 4,        // ****
        oriÃ«ntatie: 2,      // **
        ervaring: 2,        // **
        intelligentie: 2    // **
      },
      long: {
        snelheid: 2,        // **
        conditie: 4,        // ****
        oriÃ«ntatie: 4,      // ****
        techniek: 2,        // **
        ervaring: 4,        // ****
        aerodynamica: 2,    // **
        intelligentie: 4    // ****
      }
    };
  }

  // Bepaal afstand type
  getDistanceType(distance) {
    if (distance <= 200) return 'short';
    if (distance <= 500) return 'medium';
    return 'long';
  }

  // Bereken basis snelheid op basis van afstand
  calculateBaseSpeed(distance) {
    const type = this.getDistanceType(distance);
    const { min, max } = this.baseSpeeds[type];
    
    // Langere afstanden = lagere basis snelheid
    const distanceFactor = Math.max(0.8, 1 - (distance / 1000));
    const adjustedMin = min * distanceFactor;
    const adjustedMax = max * distanceFactor;
    
    return {
      min: adjustedMin,
      max: adjustedMax,
      type: type
    };
  }

  // Bereken eigenschap bonus op basis van afstand type
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
    
    // Nachtvliegen check
    const currentHour = new Date().getHours();
    if (currentHour >= 21 || currentHour <= 6) {
      if (duif.nachtvliegen !== undefined) {
        const nachtvliegenBonus = (parseFloat(duif.nachtvliegen) || 0) / 10 * 4; // ****
        totalBonus += nachtvliegenBonus;
        totalWeight += 4;
      }
    }
    
    // Gemiddelde bonus per gewicht
    return totalWeight > 0 ? totalBonus / totalWeight : 0;
  }

  // Bereken realistische snelheid met vermoeidheid
  calculateRealisticSpeed(duif, distance, currentDistance, totalDistance) {
    const baseSpeed = this.calculateBaseSpeed(distance);
    const propertyBonus = this.calculatePropertyBonus(duif, distance);
    
    // Basis snelheid met eigenschap bonus
    let speed = baseSpeed.min + (baseSpeed.max - baseSpeed.min) * propertyBonus;
    
    // Vermoeidheid factor (hoe verder, hoe langzamer)
    const fatigueFactor = this.calculateFatigueFactor(currentDistance, totalDistance, baseSpeed.type);
    speed *= fatigueFactor;
    
    // Willekeurige variatie (Â±10%)
    const variation = 0.9 + (Math.random() * 0.2);
    speed *= variation;
    
    return Math.max(30, Math.min(150, speed)); // Min 30, max 150 km/u
  }

  // Bereken vermoeidheid factor
  calculateFatigueFactor(currentDistance, totalDistance, distanceType) {
    const progress = currentDistance / totalDistance;
    
    // Verschillende vermoeidheid per afstand type
    switch (distanceType) {
      case 'short':
        // Korte vluchten: weinig vermoeidheid
        return 1 - (progress * 0.1);
      case 'medium':
        // Middellange vluchten: gemiddelde vermoeidheid
        return 1 - (progress * 0.2);
      case 'long':
        // Lange vluchten: veel vermoeidheid
        return 1 - (progress * 0.3);
      default:
        return 1;
    }
  }

  // Bereken afstand per tijd interval
  calculateDistancePerInterval(speed, intervalSeconds = 5) {
    // Snelheid van km/u naar km per interval
    return (speed / 3600) * intervalSeconds;
  }

  // Hoofdfunctie: bereken nieuwe positie
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

  // Bereken gemiddelde snelheid over hele vlucht
  calculateAverageSpeed(totalDistance, startTime, endTime) {
    const duration = (endTime - startTime) / 1000 / 60; // minuten
    return duration > 0 ? (totalDistance / duration) * 60 : 0; // km/u
  }
}

let competitionInterval = null;
let currentCompetitionId = null;
let flightAlgorithm = new FlightSimulationAlgorithm();

// Supabase configuratie
const supabaseUrl = 'SUPABASE_CONFIG.url';
const supabaseKey = 'SUPABASE_CONFIG.anonKey';

// Wacht tot Supabase geladen is
let supabase = null;

async function initializeSupabase() {
  if (window.supabase) {
    supabase = window.supabase.createClient(supabaseUrl, supabaseKey);
  } else {
    // Wacht tot Supabase beschikbaar is
    await new Promise(resolve => {
      const checkSupabase = () => {
        if (window.supabase) {
          supabase = window.supabase.createClient(supabaseUrl, supabaseKey);
          resolve();
        } else {
          setTimeout(checkSupabase, 100);
        }
      };
      checkSupabase();
    });
  }
}

// Start wedstrijd simulatie
async function startCompetitionSimulation(competitionId) {
  if (competitionInterval) {
    clearInterval(competitionInterval);
  }
  
  currentCompetitionId = competitionId;
  
  // Start de simulatie elke 5 seconden
  competitionInterval = setInterval(async () => {
    await checkAndUpdateCompetition();
  }, 5000);
  
  console.log(`Wedstrijd simulatie gestart voor wedstrijd ID: ${competitionId}`);
}

// Stop wedstrijd simulatie
function stopCompetitionSimulation() {
  if (competitionInterval) {
    clearInterval(competitionInterval);
    competitionInterval = null;
    currentCompetitionId = null;
    console.log('Wedstrijd simulatie gestopt');
  }
}

// Controleer en update wedstrijd voortgang
async function checkAndUpdateCompetition() {
  if (!currentCompetitionId) return;
  if (!supabase) {
    console.log('Supabase nog niet geÃ¯nitialiseerd voor wedstrijd updates, wacht...');
    return;
  }
  
  try {
    // Haal wedstrijd informatie op
    const { data: competition, error: competitionError } = await supabase
      .from('wedstrijden')
      .select('*')
      .eq('id', currentCompetitionId)
      .single();
    
    if (competitionError) {
      console.error('Fout bij ophalen wedstrijd:', competitionError);
      return;
    }
    
    // Haal alle deelnemers op
    const { data: participants, error: participantsError } = await supabase
      .from('wedstrijd_deelnames')
      .select(`
        *,
        duiven (*),
        users (email)
      `)
      .eq('wedstrijd_id', currentCompetitionId)
      .in('status', ['ingeschreven', 'gestart']);
    
    if (participantsError) {
      console.error('Fout bij ophalen deelnemers:', participantsError);
      return;
    }
    
    if (!participants || participants.length === 0) {
      console.log('Geen actieve deelnemers gevonden');
      return;
    }
    
    // Update elke deelnemer
    await updateCompetitionProgress(participants, competition);
    
  } catch (error) {
    console.error('Fout in wedstrijd simulatie:', error);
  }
}

// Update wedstrijd voortgang voor alle deelnemers
async function updateCompetitionProgress(participants, competition) {
  const targetDistance = parseFloat(competition.afstand_km);
  const updates = [];
  let alleVoltooid = true;
  
  for (const deelnemer of participants) {
    const duif = deelnemer.duiven;
    if (!duif) continue;
    
    // Als deelnemer nog niet gestart is, start nu
    if (deelnemer.status === 'ingeschreven') {
      const startTijd = new Date();
      const randomStartDelay = Math.random() * 30000; // 0-30 seconden vertraging
      startTijd.setMilliseconds(startTijd.getMilliseconds() + randomStartDelay);
      
      updates.push({
        id: deelnemer.id,
        status: 'gestart',
        start_tijd: startTijd.toISOString(),
        huidige_afstand_gevlogen: 0,
        afstand_nog_te_gaan: targetDistance
      });
      alleVoltooid = false;
      continue;
    }
    
    // Bereken nieuwe afstand met geavanceerd algoritme
    const result = flightAlgorithm.calculateNewPosition(duif, deelnemer.huidige_afstand_gevlogen || 0, targetDistance, 5);
    const nieuweAfstand = result.newDistance;
    
    // Check of deelnemer is aangekomen
    if (result.isFinished) {
      const eindTijd = new Date();
      const startTijd = new Date(deelnemer.start_tijd);
      const totaleTijd = (eindTijd - startTijd) / 1000 / 60; // minuten
      const gemiddeldeSnelheid = flightAlgorithm.calculateAverageSpeed(targetDistance, startTijd.getTime(), eindTijd.getTime());
      
      updates.push({
        id: deelnemer.id,
        status: 'voltooid',
        huidige_afstand_gevlogen: targetDistance,
        afstand_nog_te_gaan: 0,
        huidige_snelheid: result.currentSpeed,
        gemiddelde_snelheid: gemiddeldeSnelheid,
        eind_tijd: eindTijd.toISOString(),
        totale_tijd_minuten: totaleTijd
      });
    } else {
      // Update voortgang met geavanceerd algoritme
      const startTijd = new Date(deelnemer.start_tijd);
      const nu = new Date();
      const gemiddeldeSnelheid = nieuweAfstand > 0 ? flightAlgorithm.calculateAverageSpeed(nieuweAfstand, startTijd.getTime(), nu.getTime()) : 0;
      
      updates.push({
        id: deelnemer.id,
        huidige_afstand_gevlogen: nieuweAfstand,
        afstand_nog_te_gaan: targetDistance - nieuweAfstand,
        huidige_snelheid: result.currentSpeed,
        gemiddelde_snelheid: gemiddeldeSnelheid,
        status: 'gestart'
      });
      alleVoltooid = false;
    }
  }
  
  // Update alle deelnemers in database
  if (updates.length > 0) {
    for (const update of updates) {
      const { error } = await supabase
        .from('wedstrijd_deelnames')
        .update(update)
        .eq('id', update.id);
      
      if (error) {
        console.error('Fout bij updaten deelnemer:', error);
      }
    }
  }
  
  // Als alle deelnemers klaar zijn, finaliseer wedstrijd
  if (alleVoltooid) {
    await finalizeCompetition();
  }
}

// Finaliseer wedstrijd en bepaal winnaars
async function finalizeCompetition() {
  try {
    // Haal alle voltooide deelnemers op, gesorteerd op tijd
    const { data: finishedParticipants, error } = await supabase
      .from('wedstrijd_deelnames')
      .select(`
        *,
        duiven (*),
        users (*)
      `)
      .eq('wedstrijd_id', currentCompetitionId)
      .eq('status', 'voltooid')
      .order('totale_tijd_minuten', { ascending: true });
    
    if (error) {
      console.error('Fout bij ophalen voltooide deelnemers:', error);
      return;
    }
    
    if (!finishedParticipants || finishedParticipants.length === 0) {
      console.log('Geen voltooide deelnemers gevonden');
      return;
    }
    
    // Bepaal winnaars en prijzen
    const updates = [];
    const medailles = [];
    
    for (let i = 0; i < finishedParticipants.length; i++) {
      const deelnemer = finishedParticipants[i];
      const positie = i + 1;
      
      // Bepaal prijsgeld
      let prijsgeld = 0;
      let medailleType = null;
      
      if (positie === 1) {
        prijsgeld = 1000; // â‚¬1000 voor 1e plaats
        medailleType = 'goud';
      } else if (positie === 2) {
        prijsgeld = 500;  // â‚¬500 voor 2e plaats
        medailleType = 'zilver';
      } else if (positie === 3) {
        prijsgeld = 250;  // â‚¬250 voor 3e plaats
        medailleType = 'brons';
      }
      
      // Update positie en prijsgeld
      updates.push({
        id: deelnemer.id,
        positie: positie,
        gewonnen_bedrag: prijsgeld
      });
      
      // Voeg medaille toe als er een is
      if (medailleType) {
        medailles.push({
          duif_id: deelnemer.duif_id,
          wedstrijd_id: currentCompetitionId,
          type: medailleType,
          datum: new Date().toISOString().split('T')[0]
        });
      }
    }
    
    // Update alle posities en prijzen
    for (const update of updates) {
      await supabase
        .from('wedstrijd_deelnames')
        .update(update)
        .eq('id', update.id);
    }
    
    // Voeg medailles toe
    for (const medaille of medailles) {
      await supabase
        .from('medailles')
        .insert(medaille);
    }
    
    // Update wedstrijd status
    await supabase
      .from('wedstrijden')
      .update({ status: 'voltooid' })
      .eq('id', currentCompetitionId);
    
    console.log(`Wedstrijd ${currentCompetitionId} voltooid! ${finishedParticipants.length} deelnemers gefinisht.`);
    
    // Stop simulatie
    stopCompetitionSimulation();
    
  } catch (error) {
    console.error('Fout bij finaliseren wedstrijd:', error);
  }
}

// Start wedstrijd simulatie voor een specifieke wedstrijd
async function startCompetition(competitionId) {
  try {
    // Update wedstrijd status naar actief
    const { error } = await supabase
      .from('wedstrijden')
      .update({ status: 'actief' })
      .eq('id', competitionId);
    
    if (error) {
      console.error('Fout bij starten wedstrijd:', error);
      return;
    }
    
    // Start simulatie
    await startCompetitionSimulation(competitionId);
    
  } catch (error) {
    console.error('Fout bij starten wedstrijd:', error);
  }
}

// Export functies voor gebruik in andere bestanden
export {
  startCompetitionSimulation,
  stopCompetitionSimulation,
  startCompetition,
  checkAndUpdateCompetition
};

// Automatisch starten als er actieve wedstrijden zijn
async function checkForActiveCompetitions() {
  if (!supabase) {
    console.log('Supabase nog niet geÃ¯nitialiseerd voor wedstrijden, wacht...');
    return;
  }
  
  try {
    const { data: activeCompetitions, error } = await supabase
      .from('wedstrijden')
      .select('id')
      .eq('status', 'actief');
    
    if (error) {
      console.error('Fout bij controleren actieve wedstrijden:', error);
      return;
    }
    
    if (activeCompetitions && activeCompetitions.length > 0) {
      // Start simulatie voor eerste actieve wedstrijd
      await startCompetitionSimulation(activeCompetitions[0].id);
    }
  } catch (error) {
    console.error('Fout bij controleren actieve wedstrijden:', error);
  }
}

// Start automatische controle bij laden van pagina
document.addEventListener('DOMContentLoaded', async () => {
  await initializeSupabase();
  checkForActiveCompetitions();
}); 
