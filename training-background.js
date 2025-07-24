// Training Background Script
// Dit script draait in de achtergrond om training updates te blijven doen voor ALLE gebruikers

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

let trainingInterval = null;
let currentTrainingId = null;
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

// Initialiseer Supabase en start simulatie
async function startTrainingSimulation() {
  await initializeSupabase();
  
  // Check elke 3 seconden of er een actieve training is
  setInterval(async () => {
    await checkAndUpdateTraining();
  }, 3000);
}

// Start simulatie wanneer pagina geladen is
document.addEventListener('DOMContentLoaded', () => {
  startTrainingSimulation();
});

async function checkAndUpdateTraining() {
  if (!supabase) {
    console.log('Supabase nog niet geÃ¯nitialiseerd, wacht...');
    return;
  }
  
  try {
    // Haal actieve training op uit database
    const { data: activeTraining, error } = await supabase
      .from('trainingsvluchten')
      .select('*')
      .eq('status', 'actief')
      .single();

    if (error && error.code !== 'PGRST116') {
      console.error('Fout bij ophalen actieve training:', error);
      return;
    }

    if (activeTraining && activeTraining.id !== currentTrainingId) {
      // Nieuwe actieve training gevonden
      currentTrainingId = activeTraining.id;
      startTrainingUpdates();
      console.log('ðŸ•Šï¸ Training gestart in achtergrond:', activeTraining.id);
    } else if (!activeTraining && currentTrainingId) {
      // Geen actieve training meer
      stopTrainingUpdates();
      console.log('ðŸ›‘ Training gestopt in achtergrond');
    }
  } catch (error) {
    console.log('Geen actieve training gevonden');
  }
}

function startTrainingUpdates() {
  if (trainingInterval) {
    clearInterval(trainingInterval);
  }
  
  trainingInterval = setInterval(async () => {
    await updateTrainingProgress();
  }, 5000); // 5 seconden om database te ontlasten
}

function stopTrainingUpdates() {
  if (trainingInterval) {
    clearInterval(trainingInterval);
    trainingInterval = null;
  }
  currentTrainingId = null;
}

async function updateTrainingProgress() {
  if (!currentTrainingId) return;

  try {
    // Haal alle actieve deelnemers op
    const { data: deelnemers, error } = await supabase
      .from('trainingsvlucht_deelnames')
      .select(`
        *,
        duiven:duif_id(id, naam, geslacht, energie, snelheid, conditie, oriÃ«ntatievermogen, techniek, aerodynamica, ervaring)
      `)
      .eq('trainingsvlucht_id', currentTrainingId)
      .in('status', ['ingeschreven', 'gestart']);

    if (error) {
      console.error('Fout bij ophalen deelnemers:', error);
      return;
    }

    if (!deelnemers || deelnemers.length === 0) {
      console.log('Geen actieve deelnemers gevonden');
      return;
    }

    // Haal training informatie op
    const { data: training, error: trainingError } = await supabase
      .from('trainingsvluchten')
      .select('afstand_km')
      .eq('id', currentTrainingId)
      .single();

    if (trainingError) {
      console.error('Fout bij ophalen training info:', trainingError);
      return;
    }

    const targetDistance = training.afstand_km || 22;
    let alleVoltooid = true;
    const updates = [];

    for (const deelnemer of deelnemers) {
      if (deelnemer.status === 'voltooid') continue;

      const duif = deelnemer.duiven;
      if (!duif) continue;

      // Bereken nieuwe afstand met geavanceerd algoritme
      const result = flightAlgorithm.calculateNewPosition(duif, deelnemer.huidige_afstand_gevlogen || 0, targetDistance, 5);
      const nieuweAfstand = result.newDistance;
      
      // Zorg dat elke duif een eigen start tijd heeft
      if (!deelnemer.start_tijd) {
        // Eerste keer dat deze duif start - geef individuele start tijd
        const startTijd = new Date();
        startTijd.setSeconds(startTijd.getSeconds() + Math.floor(Math.random() * 10)); // Willekeurige start binnen 10 seconden
        
        await supabase
          .from('trainingsvlucht_deelnames')
          .update({ start_tijd: startTijd.toISOString() })
          .eq('id', deelnemer.id);
        
        deelnemer.start_tijd = startTijd.toISOString();
      }

      if (nieuweAfstand >= targetDistance) {
        // Duif heeft de finish bereikt
        const eindTijd = new Date().toISOString();
        const startTijd = new Date(deelnemer.start_tijd);
        const totaleTijd = (new Date(eindTijd) - startTijd) / 1000 / 60; // minuten
        
        updates.push({
          id: deelnemer.id,
          huidige_afstand_gevlogen: targetDistance,
          afstand_nog_te_gaan: 0,
          status: 'voltooid',
          gemiddelde_snelheid: berekenGemiddeldeSnelheid(targetDistance, totaleTijd),
          eind_tijd: eindTijd,
          totale_tijd_minuten: totaleTijd
        });
              } else {
          // Update voortgang met geavanceerd algoritme
          const startTijd = new Date(deelnemer.start_tijd);
          const nu = new Date();
          const verstrekenTijd = (nu - startTijd) / 1000 / 60; // minuten
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

    // Update alle deelnemers
    for (const update of updates) {
      const { error: updateError } = await supabase
        .from('trainingsvlucht_deelnames')
        .update(update)
        .eq('id', update.id);
      
      if (updateError) {
        console.error('Fout bij updaten deelnemer:', updateError);
      }
    }

    // Check of alle deelnemers klaar zijn
    if (alleVoltooid) {
      await finalizeTraining();
    }
    
    console.log('ðŸ”„ Training voortgang bijgewerkt:', updates.length, 'deelnemers');
  } catch (error) {
    console.error('Fout bij training update:', error);
  }
}

// Oude functies vervangen door geavanceerd algoritme

async function finalizeTraining() {
  try {
    // Bepaal winnaar
    const { data: voltooideDeelnemers, error } = await supabase
      .from('trainingsvlucht_deelnames')
      .select('*')
      .eq('trainingsvlucht_id', currentTrainingId)
      .eq('status', 'voltooid')
      .order('totale_tijd_minuten', { ascending: true });

    if (error) {
      console.error('Fout bij ophalen voltooide deelnemers:', error);
      return;
    }

    if (voltooideDeelnemers && voltooideDeelnemers.length > 0) {
      const winnaar = voltooideDeelnemers[0];
      
      // Update training status
      await supabase
        .from('trainingsvluchten')
        .update({ 
          status: 'voltooid',
          eind_tijd: new Date().toISOString(),
          winnaar_id: winnaar.duif_id
        })
        .eq('id', currentTrainingId);

      console.log('ðŸ Training voltooid! Winnaar:', winnaar.duif_id);
    }

    // Stop simulatie
    stopTrainingUpdates();
  } catch (error) {
    console.error('Fout bij finaliseren training:', error);
  }
}

// Start de achtergrond simulatie wanneer het script wordt geladen
console.log('ðŸ•Šï¸ Training achtergrond simulatie gestart'); 
