-- =====================================================================
-- RTS ENGINE — SCHEMA DINÁMICO Y ROBUSTO (JSONB + CATÁLOGO)
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────────────────────────────────
-- 1. CATÁLOGO DE ATRIBUTOS (DICCIONARIO ESTRICTO)
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS game_attribute_definitions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,    -- ej: 'fire_magic', 'hp', 'is_repairable'
    name VARCHAR(100) NOT NULL,          -- ej: 'Magia de Fuego'
    type VARCHAR(20) NOT NULL,           -- 'number', 'boolean', 'string'
    category VARCHAR(50),                -- 'combat', 'utility', 'magic'
    icon VARCHAR(20),                    -- '🔥'
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ─────────────────────────────────────────────────────────────────────
-- 2. TABLAS CORE (ENTIDADES PRINCIPALES CON JSONB)
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS game_civilizations_data (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    description TEXT,
    bonuses JSONB DEFAULT '[]'::jsonb,
    base_attributes JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS game_units_data (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    description TEXT,
    base_attributes JSONB DEFAULT '{}'::jsonb,
    upgrades_to UUID REFERENCES game_units_data(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS game_buildings_data (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    description TEXT,
    base_attributes JSONB DEFAULT '{}'::jsonb,
    upgrades_to UUID REFERENCES game_buildings_data(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS game_heroes_data (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    description TEXT,
    lore TEXT,
    base_attributes JSONB DEFAULT '{}'::jsonb,
    upgrades_to UUID REFERENCES game_heroes_data(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS game_technologies_data (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    description TEXT,
    base_attributes JSONB DEFAULT '{}'::jsonb,
    upgrades_to UUID REFERENCES game_technologies_data(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ─────────────────────────────────────────────────────────────────────
-- 3. SKINS Y OVERRIDES (POR FACCIÓN)
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS game_civilization_overrides (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    civilization_id UUID NOT NULL REFERENCES game_civilizations_data(id) ON DELETE CASCADE,
    entity_type VARCHAR(50) NOT NULL,  -- 'unit', 'building', 'hero'
    entity_id UUID NOT NULL,           -- ID de la unidad/edificio/héroe
    stat_key VARCHAR(50) NOT NULL,     -- ej: 'sprite_config', 'hp_multiplier'
    stat_value JSONB NOT NULL,         -- JSON de configuraciones
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(civilization_id, entity_type, entity_id, stat_key)
);

-- ─────────────────────────────────────────────────────────────────────
-- 4. RELACIONES DE PERTENENCIA A CIVILIZACIÓN
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS civ_units (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    civilization_id UUID NOT NULL REFERENCES game_civilizations_data(id) ON DELETE CASCADE,
    unit_id UUID NOT NULL REFERENCES game_units_data(id) ON DELETE CASCADE,
    UNIQUE(civilization_id, unit_id)
);

CREATE TABLE IF NOT EXISTS civ_buildings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    civilization_id UUID NOT NULL REFERENCES game_civilizations_data(id) ON DELETE CASCADE,
    building_id UUID NOT NULL REFERENCES game_buildings_data(id) ON DELETE CASCADE,
    UNIQUE(civilization_id, building_id)
);

CREATE TABLE IF NOT EXISTS civ_heroes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    civilization_id UUID NOT NULL REFERENCES game_civilizations_data(id) ON DELETE CASCADE,
    hero_id UUID NOT NULL REFERENCES game_heroes_data(id) ON DELETE CASCADE,
    UNIQUE(civilization_id, hero_id)
);

CREATE TABLE IF NOT EXISTS civ_technologies (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    civilization_id UUID NOT NULL REFERENCES game_civilizations_data(id) ON DELETE CASCADE,
    technology_id UUID NOT NULL REFERENCES game_technologies_data(id) ON DELETE CASCADE,
    UNIQUE(civilization_id, technology_id)
);

-- ─────────────────────────────────────────────────────────────────────
-- 5. ÁRBOL TECNOLÓGICO Y PRODUCCIÓN
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS building_produces_units (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    building_id UUID NOT NULL REFERENCES game_buildings_data(id) ON DELETE CASCADE,
    unit_id UUID NOT NULL REFERENCES game_units_data(id) ON DELETE CASCADE,
    civilization_id UUID REFERENCES game_civilizations_data(id) ON DELETE CASCADE,
    UNIQUE(building_id, unit_id, civilization_id)
);

CREATE TABLE IF NOT EXISTS building_researches (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    building_id UUID NOT NULL REFERENCES game_buildings_data(id) ON DELETE CASCADE,
    technology_id UUID NOT NULL REFERENCES game_technologies_data(id) ON DELETE CASCADE,
    civilization_id UUID REFERENCES game_civilizations_data(id) ON DELETE CASCADE,
    UNIQUE(building_id, technology_id, civilization_id)
);

CREATE TABLE IF NOT EXISTS game_requirements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL,          -- Lo que se va a desbloquear ('building', 'unit')
    entity_id UUID NOT NULL,                   -- El ID de lo que se desbloquea
    required_entity_type VARCHAR(50) NOT NULL, -- Lo que se necesita ('technology', 'building')
    required_entity_id UUID NOT NULL,          -- El ID de lo que se necesita
    civilization_id UUID REFERENCES game_civilizations_data(id) ON DELETE CASCADE,
    UNIQUE(entity_type, entity_id, required_entity_type, required_entity_id, civilization_id)
);

-- ─────────────────────────────────────────────────────────────────────
-- 6. EFECTOS Y BONIFICACIONES
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS game_technology_effects (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    technology_id UUID NOT NULL REFERENCES game_technologies_data(id) ON DELETE CASCADE,
    civilization_id UUID REFERENCES game_civilizations_data(id) ON DELETE CASCADE,
    effect_type VARCHAR(50), 
    target_type VARCHAR(50),
    effect_value JSONB,
    UNIQUE(technology_id, effect_type, target_type, civilization_id)
);

CREATE TABLE IF NOT EXISTS technology_affects_units (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    technology_id UUID NOT NULL REFERENCES game_technologies_data(id) ON DELETE CASCADE,
    unit_id UUID NOT NULL REFERENCES game_units_data(id) ON DELETE CASCADE,
    UNIQUE(technology_id, unit_id)
);

CREATE TABLE IF NOT EXISTS building_production_bonuses (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    building_id UUID NOT NULL REFERENCES game_buildings_data(id) ON DELETE CASCADE,
    civilization_id UUID REFERENCES game_civilizations_data(id) ON DELETE CASCADE,
    bonus_type VARCHAR(50),
    bonus_value JSONB,
    UNIQUE(building_id, bonus_type, civilization_id)
);

-- INSERT DE EJEMPLO PARA EL CATÁLOGO (Opcional, pero ayuda al inicio)
INSERT INTO game_attribute_definitions (code, name, type, category, icon) VALUES 
('hp', 'Puntos de Vida (HP)', 'number', 'core', '❤️'),
('attack', 'Ataque Melé', 'number', 'combat', '⚔️'),
('defense', 'Defensa', 'number', 'combat', '🛡️'),
('speed', 'Velocidad de Mov.', 'number', 'utility', '👟'),
('range', 'Rango de Ataque', 'number', 'combat', '🏹'),
('fire_magic', 'Magia de Fuego', 'number', 'magic', '🔥'),
('mana', 'Maná', 'number', 'magic', '✨'),
('is_repairable', 'Reparable', 'boolean', 'utility', '🔧'),
('build_time', 'Tiempo de Construcción', 'number', 'economy', '⏱️')
ON CONFLICT (code) DO NOTHING;
