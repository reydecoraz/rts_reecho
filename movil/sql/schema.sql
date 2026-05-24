-- =====================================================================
-- RTS GAME — Schema SQL completo (PostgreSQL / Docker)
-- Cubre: civilizaciones, eras, edificios, tropas, investigaciones,
--        recursos, mejoras, aspectos visuales por era
-- =====================================================================

-- Extensiones útiles
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─────────────────────────────────────────────────────────────────────
-- ERAS (Épocas históricas)
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE eras (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(50) NOT NULL,          -- 'Edad de Piedra', 'Edad de Bronce', etc.
    order_num   INT NOT NULL UNIQUE,           -- 1, 2, 3, 4, 5
    unlock_cost_wood    INT DEFAULT 0,
    unlock_cost_gold    INT DEFAULT 0,
    unlock_cost_stone   INT DEFAULT 0,
    description TEXT
);

INSERT INTO eras (name, order_num, unlock_cost_wood, unlock_cost_gold, unlock_cost_stone, description) VALUES
('Edad de Piedra',  1,    0,    0,    0,   'Los inicios de la civilización. Herramientas básicas.'),
('Edad de Bronce',  2,  300,  150,  100,  'Primeros metales. Agricultura organizada.'),
('Edad de Hierro',  3,  500,  400,  300,  'Dominio del hierro. Ejércitos organizados.'),
('Edad Media',      4,  800,  700,  600,  'Castillos, caballería y comercio.'),
('Edad Dorada',     5, 1500, 1200, 1000, 'Apogeo de la civilización. Tecnología avanzada.');

-- ─────────────────────────────────────────────────────────────────────
-- CIVILIZACIONES
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE civilizations (
    id              SERIAL PRIMARY KEY,
    code            VARCHAR(20) NOT NULL UNIQUE,  -- 'romans', 'vikings', 'aztecs', 'samurais'
    name            VARCHAR(50) NOT NULL,
    description     TEXT,
    -- Bonificaciones únicas
    bonus_wood      FLOAT DEFAULT 1.0,            -- multiplicador de recolección
    bonus_gold      FLOAT DEFAULT 1.0,
    bonus_stone     FLOAT DEFAULT 1.0,
    bonus_food      FLOAT DEFAULT 1.0,
    bonus_military  FLOAT DEFAULT 1.0,            -- daño de tropas
    bonus_defense   FLOAT DEFAULT 1.0,            -- defensa de edificios
    starting_era_id INT REFERENCES eras(id) DEFAULT 1,
    -- Unidad única
    unique_unit_name    VARCHAR(50),
    unique_unit_desc    TEXT
);

INSERT INTO civilizations (code, name, description, bonus_wood, bonus_gold, bonus_stone, bonus_military, unique_unit_name, unique_unit_desc) VALUES
('romans',   'Romanos',  'Imperio disciplinado. Mejores constructores y defensores.',       1.0, 1.0, 1.3, 1.1, 'Legionario',   'Infantería pesada élite con escudo y gladio.'),
('vikings',  'Vikingos', 'Guerreros del norte. Excelentes en combate y recolección.',       1.3, 1.0, 1.0, 1.2, 'Berserker',    'Guerrero furioso con doble hacha, sin armadura.'),
('aztecs',   'Aztecas',  'Civilización agrícola. Superiores en producción de alimentos.',   1.0, 1.1, 1.0, 1.0, 'Jaguar',       'Guerrero sigilo disfrazado de jaguar.'),
('samurais', 'Samurais', 'Honor y precisión. Mejores en tecnología militar y espionaje.',   1.0, 1.2, 1.0, 1.15,'Ronin',        'Maestro espadachín independiente y letal.');

-- ─────────────────────────────────────────────────────────────────────
-- ASPECTOS VISUALES POR ERA (skins de unidades/edificios)
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE era_visual_aspects (
    id              SERIAL PRIMARY KEY,
    civilization_id INT REFERENCES civilizations(id) ON DELETE CASCADE,
    era_id          INT REFERENCES eras(id) ON DELETE CASCADE,
    asset_prefix    VARCHAR(100),   -- prefijo de sprite: 'romans_era2_'
    palette_primary VARCHAR(7),     -- color hex principal '#FF5722'
    palette_secondary VARCHAR(7),
    description     TEXT,
    UNIQUE(civilization_id, era_id)
);

-- ─────────────────────────────────────────────────────────────────────
-- TIPOS DE EDIFICIO (categorías)
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE building_types (
    id      SERIAL PRIMARY KEY,
    code    VARCHAR(30) UNIQUE NOT NULL,
    name    VARCHAR(50) NOT NULL,
    icon    VARCHAR(10)           -- emoji icon
);

INSERT INTO building_types (code, name, icon) VALUES
('resource',    'Recolección de Recursos',  '⛏️'),
('military',    'Militar',                  '⚔️'),
('research',    'Investigación',             '🔬'),
('defense',     'Defensa',                  '🛡️'),
('economy',     'Economía',                 '💰'),
('housing',     'Vivienda',                 '🏠'),
('special',     'Especial de Civilización', '⭐');

-- ─────────────────────────────────────────────────────────────────────
-- EDIFICIOS
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE buildings (
    id                  SERIAL PRIMARY KEY,
    code                VARCHAR(40) UNIQUE NOT NULL,
    name                VARCHAR(60) NOT NULL,
    building_type_id    INT REFERENCES building_types(id),
    min_era_id          INT REFERENCES eras(id),           -- era mínima para construir
    -- Costos de construcción
    cost_wood           INT DEFAULT 0,
    cost_gold           INT DEFAULT 0,
    cost_stone          INT DEFAULT 0,
    cost_food           INT DEFAULT 0,
    build_time_secs     INT DEFAULT 30,
    -- Stats del edificio
    hp                  INT DEFAULT 500,
    defense             INT DEFAULT 10,
    -- Producción pasiva
    produces_wood       INT DEFAULT 0,   -- por minuto
    produces_gold       INT DEFAULT 0,
    produces_stone      INT DEFAULT 0,
    produces_food       INT DEFAULT 0,
    -- Capacidades
    pop_capacity        INT DEFAULT 0,   -- casas adicionales
    storage_capacity    INT DEFAULT 0,
    -- Flags
    is_unique_per_player BOOLEAN DEFAULT FALSE,
    requires_building_id INT REFERENCES buildings(id),  -- prerequisito
    description         TEXT
);

INSERT INTO buildings (code, name, building_type_id, min_era_id, cost_wood, cost_gold, cost_stone, build_time_secs, hp, produces_food, pop_capacity, description) VALUES
('town_center',     'Centro de Aldea',    1, 1,   0,   0,   0,   0, 2000, 0, 5, 'Edificio principal. No se puede destruir sin perder la partida.'),
('house',           'Casa',               6, 1,  50,   0,  20,  15,  300, 0, 5, 'Aumenta la capacidad de población.'),
('farm',            'Granja',             1, 1,  60,   0,   0,  20,  200, 3, 0, 'Produce comida pasivamente. Necesaria para mantener población.'),
('lumber_camp',     'Campamento Maderero',1, 1,  40,   0,  10,  25,  300, 0, 0, 'Acelera la recolección de madera cercana.'),
('mining_camp',     'Campamento Minero',  1, 1,  50,   0,  20,  30,  350, 0, 0, 'Acelera la recolección de piedra y oro.'),
('barracks',        'Cuartel',            2, 1, 100,  50,  50,  45,  800, 0, 0, 'Permite reclutar tropas básicas.'),
('archery_range',   'Campo de Arqueros',  2, 2, 120,  80,  40,  50,  600, 0, 0, 'Permite reclutar unidades a distancia.'),
('stable',          'Establo',            2, 2, 150, 100,  50,  60,  700, 0, 0, 'Permite reclutar caballería.'),
('blacksmith',      'Herrería',           3, 2,  80,  60,  80,  40,  500, 0, 0, 'Desbloquea mejoras de armas y armaduras.'),
('market',          'Mercado',            5, 2, 100,  80,  50,  50,  500, 0, 0, 'Permite comerciar recursos entre jugadores.'),
('tower',           'Torre de Vigilancia',4, 1,  50,  20,  80,  35,  600, 0, 0, 'Estructura defensiva con rango de ataque.'),
('wall',            'Muralla',            4, 1,  30,   0,  60,  15, 1500, 0, 0, 'Barrera defensiva.'),
('castle',          'Castillo',           4, 4, 400, 200, 600,  90,3000, 0, 0, 'Fortaleza principal de la era medieval.'),
('research_lab',    'Laboratorio',        3, 3, 150, 120, 100,  60,  600, 0, 0, 'Permite investigar tecnologías avanzadas.'),
('granary',         'Granero',            5, 1,  60,   0,  20,  20,  400, 0, 0, 'Aumenta capacidad de almacenamiento de comida.');

-- ─────────────────────────────────────────────────────────────────────
-- MEJORAS DE EDIFICIOS (upgrades)
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE building_upgrades (
    id              SERIAL PRIMARY KEY,
    building_id     INT REFERENCES buildings(id) ON DELETE CASCADE,
    level           INT NOT NULL DEFAULT 2,     -- nivel al que mejora (2, 3, 4...)
    name            VARCHAR(60),
    cost_wood       INT DEFAULT 0,
    cost_gold       INT DEFAULT 0,
    cost_stone      INT DEFAULT 0,
    upgrade_time_secs INT DEFAULT 30,
    -- Bonificaciones del upgrade
    hp_bonus        INT DEFAULT 0,
    defense_bonus   INT DEFAULT 0,
    production_bonus_pct FLOAT DEFAULT 0.0,    -- % de mejora en producción
    requires_era_id INT REFERENCES eras(id),
    UNIQUE(building_id, level)
);

-- ─────────────────────────────────────────────────────────────────────
-- TROPAS
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE troop_types (
    id      SERIAL PRIMARY KEY,
    code    VARCHAR(20) UNIQUE,
    name    VARCHAR(30) NOT NULL   -- 'Infantería', 'Caballería', 'Arquero', 'Asedio', 'Naval'
);

INSERT INTO troop_types (code, name) VALUES
('infantry',  'Infantería'),
('cavalry',   'Caballería'),
('ranged',    'Arquero/Distancia'),
('siege',     'Asedio'),
('naval',     'Naval'),
('special',   'Especial');

CREATE TABLE troops (
    id                  SERIAL PRIMARY KEY,
    code                VARCHAR(40) UNIQUE NOT NULL,
    name                VARCHAR(60) NOT NULL,
    troop_type_id       INT REFERENCES troop_types(id),
    min_era_id          INT REFERENCES eras(id),
    requires_building_id INT REFERENCES buildings(id),   -- edificio necesario
    -- Costos de reclutamiento
    cost_food           INT DEFAULT 50,
    cost_gold           INT DEFAULT 30,
    cost_wood           INT DEFAULT 0,
    train_time_secs     INT DEFAULT 20,
    -- Atributos base
    hp                  INT DEFAULT 100,
    attack              INT DEFAULT 10,
    defense             INT DEFAULT 5,
    speed               FLOAT DEFAULT 1.0,
    range               INT DEFAULT 1,           -- 1 = melé, >1 = distancia (tiles)
    vision_range        INT DEFAULT 5,
    population_cost     INT DEFAULT 1,
    -- Efectividades contra tipos
    bonus_vs_infantry   FLOAT DEFAULT 1.0,
    bonus_vs_cavalry    FLOAT DEFAULT 1.0,
    bonus_vs_ranged     FLOAT DEFAULT 1.0,
    bonus_vs_siege      FLOAT DEFAULT 1.0,
    bonus_vs_buildings  FLOAT DEFAULT 1.0,
    -- Flags
    is_unique           BOOLEAN DEFAULT FALSE,   -- unidad única de civilización
    civilization_id     INT REFERENCES civilizations(id),  -- NULL = genérica
    description         TEXT
);

INSERT INTO troops (code, name, troop_type_id, min_era_id, requires_building_id, cost_food, cost_gold, train_time_secs, hp, attack, defense, speed, range, population_cost, description) VALUES
('spearman',    'Lancero',      1, 1, 6,  30, 10, 20,  80, 8,  5, 1.0, 1, 1, 'Infantería básica. Bueno contra caballería.'),
('swordsman',   'Espadachín',   1, 2, 6,  50, 30, 30, 120,15, 10, 1.0, 1, 1, 'Infantería media versátil.'),
('knight',      'Caballero',    2, 3, 7,  80, 60, 45, 200,22, 15, 1.8, 1, 2, 'Caballería pesada. Rápida y poderosa.'),
('archer',      'Arquero',      3, 1, 7,  40, 20, 25,  60,12,  3, 1.0, 4, 1, 'Ataque a distancia. Débil en melé.'),
('crossbowman', 'Ballestero',   3, 3, 7,  60, 40, 35,  80,20,  5, 0.9, 5, 1, 'Mayor daño y rango que el arquero.'),
('catapult',    'Catapulta',    4, 4, 6,  80,100, 60, 150,40,  2, 0.5, 8, 3, 'Asedio pesado. Daño masivo a edificios.'),
('battering_ram','Ariete',      4, 3, 6,  60, 60, 50, 300,30,  8, 0.6, 1, 3, 'Especializado en destruir puertas y muros.');

-- Atributos de tropas de cada civilización (único)
INSERT INTO troops (code, name, troop_type_id, min_era_id, requires_building_id, cost_food, cost_gold, train_time_secs, hp, attack, defense, speed, range, is_unique, civilization_id, description) VALUES
('legionary',    'Legionario',   1, 2, 6,  60, 50, 35, 150,18, 15, 1.0, 1, TRUE, 1, 'Unidad única romana. Alta defensa con escudo.'),
('berserker',    'Berserker',    1, 2, 6,  50, 40, 25, 130,25,  4, 1.4, 1, TRUE, 2, 'Unidad única vikinga. Máximo daño, poca defensa.'),
('jaguar_warrior','Guerrero Jaguar',1,2,6, 45, 35, 25, 110,20,  8, 1.3, 1, TRUE, 3, 'Unidad única azteca. Sigilo y velocidad.'),
('ronin',        'Ronin',        1, 2, 6,  55, 45, 30, 120,22, 10, 1.2, 1, TRUE, 4, 'Unidad única samurai. Contraataque letal.');

-- ─────────────────────────────────────────────────────────────────────
-- EVOLUCIÓN DE TROPAS POR ERA (mejoras de stats)
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE troop_era_stats (
    id          SERIAL PRIMARY KEY,
    troop_id    INT REFERENCES troops(id) ON DELETE CASCADE,
    era_id      INT REFERENCES eras(id),
    hp_bonus    INT DEFAULT 0,
    attack_bonus INT DEFAULT 0,
    defense_bonus INT DEFAULT 0,
    speed_bonus  FLOAT DEFAULT 0.0,
    new_sprite  VARCHAR(100),   -- path al sprite de esta era
    UNIQUE(troop_id, era_id)
);

-- ─────────────────────────────────────────────────────────────────────
-- INVESTIGACIONES / TECNOLOGÍAS
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE research_categories (
    id      SERIAL PRIMARY KEY,
    code    VARCHAR(20) UNIQUE,
    name    VARCHAR(40),
    icon    VARCHAR(10)
);

INSERT INTO research_categories (code, name, icon) VALUES
('military',  'Militar',       '⚔️'),
('economy',   'Economía',      '📦'),
('defense',   'Defensa',       '🛡️'),
('science',   'Ciencia',       '🔬'),
('agriculture','Agricultura',  '🌾');

CREATE TABLE researches (
    id                  SERIAL PRIMARY KEY,
    code                VARCHAR(50) UNIQUE NOT NULL,
    name                VARCHAR(80) NOT NULL,
    category_id         INT REFERENCES research_categories(id),
    min_era_id          INT REFERENCES eras(id),
    requires_research_id INT REFERENCES researches(id),    -- prerequisito
    requires_building_id INT REFERENCES buildings(id),
    cost_wood           INT DEFAULT 0,
    cost_gold           INT DEFAULT 0,
    cost_stone          INT DEFAULT 0,
    research_time_secs  INT DEFAULT 60,
    -- Efectos (en JSON para flexibilidad)
    effect_json         JSONB,    -- {"troop_attack": 0.1, "wood_gather": 0.15}
    description         TEXT,
    -- Qué aspecto visual cambia con esta investigación
    changes_aspect      BOOLEAN DEFAULT FALSE,
    aspect_description  TEXT
);

INSERT INTO researches (code, name, category_id, min_era_id, cost_wood, cost_gold, cost_stone, research_time_secs, effect_json, description) VALUES
('iron_tools',     'Herramientas de Hierro', 2, 2,  80,  50, 100, 45, '{"wood_gather": 0.15, "stone_gather": 0.10}', 'Mejora la eficiencia de recolección.'),
('wheel',          'La Rueda',               2, 1,  60,  30,  40, 30, '{"unit_speed": 0.1}',                        'Todas las unidades se mueven más rápido.'),
('bronze_weapons', 'Armas de Bronce',        1, 2,  40, 100,  60, 50, '{"troop_attack": 0.10}',                     'Incrementa el ataque de todas las tropas.'),
('iron_armor',     'Armadura de Hierro',     3, 3,  30,  80, 120, 60, '{"troop_defense": 0.15}',                    'Todas las tropas tienen más defensa.'),
('crop_rotation',  'Rotación de Cultivos',   5, 2,  50,  30,   0, 40, '{"food_production": 0.25}',                  'Las granjas producen 25% más comida.'),
('masonry',        'Albañilería',             3, 2,  40,  60, 100, 50, '{"building_hp": 0.20}',                      'Todos los edificios tienen más HP.'),
('siege_craft',    'Arte del Asedio',         1, 4,  60, 150,  80, 75, '{"siege_attack": 0.20}',                     'Las máquinas de asedio hacen más daño.'),
('metallurgy',     'Metalurgia',              1, 3,  50, 120, 150, 80, '{"troop_attack": 0.15, "troop_defense": 0.10}', 'Mejora avanzada de equipo militar.');

-- ─────────────────────────────────────────────────────────────────────
-- MEJORAS DE ASPECTO (cambios visuales por investigación/era)
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE aspect_upgrades (
    id              SERIAL PRIMARY KEY,
    civilization_id INT REFERENCES civilizations(id),
    era_id          INT REFERENCES eras(id),
    research_id     INT REFERENCES researches(id),
    target_type     VARCHAR(20),   -- 'troop', 'building', 'hero'
    target_code     VARCHAR(40),   -- código de la tropa/edificio
    sprite_path     VARCHAR(150),  -- path al asset actualizado
    description     TEXT
);

-- ─────────────────────────────────────────────────────────────────────
-- PARTIDAS (matches)
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE matches (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    seed            BIGINT NOT NULL,
    map_size        INT DEFAULT 40,
    created_at      TIMESTAMP DEFAULT NOW(),
    ended_at        TIMESTAMP,
    game_mode       VARCHAR(20),   -- 'vs_ia', 'online_ffa', 'online_teams'
    winner_slot     INT,           -- índice del jugador ganador
    duration_secs   INT
);

-- ─────────────────────────────────────────────────────────────────────
-- JUGADORES EN PARTIDA
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE match_players (
    id              SERIAL PRIMARY KEY,
    match_id        UUID REFERENCES matches(id) ON DELETE CASCADE,
    slot_index      INT NOT NULL,          -- 0-7
    player_type     VARCHAR(10),           -- 'human', 'ai'
    civilization_id INT REFERENCES civilizations(id),
    ai_difficulty   VARCHAR(10),           -- 'easy', 'normal', 'hard'
    spawn_col       INT,
    spawn_row       INT,
    final_wood      INT DEFAULT 0,
    final_gold      INT DEFAULT 0,
    final_stone     INT DEFAULT 0,
    troops_trained  INT DEFAULT 0,
    buildings_built INT DEFAULT 0,
    UNIQUE(match_id, slot_index)
);

-- ─────────────────────────────────────────────────────────────────────
-- ÍNDICES para rendimiento
-- ─────────────────────────────────────────────────────────────────────
CREATE INDEX idx_buildings_era       ON buildings(min_era_id);
CREATE INDEX idx_troops_era          ON troops(min_era_id);
CREATE INDEX idx_troops_civ          ON troops(civilization_id);
CREATE INDEX idx_researches_era      ON researches(min_era_id);
CREATE INDEX idx_match_players_match ON match_players(match_id);
CREATE INDEX idx_aspect_upgrades_civ ON aspect_upgrades(civilization_id, era_id);
