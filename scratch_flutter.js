const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'movil', 'lib', 'services', 'game_data_service.dart');
let content = fs.readFileSync(filePath, 'utf8');

// Replace UnitConfig
const unitConfigRegex = /class UnitConfig \{[\s\S]*?factory UnitConfig\.fromJson\(Map<String, dynamic> json\) \{[\s\S]*?\}\s*\}/;
const newUnitConfig = `class UnitConfig {
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
      baseAttributes: json['base_attributes'] as Map<String, dynamic>? ?? {},
      upgradesTo: json['upgrades_to']?.toString(),
    );
  }

  dynamic getAttribute(String code, {dynamic defaultValue}) {
    return baseAttributes[code] ?? defaultValue;
  }
}`;
content = content.replace(unitConfigRegex, newUnitConfig);

// Replace BuildingConfig
const buildingConfigRegex = /class BuildingConfig \{[\s\S]*?factory BuildingConfig\.fromJson\(Map<String, dynamic> json\) \{[\s\S]*?\}\s*\}/;
const newBuildingConfig = `class BuildingConfig {
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
      baseAttributes: json['base_attributes'] as Map<String, dynamic>? ?? {},
      upgradesTo: json['upgrades_to']?.toString(),
    );
  }

  dynamic getAttribute(String code, {dynamic defaultValue}) {
    return baseAttributes[code] ?? defaultValue;
  }
}`;
content = content.replace(buildingConfigRegex, newBuildingConfig);

// Replace TechConfig
const techConfigRegex = /class TechConfig \{[\s\S]*?factory TechConfig\.fromJson\(Map<String, dynamic> json\) \{[\s\S]*?\}\s*\}/;
const newTechConfig = `class TechConfig {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final Map<String, dynamic> baseAttributes;
  final String? upgradesTo;

  TechConfig({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.baseAttributes = const {},
    this.upgradesTo,
  });

  factory TechConfig.fromJson(Map<String, dynamic> json) {
    return TechConfig(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString(),
      baseAttributes: json['base_attributes'] as Map<String, dynamic>? ?? {},
      upgradesTo: json['upgrades_to']?.toString(),
    );
  }

  dynamic getAttribute(String code, {dynamic defaultValue}) {
    return baseAttributes[code] ?? defaultValue;
  }
}`;
content = content.replace(techConfigRegex, newTechConfig);


// Add HeroConfig before CivilizationConfig
const heroConfigCode = `
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
      baseAttributes: json['base_attributes'] as Map<String, dynamic>? ?? {},
      upgradesTo: json['upgrades_to']?.toString(),
    );
  }

  dynamic getAttribute(String code, {dynamic defaultValue}) {
    return baseAttributes[code] ?? defaultValue;
  }
}
`;
if (!content.includes('class HeroConfig')) {
    content = content.replace('class CivilizationConfig', heroConfigCode + '\nclass CivilizationConfig');
}

// Add AttributeDefinition
const attrDefCode = `
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
`;
if (!content.includes('class AttributeDefinition')) {
    content = content.replace('class CivOverride', attrDefCode + '\nclass CivOverride');
}

// Update GameSnapshot class
let snapshotClass = content.match(/class GameSnapshot \{[\s\S]*?\}\s*}/)[0];
let newSnapshotClass = snapshotClass
    .replace('final List<UnitConfig> units;', 'final List<UnitConfig> units;\n  final List<HeroConfig> heroes;\n  final List<AttributeDefinition> attributeDefinitions;')
    .replace('required this.units,', 'required this.units,\n    required this.heroes,\n    required this.attributeDefinitions,')
    .replace('this.civUnits = const [],', 'this.civUnits = const [],\n    this.civHeroes = const [],')
    .replace('final List<Map<String, dynamic>> civUnits;', 'final List<Map<String, dynamic>> civUnits;\n  final List<Map<String, dynamic>> civHeroes;');
content = content.replace(snapshotClass, newSnapshotClass);

// Update loadSnapshot queries
let loadSnapshotFunc = content.match(/final results = await Future\.wait\(\[[\s\S]*?\]\);/)[0];
let newLoadSnapshotFunc = `final results = await Future.wait([
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
      ]);`;
content = content.replace(loadSnapshotFunc, newLoadSnapshotFunc);

// Update Snapshot instantiation
let snapshotInst = content.match(/_snapshot = GameSnapshot\([\s\S]*?\);/)[0];
let newSnapshotInst = `_snapshot = GameSnapshot(
        version: DateTime.now().millisecondsSinceEpoch,
        civilizations: (results[0] as List).map((e) => CivilizationConfig.fromJson(e)).toList(),
        units: (results[1] as List).map((e) => UnitConfig.fromJson(e)).toList(),
        buildings: (results[2] as List).map((e) => BuildingConfig.fromJson(e)).toList(),
        technologies: (results[3] as List).map((e) => TechConfig.fromJson(e)).toList(),
        heroes: (results[4] as List).map((e) => HeroConfig.fromJson(e)).toList(),
        attributeDefinitions: (results[5] as List).map((e) => AttributeDefinition.fromJson(e)).toList(),
        overrides: (results[6] as List).map((e) => CivOverride.fromJson(e)).toList(),
        civUnits: (results[7] as List).cast<Map<String, dynamic>>(),
        civBuildings: (results[8] as List).cast<Map<String, dynamic>>(),
        civTechnologies: (results[9] as List).cast<Map<String, dynamic>>(),
        civHeroes: (results[10] as List).cast<Map<String, dynamic>>(),
        buildingProductions: (results[11] as List).map((e) => BuildingProduction.fromJson(e)).toList(),
        buildingResearches: (results[12] as List).cast<Map<String, dynamic>>(),
        technologyEffects: (results[13] as List).cast<Map<String, dynamic>>(),
        requirements: (results[14] as List).cast<Map<String, dynamic>>(),
      );`;
content = content.replace(snapshotInst, newSnapshotInst);

fs.writeFileSync(filePath, content, 'utf8');
console.log('Done!');
