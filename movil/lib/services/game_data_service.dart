// =====================================================================
// GAME DATA SERVICE — RTS Isométrico
// Fetches the full game configuration snapshot from Supabase and
// provides it to the game engine. Replaces all hardcoded stats.
// =====================================================================


import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../game/engine/game_state.dart';

/// Represents a civilization loaded from Supabase

class HeroConfig {
  final String id;
  final String name;
  final String? description;
  final String? lore;
  final String? category;
  final Map<String, dynamic> baseAttributes;
  final String? upgradesTo;

  HeroConfig({
    required this.id,
    required this.name,
    this.description,
    this.lore,
    this.category,
    this.baseAttributes = const {},
    this.upgradesTo,
  });

  factory HeroConfig.fromJson(Map<String, dynamic> json) {
    return HeroConfig(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      lore: json['lore']?.toString(),
      category: json['category']?.toString(),
      baseAttributes: json,
      upgradesTo: json['upgrades_to']?.toString(),
    );
  }

  dynamic getAttribute(String code, {dynamic defaultValue}) {
    return baseAttributes[code] ?? defaultValue;
  }
}

class CivilizationConfig {
  final String id;
  final String name;
  final String? description;
  final String? primaryColor;
  final String? emblemAssetPath;
  final List<Map<String, dynamic>> bonuses;

  CivilizationConfig({
    required this.id,
    required this.name,
    this.description,
    this.primaryColor,
    this.emblemAssetPath,
    this.bonuses = const [],
  });

  factory CivilizationConfig.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> parsedBonuses = [];
    if (json['bonuses'] != null) {
      if (json['bonuses'] is List) {
        parsedBonuses = (json['bonuses'] as List).cast<Map<String, dynamic>>();
      }
    }
    return CivilizationConfig(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      primaryColor: json['primary_color']?.toString(),
      emblemAssetPath: json['emblem_asset_path']?.toString(),
      bonuses: parsedBonuses,
    );
  }
}

/// Represents a unit type loaded from Supabase
class UnitConfig {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final Map<String, dynamic> baseAttributes;
  final String? upgradesTo;

  UnitConfig({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.baseAttributes = const {},
    this.upgradesTo,
  });

  factory UnitConfig.fromJson(Map<String, dynamic> json) {
    return UnitConfig(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString(),
      baseAttributes: json,
      upgradesTo: json['upgrades_to']?.toString(),
    );
  }

  dynamic getAttribute(String code, {dynamic defaultValue}) {
    return baseAttributes[code] ?? defaultValue;
  }

  int get maxHealth => (getAttribute('max_health', defaultValue: 100) as num).toInt();
  double get movementSpeed => (getAttribute('movement_speed', defaultValue: 1.0) as num).toDouble();
  double get attackRange => (getAttribute('attack_range', defaultValue: 1.0) as num).toDouble();
  double get meleeAttack => (getAttribute('melee_attack', defaultValue: 0) as num).toDouble();
  double get rangedAttack => (getAttribute('ranged_attack', defaultValue: 0) as num).toDouble();
  int get productionTime => (getAttribute('production_time', defaultValue: 10) as num).toInt();
  String? get spriteUrl => getAttribute('sprite_url');
  int get costFood => (getAttribute('cost_food', defaultValue: 0) as num).toInt();
  int get costWood => (getAttribute('cost_wood', defaultValue: 0) as num).toInt();
  int get costGold => (getAttribute('cost_gold', defaultValue: 0) as num).toInt();
  int get costStone => (getAttribute('cost_stone', defaultValue: 0) as num).toInt();
  int get populationCost => (getAttribute('population_cost', defaultValue: 1) as num).toInt();
}

/// Represents a building type loaded from Supabase
class BuildingConfig {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final Map<String, dynamic> baseAttributes;
  final String? upgradesTo;

  BuildingConfig({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.baseAttributes = const {},
    this.upgradesTo,
  });

  factory BuildingConfig.fromJson(Map<String, dynamic> json) {
    return BuildingConfig(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString(),
      baseAttributes: json,
      upgradesTo: json['upgrades_to']?.toString(),
    );
  }

  dynamic getAttribute(String code, {dynamic defaultValue}) {
    return baseAttributes[code] ?? defaultValue;
  }

  int get maxHealth => (getAttribute('max_health', defaultValue: 1000) as num).toInt();
  int get constructionTime => (getAttribute('construction_time', defaultValue: 30) as num).toInt();
  double get attackRange => (getAttribute('attack_range', defaultValue: 0) as num).toDouble();
  double get rangedAttack => (getAttribute('ranged_attack', defaultValue: 0) as num).toDouble();
  String? get spriteUrl => getAttribute('sprite_url');
  int get costWood => (getAttribute('cost_wood', defaultValue: 0) as num).toInt();
  int get costStone => (getAttribute('cost_stone', defaultValue: 0) as num).toInt();
  int get costGold => (getAttribute('cost_gold', defaultValue: 0) as num).toInt();
}

/// Represents a technology loaded from Supabase
class TechConfig {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final Map<String, dynamic> baseAttributes;
  final String? requiredEra;
  final List<String> requiredTechnologies;
  final String? upgradesTo;

  TechConfig({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.baseAttributes = const {},
    this.requiredEra,
    this.requiredTechnologies = const [],
    this.upgradesTo,
  });

  factory TechConfig.fromJson(Map<String, dynamic> json) {
    List<String> reqTechs = [];
    if (json['required_technologies'] is List) {
      reqTechs = (json['required_technologies'] as List).map((item) => item.toString()).toList();
    }
    return TechConfig(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString(),
      baseAttributes: json,
      requiredEra: json['required_era']?.toString(),
      requiredTechnologies: reqTechs,
      upgradesTo: json['upgrades_to']?.toString(),
    );
  }

  dynamic getAttribute(String code, {dynamic defaultValue}) {
    return baseAttributes[code] ?? defaultValue;
  }
}

/// A stat override for a specific civilization

class AttributeDefinition {
  final String id;
  final String code;
  final String name;
  final String type;
  final String? category;
  final String? icon;

  AttributeDefinition({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.category,
    this.icon,
  });

  factory AttributeDefinition.fromJson(Map<String, dynamic> json) {
    return AttributeDefinition(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      category: json['category']?.toString(),
      icon: json['icon']?.toString(),
    );
  }
}

class CivOverride {
  final String civilizationId;
  final String entityType;
  final String entityId;
  final String statKey;
  final String statValue;

  CivOverride({
    required this.civilizationId,
    required this.entityType,
    required this.entityId,
    required this.statKey,
    required this.statValue,
  });

  factory CivOverride.fromJson(Map<String, dynamic> json) {
    return CivOverride(
      civilizationId: json['civilization_id']?.toString() ?? '',
      entityType: json['entity_type']?.toString() ?? '',
      entityId: json['entity_id']?.toString() ?? '',
      statKey: json['stat_key']?.toString() ?? '',
      statValue: json['stat_value']?.toString() ?? '',
    );
  }
}

/// Relationship: which building produces which unit for a given civ
class BuildingProduction {
  final String buildingId;
  final String unitId;
  final String civilizationId;
  final String? requiredEra;

  BuildingProduction({
    required this.buildingId,
    required this.unitId,
    required this.civilizationId,
    this.requiredEra,
  });

  factory BuildingProduction.fromJson(Map<String, dynamic> json) {
    return BuildingProduction(
      buildingId: json['building_id']?.toString() ?? '',
      unitId: json['unit_id']?.toString() ?? '',
      civilizationId: json['civilization_id']?.toString() ?? '',
      requiredEra: json['required_era']?.toString(),
    );
  }
}

/// The full game data snapshot — everything the mobile client needs
class GameSnapshot {
  final int version;
  final List<CivilizationConfig> civilizations;
  final List<UnitConfig> units;
  final List<HeroConfig> heroes;
  final List<AttributeDefinition> attributeDefinitions;
  final List<BuildingConfig> buildings;
  final List<TechConfig> technologies;
  final List<CivOverride> overrides;
  final List<BuildingProduction> buildingProductions;
  // Raw relation data
  final List<Map<String, dynamic>> civUnits;
  final List<Map<String, dynamic>> civHeroes;
  final List<Map<String, dynamic>> civBuildings;
  final List<Map<String, dynamic>> civTechnologies;
  final List<Map<String, dynamic>> buildingResearches;
  final List<Map<String, dynamic>> technologyEffects;
  final List<Map<String, dynamic>> requirements;

  GameSnapshot({
    required this.version,
    required this.civilizations,
    required this.units,
    required this.heroes,
    required this.attributeDefinitions,
    required this.buildings,
    required this.technologies,
    required this.overrides,
    required this.buildingProductions,
    this.civUnits = const [],
    this.civHeroes = const [],
    this.civBuildings = const [],
    this.civTechnologies = const [],
    this.buildingResearches = const [],
    this.technologyEffects = const [],
    this.requirements = const [],
  });
}

/// GameDataService — Singleton that loads and caches game configuration.
/// The mobile app calls [loadSnapshot] on login or before a match.
class GameDataService extends ChangeNotifier {
  static final GameDataService _instance = GameDataService._internal();
  factory GameDataService() => _instance;
  GameDataService._internal();

  GameSnapshot? _snapshot;
  GameSnapshot? get snapshot => _snapshot;
  bool get isLoaded => _snapshot != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Load the full game snapshot from Supabase directly.
  /// Can also be pointed at the NestJS endpoint if desired.
  Future<void> loadSnapshot() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final client = Supabase.instance.client;

      // Fetch all tables in parallel (same as the NestJS snapshot endpoint)
      final results = await Future.wait([
        client.from('game_civilizations_data').select(),   // 0
        client.from('game_units_data').select(),           // 1
        client.from('game_buildings_data').select(),       // 2
        client.from('game_technologies_data').select(),    // 3
        client.from('game_heroes_data').select(),          // 4
        client.from('game_attribute_definitions').select(),// 5
        client.from('game_civilization_overrides').select(),// 6
        client.from('civ_units').select(),                 // 7
        client.from('civ_buildings').select(),             // 8
        client.from('civ_technologies').select(),          // 9
        client.from('civ_heroes').select(),                // 10
        client.from('building_produces_units').select(),   // 11
        client.from('building_researches').select(),       // 12
        client.from('game_technology_effects').select(),   // 13
        client.from('game_requirements').select(),         // 14
      ]);

      final civilizations = (results[0] as List).map((e) => CivilizationConfig.fromJson(e)).toList();
      final units = (results[1] as List).map((e) => UnitConfig.fromJson(e)).toList();
      final buildings = (results[2] as List).map((e) => BuildingConfig.fromJson(e)).toList();
      
      final technologies = (results[3] as List).map((e) => TechConfig.fromJson(e)).toList();
      // Inject era advance technologies
      technologies.add(TechConfig(
        id: 'tech_era_bronze',
        name: 'Edad de Bronce',
        description: 'Avanza a la Edad de Bronce para desbloquear nuevas unidades y tecnologías.',
        category: 'era_advance',
        baseAttributes: {
          'cost_food': 500,
          'cost_wood': 0,
          'cost_gold': 0,
          'cost_stone': 0,
          'affected_stat': 'bronze',
        },
        requiredEra: 'stone',
        requiredTechnologies: [],
      ));

      technologies.add(TechConfig(
        id: 'tech_era_iron',
        name: 'Edad de Hierro',
        description: 'Avanza a la Edad de Hierro para desbloquear las mejores unidades y tecnologías.',
        category: 'era_advance',
        baseAttributes: {
          'cost_food': 800,
          'cost_wood': 0,
          'cost_gold': 400,
          'cost_stone': 0,
          'affected_stat': 'iron',
        },
        requiredEra: 'bronze',
        requiredTechnologies: [],
      ));

      final heroes = (results[4] as List).map((e) => HeroConfig.fromJson(e)).toList();
      final attributeDefinitions = (results[5] as List).map((e) => AttributeDefinition.fromJson(e)).toList();
      final overrides = (results[6] as List).map((e) => CivOverride.fromJson(e)).toList();
      final civUnits = (results[7] as List).cast<Map<String, dynamic>>().toList();
      final civBuildings = (results[8] as List).cast<Map<String, dynamic>>().toList();
      final civTechnologies = (results[9] as List).cast<Map<String, dynamic>>().toList();
      final civHeroes = (results[10] as List).cast<Map<String, dynamic>>().toList();
      
      final buildingProductions = (results[11] as List).map((e) => BuildingProduction.fromJson(e)).toList();
      
      // Duplicar mapeos de producción para civs que no tengan (ej: Egipcios)
      final civIds = civilizations.map((c) => c.id).toList();
      for (var civId in civIds) {
        bool hasProductions = buildingProductions.any((bp) => bp.civilizationId == civId);
        if (!hasProductions) {
          debugPrint('GameDataService: Copiando mapeos de producción de civ_romans a $civId');
          final romansProds = buildingProductions.where((bp) => bp.civilizationId == 'civ_romans').toList();
          for (var rp in romansProds) {
            buildingProductions.add(BuildingProduction(
              buildingId: rp.buildingId,
              unitId: rp.unitId,
              civilizationId: civId,
              requiredEra: rp.requiredEra,
            ));
          }
        }
      }

      // Duplicar relaciones civ_units, civ_buildings si están vacías para otras civs
      for (var civId in civIds) {
        bool hasCivUnits = civUnits.any((cu) => cu['civilization_id'] == civId);
        if (!hasCivUnits) {
          debugPrint('GameDataService: Copiando civ_units de civ_romans a $civId');
          final romansUnits = civUnits.where((cu) => cu['civilization_id'] == 'civ_romans').toList();
          for (var ru in romansUnits) {
            civUnits.add({
              'civilization_id': civId,
              'unit_id': ru['unit_id'],
              'is_unique': false,
            });
          }
        }
        
        bool hasCivBldgs = civBuildings.any((cb) => cb['civilization_id'] == civId);
        if (!hasCivBldgs) {
          debugPrint('GameDataService: Copiando civ_buildings de civ_romans a $civId');
          final romansBldgs = civBuildings.where((cb) => cb['civilization_id'] == 'civ_romans').toList();
          for (var rb in romansBldgs) {
            civBuildings.add({
              'civilization_id': civId,
              'building_id': rb['building_id'],
              'is_unique': false,
            });
          }
        }
      }

      final buildingResearches = (results[12] as List).cast<Map<String, dynamic>>();
      final technologyEffects = (results[13] as List).cast<Map<String, dynamic>>();
      final requirements = (results[14] as List).cast<Map<String, dynamic>>();

      _snapshot = GameSnapshot(
        version: DateTime.now().millisecondsSinceEpoch,
        civilizations: civilizations,
        units: units,
        buildings: buildings,
        technologies: technologies,
        heroes: heroes,
        attributeDefinitions: attributeDefinitions,
        overrides: overrides,
        civUnits: civUnits,
        civBuildings: civBuildings,
        civTechnologies: civTechnologies,
        civHeroes: civHeroes,
        buildingProductions: buildingProductions,
        buildingResearches: buildingResearches,
        technologyEffects: technologyEffects,
        requirements: requirements,
      );

      debugPrint('GameDataService: Snapshot cargado — '
          '${_snapshot!.civilizations.length} civs, '
          '${_snapshot!.units.length} units, '
          '${_snapshot!.buildings.length} buildings, '
          '${_snapshot!.technologies.length} techs, '
          '${_snapshot!.overrides.length} overrides');

      // --- Pre-cargar todos los sprites en segundo plano (Pre-warm Cache) ---
      debugPrint('GameDataService: Pre-calentando caché de sprites en segundo plano...');
      for (var u in _snapshot!.units) {
        if (u.spriteUrl != null && u.spriteUrl!.isNotEmpty) {
          loadImageFromUrl(u.spriteUrl!).catchError((e) {
            debugPrint('Error pre-cargando sprite de unidad para ${u.name}: $e');
            return null;
          });
        }
      }
      for (var b in _snapshot!.buildings) {
        if (b.spriteUrl != null && b.spriteUrl!.isNotEmpty) {
          loadImageFromUrl(b.spriteUrl!).catchError((e) {
            debugPrint('Error pre-cargando sprite de edificio para ${b.name}: $e');
            return null;
          });
        }
      }

    } catch (e) {
      debugPrint('GameDataService ERROR: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Helpers for the game engine ────────────────────────────────────

  /// Get all civilizations available
  List<CivilizationConfig> get civilizations => _snapshot?.civilizations ?? [];

  /// Get civilization by ID
  CivilizationConfig? getCivilization(String id) {
    return _snapshot?.civilizations.where((c) => c.id == id).firstOrNull;
  }

  /// Get unit config by ID, with optional civ overrides applied
  UnitConfig? getUnit(String id) {
    return _snapshot?.units.where((u) => u.id == id).firstOrNull;
  }

  /// Get unit config by name (for backward compatibility with old hardcoded names)
  UnitConfig? getUnitByName(String name) {
    return _snapshot?.units.where((u) => u.name == name).firstOrNull;
  }

  /// Get building config by ID
  BuildingConfig? getBuilding(String id) {
    return _snapshot?.buildings.where((b) => b.id == id).firstOrNull;
  }

  /// Get building config by name
  BuildingConfig? getBuildingByName(String name) {
    return _snapshot?.buildings.where((b) => b.name == name).firstOrNull;
  }

  /// Get technology config by ID
  TechConfig? getTech(String id) {
    return _snapshot?.technologies.where((t) => t.id == id).firstOrNull;
  }

  /// Get technology config by name
  TechConfig? getTechByName(String name) {
    return _snapshot?.technologies.where((t) => t.name == name).firstOrNull;
  }

  /// Get all units available for a specific civilization
  List<UnitConfig> getUnitsForCiv(String civId) {
    if (_snapshot == null) return [];
    final civUnitIds = _snapshot!.civUnits
        .where((cu) => cu['civilization_id'] == civId)
        .map((cu) => cu['unit_id'])
        .toSet();
    return _snapshot!.units.where((u) => civUnitIds.contains(u.id)).toList();
  }

  /// Get all buildings available for a specific civilization
  List<BuildingConfig> getBuildingsForCiv(String civId) {
    if (_snapshot == null) return [];
    final civBuildingIds = _snapshot!.civBuildings
        .where((cb) => cb['civilization_id'] == civId)
        .map((cb) => cb['building_id'])
        .toSet();
    return _snapshot!.buildings.where((b) => civBuildingIds.contains(b.id)).toList();
  }

  /// Get what a building produces for a given civ
  List<UnitConfig> getBuildingProduction(String buildingId, String civId) {
    if (_snapshot == null) return [];
    final unitIds = _snapshot!.buildingProductions
        .where((bp) => bp.buildingId == buildingId && bp.civilizationId == civId)
        .map((bp) => bp.unitId)
        .toSet();
    return _snapshot!.units.where((u) => unitIds.contains(u.id)).toList();
  }

  /// Get all overrides for a specific civilization
  List<CivOverride> getOverridesForCiv(String civId) {
    return _snapshot?.overrides.where((o) => o.civilizationId == civId).toList() ?? [];
  }

  /// Get overridden stat value for a specific entity in a civilization.
  /// Returns null if no override exists.
  double? getOverriddenStat(String civId, String entityType, String entityId, String statKey) {
    final override = _snapshot?.overrides.where((o) =>
        o.civilizationId == civId &&
        o.entityType == entityType &&
        o.entityId == entityId &&
        o.statKey == statKey
    ).firstOrNull;
    if (override == null) return null;
    return double.tryParse(override.statValue);
  }
}
