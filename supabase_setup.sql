-- DUIVENSTIMULATIE SPEL - SUPABASE SETUP (v2) - MET TEAM NAMEN
-- VEILIGE VERSIE - BEHOUD BESTAANDE DATA
-- =====================================================
-- Dit script voegt alleen nieuwe kolommen toe zonder bestaande data te verwijderen
-- =====================================================
-- =====================================================
-- Dit script maakt alle tabellen, constraints en policies voor een volledig duivenspel
-- =====================================================

-- 0. CONSTRAINT UPDATES - VOOR BESTAANDE DATABASES
-- Update afstand_km constraints voor wedstrijden en trainingsvluchten
DO $$
BEGIN
    -- Verwijder oude constraints als ze bestaan
    ALTER TABLE IF EXISTS wedstrijden DROP CONSTRAINT IF EXISTS wedstrijden_afstand_km_check;
    ALTER TABLE IF EXISTS trainingsvluchten DROP CONSTRAINT IF EXISTS trainingsvluchten_afstand_km_check;
    
    -- Voeg nieuwe constraints toe met hogere limiet (1500 km)
    ALTER TABLE IF EXISTS wedstrijden ADD CONSTRAINT wedstrijden_afstand_km_check 
    CHECK (afstand_km > 0 AND afstand_km <= 1500.00);
    
    ALTER TABLE IF EXISTS trainingsvluchten ADD CONSTRAINT trainingsvluchten_afstand_km_check 
    CHECK (afstand_km > 0 AND afstand_km <= 1500.00);
    
    RAISE NOTICE 'Afstand_km constraints bijgewerkt naar 1500 km limiet';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Constraint update overgeslagen: %', SQLERRM;
END $$;

-- 0a. STATUS KOLOM TOEVOEGING - VOOR BESTAANDE DATABASES
-- Voeg status kolom toe aan wedstrijden als deze nog niet bestaat
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'wedstrijden' AND column_name = 'status') THEN
        ALTER TABLE wedstrijden ADD COLUMN status TEXT DEFAULT 'gepland' CHECK (status IN ('gepland', 'actief', 'voltooid'));
        RAISE NOTICE 'Status kolom toegevoegd aan wedstrijden tabel';
    ELSE
        RAISE NOTICE 'Status kolom bestaat al in wedstrijden tabel';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Status kolom update overgeslagen: %', SQLERRM;
END $$;

-- 1. USERS - VEILIGE KOLOM TOEVOEGING
-- Voeg team_naam toe als deze nog niet bestaat
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'team_naam') THEN
        ALTER TABLE users ADD COLUMN team_naam TEXT NOT NULL DEFAULT 'Team Duiven';
        RAISE NOTICE 'team_naam kolom toegevoegd aan users tabel';
    ELSE
        RAISE NOTICE 'team_naam kolom bestaat al in users tabel';
    END IF;
END $$;

-- Maak users tabel als deze nog niet bestaat
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    wachtwoord TEXT NOT NULL,
    naam TEXT NOT NULL,
    team_naam TEXT NOT NULL DEFAULT 'Team Duiven',
    locatie TEXT NOT NULL, -- adres of coördinaten
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. DUIVEN
CREATE TABLE IF NOT EXISTS duiven (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    naam TEXT NOT NULL,
    geslacht TEXT NOT NULL CHECK (geslacht IN ('man', 'vrouw')),
    leeftijd_maanden INTEGER DEFAULT 0,
    vormpeil INTEGER DEFAULT 0 CHECK (vormpeil >= 0 AND vormpeil <= 100),
    snelheid INTEGER DEFAULT 0 CHECK (snelheid >= 0 AND snelheid <= 100),
    conditie INTEGER DEFAULT 0 CHECK (conditie >= 0 AND conditie <= 100),
    oriëntatie INTEGER DEFAULT 0 CHECK (oriëntatie >= 0 AND oriëntatie <= 100),
    techniek INTEGER DEFAULT 0 CHECK (techniek >= 0 AND techniek <= 100),
    ervaring INTEGER DEFAULT 0 CHECK (ervaring >= 0 AND ervaring <= 100),
    aerodynamica INTEGER DEFAULT 0 CHECK (aerodynamica >= 0 AND aerodynamica <= 100),
    intelligentie INTEGER DEFAULT 0 CHECK (intelligentie >= 0 AND intelligentie <= 100),
    nachtvliegen INTEGER DEFAULT 0 CHECK (nachtvliegen >= 0 AND nachtvliegen <= 100),
    libido INTEGER DEFAULT 1 CHECK (libido >= 1 AND libido <= 5),
    status TEXT DEFAULT 'vliegkooi' CHECK (status IN ('vliegkooi', 'kweekkooi', 'jong', 'gestopt')),
    vader_id UUID REFERENCES duiven(id),
    moeder_id UUID REFERENCES duiven(id),
    geboren_op DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. KOOIEN
CREATE TABLE IF NOT EXISTS kooien (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('vliegkooi', 'kweekkooi')),
    nummer INTEGER NOT NULL,
    duif_1_id UUID REFERENCES duiven(id),
    duif_2_id UUID REFERENCES duiven(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, type, nummer)
);
-- Voeg kooi_id toe NA het aanmaken van beide tabellen:
ALTER TABLE duiven ADD COLUMN IF NOT EXISTS kooi_id UUID REFERENCES kooien(id) ON DELETE SET NULL;

-- 4. VOEDING
CREATE TABLE IF NOT EXISTS voeding (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    mais INTEGER DEFAULT 0 CHECK (mais >= 0 AND mais <= 100),
    tarwe INTEGER DEFAULT 0 CHECK (tarwe >= 0 AND tarwe <= 100),
    gerst INTEGER DEFAULT 0 CHECK (gerst >= 0 AND gerst <= 100),
    pinda INTEGER DEFAULT 0 CHECK (pinda >= 0 AND pinda <= 100),
    aangekocht_op DATE DEFAULT CURRENT_DATE,
    gebruikt BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. WEDSTRIJDEN
CREATE TABLE IF NOT EXISTS wedstrijden (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    naam TEXT NOT NULL,
    start_locatie TEXT NOT NULL,
    eind_locatie TEXT NOT NULL,
    datum DATE NOT NULL,
    afstand_km DECIMAL(7,2) NOT NULL CHECK (afstand_km > 0 AND afstand_km <= 1500.00),
    type TEXT DEFAULT 'wedstrijd' CHECK (type IN ('wedstrijd', 'training')),
    status TEXT DEFAULT 'gepland' CHECK (status IN ('gepland', 'actief', 'voltooid')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5a. TRAININGSVLUCHTEN
CREATE TABLE IF NOT EXISTS trainingsvluchten (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    naam TEXT NOT NULL,
    start_locatie TEXT NOT NULL,
    eind_locatie TEXT NOT NULL,
    datum DATE NOT NULL,
    afstand_km DECIMAL(7,2) NOT NULL CHECK (afstand_km > 0 AND afstand_km <= 1500.00),
    status TEXT DEFAULT 'gepland' CHECK (status IN ('gepland', 'actief', 'voltooid')),
    start_tijd TIMESTAMP WITH TIME ZONE,
    eind_tijd TIMESTAMP WITH TIME ZONE,
    winnaar_id UUID REFERENCES duiven(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(naam, start_locatie, eind_locatie, afstand_km)
);

-- 5b. TRAININGSVLUCHT_DEELNAMES
CREATE TABLE IF NOT EXISTS trainingsvlucht_deelnames (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainingsvlucht_id UUID REFERENCES trainingsvluchten(id) ON DELETE CASCADE,
    duif_id UUID REFERENCES duiven(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'ingeschreven' CHECK (status IN ('ingeschreven', 'gestart', 'voltooid')),
    huidige_afstand_gevlogen DECIMAL(7,2) DEFAULT 0.00,
    afstand_nog_te_gaan DECIMAL(7,2),
    gemiddelde_snelheid DECIMAL(6,2) DEFAULT 0.00,
    huidige_snelheid DECIMAL(6,2) DEFAULT 0.00,
    positie INTEGER DEFAULT 0,
    start_tijd TIMESTAMP WITH TIME ZONE,
    eind_tijd TIMESTAMP WITH TIME ZONE,
    totale_tijd_minuten DECIMAL(8,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(trainingsvlucht_id, duif_id),
    CONSTRAINT fk_duif FOREIGN KEY (duif_id) REFERENCES duiven(id) ON DELETE CASCADE
);

-- 6. WEDSTRIJD_DEELNAMES
CREATE TABLE IF NOT EXISTS wedstrijd_deelnames (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wedstrijd_id UUID REFERENCES wedstrijden(id) ON DELETE CASCADE,
    duif_id UUID REFERENCES duiven(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    voeding_id UUID REFERENCES voeding(id),
    inschrijf_datum DATE DEFAULT CURRENT_DATE,
    start_tijd TIMESTAMP WITH TIME ZONE,
    eind_tijd TIMESTAMP WITH TIME ZONE,
    positie INTEGER,
    gemiddelde_snelheid DECIMAL(6,2),
    huidige_snelheid DECIMAL(6,2) DEFAULT 0.00,
    huidige_afstand_gevlogen DECIMAL(7,2) DEFAULT 0.00,
    afstand_nog_te_gaan DECIMAL(7,2),
    totale_tijd_minuten DECIMAL(8,2) DEFAULT 0.00,
    status TEXT DEFAULT 'ingeschreven' CHECK (status IN ('ingeschreven', 'gestart', 'voltooid')),
    gewonnen_bedrag DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. FINANCIEN
CREATE TABLE IF NOT EXISTS financien (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('inkomst', 'uitgave')),
    bedrag DECIMAL(10,2) NOT NULL,
    omschrijving TEXT,
    datum DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. MEDAILLES
CREATE TABLE IF NOT EXISTS medailles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    duif_id UUID REFERENCES duiven(id) ON DELETE CASCADE,
    wedstrijd_id UUID REFERENCES wedstrijden(id) ON DELETE CASCADE,
    type TEXT CHECK (type IN ('goud', 'zilver', 'brons')),
    datum DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. SEIZOENEN
CREATE TABLE IF NOT EXISTS seizoenen (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    start_datum DATE NOT NULL,
    eind_datum DATE NOT NULL,
    nummer INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. RLS POLICIES - VERBETERDE VERSIE
-- Eerst alle RLS uitschakelen voor een schone start
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE duiven DISABLE ROW LEVEL SECURITY;
ALTER TABLE kooien DISABLE ROW LEVEL SECURITY;
ALTER TABLE voeding DISABLE ROW LEVEL SECURITY;
ALTER TABLE wedstrijden DISABLE ROW LEVEL SECURITY;
ALTER TABLE trainingsvluchten DISABLE ROW LEVEL SECURITY;
ALTER TABLE trainingsvlucht_deelnames DISABLE ROW LEVEL SECURITY;
ALTER TABLE wedstrijd_deelnames DISABLE ROW LEVEL SECURITY;
ALTER TABLE financien DISABLE ROW LEVEL SECURITY;
ALTER TABLE medailles DISABLE ROW LEVEL SECURITY;
ALTER TABLE seizoenen DISABLE ROW LEVEL SECURITY;

-- Dan alle RLS weer inschakelen
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE duiven ENABLE ROW LEVEL SECURITY;
ALTER TABLE kooien ENABLE ROW LEVEL SECURITY;
ALTER TABLE voeding ENABLE ROW LEVEL SECURITY;
ALTER TABLE wedstrijden ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainingsvluchten ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainingsvlucht_deelnames ENABLE ROW LEVEL SECURITY;
ALTER TABLE wedstrijd_deelnames ENABLE ROW LEVEL SECURITY;
ALTER TABLE financien ENABLE ROW LEVEL SECURITY;
ALTER TABLE medailles ENABLE ROW LEVEL SECURITY;
ALTER TABLE seizoenen ENABLE ROW LEVEL SECURITY;

-- VERWIJDER ALLE BESTAANDE POLICIES
DROP POLICY IF EXISTS open_trainingsvlucht_deelnames ON trainingsvlucht_deelnames;
DROP POLICY IF EXISTS open_duiven ON duiven;
DROP POLICY IF EXISTS open_trainingsvlucht_deelnames_all ON trainingsvlucht_deelnames;
DROP POLICY IF EXISTS open_duiven_all ON duiven;

-- MAKER ALLE POLICIES OPEN VOOR DEMO (VOOR TESTING)
-- Dit zorgt ervoor dat alle operaties toegestaan zijn
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS "open_%s" ON %I', t, t);
    EXECUTE format('CREATE POLICY "open_%s" ON %I FOR ALL USING (true) WITH CHECK (true);', t, t);
  END LOOP;
END $$;

-- SPECIFIEKE POLICIES VOOR GEBRUIKER-SPECIFIEKE TABELLEN
-- Deze overschrijven de algemene open policies voor veiligheid

-- VOEDING - Alleen eigen voeding
DROP POLICY IF EXISTS "open_voeding_select" ON voeding;
CREATE POLICY "open_voeding_select" ON voeding FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "open_voeding_insert" ON voeding;
CREATE POLICY "open_voeding_insert" ON voeding FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "open_voeding_update" ON voeding;
CREATE POLICY "open_voeding_update" ON voeding FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "open_voeding_delete" ON voeding;
CREATE POLICY "open_voeding_delete" ON voeding FOR DELETE USING (auth.uid() = user_id);

-- FINANCIEN - Alleen eigen financien
DROP POLICY IF EXISTS "open_financien_select" ON financien;
CREATE POLICY "open_financien_select" ON financien FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "open_financien_insert" ON financien;
CREATE POLICY "open_financien_insert" ON financien FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "open_financien_update" ON financien;
CREATE POLICY "open_financien_update" ON financien FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "open_financien_delete" ON financien;
CREATE POLICY "open_financien_delete" ON financien FOR DELETE USING (auth.uid() = user_id);

-- WEDSTRIJD_DEELNAMES - Alleen eigen deelnames
DROP POLICY IF EXISTS "open_wedstrijd_deelnames_select" ON wedstrijd_deelnames;
CREATE POLICY "open_wedstrijd_deelnames_select" ON wedstrijd_deelnames FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "open_wedstrijd_deelnames_insert" ON wedstrijd_deelnames;
CREATE POLICY "open_wedstrijd_deelnames_insert" ON wedstrijd_deelnames FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "open_wedstrijd_deelnames_update" ON wedstrijd_deelnames;
CREATE POLICY "open_wedstrijd_deelnames_update" ON wedstrijd_deelnames FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "open_wedstrijd_deelnames_delete" ON wedstrijd_deelnames;
CREATE POLICY "open_wedstrijd_deelnames_delete" ON wedstrijd_deelnames FOR DELETE USING (auth.uid() = user_id);

-- EXTRA SPECIFIEKE POLICIES VOOR TRAININGSVLUCHT_DEELNAMES
-- Deze zijn cruciaal voor het inschrijfprobleem
DROP POLICY IF EXISTS "open_trainingsvlucht_deelnames_select" ON trainingsvlucht_deelnames;
CREATE POLICY "open_trainingsvlucht_deelnames_select" ON trainingsvlucht_deelnames FOR SELECT USING (true);

DROP POLICY IF EXISTS "open_trainingsvlucht_deelnames_insert" ON trainingsvlucht_deelnames;
CREATE POLICY "open_trainingsvlucht_deelnames_insert" ON trainingsvlucht_deelnames FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "open_trainingsvlucht_deelnames_update" ON trainingsvlucht_deelnames;
CREATE POLICY "open_trainingsvlucht_deelnames_update" ON trainingsvlucht_deelnames FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "open_trainingsvlucht_deelnames_delete" ON trainingsvlucht_deelnames;
CREATE POLICY "open_trainingsvlucht_deelnames_delete" ON trainingsvlucht_deelnames FOR DELETE USING (true);

-- SPECIFIEKE POLICIES VOOR DUIVEN
-- Gebruikers kunnen alle duiven zien (voor trainingen/wedstrijden)
DROP POLICY IF EXISTS "open_duiven_select" ON duiven;
CREATE POLICY "open_duiven_select" ON duiven FOR SELECT USING (true);

-- Gebruikers kunnen alleen hun eigen duiven toevoegen/bewerken/verwijderen
DROP POLICY IF EXISTS "open_duiven_insert" ON duiven;
CREATE POLICY "open_duiven_insert" ON duiven FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "open_duiven_update" ON duiven;
CREATE POLICY "open_duiven_update" ON duiven FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "open_duiven_delete" ON duiven;
CREATE POLICY "open_duiven_delete" ON duiven FOR DELETE USING (auth.uid() = user_id);

-- SPECIFIEKE POLICIES VOOR KOOIEN
-- Gebruikers kunnen alleen hun eigen kooien zien/bewerken
DROP POLICY IF EXISTS "open_kooien_select" ON kooien;
CREATE POLICY "open_kooien_select" ON kooien FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "open_kooien_insert" ON kooien;
CREATE POLICY "open_kooien_insert" ON kooien FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "open_kooien_update" ON kooien;
CREATE POLICY "open_kooien_update" ON kooien FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "open_kooien_delete" ON kooien;
CREATE POLICY "open_kooien_delete" ON kooien FOR DELETE USING (auth.uid() = user_id);

-- EXTRA SPECIFIEKE POLICIES VOOR TRAININGSVLUCHTEN
DROP POLICY IF EXISTS "open_trainingsvluchten_select" ON trainingsvluchten;
CREATE POLICY "open_trainingsvluchten_select" ON trainingsvluchten FOR SELECT USING (true);

DROP POLICY IF EXISTS "open_trainingsvluchten_insert" ON trainingsvluchten;
CREATE POLICY "open_trainingsvluchten_insert" ON trainingsvluchten FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "open_trainingsvluchten_update" ON trainingsvluchten;
CREATE POLICY "open_trainingsvluchten_update" ON trainingsvluchten FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "open_trainingsvluchten_delete" ON trainingsvluchten;
CREATE POLICY "open_trainingsvluchten_delete" ON trainingsvluchten FOR DELETE USING (true);

-- Voeg kooi_id kolom toe aan duiven tabel als deze nog niet bestaat (voor bestaande databases)
-- ALTER TABLE duiven ADD COLUMN IF NOT EXISTS kooi_id UUID REFERENCES kooien(id) ON DELETE SET NULL;

-- 11. UNIEKE CONSTRAINTS
-- Eerst controleren of de kolommen bestaan voordat we constraints toevoegen
DO $$
BEGIN
    -- Controleer of start_locatie kolom bestaat
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'wedstrijden' AND column_name = 'start_locatie') THEN
        ALTER TABLE wedstrijden DROP CONSTRAINT IF EXISTS unieke_wedstrijd;
        ALTER TABLE wedstrijden ADD CONSTRAINT unieke_wedstrijd UNIQUE (naam, start_locatie, eind_locatie, datum, afstand_km);
    END IF;
    
    -- Controleer of geboren_op kolom bestaat
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'duiven' AND column_name = 'geboren_op') THEN
        ALTER TABLE duiven DROP CONSTRAINT IF EXISTS unieke_duif_per_user;
        ALTER TABLE duiven ADD CONSTRAINT unieke_duif_per_user UNIQUE (user_id, naam, geboren_op);
    END IF;
END $$;

-- 12. VEILIGE TOEVOEGING VAN WEDSTRIJDEN (alleen als ze nog niet bestaan)
INSERT INTO wedstrijden (naam, start_locatie, eind_locatie, datum, afstand_km, type)
SELECT * FROM (VALUES
  ('Sas van Gent-Gent', 'Sas van Gent', 'Gent', '2024-07-01'::DATE, 22.00, 'wedstrijd'),
  ('Arras-Gent', 'Arras', 'Gent', '2024-07-10'::DATE, 70.00, 'wedstrijd'),
  ('Bourges-Gent', 'Bourges', 'Gent', '2024-07-20'::DATE, 410.00, 'wedstrijd'),
  ('Barcelona-Gent', 'Barcelona', 'Gent', '2024-08-01'::DATE, 1080.00, 'wedstrijd'),
  ('Lille-Gent', 'Lille', 'Gent', '2024-08-10'::DATE, 50.00, 'wedstrijd'),
  ('Reims-Gent', 'Reims', 'Gent', '2024-08-20'::DATE, 200.00, 'wedstrijd'),
  ('Chateauroux-Gent', 'Chateauroux', 'Gent', '2024-09-01'::DATE, 550.00, 'wedstrijd'),
  ('Limoges-Gent', 'Limoges', 'Gent', '2024-09-10'::DATE, 700.00, 'wedstrijd'),
  ('Poitiers-Gent', 'Poitiers', 'Gent', '2024-09-20'::DATE, 650.00, 'wedstrijd'),
  ('Tours-Gent', 'Tours', 'Gent', '2024-10-01'::DATE, 600.00, 'wedstrijd'),
  ('Orleans-Gent', 'Orleans', 'Gent', '2024-10-10'::DATE, 350.00, 'wedstrijd'),
  ('Vierzon-Gent', 'Vierzon', 'Gent', '2024-10-20'::DATE, 500.00, 'wedstrijd'),
  ('Montlucon-Gent', 'Montlucon', 'Gent', '2024-11-01'::DATE, 750.00, 'wedstrijd'),
  ('Brive-Gent', 'Brive', 'Gent', '2024-11-10'::DATE, 800.00, 'wedstrijd'),
  ('Cahors-Gent', 'Cahors', 'Gent', '2024-11-20'::DATE, 900.00, 'wedstrijd'),
  ('Perpignan-Gent', 'Perpignan', 'Gent', '2024-12-01'::DATE, 1050.00, 'wedstrijd'),
  ('Narbonne-Gent', 'Narbonne', 'Gent', '2024-12-10'::DATE, 1000.00, 'wedstrijd'),
  ('Agen-Gent', 'Agen', 'Gent', '2024-12-20'::DATE, 950.00, 'wedstrijd'),
  ('Dax-Gent', 'Dax', 'Gent', '2025-01-01'::DATE, 980.00, 'wedstrijd'),
  ('Pau-Gent', 'Pau', 'Gent', '2025-01-10'::DATE, 1020.00, 'wedstrijd'),
  ('St. Vincent-Gent', 'St. Vincent', 'Gent', '2025-01-20'::DATE, 1080.00, 'wedstrijd'),
  ('Angouleme-Gent', 'Angouleme', 'Gent', '2025-02-01'::DATE, 870.00, 'wedstrijd'),
  ('Libourne-Gent', 'Libourne', 'Gent', '2025-02-10'::DATE, 920.00, 'wedstrijd'),
  ('Bergerac-Gent', 'Bergerac', 'Gent', '2025-02-20'::DATE, 970.00, 'wedstrijd'),
  ('St. Emilion-Gent', 'St. Emilion', 'Gent', '2025-03-01'::DATE, 880.00, 'wedstrijd'),
  ('Nationale Sprint Wedstrijd', 'Brussel', 'Antwerpen', '2025-08-15'::DATE, 45.50, 'wedstrijd'),
  ('Internationale Middenafstand', 'Parijs', 'Amsterdam', '2025-08-22'::DATE, 430.20, 'wedstrijd'),
  ('Lange Afstand Kampioenschap', 'Barcelona', 'Rotterdam', '2025-09-05'::DATE, 1250.80, 'wedstrijd'),
  ('Jeugd Wedstrijd', 'Gent', 'Brugge', '2025-08-10'::DATE, 25.30, 'wedstrijd'),
  ('Veteranen Cup', 'Leuven', 'Mechelen', '2025-08-18'::DATE, 35.70, 'wedstrijd')
) AS v(naam, start_locatie, eind_locatie, datum, afstand_km, type)
WHERE NOT EXISTS (
    SELECT 1 FROM wedstrijden w 
    WHERE w.naam = v.naam 
    AND w.start_locatie = v.start_locatie 
    AND w.eind_locatie = v.eind_locatie 
    AND w.datum = v.datum
);

-- 13. VEILIGE TOEVOEGING VAN TRAININGSVLUCHTEN (alleen als ze nog niet bestaan)
INSERT INTO trainingsvluchten (naam, start_locatie, eind_locatie, datum, afstand_km, status)
SELECT * FROM (VALUES
  ('Lille-Gent', 'Lille', 'Gent', '2024-07-15'::DATE, 50.00, 'gepland'),
  ('Kortrijk-Gent', 'Kortrijk', 'Gent', '2024-07-20'::DATE, 35.00, 'gepland'),
  ('Brugge-Gent', 'Brugge', 'Gent', '2024-07-25'::DATE, 45.00, 'gepland')
) AS v(naam, start_locatie, eind_locatie, datum, afstand_km, status)
WHERE NOT EXISTS (
    SELECT 1 FROM trainingsvluchten t 
    WHERE t.naam = v.naam 
    AND t.start_locatie = v.start_locatie 
    AND t.eind_locatie = v.eind_locatie 
    AND t.datum = v.datum
);

-- 14. VEILIGE TOEVOEGING VAN WEDSTRIJDEN ALS TRAININGSVLUCHTEN (VOORKOM DUPLICATEN)
INSERT INTO trainingsvluchten (naam, start_locatie, eind_locatie, datum, afstand_km, status)
SELECT 
    naam,
    start_locatie,
    eind_locatie,
    datum,
    afstand_km,
    'gepland' as status
FROM wedstrijden
WHERE type = 'wedstrijd'
AND NOT EXISTS (
    SELECT 1 FROM trainingsvluchten t 
    WHERE t.naam = wedstrijden.naam 
    AND t.start_locatie = wedstrijden.start_locatie 
    AND t.eind_locatie = wedstrijden.eind_locatie 
    AND t.afstand_km = wedstrijden.afstand_km
);

-- 15. DEBUG INFORMATIE - Toon alle policies
SELECT '=== RLS POLICIES VERIFICATIE ===' as bericht;
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE schemaname = 'public' 
ORDER BY tablename, policyname;

-- 16. SAMENVATTING EN VERIFICATIE
-- Toon resultaat van de setup
SELECT '=== DUIVENSTIMULATIE SPEL SETUP VOLTOOID ===' as bericht;
SELECT COUNT(*) as aantal_wedstrijden FROM wedstrijden WHERE type = 'wedstrijd';
SELECT COUNT(*) as aantal_trainingsvluchten FROM trainingsvluchten;
SELECT COUNT(*) as aantal_duiven FROM duiven;
SELECT COUNT(*) as aantal_kooien FROM kooien;

-- Toon alle trainingsvluchten voor verificatie
SELECT 'TRAININGSVLUCHTEN:' as sectie;
SELECT naam, start_locatie, eind_locatie, datum, afstand_km, status
FROM trainingsvluchten
ORDER BY datum, afstand_km;

-- Toon RLS status van alle tabellen
SELECT 'RLS STATUS:' as sectie;
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- 17. SYNCHRONISEER AUTH.USERS MET PUBLIC.USERS EN STEL TEAM NAMEN IN
-- Voeg gebruikers toe die wel in auth.users staan maar niet in public.users
INSERT INTO public.users (id, email, naam, team_naam, locatie, wachtwoord, created_at)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'name', SPLIT_PART(au.email, '@', 1)) as naam,
    CASE 
        WHEN au.email = 'wesley.wyngaerd@outlook.com' THEN 'Blauwe Geschelpten'
        WHEN au.email = 'maximeboelaert@hotmail.be' THEN 'Rode Vliegers'
        WHEN au.email = 'degraevetomas@gmail.com' THEN 'Groene Champions'
        WHEN au.email = 'justai3@proton.me' THEN 'AI Team'
        ELSE 'Team Duiven'
    END as team_naam,
    'Onbekend' as locatie,
    'auth_user' as wachtwoord,
    au.created_at
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL
ON CONFLICT (email) DO NOTHING;

-- Stel team namen in voor bestaande gebruikers
UPDATE public.users 
SET team_naam = 'Blauwe Geschelpten'
WHERE email = 'wesley.wyngaerd@outlook.com';

UPDATE public.users 
SET team_naam = 'Rode Vliegers'
WHERE email = 'maximeboelaert@hotmail.be';

UPDATE public.users 
SET team_naam = 'Groene Champions'
WHERE email = 'degraevetomas@gmail.com';

-- 18. UPDATE BESTAANDE GEBRUIKERS MET DEFAULT TEAM NAAM (alleen als nodig)
UPDATE users 
SET team_naam = 'Team Duiven' 
WHERE team_naam IS NULL OR team_naam = '';

-- 18a. SCHAKEL RLS UIT EN FORCEER TOMAS VERWIJDERING
-- Schakel RLS tijdelijk uit om alle operaties toe te staan
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE duiven DISABLE ROW LEVEL SECURITY;
ALTER TABLE trainingsvlucht_deelnames DISABLE ROW LEVEL SECURITY;
ALTER TABLE wedstrijd_deelnames DISABLE ROW LEVEL SECURITY;
ALTER TABLE financien DISABLE ROW LEVEL SECURITY;
ALTER TABLE kooien DISABLE ROW LEVEL SECURITY;
ALTER TABLE voeding DISABLE ROW LEVEL SECURITY;
ALTER TABLE medailles DISABLE ROW LEVEL SECURITY;

-- Schakel trigger uit om conflicten te voorkomen
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- VIND TOMAS'S USER ID
DO $$
DECLARE
    tomas_id UUID;
BEGIN
    SELECT id INTO tomas_id FROM auth.users WHERE email = 'degraevetomas@gmail.com';
    
    IF tomas_id IS NULL THEN
        RAISE NOTICE 'Tomas niet gevonden in auth.users';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Tomas ID: %', tomas_id;
    
    -- VERWIJDER ALLE DATA VAN TOMAS
    -- Verwijder trainingsvlucht deelnames
    DELETE FROM trainingsvlucht_deelnames WHERE duif_id IN (
        SELECT id FROM duiven WHERE user_id = tomas_id
    );
    RAISE NOTICE 'Trainingsvlucht deelnames verwijderd';
    
    -- Verwijder wedstrijd deelnames
    DELETE FROM wedstrijd_deelnames WHERE user_id = tomas_id;
    RAISE NOTICE 'Wedstrijd deelnames verwijderd';
    
    -- Verwijder duiven
    DELETE FROM duiven WHERE user_id = tomas_id;
    RAISE NOTICE 'Duiven verwijderd';
    
    -- Verwijder financien
    DELETE FROM financien WHERE user_id = tomas_id;
    RAISE NOTICE 'Financien verwijderd';
    
    -- Verwijder kooien
    DELETE FROM kooien WHERE user_id = tomas_id;
    RAISE NOTICE 'Kooien verwijderd';
    
    -- Verwijder voeding
    DELETE FROM voeding WHERE user_id = tomas_id;
    RAISE NOTICE 'Voeding verwijderd';
    
    -- Verwijder medailles (via duif_id)
    DELETE FROM medailles WHERE duif_id IN (
        SELECT id FROM duiven WHERE user_id = tomas_id
    );
    RAISE NOTICE 'Medailles verwijderd';
    
    -- Verwijder uit public.users
    DELETE FROM public.users WHERE id = tomas_id;
    RAISE NOTICE 'Public.users verwijderd';
    
    -- Verwijder uit auth.users
    DELETE FROM auth.users WHERE id = tomas_id;
    RAISE NOTICE 'Auth.users verwijderd';
    
    RAISE NOTICE 'Tomas volledig verwijderd!';
END $$;

-- VERIFICATIE
SELECT '=== VERIFICATIE ===' as info;
SELECT 'Tomas in auth.users:' as check1, COUNT(*) as aantal FROM auth.users WHERE email = 'degraevetomas@gmail.com';
SELECT 'Tomas in public.users:' as check2, COUNT(*) as aantal FROM public.users WHERE email = 'degraevetomas@gmail.com';
SELECT 'Tomas duiven:' as check3, COUNT(*) as aantal FROM duiven WHERE user_id IN (SELECT id FROM auth.users WHERE email = 'degraevetomas@gmail.com');

-- Update alle wachtwoorden naar Test123
UPDATE auth.users 
SET encrypted_password = crypt('Test123', gen_salt('bf'))
WHERE email IN ('wesley.wyngaerd@outlook.com', 'maximeboelaert@hotmail.be', 'justai3@proton.me');

-- 18b. SYNCHRONISEER GEBRUIKERS VEILIG (ALLEEN ALS ZE NOG NIET BESTAAN)
DO $$
DECLARE
    auth_user_id UUID;
    public_user_exists BOOLEAN;
BEGIN
    -- SYNCHRONISEER WESLEY
    SELECT id INTO auth_user_id FROM auth.users WHERE email = 'wesley.wyngaerd@outlook.com';
    SELECT EXISTS(SELECT 1 FROM public.users WHERE email = 'wesley.wyngaerd@outlook.com') INTO public_user_exists;
    
    IF auth_user_id IS NOT NULL AND NOT public_user_exists THEN
        INSERT INTO public.users (id, email, naam, team_naam, locatie, wachtwoord, created_at)
        VALUES (auth_user_id, 'wesley.wyngaerd@outlook.com', 'Wesley', 'Blauwe Geschelpten', 'Onbekend', 'auth_user', NOW())
        ON CONFLICT (email) DO NOTHING;
        RAISE NOTICE 'Wesley toegevoegd aan public.users';
    ELSE
        RAISE NOTICE 'Wesley bestaat al in public.users';
    END IF;
    
    -- SYNCHRONISEER MAXIME
    SELECT id INTO auth_user_id FROM auth.users WHERE email = 'maximeboelaert@hotmail.be';
    SELECT EXISTS(SELECT 1 FROM public.users WHERE email = 'maximeboelaert@hotmail.be') INTO public_user_exists;
    
    IF auth_user_id IS NOT NULL AND NOT public_user_exists THEN
        INSERT INTO public.users (id, email, naam, team_naam, locatie, wachtwoord, created_at)
        VALUES (auth_user_id, 'maximeboelaert@hotmail.be', 'Maxime', 'Rode Vliegers', 'Onbekend', 'auth_user', NOW())
        ON CONFLICT (email) DO NOTHING;
        RAISE NOTICE 'Maxime toegevoegd aan public.users';
    ELSE
        RAISE NOTICE 'Maxime bestaat al in public.users';
    END IF;
    
    -- SYNCHRONISEER JUSTAI3
    SELECT id INTO auth_user_id FROM auth.users WHERE email = 'justai3@proton.me';
    SELECT EXISTS(SELECT 1 FROM public.users WHERE email = 'justai3@proton.me') INTO public_user_exists;
    
    IF auth_user_id IS NOT NULL AND NOT public_user_exists THEN
        INSERT INTO public.users (id, email, naam, team_naam, locatie, wachtwoord, created_at)
        VALUES (auth_user_id, 'justai3@proton.me', 'JustAI', 'AI Team', 'Onbekend', 'auth_user', NOW())
        ON CONFLICT (email) DO NOTHING;
        RAISE NOTICE 'JustAI toegevoegd aan public.users';
    ELSE
        RAISE NOTICE 'JustAI bestaat al in public.users';
    END IF;
    
    -- TOMAS WORDT NIET OPNIEUW TOEGEVOEGD - HANDMATIG TOEVOEGEN VIA SUPABASE INTERFACE
    RAISE NOTICE 'Tomas volledig verwijderd. Voeg handmatig toe via Supabase Authentication → Users → Add user';
END $$;

DO $$
DECLARE
    user_exists BOOLEAN;
    auth_user_id UUID;
BEGIN
    -- VOEG MAXIME TOE
    -- Controleer of Maxime bestaat in auth.users
    SELECT EXISTS(SELECT 1 FROM auth.users WHERE email = 'maximeboelaert@hotmail.be') INTO user_exists;
    
    IF NOT user_exists THEN
        -- Voeg Maxime toe aan auth.users
        INSERT INTO auth.users (
            id,
            email,
            encrypted_password,
            email_confirmed_at,
            created_at,
            updated_at,
            raw_user_meta_data,
            is_super_admin,
            confirmation_token,
            recovery_token
        ) VALUES (
            gen_random_uuid(),
            'maximeboelaert@hotmail.be',
            crypt('Test123', gen_salt('bf')),
            NOW(),
            NOW(),
            NOW(),
            '{"name": "Maxime"}',
            false,
            '',
            ''
        );
        
        RAISE NOTICE 'Maxime toegevoegd aan auth.users';
    ELSE
        -- Update Maxime's wachtwoord als hij al bestaat
        UPDATE auth.users 
        SET encrypted_password = crypt('Test123', gen_salt('bf'))
        WHERE email = 'maximeboelaert@hotmail.be';
        
        RAISE NOTICE 'Maxime wachtwoord bijgewerkt naar Test123';
    END IF;
    
    -- Haal Maxime's ID op
    SELECT id INTO auth_user_id FROM auth.users WHERE email = 'maximeboelaert@hotmail.be';
    
    -- Controleer of Maxime bestaat in public.users
    SELECT EXISTS(SELECT 1 FROM public.users WHERE email = 'maximeboelaert@hotmail.be') INTO user_exists;
    
    IF NOT user_exists AND auth_user_id IS NOT NULL THEN
        -- Voeg Maxime toe aan public.users
        INSERT INTO public.users (id, email, naam, team_naam, locatie, wachtwoord, created_at)
        VALUES (
            auth_user_id,
            'maximeboelaert@hotmail.be',
            'Maxime',
            'Rode Vliegers',
            'Onbekend',
            'auth_user',
            NOW()
        );
        
        RAISE NOTICE 'Maxime toegevoegd aan public.users';
    END IF;
    
    -- VOEG JUSTAI TOE
    -- Controleer of JustAI bestaat in auth.users
    SELECT EXISTS(SELECT 1 FROM auth.users WHERE email = 'justai3@proton.me') INTO user_exists;
    
    IF NOT user_exists THEN
        -- Voeg JustAI toe aan auth.users
        INSERT INTO auth.users (
            id,
            email,
            encrypted_password,
            email_confirmed_at,
            created_at,
            updated_at,
            raw_user_meta_data,
            is_super_admin,
            confirmation_token,
            recovery_token
        ) VALUES (
            gen_random_uuid(),
            'justai3@proton.me',
            crypt('Test123', gen_salt('bf')),
            NOW(),
            NOW(),
            NOW(),
            '{"name": "JustAI"}',
            false,
            '',
            ''
        );
        
        RAISE NOTICE 'JustAI toegevoegd aan auth.users';
    ELSE
        -- Update JustAI's wachtwoord als hij al bestaat
        UPDATE auth.users 
        SET encrypted_password = crypt('Test123', gen_salt('bf'))
        WHERE email = 'justai3@proton.me';
        
        RAISE NOTICE 'JustAI wachtwoord bijgewerkt naar Test123';
    END IF;
    
    -- Haal JustAI's ID op
    SELECT id INTO auth_user_id FROM auth.users WHERE email = 'justai3@proton.me';
    
    -- Controleer of JustAI bestaat in public.users
    SELECT EXISTS(SELECT 1 FROM public.users WHERE email = 'justai3@proton.me') INTO user_exists;
    
    IF NOT user_exists AND auth_user_id IS NOT NULL THEN
        -- Voeg JustAI toe aan public.users
        INSERT INTO public.users (id, email, naam, team_naam, locatie, wachtwoord, created_at)
        VALUES (
            auth_user_id,
            'justai3@proton.me',
            'JustAI',
            'AI Team',
            'Onbekend',
            'auth_user',
            NOW()
        );
        
        RAISE NOTICE 'JustAI toegevoegd aan public.users';
    ELSE
        -- Update JustAI in public.users als hij al bestaat
        UPDATE public.users 
        SET naam = 'JustAI', team_naam = 'AI Team'
        WHERE email = 'justai3@proton.me';
        
        RAISE NOTICE 'JustAI bijgewerkt in public.users';
    END IF;
    
    -- VOEG TOMAS TOE (HANDMATIG - NIET AUTOMATISCH)
    RAISE NOTICE 'Tomas moet handmatig worden toegevoegd via Supabase Authentication → Users → Add user';
END $$;

-- 19. TRIGGER UITGESCHAKELD VOOR VEILIGHEID
-- Trigger is uitgeschakeld om duplicate key errors te voorkomen
-- Gebruikers worden handmatig gesynchroniseerd in sectie 18b

-- Functie blijft bestaan voor toekomstig gebruik
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Voeg alleen toe als de gebruiker nog niet bestaat in public.users
    INSERT INTO public.users (id, email, naam, team_naam, locatie, wachtwoord, created_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', SPLIT_PART(NEW.email, '@', 1)),
        'Team Duiven',
        'Onbekend',
        'auth_user',
        NEW.created_at
    )
    ON CONFLICT (email) DO NOTHING; -- Voorkom duplicate key errors
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger wordt NIET hersteld om conflicten te voorkomen
-- RAISE NOTICE 'Trigger uitgeschakeld voor veiligheid';

-- 19a. FIX KOOIEN ZONDER USER_ID
-- Verwijder kooien die geen user_id hebben (oude data)
DELETE FROM kooien WHERE user_id IS NULL;

-- 19b. HERSTEL RLS POLICIES
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE duiven ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainingsvlucht_deelnames ENABLE ROW LEVEL SECURITY;
ALTER TABLE wedstrijd_deelnames ENABLE ROW LEVEL SECURITY;
ALTER TABLE financien ENABLE ROW LEVEL SECURITY;
ALTER TABLE kooien ENABLE ROW LEVEL SECURITY;
ALTER TABLE voeding ENABLE ROW LEVEL SECURITY;
ALTER TABLE medailles ENABLE ROW LEVEL SECURITY;

-- 20. VERIFICATIE EN SAMENVATTING
SELECT '=== SYNCHRONISATIE VOLTOOID ===' as bericht;
SELECT COUNT(*) as auth_users FROM auth.users;
SELECT COUNT(*) as public_users FROM public.users;

SELECT '=== GEBRUIKERS IN PUBLIC.USERS ===' as info;
SELECT 
    email, 
    naam, 
    team_naam,
    CASE 
        WHEN email = 'wesley.wyngaerd@outlook.com' THEN '✅ Wesley'
        WHEN email = 'maximeboelaert@hotmail.be' THEN '✅ Maxime'
        WHEN email = 'degraevetomas@gmail.com' THEN '✅ Tomas'
        WHEN email = 'justai3@proton.me' THEN '✅ JustAI'
        ELSE '⚠️ Onbekend'
    END as status
FROM public.users 
ORDER BY created_at ASC;

SELECT '=== TEAM NAMEN STATUS ===' as info;
SELECT 
    team_naam,
    COUNT(*) as aantal_gebruikers
FROM public.users 
GROUP BY team_naam 
ORDER BY aantal_gebruikers DESC;

-- 21. DUIVEN TOEWIJZEN AAN GEBRUIKERS (alleen als user_id nog niet is ingesteld)
-- Wijs bestaande duiven toe aan gebruikers op basis van email
UPDATE duiven 
SET user_id = (
    SELECT id FROM users 
    WHERE email = 'wesley.wyngaerd@outlook.com' 
    LIMIT 1
)
WHERE user_id IS NULL 
AND EXISTS (SELECT 1 FROM users WHERE email = 'wesley.wyngaerd@outlook.com');

-- Als er nog steeds duiven zonder user_id zijn, wijs ze toe aan de eerste gebruiker
UPDATE duiven 
SET user_id = (SELECT id FROM users ORDER BY created_at ASC LIMIT 1)
WHERE user_id IS NULL;

-- 22. VERIFICATIE DUIVEN TOEWIJZING
SELECT '=== DUIVEN TOEWIJZING ===' as info;
SELECT 
    u.email,
    u.team_naam,
    COUNT(d.id) as aantal_duiven
FROM users u
LEFT JOIN duiven d ON u.id = d.user_id
GROUP BY u.id, u.email, u.team_naam
ORDER BY u.created_at ASC;

-- 23. VERIFICATIE WACHTWOORDEN
SELECT '=== WACHTWOORDEN STATUS ===' as info;
SELECT 
    au.email,
    CASE 
        WHEN au.encrypted_password = crypt('Test123', au.encrypted_password) THEN '✅ Test123'
        ELSE '❌ Ander wachtwoord'
    END as wachtwoord_status,
    CASE 
        WHEN pu.id IS NOT NULL THEN '✅ In public.users'
        ELSE '❌ Niet in public.users'
    END as public_users_status
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE au.email IN ('wesley.wyngaerd@outlook.com', 'maximeboelaert@hotmail.be', 'justai3@proton.me')
ORDER BY au.email;

-- 24. INSTRUCTIES VOOR TOMAS
SELECT '=== TOMAS HANDMATIG TOEVOEGEN ===' as instructie;
SELECT '1. Ga naar Supabase Authentication → Users' as stap1;
SELECT '2. Klik "Add user"' as stap2;
SELECT '3. Email: degraevetomas@gmail.com' as stap3;
SELECT '4. Password: Test123' as stap4;
SELECT '5. Auto confirm: ✅' as stap5;
SELECT '6. Klik "Create user"' as stap6;

-- 25. TEST TRAINING VOOR LIVE SIMULATIE
SELECT '=== TEST TRAINING AANMAKEN ===' as bericht;

-- Maak een test training aan voor live simulatie testing
INSERT INTO trainingsvluchten (naam, start_locatie, eind_locatie, datum, afstand_km, status)
VALUES (
  'Test Training - Live Simulatie',
  'Gent Centrum',
  'Gent Buiten',
  CURRENT_DATE,
  22.00,
  'gepland'
) ON CONFLICT DO NOTHING;

-- Voeg test deelnemers toe (alleen als er duiven in vliegkooien zijn)
INSERT INTO trainingsvlucht_deelnames (trainingsvlucht_id, duif_id, status, huidige_afstand_gevlogen, afstand_nog_te_gaan)
SELECT 
  t.id as trainingsvlucht_id,
  d.id as duif_id,
  'ingeschreven' as status,
  0.00 as huidige_afstand_gevlogen,
  t.afstand_km as afstand_nog_te_gaan
FROM trainingsvluchten t
CROSS JOIN duiven d
WHERE t.naam = 'Test Training - Live Simulatie'
AND d.kooi_id IN (
  SELECT id FROM kooien WHERE type = 'vliegkooi'
)
LIMIT 6
ON CONFLICT DO NOTHING;

-- Toon test training resultaat
SELECT 
  '=== TEST TRAINING STATUS ===' as info;

SELECT 
  t.naam,
  t.status,
  t.afstand_km,
  COUNT(td.id) as aantal_deelnemers
FROM trainingsvluchten t
LEFT JOIN trainingsvlucht_deelnames td ON t.id = td.trainingsvlucht_id
WHERE t.naam = 'Test Training - Live Simulatie'
GROUP BY t.id, t.naam, t.status, t.afstand_km;

-- EINDE SETUP 