import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/game_models.dart';
import '../game_state.dart';
import '../../../services/game_data_service.dart';
import 'economy_director.dart';
import 'military_director.dart';

class AiDirector {
  final GameState state;
  final Random rand = Random();
  
  late final EconomyDirector economy;
  late final MilitaryDirector military;

  AiDirector(this.state) {
    economy = EconomyDirector(state);
    military = MilitaryDirector(state);
  }

  // Cooldown de construcción global por jugador IA (en segundos)
  final Map<int, double> buildCooldowns = {};

  void processServerTick() {
    economy.assignIdleWorkersGlobal();

    // Debug temporal para verificar mapeos de producción
    if (state.gameTick % 10 == 0) {
      debugPrint('AI DEBUG: buildingProduces = ${state.buildingProduces}');
      debugPrint('AI DEBUG: entityBaseStats keys = ${entityBaseStats.keys.toList()}');
    }

    for (var sp in state.spawnZones) {
      int pIdx = sp.playerIndex;
      if (state.players[pIdx].type != PlayerType.ai) continue;

      // Inicializar el cooldown de construcción si no existe (retardo inicial de 10 a 25 segundos)
      buildCooldowns.putIfAbsent(pIdx, () => 10.0 + rand.nextDouble() * 15.0);

      // Disminuir el cooldown (este tick ocurre cada 0.5s)
      if (buildCooldowns[pIdx]! > 0) {
        buildCooldowns[pIdx] = buildCooldowns[pIdx]! - 0.5;
      }

      state.aiDecisionTimers[pIdx] -= 0.5; 
      if (state.aiDecisionTimers[pIdx] > 0) continue;
      state.aiDecisionTimers[pIdx] = 2.0 + (rand.nextDouble() * 2.0); 

      int curPop = state.currentPopulation(pIdx);
      int popLimit = state.maxPopulation(pIdx);
      var myBuildings = state.entities.where((e) => e.playerIndex == pIdx && e.type == EntityType.building).toList();
      String? workerName = economy.getWorkerName(state.players[pIdx].civId);
      int workersCount = state.entities.where((e) => e.playerIndex == pIdx && e.name == workerName).length;

      bool allowConstruction = buildCooldowns[pIdx]! <= 0;

      // 1. Delegar al Director Económico
      bool econBuilt = economy.processEconomy(pIdx, myBuildings, curPop, popLimit, workersCount, allowConstruction);
      economy.balanceWorkers(pIdx, myBuildings);

      if (econBuilt) {
        buildCooldowns[pIdx] = 12.0 + rand.nextDouble() * 8.0; // Cooldown de 12 a 20 segundos
        allowConstruction = false; // Desactivar construcción militar por este tick
      }

      // 2. Delegar al Director Militar
      bool milBuilt = military.processMilitary(pIdx, myBuildings, curPop, popLimit, workersCount, allowConstruction);

      if (milBuilt) {
        buildCooldowns[pIdx] = 15.0 + rand.nextDouble() * 10.0; // Cooldown de 15 a 25 segundos para edificios militares
      }

      // 3. Investigaciones y Avance de Era de la IA
      _processAiResearch(pIdx);
    }

    // Curación pasiva de edificios
    for (var entity in state.entities) {
      if (entity.type == EntityType.building && entity.hp < entity.maxHp) {
        entity.hp += 10; 
        if (entity.hp > entity.maxHp) {
          entity.hp = entity.maxHp; 
        }
      }
    }
  }

  void _processAiResearch(int pIdx) {
    final snapshot = GameDataService().snapshot;
    if (snapshot == null) {
      debugPrint('AI RESEARCH DEBUG [Player $pIdx]: Snapshot is null!');
      return;
    }

    final resources = state.playerResources[pIdx];
    // debugPrint('AI RESEARCH DEBUG [Player $pIdx]: Processing ${snapshot.technologies.length} techs...');

    for (var tech in snapshot.technologies) {
      bool can = state.techManager.canResearch(pIdx, tech.id);
      if (!can) {
        // debugPrint('AI RESEARCH DEBUG [Player $pIdx]: Cannot research ${tech.name} (id: ${tech.id})');
        continue;
      }
      
      bool isEraAdvance = tech.category == 'era_advance';
      
      // Si es avance de era, investigarlo con alta prioridad
      if (isEraAdvance) {
        state.techManager.researchTechnology(pIdx, tech.id);
        debugPrint('AI RESEARCH [Player $pIdx]: Advanced to next era using ${tech.name}');
        break; // Solo una investigación por tick
      }
      
      // Para tecnologías normales, mantener un buffer de seguridad
      int woodCost = (tech.getAttribute('cost_wood', defaultValue: 0) as num).toInt();
      int foodCost = (tech.getAttribute('cost_food', defaultValue: 0) as num).toInt();
      int goldCost = (tech.getAttribute('cost_gold', defaultValue: 0) as num).toInt();
      
      if (resources.wood - woodCost >= 150 &&
          resources.food - foodCost >= 150 &&
          resources.gold - goldCost >= 100) {
        state.techManager.researchTechnology(pIdx, tech.id);
        debugPrint('AI RESEARCH [Player $pIdx]: Researched ${tech.name}');
        break; // Solo una investigación por tick
      } else {
        // debugPrint('AI RESEARCH DEBUG [Player $pIdx]: Failed resource check for ${tech.name} (wood: ${resources.wood}, woodCost: $woodCost)');
      }
    }
  }
}
