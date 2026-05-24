import 'dart:math';
import '../../models/game_models.dart';
import '../../../services/game_data_service.dart';
import '../game_state.dart';
import 'city_planner.dart';
import 'pathfinding_manager.dart';

class MilitaryDirector {
  final GameState state;
  final Random rand = Random();

  MilitaryDirector(this.state);

  String? _getBuildingName(String civId, String category) {
    var buildings = GameDataService().getBuildingsForCiv(civId);
    var found = buildings.where((b) => b.category == category).firstOrNull?.name;
    if (found != null) return found;
    switch(category) {
      case 'town_center': return 'Centro Urbano';
      case 'house': return 'Casa';
      case 'resource_wood': return 'Campamento Maderero';
      case 'resource_gold_stone': return 'Mina';
      case 'farm': return 'Granja';
      case 'military_barracks': return 'Cuartel';
      case 'military_archery': return 'Galería de Tiro';
      case 'military_stable': return 'Establo';
    }
    return null;
  }

  bool _isMilitaryUnit(String unitName) {
    var unit = GameDataService().getUnitByName(unitName);
    if (unit == null) return false;
    return unit.category != 'worker' && unit.category != 'civilian' && unit.category != 'building';
  }

  bool processMilitary(int pIdx, Iterable<GameEntity> myBuildings, int curPop, int popLimit, int workersCount, bool allowConstruction) {
    String civId = state.players[pIdx].civId;

    String? barracksName = _getBuildingName(civId, 'military_barracks');
    String? archeryName = _getBuildingName(civId, 'military_archery');
    String? stableName = _getBuildingName(civId, 'military_stable');

    // 1. Construir Edificios Militares
    int barracksCount = barracksName != null ? myBuildings.where((b) => b.name == barracksName).length : 0;
    int archeryCount = archeryName != null ? myBuildings.where((b) => b.name == archeryName).length : 0;
    int stableCount = stableName != null ? myBuildings.where((b) => b.name == stableName).length : 0;

    if (allowConstruction && barracksName != null && barracksCount < 3 && state.playerResources[pIdx].wood >= 100 && workersCount >= 5) {
      GameEntity? centerBldg = (myBuildings.toList()..shuffle()).firstOrNull;
      if (centerBldg != null) {
        final planner = CityPlanner(state.tiles, state.entities);
        MapTile? spot;
        for (int radius in [10, 14, 18, 22]) {
          spot = planner.findSafeBuildSpot(centerBldg.col.round(), centerBldg.row.round(), radius);
          if (spot != null) break;
        }
        if (spot != null) {
          state.playerResources[pIdx].wood -= 100;
          spot.isWalkable = false;
          state.addBuildingEntity(pIdx, GameEntity(
            id: 'barracks_${pIdx}_${rand.nextInt(99999)}', playerIndex: pIdx, type: EntityType.building, name: barracksName,
            col: spot.col.toDouble(), row: spot.row.toDouble(), hp: 1, maxHp: entityBaseStats[barracksName]?.maxHp ?? 100,
          ));
          return true;
        }
      }
    } else if (allowConstruction && archeryName != null && state.playerResources[pIdx].wood >= 150 && barracksCount >= 1 && archeryCount < 2) {
      GameEntity? centerBldg = (myBuildings.toList()..shuffle()).firstOrNull;
      if (centerBldg != null) {
        final planner = CityPlanner(state.tiles, state.entities);
        MapTile? spot;
        for (int radius in [12, 16, 20, 24]) {
          spot = planner.findSafeBuildSpot(centerBldg.col.round(), centerBldg.row.round(), radius);
          if (spot != null) break;
        }
        if (spot != null) {
          state.playerResources[pIdx].wood -= 150;
          spot.isWalkable = false;
          state.addBuildingEntity(pIdx, GameEntity(id: 'archery_${pIdx}_${rand.nextInt(99999)}', playerIndex: pIdx, type: EntityType.building, name: archeryName, col: spot.col.toDouble(), row: spot.row.toDouble(), hp: 1, maxHp: entityBaseStats[archeryName]?.maxHp ?? 100));
          return true;
        }
      }
    } else if (allowConstruction && stableName != null && state.playerResources[pIdx].wood >= 175 && archeryCount >= 1 && stableCount < 1) {
      GameEntity? centerBldg = (myBuildings.toList()..shuffle()).firstOrNull;
      if (centerBldg != null) {
        final planner = CityPlanner(state.tiles, state.entities);
        MapTile? spot;
        for (int radius in [8, 12, 16, 20]) {
          spot = planner.findSafeBuildSpot(centerBldg.col.round(), centerBldg.row.round(), radius);
          if (spot != null) break;
        }
        if (spot != null) {
          state.playerResources[pIdx].wood -= 175;
          spot.isWalkable = false;
          state.addBuildingEntity(pIdx, GameEntity(id: 'stable_${pIdx}_${rand.nextInt(99999)}', playerIndex: pIdx, type: EntityType.building, name: stableName, col: spot.col.toDouble(), row: spot.row.toDouble(), hp: 1, maxHp: entityBaseStats[stableName]?.maxHp ?? 100));
          return true;
        }
      }
    }

    // 2. Producir Unidades Militares Dinámicamente (Según buildingProduces de Supabase)
    if (curPop < popLimit && state.buildingProduces.isNotEmpty) {
      for (var bName in List<String>.from(state.buildingProduces.keys)) {
        var bList = myBuildings.where((b) => b.name == bName && b.hp >= b.maxHp * 0.70 && b.productionName == null).toList();
        for (var bInstance in bList) {
          if (curPop >= popLimit) break;
          String targetUnit = state.buildingProduces[bName]!.first;
          
          // Solo producimos militares en esta rutina, los trabajadores los hace EconomyDirector
          if (!_isMilitaryUnit(targetUnit)) continue;

          var stats = entityBaseStats[targetUnit];
          if (stats == null) continue;

          if (state.playerResources[pIdx].food >= stats.costFood && 
              state.playerResources[pIdx].wood >= stats.costWood && 
              state.playerResources[pIdx].gold >= stats.costGold) {
              
              state.playerResources[pIdx].food = (state.playerResources[pIdx].food - stats.costFood).toInt();
              state.playerResources[pIdx].wood = (state.playerResources[pIdx].wood - stats.costWood).toInt();
              state.playerResources[pIdx].gold = (state.playerResources[pIdx].gold - stats.costGold).toInt();
              
              bInstance.productionName = targetUnit;
              bInstance.productionTimer = stats.creationTime;
              curPop += stats.populationCost;
          }
        }
      }
    }

    // 3. Organizar Ataques
    if (state.gameTick % 10 == 0) { 
      var army = state.entities.where((e) => 
        e.playerIndex == pIdx && e.type == EntityType.unit && 
        _isMilitaryUnit(e.name) &&
        e.state == EntityState.idle
      ).toList();

      if (army.length >= 8) { 
        String? enemyTcName = _getBuildingName(state.players.firstWhere((p) => p.index != pIdx, orElse: () => state.players[0]).civId, 'town_center');
        
        GameEntity? enemyBase = state.entities.where((e) => 
          e.playerIndex != pIdx && e.playerIndex != -1 && e.type == EntityType.building && 
          (enemyTcName != null && e.name == enemyTcName)
        ).firstOrNull;

        if (enemyBase == null) {
          enemyBase = state.entities.where((e) => 
            e.playerIndex != pIdx && e.playerIndex != -1 && e.type == EntityType.building
          ).firstOrNull;
        }

        if (enemyBase != null) {
          int count = army.length;
          int gridSize = sqrt(count).ceil();
          
          double slowest = 99.0;
          for(var s in army) {
            double baseSpd = entityBaseStats[s.name]?.speed ?? 2.0;
            double sSpeed = state.techManager.getUnitStat(s, 'movement_speed', baseSpd);
            if (sSpeed < slowest) slowest = sSpeed;
          }

          for (int i = 0; i < count; i++) {
            int r = i ~/ gridSize;
            int c = i % gridSize;
            int targetCol = enemyBase.col.round() + (c - gridSize ~/ 2);
            int targetRow = enemyBase.row.round() + (r - gridSize ~/ 2);

            var soldier = army[i];
            soldier.groupSpeed = slowest; 
            soldier.currentPath = PathfindingManager.findPath(
              state.tiles, soldier.col.round(), soldier.row.round(), targetCol, targetRow
            );
            if (soldier.currentPath.isNotEmpty) {
              soldier.state = EntityState.attacking;
            }
          }
        }
      }
    }
    return false;
  }
}
