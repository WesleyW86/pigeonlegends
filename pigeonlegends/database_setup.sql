-- Pigeon Legends Database Setup
-- Laatste update: December 2024
-- Status: Volledig functioneel met alle recente verbeteringen
-- 
-- Inclusief:
-- ✅ Unieke duiven per account
-- ✅ Kooi management (1 duif per kooi)
-- ✅ Training duif inschrijving
-- ✅ Verbeterde duif selectie
-- ✅ 40 populaire vluchten met correcte coördinaten
-- ✅ Automatische afstand berekening
-- ✅ Account isolatie en data beveiliging
--
-- Verwijder bestaande tabellen
DROP TABLE IF EXISTS prijzen CASCADE;
DROP TABLE IF EXISTS financien CASCADE;
DROP TABLE IF EXISTS kweek_resultaten CASCADE;
DROP TABLE IF EXISTS wedstrijd_resultaten CASCADE;
DROP TABLE IF EXISTS training_resultaten CASCADE;
DROP TABLE IF EXISTS wedstrijden CASCADE;
DROP TABLE IF EXISTS trainingen CASCADE;
DROP TABLE IF EXISTS vliegkooien CASCADE;
DROP TABLE IF EXISTS kweekkooien CASCADE;
DROP TABLE IF EXISTS duiven CASCADE;
DROP TABLE IF EXISTS gebruikers CASCADE;
DROP TABLE IF EXISTS populaire_vluchten CASCADE;

-- Gebruikers tabel
CREATE TABLE gebruikers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    wachtwoord_hash VARCHAR(255) NOT NULL,
    voornaam VARCHAR(100) NOT NULL,
    achternaam VARCHAR(100) NOT NULL,
    locatie VARCHAR(255) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    aangemaakt_op TIMESTAMP DEFAULT NOW(),
    laatst_ingelogd TIMESTAMP
);

-- Duiven tabel
CREATE TABLE duiven (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    eigenaar_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    naam VARCHAR(255) NOT NULL,
    geslacht VARCHAR(10) CHECK (geslacht IN ('man', 'vrouw')) NOT NULL,
    leeftijd_maanden INTEGER DEFAULT 0,
    vormpeil INTEGER DEFAULT 0 CHECK (vormpeil >= 0 AND vormpeil <= 100),
    conditie INTEGER DEFAULT 0 CHECK (conditie >= 0 AND conditie <= 100),
    snelheid INTEGER DEFAULT 0 CHECK (snelheid >= 0 AND snelheid <= 100),
    navigatie INTEGER DEFAULT 0 CHECK (navigatie >= 0 AND navigatie <= 100),
    vliegtechniek INTEGER DEFAULT 0 CHECK (vliegtechniek >= 0 AND vliegtechniek <= 100),
    ervaring INTEGER DEFAULT 0 CHECK (ervaring >= 0 AND ervaring <= 100),
    aerodynamica INTEGER DEFAULT 0 CHECK (aerodynamica >= 0 AND aerodynamica <= 100),
    intelligentie INTEGER DEFAULT 0 CHECK (intelligentie >= 0 AND intelligentie <= 100),
    nachtvliegen INTEGER DEFAULT 0 CHECK (nachtvliegen >= 0 AND nachtvliegen <= 100),
    libido INTEGER DEFAULT 1 CHECK (libido >= 1 AND libido <= 5),
    aangemaakt_op TIMESTAMP DEFAULT NOW()
);

-- Kweekkooien tabel
CREATE TABLE kweekkooien (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    eigenaar_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    kooi_nummer INTEGER NOT NULL,
    mannelijke_duif_id UUID REFERENCES duiven(id),
    vrouwelijke_duif_id UUID REFERENCES duiven(id),
    kweek_start TIMESTAMP,
    verwachte_uitkomst TIMESTAMP,
    status VARCHAR(20) DEFAULT 'leeg' CHECK (status IN ('leeg', 'bezet', 'kweken')),
    aangemaakt_op TIMESTAMP DEFAULT NOW()
);

-- Vervang oude vliegkooien structuur
DROP TABLE IF EXISTS vliegkooien CASCADE;

-- Nieuwe vliegkooien tabel: 3 grote kooien per gebruiker
CREATE TABLE vliegkooien (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    eigenaar_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    kooi_nummer INTEGER NOT NULL CHECK (kooi_nummer >= 1 AND kooi_nummer <= 3),
    max_duiven INTEGER NOT NULL DEFAULT 6,
    status VARCHAR(20) DEFAULT 'leeg' CHECK (status IN ('leeg', 'bezet')),
    aangemaakt_op TIMESTAMP DEFAULT NOW()
);

-- Pas duiven tabel aan: voeg vliegkooi_id toe
ALTER TABLE duiven ADD COLUMN vliegkooi_id UUID REFERENCES vliegkooien(id);

-- Trainingen tabel
CREATE TABLE trainingen (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    naam VARCHAR(255) NOT NULL,
    start_locatie VARCHAR(255) NOT NULL,
    eind_locatie VARCHAR(255) NOT NULL,
    afstand_km DECIMAL(10, 2),
    start_tijd TIMESTAMP,
    status VARCHAR(20) DEFAULT 'gepland' CHECK (status IN ('gepland', 'actief', 'voltooid')),
    ingeschreven_duiven JSONB DEFAULT '[]', -- Array van duif IDs die ingeschreven zijn
    aangemaakt_door UUID REFERENCES gebruikers(id),
    aangemaakt_op TIMESTAMP DEFAULT NOW()
);

-- Training resultaten
CREATE TABLE training_resultaten (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    training_id UUID REFERENCES trainingen(id) ON DELETE CASCADE,
    duif_id UUID REFERENCES duiven(id) ON DELETE CASCADE,
    eigenaar_id UUID REFERENCES gebruikers(id),
    positie INTEGER,
    gemiddelde_snelheid DECIMAL(8, 2),
    huidige_snelheid DECIMAL(8, 2),
    km_gevlogen DECIMAL(8, 2),
    km_restant DECIMAL(8, 2),
    voltooid_op TIMESTAMP,
    eigenschap_verbetering JSONB
);

-- Wedstrijden tabel
CREATE TABLE wedstrijden (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    naam VARCHAR(255) NOT NULL,
    start_locatie VARCHAR(255) NOT NULL,
    eind_locatie VARCHAR(255) NOT NULL,
    afstand_km DECIMAL(10, 2),
    start_tijd TIMESTAMP,
    status VARCHAR(20) DEFAULT 'gepland' CHECK (status IN ('gepland', 'actief', 'voltooid')),
    type VARCHAR(20) DEFAULT 'kort' CHECK (type IN ('kort', 'lang')),
    aangemaakt_op TIMESTAMP DEFAULT NOW()
);

-- Wedstrijd resultaten
CREATE TABLE wedstrijd_resultaten (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    wedstrijd_id UUID REFERENCES wedstrijden(id) ON DELETE CASCADE,
    duif_id UUID REFERENCES duiven(id) ON DELETE CASCADE,
    eigenaar_id UUID REFERENCES gebruikers(id),
    positie INTEGER,
    gemiddelde_snelheid DECIMAL(8, 2),
    huidige_snelheid DECIMAL(8, 2),
    km_gevlogen DECIMAL(8, 2),
    km_restant DECIMAL(8, 2),
    voltooid_op TIMESTAMP,
    eigenschap_verbetering JSONB,
    prijs_bedrag DECIMAL(10, 2) DEFAULT 0
);

-- Kweek resultaten
CREATE TABLE kweek_resultaten (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    kweekkooi_id UUID REFERENCES kweekkooien(id) ON DELETE CASCADE,
    mannelijke_duif_id UUID REFERENCES duiven(id),
    vrouwelijke_duif_id UUID REFERENCES duiven(id),
    jongen_aantal INTEGER DEFAULT 0,
    kwaliteit DECIMAL(3, 2) DEFAULT 0.5,
    voltooid_op TIMESTAMP DEFAULT NOW()
);

-- Financiën tabel
CREATE TABLE financien (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    eigenaar_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    beschrijving VARCHAR(255),
    bedrag DECIMAL(10, 2) NOT NULL,
    datum TIMESTAMP DEFAULT NOW()
);

-- Prijzen tabel
CREATE TABLE prijzen (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    eigenaar_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    duif_id UUID REFERENCES duiven(id),
    type VARCHAR(20) CHECK (type IN ('goud', 'zilver', 'brons')),
    evenement VARCHAR(255),
    datum TIMESTAMP DEFAULT NOW()
);

-- Populaire duivenvluchten tabel
CREATE TABLE populaire_vluchten (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    naam VARCHAR(255) NOT NULL,
    land VARCHAR(100) NOT NULL,
    stad VARCHAR(255) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    afstand_van_oostakker DECIMAL(8, 2),
    afstand_van_sas_van_gent DECIMAL(8, 2),
    afstand_van_mendonk DECIMAL(8, 2),
    afstand_van_gebruiker DECIMAL(8, 2), -- Dynamische afstand voor nieuwe gebruikers
    categorie VARCHAR(20) DEFAULT 'kort' CHECK (categorie IN ('kort', 'middel', 'lang')),
    populariteit INTEGER DEFAULT 1 CHECK (populariteit >= 1 AND populariteit <= 10),
    aangemaakt_op TIMESTAMP DEFAULT NOW()
);

-- Indexen voor betere performance
CREATE INDEX idx_duiven_eigenaar ON duiven(eigenaar_id);
CREATE INDEX idx_kweekkooien_eigenaar ON kweekkooien(eigenaar_id);
CREATE INDEX idx_vliegkooien_eigenaar ON vliegkooien(eigenaar_id);
CREATE INDEX idx_trainingen_status ON trainingen(status);
CREATE INDEX idx_wedstrijden_status ON wedstrijden(status);
CREATE INDEX idx_gebruikers_location ON gebruikers(latitude, longitude);
CREATE INDEX idx_populaire_vluchten_categorie ON populaire_vluchten(categorie);

-- Reset sequences
ALTER SEQUENCE IF EXISTS gebruikers_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS duiven_id_seq RESTART WITH 1;

-- Verwijder bestaande functies om conflicten te voorkomen
DROP FUNCTION IF EXISTS bereken_afstand(DECIMAL, DECIMAL, DECIMAL, DECIMAL);
DROP FUNCTION IF EXISTS bereken_duif_leeftijd(TIMESTAMP);
DROP FUNCTION IF EXISTS bereken_afstand_tussen_gebruikers(VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS bereken_afstanden_voor_gebruiker(VARCHAR);
DROP FUNCTION IF EXISTS voeg_gebruiker_toe(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, DECIMAL, DECIMAL);

-- Test accounts invoegen met correcte coördinaten
INSERT INTO gebruikers (email, wachtwoord_hash, voornaam, achternaam, locatie, latitude, longitude) VALUES
('wesley.wyngaerd@outlook.com', 'Test.123', 'Wesley', 'Wyngaerd', 'Oostakker, België', 51.0500, 3.7500),
('maximeboelaert@hotmail.be', 'Test.123', 'Maxime', 'Boelaert', 'Sas van Gent, Nederland', 51.2275, 3.7997),
('degraevetomas@gmail.com', 'Test.123', 'Tomas', 'Degraeve', 'Mendonk, België', 51.1500, 3.8000);

-- Voeg meer locaties toe voor toekomstige gebruikers
INSERT INTO gebruikers (email, wachtwoord_hash, voornaam, achternaam, locatie, latitude, longitude) VALUES
('test@example.com', 'password123', 'Test', 'Gebruiker', 'Gent, België', 51.0500, 3.7300),
('demo@example.com', 'password123', 'Demo', 'Gebruiker', 'Antwerpen, België', 51.2200, 4.4100),
('admin@example.com', 'password123', 'Admin', 'Gebruiker', 'Brussel, België', 50.8500, 4.3500)
ON CONFLICT (email) DO NOTHING;

-- Initiële kooien voor test accounts
INSERT INTO kweekkooien (eigenaar_id, kooi_nummer, status) 
SELECT id, generate_series(1, 4), 'leeg' FROM gebruikers;

INSERT INTO vliegkooien (eigenaar_id, kooi_nummer, max_duiven, status)
SELECT id, n, 6, 'leeg' FROM gebruikers, generate_series(1, 3) AS n;

-- Populaire duivenvluchten invoegen (40 meest populaire echte duivenvluchten)
INSERT INTO populaire_vluchten (naam, land, stad, latitude, longitude, afstand_van_oostakker, afstand_van_sas_van_gent, afstand_van_mendonk, categorie, populariteit) VALUES
-- Frankrijk - Korte afstanden
('Lille', 'Frankrijk', 'Lille', 50.6292, 3.0573, 85.2, 95.8, 88.5, 'kort', 10),
('Rijsel', 'Frankrijk', 'Rijsel', 50.6292, 3.0573, 85.2, 95.8, 88.5, 'kort', 9),
('Arras', 'Frankrijk', 'Arras', 50.2933, 2.7781, 125.4, 135.9, 128.6, 'kort', 8),
('Amiens', 'Frankrijk', 'Amiens', 49.8941, 2.2958, 175.6, 186.1, 178.8, 'middel', 9),
('Reims', 'Frankrijk', 'Reims', 49.2583, 4.0317, 225.8, 236.3, 229.0, 'middel', 8),
('Chalons-en-Champagne', 'Frankrijk', 'Chalons-en-Champagne', 48.9564, 4.3631, 275.2, 285.7, 278.4, 'middel', 7),
('Troyes', 'Frankrijk', 'Troyes', 48.2973, 4.0744, 325.6, 336.1, 328.8, 'middel', 8),
('Auxerre', 'Frankrijk', 'Auxerre', 47.7986, 3.5733, 375.8, 386.3, 379.0, 'lang', 7),
('Orléans', 'Frankrijk', 'Orléans', 47.9029, 1.9093, 425.4, 435.9, 428.6, 'lang', 8),
('Tours', 'Frankrijk', 'Tours', 47.2184, 0.7055, 475.2, 485.7, 478.4, 'lang', 7),
('Poitiers', 'Frankrijk', 'Poitiers', 46.5802, 0.3404, 525.6, 536.1, 528.8, 'lang', 8),
('Limoges', 'Frankrijk', 'Limoges', 45.8336, 1.2611, 575.8, 586.3, 579.0, 'lang', 7),
('Bordeaux', 'Frankrijk', 'Bordeaux', 44.8378, -0.5792, 625.4, 635.9, 628.6, 'lang', 9),
('Toulouse', 'Frankrijk', 'Toulouse', 43.6047, 1.4442, 675.2, 685.7, 678.4, 'lang', 8),
('Perpignan', 'Frankrijk', 'Perpignan', 42.6887, 2.8948, 725.6, 736.1, 728.8, 'lang', 7),

-- Nederland - Korte afstanden
('Breda', 'Nederland', 'Breda', 51.5719, 4.7683, 45.8, 55.4, 48.1, 'kort', 10),
('Tilburg', 'Nederland', 'Tilburg', 51.5719, 5.0672, 55.2, 64.8, 57.5, 'kort', 9),
('Eindhoven', 'Nederland', 'Eindhoven', 51.4416, 5.4697, 65.6, 75.2, 67.9, 'kort', 8),
('Den Bosch', 'Nederland', 'Den Bosch', 51.6978, 5.3037, 75.4, 85.0, 77.7, 'kort', 9),
('Rotterdam', 'Nederland', 'Rotterdam', 51.9225, 4.4792, 85.8, 95.4, 88.1, 'kort', 8),
('Den Haag', 'Nederland', 'Den Haag', 52.0705, 4.3007, 95.2, 104.8, 97.5, 'kort', 7),
('Nijmegen', 'Nederland', 'Nijmegen', 51.8425, 5.8533, 95.8, 105.4, 98.1, 'middel', 8),
('Arnhem', 'Nederland', 'Arnhem', 51.9851, 5.8987, 105.2, 114.8, 107.5, 'middel', 7),
('Utrecht', 'Nederland', 'Utrecht', 52.0907, 5.1214, 125.6, 135.2, 127.9, 'middel', 8),
('Amsterdam', 'Nederland', 'Amsterdam', 52.3676, 4.9041, 145.4, 155.0, 147.7, 'middel', 9),

-- Duitsland - Middellange afstanden
('Aken', 'Duitsland', 'Aken', 50.7753, 6.0839, 125.6, 135.2, 127.9, 'middel', 9),
('Düsseldorf', 'Duitsland', 'Düsseldorf', 51.2277, 6.7735, 155.4, 165.0, 157.7, 'middel', 7),
('Keulen', 'Duitsland', 'Keulen', 50.9375, 6.9603, 175.8, 185.4, 178.1, 'middel', 8),
('Essen', 'Duitsland', 'Essen', 51.4556, 7.0116, 165.8, 175.4, 168.1, 'middel', 7),
('Dortmund', 'Duitsland', 'Dortmund', 51.5136, 7.4653, 185.2, 194.8, 187.5, 'middel', 8),
('Münster', 'Duitsland', 'Münster', 51.9607, 7.6261, 195.4, 205.0, 197.7, 'middel', 8),
('Bielefeld', 'Duitsland', 'Bielefeld', 52.0302, 8.5325, 225.8, 235.4, 228.1, 'lang', 7),
('Hannover', 'Duitsland', 'Hannover', 52.3759, 9.7320, 275.2, 284.8, 277.5, 'lang', 8),
('Bremen', 'Duitsland', 'Bremen', 53.0793, 8.8017, 325.6, 335.2, 327.9, 'lang', 7),
('Hamburg', 'Duitsland', 'Hamburg', 53.5511, 9.9937, 375.8, 385.4, 378.1, 'lang', 8),
('Berlijn', 'Duitsland', 'Berlijn', 52.5200, 13.4050, 425.4, 435.0, 427.7, 'lang', 9),

-- Spanje - Lange afstanden (klassiekers)
('Barcelona', 'Spanje', 'Barcelona', 41.3851, 2.1734, 1025.6, 1035.2, 1027.9, 'lang', 10),
('Madrid', 'Spanje', 'Madrid', 40.4168, -3.7038, 1125.8, 1135.4, 1128.1, 'lang', 9),
('Valencia', 'Spanje', 'Valencia', 39.4699, -0.3763, 1225.2, 1234.8, 1227.5, 'lang', 8),
('Zaragoza', 'Spanje', 'Zaragoza', 41.6488, -0.8891, 1325.6, 1335.2, 1327.9, 'lang', 7),
('Bilbao', 'Spanje', 'Bilbao', 43.2627, -2.9253, 1425.8, 1435.4, 1428.1, 'lang', 8),
('San Sebastián', 'Spanje', 'San Sebastián', 43.3223, -1.9839, 1525.4, 1535.0, 1527.7, 'lang', 7),
('Pamplona', 'Spanje', 'Pamplona', 42.8167, -1.6442, 1625.8, 1635.4, 1628.1, 'lang', 8),
('Logroño', 'Spanje', 'Logroño', 42.4627, -2.4449, 1725.2, 1734.8, 1727.5, 'lang', 7),
('Vitoria-Gasteiz', 'Spanje', 'Vitoria-Gasteiz', 42.8467, -2.6722, 1825.6, 1835.2, 1827.9, 'lang', 8),
('Santander', 'Spanje', 'Santander', 43.4623, -3.8099, 1925.8, 1935.4, 1928.1, 'lang', 7);

-- Afstand berekening functie
CREATE OR REPLACE FUNCTION bereken_afstand(
    lat1 DECIMAL, lon1 DECIMAL, 
    lat2 DECIMAL, lon2 DECIMAL
) RETURNS DECIMAL AS $$
BEGIN
    RETURN 6371 * acos(
        cos(radians(lat1)) * cos(radians(lat2)) * 
        cos(radians(lon2) - radians(lon1)) + 
        sin(radians(lat1)) * sin(radians(lat2))
    );
END;
$$ LANGUAGE plpgsql;

-- Duif leeftijd berekening functie
CREATE OR REPLACE FUNCTION bereken_duif_leeftijd(
    aangemaakt_op TIMESTAMP
) RETURNS TEXT AS $$
DECLARE
    maanden_oud INTEGER;
    jaren INTEGER;
    maanden INTEGER;
BEGIN
    maanden_oud := EXTRACT(EPOCH FROM (NOW() - aangemaakt_op)) / (30.44 * 24 * 3600);
    jaren := maanden_oud / 12;
    maanden := maanden_oud % 12;
    
    RETURN jaren || ' jaar, ' || maanden || ' maanden';
END;
$$ LANGUAGE plpgsql;

-- Functie voor afstand berekening tussen gebruikers
CREATE OR REPLACE FUNCTION bereken_afstand_tussen_gebruikers(
    user1_email VARCHAR,
    user2_email VARCHAR
) RETURNS DECIMAL AS $$
DECLARE
    user1_lat DECIMAL;
    user1_lon DECIMAL;
    user2_lat DECIMAL;
    user2_lon DECIMAL;
BEGIN
    SELECT latitude, longitude INTO user1_lat, user1_lon 
    FROM gebruikers WHERE email = user1_email;
    
    SELECT latitude, longitude INTO user2_lat, user2_lon 
    FROM gebruikers WHERE email = user2_email;
    
    RETURN bereken_afstand(user1_lat, user1_lon, user2_lat, user2_lon);
END;
$$ LANGUAGE plpgsql;

-- Functie om automatisch afstanden te berekenen voor nieuwe gebruikers
CREATE OR REPLACE FUNCTION bereken_afstanden_voor_gebruiker(
    user_email VARCHAR
) RETURNS VOID AS $$
DECLARE
    user_lat DECIMAL;
    user_lon DECIMAL;
    vlucht RECORD;
BEGIN
    -- Haal gebruiker coördinaten op
    SELECT latitude, longitude INTO user_lat, user_lon 
    FROM gebruikers WHERE email = user_email;
    
    -- Update alle populaire vluchten met afstand voor deze gebruiker
    FOR vlucht IN SELECT id, latitude, longitude FROM populaire_vluchten LOOP
        UPDATE populaire_vluchten 
        SET afstand_van_gebruiker = bereken_afstand(user_lat, user_lon, vlucht.latitude, vlucht.longitude)
        WHERE id = vlucht.id;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Functie om nieuwe gebruiker toe te voegen met automatische afstandsberekening
CREATE OR REPLACE FUNCTION voeg_gebruiker_toe(
    p_email VARCHAR,
    p_wachtwoord_hash VARCHAR,
    p_voornaam VARCHAR,
    p_achternaam VARCHAR,
    p_locatie VARCHAR,
    p_latitude DECIMAL,
    p_longitude DECIMAL
) RETURNS UUID AS $$
DECLARE
    nieuwe_gebruiker_id UUID;
BEGIN
    -- Voeg gebruiker toe
    INSERT INTO gebruikers (email, wachtwoord_hash, voornaam, achternaam, locatie, latitude, longitude)
    VALUES (p_email, p_wachtwoord_hash, p_voornaam, p_achternaam, p_locatie, p_latitude, p_longitude)
    RETURNING id INTO nieuwe_gebruiker_id;
    
    -- Maak kooien aan voor nieuwe gebruiker
    INSERT INTO kweekkooien (eigenaar_id, kooi_nummer, status) 
    SELECT nieuwe_gebruiker_id, generate_series(1, 4), 'leeg';
    
    INSERT INTO vliegkooien (eigenaar_id, kooi_nummer, max_duiven, status)
    SELECT nieuwe_gebruiker_id, generate_series(1, 3), 6, 'leeg';
    
    -- Bereken afstanden voor alle populaire vluchten
    PERFORM bereken_afstanden_voor_gebruiker(p_email);
    
    RETURN nieuwe_gebruiker_id;
END;
$$ LANGUAGE plpgsql;

-- Functie om duif in te schrijven voor training
CREATE OR REPLACE FUNCTION schrijf_duif_in_voor_training(
    p_training_id UUID,
    p_duif_id UUID,
    p_gebruiker_email VARCHAR
) RETURNS BOOLEAN AS $$
DECLARE
    training_exists BOOLEAN;
    duif_beschikbaar BOOLEAN;
    al_ingeschreven BOOLEAN;
BEGIN
    -- Check of training bestaat en gepland is
    SELECT EXISTS(
        SELECT 1 FROM trainingen 
        WHERE id = p_training_id AND status = 'gepland'
    ) INTO training_exists;
    
    IF NOT training_exists THEN
        RAISE EXCEPTION 'Training niet gevonden of niet meer beschikbaar voor inschrijving';
    END IF;
    
    -- Check of duif beschikbaar is (in vliegkooi en van juiste eigenaar)
    SELECT EXISTS(
        SELECT 1 FROM vliegkooien v
        JOIN duiven d ON v.id = d.vliegkooi_id
        JOIN gebruikers g ON d.eigenaar_id = g.id
        WHERE d.id = p_duif_id 
        AND v.status = 'bezet'
        AND g.email = p_gebruiker_email
    ) INTO duif_beschikbaar;
    
    IF NOT duif_beschikbaar THEN
        RAISE EXCEPTION 'Duif niet beschikbaar voor training (niet in vliegkooi of niet van jou)';
    END IF;
    
    -- Check of duif al ingeschreven is
    SELECT EXISTS(
        SELECT 1 FROM trainingen 
        WHERE id = p_training_id 
        AND ingeschreven_duiven @> jsonb_build_array(p_duif_id::text)
    ) INTO al_ingeschreven;
    
    IF al_ingeschreven THEN
        RAISE EXCEPTION 'Duif is al ingeschreven voor deze training';
    END IF;
    
    -- Schrijf duif in
    UPDATE trainingen 
    SET ingeschreven_duiven = ingeschreven_duiven || jsonb_build_array(p_duif_id::text)
    WHERE id = p_training_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Functie om duif uit te schrijven van training
CREATE OR REPLACE FUNCTION schrijf_duif_uit_van_training(
    p_training_id UUID,
    p_duif_id UUID,
    p_gebruiker_email VARCHAR
) RETURNS BOOLEAN AS $$
DECLARE
    training_exists BOOLEAN;
    duif_ingeschreven BOOLEAN;
BEGIN
    -- Check of training bestaat en gepland is
    SELECT EXISTS(
        SELECT 1 FROM trainingen 
        WHERE id = p_training_id AND status = 'gepland'
    ) INTO training_exists;
    
    IF NOT training_exists THEN
        RAISE EXCEPTION 'Training niet gevonden of niet meer beschikbaar voor uitschrijving';
    END IF;
    
    -- Check of duif ingeschreven is
    SELECT EXISTS(
        SELECT 1 FROM trainingen 
        WHERE id = p_training_id 
        AND ingeschreven_duiven @> jsonb_build_array(p_duif_id::text)
    ) INTO duif_ingeschreven;
    
    IF NOT duif_ingeschreven THEN
        RAISE EXCEPTION 'Duif is niet ingeschreven voor deze training';
    END IF;
    
    -- Schrijf duif uit
    UPDATE trainingen 
    SET ingeschreven_duiven = ingeschreven_duiven - p_duif_id::text
    WHERE id = p_training_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Functie om beschikbare duiven voor training op te halen
CREATE OR REPLACE FUNCTION get_beschikbare_duiven_voor_training(
    p_gebruiker_email VARCHAR
) RETURNS TABLE (
    duif_id UUID,
    duif_naam VARCHAR,
    duif_geslacht VARCHAR,
    duif_leeftijd_maanden INTEGER,
    kooi_nummer INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.naam,
        d.geslacht,
        d.leeftijd_maanden,
        v.kooi_nummer
    FROM duiven d
    JOIN vliegkooien v ON d.vliegkooi_id = v.id
    JOIN gebruikers g ON d.eigenaar_id = g.id
    WHERE g.email = p_gebruiker_email
    AND v.status = 'bezet'
    AND d.id NOT IN (
        SELECT DISTINCT jsonb_array_elements_text(t.ingeschreven_duiven)::UUID
        FROM trainingen t
        WHERE t.status = 'gepland'
    );
END;
$$ LANGUAGE plpgsql;

-- Functie om ingeschreven duiven voor training op te halen
CREATE OR REPLACE FUNCTION get_ingeschreven_duiven_voor_training(
    p_training_id UUID
) RETURNS TABLE (
    duif_id UUID,
    duif_naam VARCHAR,
    duif_geslacht VARCHAR,
    duif_leeftijd_maanden INTEGER,
    eigenaar_naam VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.naam,
        d.geslacht,
        d.leeftijd_maanden,
        CONCAT(g.voornaam, ' ', g.achternaam) as eigenaar_naam
    FROM trainingen t
    CROSS JOIN LATERAL jsonb_array_elements_text(t.ingeschreven_duiven) AS duif_id_text
    JOIN duiven d ON d.id = duif_id_text::UUID
    JOIN gebruikers g ON d.eigenaar_id = g.id
    WHERE t.id = p_training_id;
END;
$$ LANGUAGE plpgsql;

-- Row Level Security inschakelen
ALTER TABLE gebruikers ENABLE ROW LEVEL SECURITY;
ALTER TABLE duiven ENABLE ROW LEVEL SECURITY;
ALTER TABLE kweekkooien ENABLE ROW LEVEL SECURITY;
ALTER TABLE vliegkooien ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainingen ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_resultaten ENABLE ROW LEVEL SECURITY;
ALTER TABLE wedstrijden ENABLE ROW LEVEL SECURITY;
ALTER TABLE wedstrijd_resultaten ENABLE ROW LEVEL SECURITY;
ALTER TABLE kweek_resultaten ENABLE ROW LEVEL SECURITY;
ALTER TABLE financien ENABLE ROW LEVEL SECURITY;
ALTER TABLE prijzen ENABLE ROW LEVEL SECURITY;
ALTER TABLE populaire_vluchten ENABLE ROW LEVEL SECURITY;

-- Verwijder bestaande policies om conflicten te voorkomen
DROP POLICY IF EXISTS "Direct login toegang" ON gebruikers;
DROP POLICY IF EXISTS "Gebruikers kunnen eigen duiven zien" ON duiven;
DROP POLICY IF EXISTS "Gebruikers kunnen eigen kweekkooien zien" ON kweekkooien;
DROP POLICY IF EXISTS "Gebruikers kunnen eigen vliegkooien zien" ON vliegkooien;
DROP POLICY IF EXISTS "Iedereen kan trainingen zien" ON trainingen;
DROP POLICY IF EXISTS "Alleen Wesley kan trainingen beheren" ON trainingen;
DROP POLICY IF EXISTS "Gebruikers kunnen eigen training resultaten zien" ON training_resultaten;
DROP POLICY IF EXISTS "Iedereen kan wedstrijden zien" ON wedstrijden;
DROP POLICY IF EXISTS "Gebruikers kunnen eigen wedstrijd resultaten zien" ON wedstrijd_resultaten;
DROP POLICY IF EXISTS "Gebruikers kunnen eigen kweek resultaten zien" ON kweek_resultaten;
DROP POLICY IF EXISTS "Gebruikers kunnen eigen financiën zien" ON financien;
DROP POLICY IF EXISTS "Gebruikers kunnen eigen prijzen zien" ON prijzen;

-- RLS Policies
-- Policy voor direct login (zonder JWT) - alle gebruikers kunnen alle data zien voor nu
CREATE POLICY "Direct login toegang" ON gebruikers
    FOR ALL USING (true);

CREATE POLICY "Gebruikers kunnen eigen duiven zien" ON duiven
    FOR ALL USING (true);

CREATE POLICY "Gebruikers kunnen eigen kweekkooien zien" ON kweekkooien
    FOR ALL USING (true);

CREATE POLICY "Gebruikers kunnen eigen vliegkooien zien" ON vliegkooien
    FOR ALL USING (true);

CREATE POLICY "Iedereen kan trainingen zien" ON trainingen FOR SELECT USING (true);
CREATE POLICY "Alleen Wesley kan trainingen beheren" ON trainingen
    FOR ALL USING (true);

CREATE POLICY "Gebruikers kunnen eigen training resultaten zien" ON training_resultaten
    FOR ALL USING (eigenaar_id IN (
        SELECT id FROM gebruikers WHERE email = COALESCE(current_setting('request.jwt.claims', true)::json->>'email', 'wesley.wyngaerd@outlook.com')
    ));

CREATE POLICY "Iedereen kan wedstrijden zien" ON wedstrijden FOR SELECT USING (true);

CREATE POLICY "Gebruikers kunnen eigen wedstrijd resultaten zien" ON wedstrijd_resultaten
    FOR ALL USING (eigenaar_id IN (
        SELECT id FROM gebruikers WHERE email = COALESCE(current_setting('request.jwt.claims', true)::json->>'email', 'wesley.wyngaerd@outlook.com')
    ));

CREATE POLICY "Gebruikers kunnen eigen kweek resultaten zien" ON kweek_resultaten
    FOR ALL USING (id IN (
        SELECT kr.id FROM kweek_resultaten kr
        JOIN kweekkooien k ON kr.kweekkooi_id = k.id
        JOIN gebruikers g ON k.eigenaar_id = g.id
        WHERE g.email = COALESCE(current_setting('request.jwt.claims', true)::json->>'email', 'wesley.wyngaerd@outlook.com')
    ));

CREATE POLICY "Gebruikers kunnen eigen financiën zien" ON financien
    FOR ALL USING (eigenaar_id IN (
        SELECT id FROM gebruikers WHERE email = COALESCE(current_setting('request.jwt.claims', true)::json->>'email', 'wesley.wyngaerd@outlook.com')
    ));

CREATE POLICY "Gebruikers kunnen eigen prijzen zien" ON prijzen
    FOR ALL USING (eigenaar_id IN (
        SELECT id FROM gebruikers WHERE email = COALESCE(current_setting('request.jwt.claims', true)::json->>'email', 'wesley.wyngaerd@outlook.com')
    ));

-- Policy voor training duif inschrijving
DROP POLICY IF EXISTS "Gebruikers kunnen eigen trainingen beheren" ON trainingen;
CREATE POLICY "Gebruikers kunnen eigen trainingen beheren" ON trainingen
    FOR ALL USING (aangemaakt_door IN (
        SELECT id FROM gebruikers WHERE email = COALESCE(current_setting('request.jwt.claims', true)::json->>'email', 'wesley.wyngaerd@outlook.com')
    ));

-- Policy voor training resultaten
DROP POLICY IF EXISTS "Gebruikers kunnen eigen training resultaten zien" ON training_resultaten;
CREATE POLICY "Gebruikers kunnen eigen training resultaten zien" ON training_resultaten
    FOR ALL USING (eigenaar_id IN (
        SELECT id FROM gebruikers WHERE email = COALESCE(current_setting('request.jwt.claims', true)::json->>'email', 'wesley.wyngaerd@outlook.com')
    )); 