-- Database setup voor Pigeon Legends
-- Voer dit uit in Supabase SQL Editor

-- 1. Gebruikers tabel
DROP TABLE IF EXISTS competition_participants CASCADE;
DROP TABLE IF EXISTS training_participants CASCADE;
DROP TABLE IF EXISTS competitions CASCADE;
DROP TABLE IF EXISTS trainings CASCADE;
DROP TABLE IF EXISTS lofts CASCADE;
DROP TABLE IF EXISTS pigeons CASCADE;
DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    team_name VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Duiven tabel (geüpdatet met alle eigenschappen)
CREATE TABLE pigeons (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    gender VARCHAR(10) CHECK (gender IN ('Mannetje', 'Vrouwtje')),
    age_years INTEGER DEFAULT 0,
    age_months INTEGER DEFAULT 0,
    energy INTEGER DEFAULT 100,
    vormpijl INTEGER DEFAULT 0,
    snelheid INTEGER DEFAULT 0,
    conditie INTEGER DEFAULT 0,
    techniek INTEGER DEFAULT 0,
    orientatie INTEGER DEFAULT 0,
    ervaring INTEGER DEFAULT 0,
    aerodynamica INTEGER DEFAULT 0,
    intelligentie INTEGER DEFAULT 0,
    nachtvliegen INTEGER DEFAULT 0,
    libido INTEGER DEFAULT 1,
    talent VARCHAR(50) DEFAULT 'Onbekend',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Duiventillen tabel
CREATE TABLE lofts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    capacity INTEGER DEFAULT 10,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Trainingen tabel
CREATE TABLE trainings (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    distance_km INTEGER NOT NULL,
    start_location VARCHAR(255) NOT NULL,
    end_location VARCHAR(255) NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) DEFAULT 'Gepland' CHECK (status IN ('Gepland', 'Actief', 'Voltooid')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Wedstrijden tabel
CREATE TABLE competitions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    distance_km INTEGER NOT NULL,
    start_location VARCHAR(255) NOT NULL,
    end_location VARCHAR(255) NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) DEFAULT 'Gepland' CHECK (status IN ('Gepland', 'Actief', 'Voltooid')),
    prize_money DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Deelnemers aan trainingen
CREATE TABLE training_participants (
    id SERIAL PRIMARY KEY,
    training_id INTEGER REFERENCES trainings(id) ON DELETE CASCADE,
    pigeon_id INTEGER REFERENCES pigeons(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    finish_time TIMESTAMP WITH TIME ZONE,
    finish_position INTEGER,
    average_speed DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Deelnemers aan wedstrijden
CREATE TABLE competition_participants (
    id SERIAL PRIMARY KEY,
    competition_id INTEGER REFERENCES competitions(id) ON DELETE CASCADE,
    pigeon_id INTEGER REFERENCES pigeons(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    finish_time TIMESTAMP WITH TIME ZONE,
    finish_position INTEGER,
    average_speed DECIMAL(5,2),
    prize_won DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Verwijder alle bestaande data en voeg test gebruikers toe
DELETE FROM competition_participants;
DELETE FROM training_participants;
DELETE FROM competitions;
DELETE FROM trainings;
DELETE FROM lofts;
DELETE FROM pigeons;
DELETE FROM users;

-- Reset alle auto-increment counters
ALTER SEQUENCE users_id_seq RESTART WITH 1;
ALTER SEQUENCE pigeons_id_seq RESTART WITH 1;
ALTER SEQUENCE lofts_id_seq RESTART WITH 1;
ALTER SEQUENCE trainings_id_seq RESTART WITH 1;
ALTER SEQUENCE competitions_id_seq RESTART WITH 1;
ALTER SEQUENCE training_participants_id_seq RESTART WITH 1;
ALTER SEQUENCE competition_participants_id_seq RESTART WITH 1;

-- Voeg de 3 test gebruikers toe
INSERT INTO users (id, email, full_name, location, team_name) VALUES
(1, 'wesley.wyngaerd@outlook.com', 'Wesley Wyngaerd', 'Oostakker, België', 'Team Wesley'),
(2, 'maximeboelaert@hotmail.be', 'Maxime Boelaert', 'Sas van Gent, België', 'Team Maxime'),
(3, 'degraevetomas@gmail.com', 'Tomas De Graeve', 'Mendonk, België', 'Team Tomas');

-- 9. Row Level Security (RLS) UITGESCHAKELD voor eenvoudige toegang
-- RLS policies zijn uitgeschakeld voor testing

-- 11. Duiventil types tabel
CREATE TABLE IF NOT EXISTS loft_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    image VARCHAR(255) NOT NULL,
    breeding_cages INTEGER NOT NULL,
    flight_cages INTEGER NOT NULL,
    total_capacity INTEGER NOT NULL,
    price INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. Gebruiker duiventillen tabel
CREATE TABLE IF NOT EXISTS user_lofts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    loft_type_id INTEGER REFERENCES loft_types(id),
    status VARCHAR(20) DEFAULT 'owned' CHECK (status IN ('owned', 'available', 'locked')),
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 13. Kooien tabel met unieke IDs per gebruiker
CREATE TABLE IF NOT EXISTS cages (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    user_loft_id INTEGER REFERENCES user_lofts(id) ON DELETE CASCADE,
    cage_id VARCHAR(20) NOT NULL, -- B1-1, F1-1, etc.
    cage_type VARCHAR(10) NOT NULL CHECK (cage_type IN ('breeding', 'flight')),
    capacity INTEGER NOT NULL, -- 2 voor breeding, 1 voor flight
    is_occupied BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, cage_id) -- Zorgt voor unieke IDs per gebruiker
);

-- 14. Duiven in kooien tabel (1 duif = 1 kooi)
CREATE TABLE IF NOT EXISTS pigeons_in_cages (
    id SERIAL PRIMARY KEY,
    cage_id INTEGER REFERENCES cages(id) ON DELETE CASCADE,
    pigeon_id INTEGER REFERENCES pigeons(id) ON DELETE CASCADE,
    placed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(pigeon_id) -- Zorgt dat 1 duif maar in 1 kooi kan zitten
);

-- 15. Voeding types tabel
CREATE TABLE IF NOT EXISTS food_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    image VARCHAR(255) NOT NULL,
    price_per_kg DECIMAL(10,2) NOT NULL,
    energy_value INTEGER NOT NULL, -- Energie die duiven krijgen
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 16. Gebruiker voeding voorraad
CREATE TABLE IF NOT EXISTS user_food (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    food_type_id INTEGER REFERENCES food_types(id),
    quantity_kg DECIMAL(10,2) DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, food_type_id) -- 1 rij per gebruiker per voeding type
);

-- Verwijder bestaande data
DELETE FROM user_food;
DELETE FROM food_types;
DELETE FROM pigeons_in_cages;
DELETE FROM cages;
DELETE FROM user_lofts;
DELETE FROM loft_types;

-- Reset sequences
ALTER SEQUENCE loft_types_id_seq RESTART WITH 1;
ALTER SEQUENCE user_lofts_id_seq RESTART WITH 1;
ALTER SEQUENCE cages_id_seq RESTART WITH 1;
ALTER SEQUENCE pigeons_in_cages_id_seq RESTART WITH 1;
ALTER SEQUENCE food_types_id_seq RESTART WITH 1;
ALTER SEQUENCE user_food_id_seq RESTART WITH 1;

-- Voeg duiventil types toe
INSERT INTO loft_types (id, name, image, breeding_cages, flight_cages, total_capacity, price) VALUES
(1, 'Starters Loft', 'Til1.png', 4, 17, 25, 0),
(2, 'Hobby Loft', 'Til2.png', 8, 34, 50, 1000),
(3, 'Pro Loft', 'Til3.png', 12, 51, 75, 2500),
(4, 'Master Loft', 'Til4.png', 16, 68, 100, 5000);

-- Voeg voeding types toe
INSERT INTO food_types (id, name, image, price_per_kg, energy_value, description) VALUES
(1, 'Maïs', 'mais.png', 2.50, 80, 'Basis voeding voor duiven, rijk aan koolhydraten'),
(2, 'Tarwe', 'tarwe.png', 3.00, 90, 'Gezonde graansoort, goed voor energie'),
(3, 'Gerst', 'gerst.png', 2.80, 85, 'Licht verteerbaar, ideaal voor jonge duiven'),
(4, 'Pinda''s', 'pindas.png', 8.50, 120, 'Premium voeding, hoog in eiwitten en vetten');

-- Voeg Starters Loft toe voor alle test gebruikers
INSERT INTO user_lofts (user_id, loft_type_id, status) VALUES
(1, 1, 'owned'), -- Wesley
(2, 1, 'owned'), -- Maxime  
(3, 1, 'owned'); -- Tomas

-- Voeg basis voeding voorraad toe voor alle gebruikers
INSERT INTO user_food (user_id, food_type_id, quantity_kg) VALUES
(1, 1, 10.0), -- Wesley: 10kg maïs
(1, 2, 5.0),  -- Wesley: 5kg tarwe
(1, 3, 3.0),  -- Wesley: 3kg gerst
(1, 4, 1.0),  -- Wesley: 1kg pinda's
(2, 1, 10.0), -- Maxime: 10kg maïs
(2, 2, 5.0),  -- Maxime: 5kg tarwe
(2, 3, 3.0),  -- Maxime: 3kg gerst
(2, 4, 1.0),  -- Maxime: 1kg pinda's
(3, 1, 10.0), -- Tomas: 10kg maïs
(3, 2, 5.0),  -- Tomas: 5kg tarwe
(3, 3, 3.0),  -- Tomas: 3kg gerst
(3, 4, 1.0);  -- Tomas: 1kg pinda's

-- Functie om kooien aan te maken voor een gebruiker
CREATE OR REPLACE FUNCTION create_cages_for_user(user_loft_id INTEGER)
RETURNS VOID AS $$
DECLARE
    loft_record RECORD;
    i INTEGER;
    cage_id_text VARCHAR(20);
BEGIN
    -- Haal duiventil info op
    SELECT lt.breeding_cages, lt.flight_cages, ul.user_id, ul.id as user_loft_id
    INTO loft_record
    FROM user_lofts ul
    JOIN loft_types lt ON ul.loft_type_id = lt.id
    WHERE ul.id = user_loft_id;
    
    -- Maak kweekkooien aan
    FOR i IN 1..loft_record.breeding_cages LOOP
        cage_id_text := 'B' || user_loft_id || '-' || i;
        INSERT INTO cages (user_id, user_loft_id, cage_id, cage_type, capacity)
        VALUES (loft_record.user_id, user_loft_id, cage_id_text, 'breeding', 2);
    END LOOP;
    
    -- Maak vliegkooien aan
    FOR i IN 1..loft_record.flight_cages LOOP
        cage_id_text := 'F' || user_loft_id || '-' || i;
        INSERT INTO cages (user_id, user_loft_id, cage_id, cage_type, capacity)
        VALUES (loft_record.user_id, user_loft_id, cage_id_text, 'flight', 1);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Maak kooien aan voor alle bestaande duiventillen
SELECT create_cages_for_user(id) FROM user_lofts;

-- Functie om duif in kooi te plaatsen (1 duif = 1 kooi)
CREATE OR REPLACE FUNCTION place_pigeon_in_cage(p_user_id INTEGER, p_cage_id VARCHAR(20), p_pigeon_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    cage_record RECORD;
    pigeon_count INTEGER;
BEGIN
    -- Controleer of kooi bestaat en van de juiste gebruiker is
    SELECT * INTO cage_record
    FROM cages
    WHERE user_id = p_user_id AND cage_id = p_cage_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Controleer of kooi vol is
    SELECT COUNT(*) INTO pigeon_count
    FROM pigeons_in_cages pic
    JOIN cages c ON pic.cage_id = c.id
    WHERE c.id = cage_record.id;
    
    IF pigeon_count >= cage_record.capacity THEN
        RETURN FALSE;
    END IF;
    
    -- Controleer of duif al in een kooi zit (1 duif = 1 kooi)
    IF EXISTS (SELECT 1 FROM pigeons_in_cages WHERE pigeon_id = p_pigeon_id) THEN
        RETURN FALSE;
    END IF;
    
    -- Plaats duif in kooi
    INSERT INTO pigeons_in_cages (cage_id, pigeon_id)
    VALUES (cage_record.id, p_pigeon_id);
    
    -- Update kooi status
    UPDATE cages SET is_occupied = TRUE WHERE id = cage_record.id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Functie om duif uit kooi te halen
CREATE OR REPLACE FUNCTION remove_pigeon_from_cage(p_user_id INTEGER, p_cage_id VARCHAR(20), p_pigeon_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    cage_record RECORD;
    pigeon_count INTEGER;
BEGIN
    -- Controleer of kooi bestaat en van de juiste gebruiker is
    SELECT * INTO cage_record
    FROM cages
    WHERE user_id = p_user_id AND cage_id = p_cage_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Verwijder duif uit kooi
    DELETE FROM pigeons_in_cages 
    WHERE cage_id = cage_record.id AND pigeon_id = p_pigeon_id;
    
    -- Controleer of kooi nu leeg is
    SELECT COUNT(*) INTO pigeon_count
    FROM pigeons_in_cages
    WHERE cage_id = cage_record.id;
    
    -- Update kooi status
    UPDATE cages SET is_occupied = (pigeon_count > 0) WHERE id = cage_record.id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Functie om voeding te kopen
CREATE OR REPLACE FUNCTION buy_food(p_user_id INTEGER, p_food_type_id INTEGER, p_quantity_kg DECIMAL(10,2))
RETURNS BOOLEAN AS $$
DECLARE
    food_record RECORD;
    total_cost DECIMAL(10,2);
BEGIN
    -- Haal voeding info op
    SELECT * INTO food_record
    FROM food_types
    WHERE id = p_food_type_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Bereken totale kosten
    total_cost := food_record.price_per_kg * p_quantity_kg;
    
    -- Hier zou je geld controle en afschrijving moeten doen
    -- Voor nu: voeg gewoon toe aan voorraad
    
    -- Update of voeg toe aan voorraad
    INSERT INTO user_food (user_id, food_type_id, quantity_kg)
    VALUES (p_user_id, p_food_type_id, p_quantity_kg)
    ON CONFLICT (user_id, food_type_id)
    DO UPDATE SET 
        quantity_kg = user_food.quantity_kg + p_quantity_kg,
        last_updated = NOW();
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Functie om gebruiker ID op te halen
CREATE OR REPLACE FUNCTION get_user_id(user_email TEXT)
RETURNS INTEGER AS $$
BEGIN
    RETURN (SELECT id FROM users WHERE email = user_email);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 
