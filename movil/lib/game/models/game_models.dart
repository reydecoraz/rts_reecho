// =====================================================================
// GAME MODELS — RTS Isométrico
// Modelos de datos del juego: tiles, recursos, jugadores, edificios
// =====================================================================

import 'dart:ui' as ui;

enum TileType {
  empty,       // Fuera del rombo (no se renderiza)
  grass,
  forest,      // Madera
  mountain,    // Piedra (reservado para futuro)
  goldDeposit, // Oro
  water,
  deepWater,
  sand,
  hill,
  spawn,       // Zona de aparición de jugador
  berryBush,   // Comida inicial (Arbustos)
}

enum ResourceType { wood, gold, stone, food }

enum PlayerType { human, ai }

enum AIDifficulty { easy, normal, hard }

enum Civilization { romans, vikings, aztecs, samurais }

class ResourceNode {
  final ResourceType type;
  int amount;
  final int maxAmount;

  ResourceNode({required this.type, required this.amount, required this.maxAmount});
}

class MapTile {
  final int col;
  final int row;
  TileType type;
  ResourceNode? resource;
  bool isWalkable;
  bool isOccupied;
  int? occupiedByPlayer; // índice del jugador que lo ocupa

  MapTile({
    required this.col,
    required this.row,
    required this.type,
    this.resource,
    this.isWalkable = true,
    this.isOccupied = false,
    this.occupiedByPlayer,
  });

  bool get hasResource => resource != null;

  bool get isWater => type == TileType.water || type == TileType.deepWater;
}

class SpawnZone {
  final int playerIndex;
  final int centerCol;
  final int centerRow;
  final int radius;

  SpawnZone({
    required this.playerIndex,
    required this.centerCol,
    required this.centerRow,
    this.radius = 3,
  });
}

class PlayerConfig {
  final int index;
  final int teamIndex; // 0 para equipo A, 1 para equipo B, etc.
  final PlayerType type;
  final String civId; // Dynamic civ ID from Supabase (replaces old Civilization enum)
  final AIDifficulty? aiDifficulty;
  final String name;
  final int colorIndex;

  PlayerConfig({
    required this.index,
    required this.teamIndex,
    required this.type,
    required this.civId,
    this.aiDifficulty,
    required this.name,
    required this.colorIndex,
  });

  // Backward-compatible getter for old code that uses the enum
  @Deprecated('Use civId instead')
  Civilization get civilization {
    switch (civId) {
      case 'romans': return Civilization.romans;
      case 'vikings': return Civilization.vikings;
      case 'aztecs': return Civilization.aztecs;
      case 'samurais': return Civilization.samurais;
      default: return Civilization.romans;
    }
  }
}

class PlayerResources {
  int wood;
  int gold;
  int stone;
  int food;
  int population;
  int maxPopulation;

  PlayerResources({
    this.wood = 0,
    this.gold = 0,
    this.stone = 0,
    this.food = 0,
    this.population = 0,
    this.maxPopulation = 10,
  });

  /// Create PlayerResources using a civId string. Falls back to defaults
  /// if the civId is not found in the legacy map.
  factory PlayerResources.fromCivId(String civId) {
    // Try to match against the legacy map first
    final legacyMap = {
      'romans': Civilization.romans,
      'vikings': Civilization.vikings,
      'aztecs': Civilization.aztecs,
      'samurais': Civilization.samurais,
    };
    final civ = legacyMap[civId];
    final stats = civ != null ? civBaseStats[civ] : null;
    return PlayerResources(
      wood: stats?.startWood ?? 500,
      gold: stats?.startGold ?? 400,
      stone: stats?.startStone ?? 300,
      food: stats?.startFood ?? 400,
    );
  }

  @Deprecated('Use fromCivId instead')
  factory PlayerResources.fromCiv(Civilization civ) {
    final stats = civBaseStats[civ] ?? civBaseStats[Civilization.romans]!;
    return PlayerResources(
      wood: stats.startWood,
      gold: stats.startGold,
      stone: stats.startStone,
      food: stats.startFood,
    );
  }
}

class GameMatch {
  final int seed;
  final List<PlayerConfig> players;
  final int mapSize;
  final String matchId;

  GameMatch({
    required this.seed,
    required this.players,
    required this.mapSize,
    required this.matchId,
  });
}

// Colores asignados a cada jugador slot
const playerColors = [
  0xFF4FC3F7, // Azul claro (human)
  0xFFEF5350, // Rojo
  0xFF66BB6A, // Verde
  0xFFFFB300, // Ámbar
  0xFFAB47BC, // Morado
  0xFF26A69A, // Teal
  0xFFEC407A, // Rosa
  0xFFFF7043, // Naranja profundo
];

const civNames = {
  Civilization.romans: 'ROMANOS',
  Civilization.vikings: 'VIKINGOS',
  Civilization.aztecs: 'AZTECAS',
  Civilization.samurais: 'SAMURAIS',
};

class PlayerTechState {
  String currentEra = 'stone'; // Por defecto empezamos en la primera
  Set<String> unlockedTechIds = {};
  
  // Caché de multiplicadores y sumas: multipliers[unitName][statName]
  Map<String, Map<String, double>> multipliers = {};
  Map<String, Map<String, double>> bonusValues = {};

  double getMultiplier(String unitName, String stat) {
    return multipliers[unitName]?[stat] ?? 1.0;
  }

  double getBonusValue(String unitName, String stat) {
    return bonusValues[unitName]?[stat] ?? 0.0;
  }

  void addBonus(String unitName, String stat, double mult, double bonus) {
    multipliers.putIfAbsent(unitName, () => {});
    bonusValues.putIfAbsent(unitName, () => {});
    
    multipliers[unitName]![stat] = (multipliers[unitName]![stat] ?? 1.0) * mult;
    bonusValues[unitName]![stat] = (bonusValues[unitName]![stat] ?? 0.0) + bonus;
  }
}

class CivBaseStats {
  final int startWood;
  final int startGold;
  final int startStone;
  final int startFood;

  const CivBaseStats({
    required this.startWood,
    required this.startGold,
    required this.startStone,
    required this.startFood,
  });
}

Map<Civilization, CivBaseStats> civBaseStats = {
  Civilization.romans: CivBaseStats(startWood: 500, startGold: 400, startStone: 300, startFood: 400),
  Civilization.vikings: CivBaseStats(startWood: 600, startGold: 300, startStone: 300, startFood: 500),
  Civilization.aztecs: CivBaseStats(startWood: 400, startGold: 500, startStone: 200, startFood: 500),
  Civilization.samurais: CivBaseStats(startWood: 400, startGold: 400, startStone: 500, startFood: 400),
};

class EntityBaseStats {
  final int maxHp;
  final double speed;
  final double attackRange;
  final int attackDamage;
  double attackSpeed;
  double creationTime;
  final String? spriteUrl;
  ui.Image? spriteImage;

  // Costs
  final int costFood;
  final int costWood;
  final int costGold;
  final int costStone;
  final int populationCost;
  
  EntityBaseStats({
    required this.maxHp, 
    this.speed = 2.0, 
    this.attackRange = 1.5,
    this.attackDamage = 0,
    this.attackSpeed = 1.0,
    this.creationTime = 10.0,
    this.spriteUrl,
    this.spriteImage,
    this.costFood = 0,
    this.costWood = 0,
    this.costGold = 0,
    this.costStone = 0,
    this.populationCost = 1,
  });
}

Map<String, EntityBaseStats> entityBaseStats = {};

enum EntityType { building, unit }
enum EntityState { idle, moving, movingToResource, gathering, returningToTC, attacking, fleeing }

class GameEntity {
  final String id;
  final int playerIndex;
  final EntityType type;
  String name;
  double col; // double para animación suave
  double row;
  int hp;
  int maxHp;
  int attackDamage;
  double attackSpeed;
  double creationTime;
  List<ui.Offset> currentPath = []; // El camino que debe seguir
  
  // Variables de la Máquina de Estados (Economía)
  EntityState state = EntityState.idle;
  double actionTimer = 0.0;
  double pathTimer = 0.0; // Enfriamiento para pathfinding
  int carriedResource = 0;
  int maxCarryCapacity = 15;
  MapTile? targetResourceTile;
  MapTile? assignedResourceTile; // Recurso al que está asignado permanentemente
  String workerRole = 'wood'; // Puede ser 'wood' o 'gold'
  
  // Detección de Atascos
  double lastCol = 0;
  double lastRow = 0;
  double stuckTimer = 0;
  
  // Producción (Edificios)
  String? productionName;
  double productionTimer = 0.0;

  double? groupSpeed; // Velocidad sincronizada para marchas en grupo
  int visionRadius;
  
  GameEntity({
    required this.id,
    required this.playerIndex,
    required this.type,
    required this.name,
    required this.col,
    required this.row,
    int? hp,
    int? maxHp,
    int? attackDamage,
    double? attackSpeed,
    double? creationTime,
    int? visionRadius,
  }) : 
    maxHp = maxHp ?? entityBaseStats[name]?.maxHp ?? 100,
    hp = hp ?? (maxHp ?? entityBaseStats[name]?.maxHp ?? 100),
    attackDamage = attackDamage ?? entityBaseStats[name]?.attackDamage ?? 0,
    attackSpeed = attackSpeed ?? entityBaseStats[name]?.attackSpeed ?? 1.0,
    creationTime = creationTime ?? entityBaseStats[name]?.creationTime ?? 10.0,
    visionRadius = visionRadius ?? (type == EntityType.building ? 8 : 5);
}

class Projectile {
  final String id;
  final double startCol;
  final double startRow;
  final double targetCol;
  final double targetRow;
  double col;
  double row;
  final double speed;
  final String type;
  final int damage;
  final String targetEntityId;
  bool isDead = false;

  Projectile({
    required this.id,
    required this.startCol,
    required this.startRow,
    required this.targetCol,
    required this.targetRow,
    required this.damage,
    required this.targetEntityId,
    this.speed = 10.0,
    this.type = 'arrow',
  })  : col = startCol,
        row = startRow;

  void update(double dt) {
    double dx = targetCol - col;
    double dy = targetRow - row;
    double dist = ui.Offset(dx, dy).distance;
    if (dist < speed * dt) {
      col = targetCol;
      row = targetRow;
      isDead = true;
    } else {
      col += (dx / dist) * speed * dt;
      row += (dy / dist) * speed * dt;
    }
  }
}

class PlayerStats {
  final int playerIndex;
  final String playerName;
  final String civId;
  final String colorHex;

  int woodGathered = 0;
  int foodGathered = 0;
  int goldGathered = 0;
  int stoneGathered = 0;

  int unitsTrained = 0;
  int unitsKilled = 0;
  int buildingsBuilt = 0;
  int buildingsDestroyed = 0;

  PlayerStats({
    required this.playerIndex,
    required this.playerName,
    required this.civId,
    required this.colorHex,
  });

  int get economyScore =>
      ((woodGathered + foodGathered + goldGathered + stoneGathered) ~/ 10) +
      (unitsTrained * 5);

  int get militaryScore =>
      (unitsKilled * 15) + (buildingsDestroyed * 40);

  int get totalScore => economyScore + militaryScore;
}

class TimelineSnapshot {
  final double elapsedSeconds;
  final List<int> populations; // index coincide con playerIndex
  final List<int> totalResources; // index coincide con playerIndex (wood + food + gold + stone)

  TimelineSnapshot({
    required this.elapsedSeconds,
    required this.populations,
    required this.totalResources,
  });
}


