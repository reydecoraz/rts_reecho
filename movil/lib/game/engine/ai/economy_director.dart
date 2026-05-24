import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/game_models.dart';
import '../../../services/game_data_service.dart';
import '../game_state.dart';
import 'city_planner.dart';

class EconomyDirector {
  final GameState state;
  final Random rand = Random();

  EconomyDirector(this.state);

  String? getWorkerName(String civId) {
    var units = GameDataService().getUnitsForCiv(civId);
    return units.where((u) => u.category == 'worker').firstOrNull?.name ?? 'Aldeano';
  }

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

  bool processEconomy(int pIdx, Iterable<GameEntity> myBuildings, int curPop, int popLimit, int workersCount, bool allowConstruction) {
    String civId = state.players[pIdx].civId;
    String? workerName = getWorkerName(civId);
    String? tcName = _getBuildingName(civId, 'town_center');
    String? houseName = _getBuildingName(civId, 'house');
    String? lumberName = _getBuildingName(civId, 'resource_wood');
    String? miningName = _getBuildingName(civId, 'resource_gold_stone');
    String? farmName = _getBuildingName(civId, 'farm');

    debugPrint('AI ECONOMY [Player $pIdx]: worker=$workerName, tc=$tcName, house=$houseName, lumber=$lumberName, mining=$miningName, farm=$farmName, pop=$curPop/$popLimit, workers=$workersCount, wood=${state.playerResources[pIdx].wood}, food=${state.playerResources[pIdx].food}');

    if (workerName == null || tcName == null) {
      debugPrint('AI ECONOMY [Player $pIdx] ABORTED: workerName or tcName is null!');
      return false;
    }



    // 1. Producir Aldeanos (hasta 30, o la mitad del límite de población) - No consume cooldown global
    int maxWorkers = (popLimit * 0.5).clamp(10, 30).toInt();
    if (curPop < popLimit && workersCount < maxWorkers && state.playerResources[pIdx].food >= 50) {
      var tc = myBuildings.where((b) => b.name == tcName && b.hp >= b.maxHp * 0.15 && b.productionName == null).firstOrNull;
      if (tc != null) {
        state.playerResources[pIdx].food -= 50;
        tc.productionName = workerName;
        tc.productionTimer = entityBaseStats[workerName]?.creationTime ?? 3.0;
        debugPrint('AI ECONOMY [Player $pIdx] Queued worker: $workerName in TC at (${tc.col}, ${tc.row})');
      }
    }

    // 2. Construir Casas para no quedarse "population blocked" (con radio ampliado de 20)
    int houseThreshold = popLimit < 30 ? 5 : 3;
    if (allowConstruction && houseName != null && popLimit - curPop <= houseThreshold && state.playerResources[pIdx].wood >= 25) {
      var candidateBldgs = myBuildings.where((e) => e.name == tcName || e.name == houseName).toList()..shuffle();
      GameEntity? tc = myBuildings.where((e) => e.name == tcName).firstOrNull;
      GameEntity? centerBldg = candidateBldgs.isNotEmpty ? candidateBldgs.first : (tc ?? myBuildings.firstOrNull);
      
      if (centerBldg != null && tc != null) {
        final planner = CityPlanner(state.tiles, state.entities);
        final spot = planner.findSafeBuildSpot(tc.col.round(), tc.row.round(), 20);
        debugPrint('AI ECONOMY [Player $pIdx] House build spot check: $spot');
        if (spot != null) {
          state.playerResources[pIdx].wood -= 25;
          spot.isWalkable = false;
          state.entities.add(GameEntity(
            id: 'house_${pIdx}_${rand.nextInt(99999)}', playerIndex: pIdx, type: EntityType.building, name: houseName,
            col: spot.col.toDouble(), row: spot.row.toDouble(), hp: 1, maxHp: entityBaseStats[houseName]?.maxHp ?? 100,
          ));
          debugPrint('AI ECONOMY [Player $pIdx] Placed house at (${spot.col}, ${spot.row})');
          return true;
        }
      }
    }

    // 3. Campamentos Madereros
    if (allowConstruction && lumberName != null) {
      int lumberCampsCount = myBuildings.where((b) => b.name == lumberName).length;
      if (state.playerResources[pIdx].wood >= 50 && lumberCampsCount < 2 && workersCount >= 3) {
        GameEntity? tc = myBuildings.where((e) => e.name == tcName).firstOrNull;
        if (tc != null) {
          final planner = CityPlanner(state.tiles, state.entities);
          final spot = planner.findResourceBuildSpot(tc.col.round(), tc.row.round(), 25, [ResourceType.wood]); 
          debugPrint('AI ECONOMY [Player $pIdx] Lumber camp build spot check: $spot');
          if (spot != null) {
            state.playerResources[pIdx].wood -= 50;
            spot.isWalkable = false;
            state.entities.add(GameEntity(
              id: 'lumbercamp_${pIdx}_${rand.nextInt(99999)}', playerIndex: pIdx, type: EntityType.building, name: lumberName,
              col: spot.col.toDouble(), row: spot.row.toDouble(), hp: 1, maxHp: entityBaseStats[lumberName]?.maxHp ?? 100,
            ));
            debugPrint('AI ECONOMY [Player $pIdx] Placed lumber camp at (${spot.col}, ${spot.row})');
            return true;
          }
        }
      }
    }

    // 4. Campamentos Mineros
    if (allowConstruction && miningName != null) {
      int miningCampsCount = myBuildings.where((b) => b.name == miningName).length;
      if (state.playerResources[pIdx].wood >= 50 && miningCampsCount < 2 && workersCount >= 6) {
        GameEntity? tc = myBuildings.where((e) => e.name == tcName).firstOrNull;
        if (tc != null) {
          final planner = CityPlanner(state.tiles, state.entities);
          final spot = planner.findResourceBuildSpot(tc.col.round(), tc.row.round(), 25, [ResourceType.gold, ResourceType.stone]); 
          debugPrint('AI ECONOMY [Player $pIdx] Mining camp build spot check: $spot');
          if (spot != null) {
            state.playerResources[pIdx].wood -= 50;
            spot.isWalkable = false;
            state.entities.add(GameEntity(
              id: 'miningcamp_${pIdx}_${rand.nextInt(99999)}', playerIndex: pIdx, type: EntityType.building, name: miningName,
              col: spot.col.toDouble(), row: spot.row.toDouble(), hp: 1, maxHp: entityBaseStats[miningName]?.maxHp ?? 100,
            ));
            debugPrint('AI ECONOMY [Player $pIdx] Placed mining camp at (${spot.col}, ${spot.row})');
            return true;
          }
        }
      }
    }

    // 5. Granjas
    if (allowConstruction && farmName != null) {
      int farmsCount = myBuildings.where((b) => b.name == farmName).length;
      if (state.playerResources[pIdx].wood >= 130 && farmsCount < (workersCount * 0.3).ceil() + 1) {
        GameEntity? tc = myBuildings.where((e) => e.name == tcName).firstOrNull;
        if (tc != null) {
          final planner = CityPlanner(state.tiles, state.entities);
          final spot = planner.findSafeBuildSpot(tc.col.round(), tc.row.round(), 8, ignoreMinDistance: true); 
          debugPrint('AI ECONOMY [Player $pIdx] Farm build spot check: $spot');
          if (spot != null) {
            state.playerResources[pIdx].wood -= 60;
            spot.isWalkable = true; 
            spot.resource = ResourceNode(type: ResourceType.food, amount: 99999, maxAmount: 99999);
            state.entities.add(GameEntity(
              id: 'farm_${pIdx}_${rand.nextInt(99999)}', playerIndex: pIdx, type: EntityType.building, name: farmName,
              col: spot.col.toDouble(), row: spot.row.toDouble(), hp: 1, maxHp: entityBaseStats[farmName]?.maxHp ?? 100,
            ));
            debugPrint('AI ECONOMY [Player $pIdx] Placed farm at (${spot.col}, ${spot.row})');
            return true;
          }
        }
      }
    }

    return false;
  }

  void balanceWorkers(int pIdx, Iterable<GameEntity> myBuildings) {
    String civId = state.players[pIdx].civId;
    String? workerName = getWorkerName(civId);
    String? farmName = _getBuildingName(civId, 'farm');

    if (workerName == null || farmName == null) return;

    var myFarms = myBuildings.where((b) => b.name == farmName && b.hp == b.maxHp);
    int foodWorkers = state.entities.where((e) => e.playerIndex == pIdx && e.type == EntityType.unit && e.workerRole == 'food').length;
    
    // Si hay más granjas que granjeros, asignar inactivos o madereros a comida
    if (foodWorkers < myFarms.length) {
      var candidate = state.entities.where((e) => 
        e.playerIndex == pIdx && 
        e.type == EntityType.unit && 
        e.name == workerName && 
        e.workerRole != 'food' && 
        (e.state == EntityState.idle || e.workerRole == 'wood')
      ).firstOrNull;

      if (candidate != null) {
        candidate.workerRole = 'food';
        candidate.targetResourceTile = null;
        candidate.state = EntityState.idle;
        candidate.pathTimer = 0.0;
      }
    } else if (foodWorkers > myFarms.length) {
      // Si sobran granjeros, mandarlos a madera o inactivos a madera
      var candidate = state.entities.where((e) => 
        e.playerIndex == pIdx && 
        e.type == EntityType.unit && 
        e.name == workerName && 
        e.workerRole == 'food' && 
        e.state == EntityState.idle
      ).firstOrNull;

      if (candidate != null) {
        candidate.workerRole = 'wood';
        candidate.targetResourceTile = null;
        candidate.state = EntityState.idle;
        candidate.pathTimer = 0.0;
      }
    }
  }

  void assignIdleWorkersGlobal() {
    for (int pIdx = 0; pIdx < state.players.length; pIdx++) {
      String civId = state.players[pIdx].civId;
      String? workerName = getWorkerName(civId);
      String? farmName = _getBuildingName(civId, 'farm');

      if (workerName == null || farmName == null) continue;

      var idleWorkers = state.entities.where((e) => 
        e.playerIndex == pIdx && 
        e.type == EntityType.unit && 
        e.name == workerName && 
        e.state == EntityState.idle
      ).toList();

      if (idleWorkers.isEmpty) continue;

      int foodWorkers = state.entities.where((e) => e.playerIndex == pIdx && e.type == EntityType.unit && e.workerRole == 'food' && e.state != EntityState.idle).length;
      int woodWorkers = state.entities.where((e) => e.playerIndex == pIdx && e.type == EntityType.unit && e.workerRole == 'wood' && e.state != EntityState.idle).length;
      int goldWorkers = state.entities.where((e) => e.playerIndex == pIdx && e.type == EntityType.unit && e.workerRole == 'gold' && e.state != EntityState.idle).length;
      int stoneWorkers = state.entities.where((e) => e.playerIndex == pIdx && e.type == EntityType.unit && e.workerRole == 'stone' && e.state != EntityState.idle).length;

      int totalWorkers = state.entities.where((e) => e.playerIndex == pIdx && GameDataService().getUnitByName(e.name)?.category == 'worker').length;
      int targetWood = (totalWorkers * 0.35).clamp(2, 15).toInt();
      int targetFood = (totalWorkers * 0.35).clamp(2, 15).toInt();

      for (var worker in idleWorkers) {
        var myFarms = state.entities.where((e) => 
          e.playerIndex == pIdx && 
          e.name == farmName && 
          e.hp == e.maxHp
        ).toList();

        if (foodWorkers < targetFood && foodWorkers < myFarms.length) {
          worker.workerRole = 'food';
          foodWorkers++;
        } else if (woodWorkers < targetWood) {
          worker.workerRole = 'wood';
          woodWorkers++;
        } else if (woodWorkers < foodWorkers) {
          worker.workerRole = 'wood';
          woodWorkers++;
        } else {
          // Distribuir equitativamente entre oro y piedra
          if (stoneWorkers < goldWorkers) {
            worker.workerRole = 'stone';
            stoneWorkers++;
          } else {
            worker.workerRole = 'gold';
            goldWorkers++;
          }
        }
      }
    }
  }
}
