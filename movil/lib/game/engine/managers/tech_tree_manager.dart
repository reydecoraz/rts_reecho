import 'package:flutter/foundation.dart';
import '../../models/game_models.dart';
import '../../../services/game_data_service.dart';
import '../game_state.dart';

class TechTreeManager {
  final GameState gameState;
  List<PlayerTechState> get playerTechStates => gameState.playerTechStates;

  TechTreeManager(this.gameState);

  double getUnitStat(GameEntity entity, String statKey, double baseValue) {
    if (entity.playerIndex < 0 || entity.playerIndex >= playerTechStates.length) return baseValue;
    double mult = playerTechStates[entity.playerIndex].getMultiplier(entity.name, statKey);
    double bonus = playerTechStates[entity.playerIndex].getBonusValue(entity.name, statKey);
    return (baseValue * mult) + bonus;
  }

  bool canResearch(int playerIndex, String techId) {
    if (playerIndex < 0 || playerIndex >= playerTechStates.length) return false;
    final state = playerTechStates[playerIndex];
    if (state.unlockedTechIds.contains(techId)) return false;

    final tech = GameDataService().getTech(techId);
    if (tech == null) return false;

    // 1. Validar Era
    if (tech.requiredEra != null && tech.requiredEra!.isNotEmpty && tech.requiredEra != state.currentEra) {
       // Logica simplificada: Si no es la misma era, y asumiendo un orden lineal (dark_age -> feudal_age -> etc)
       // Para hacerlo seguro y dinámico, asumimos que debe coincidir o estar en la lista de investigadas
       // Pero por diseño dictado en el DB, requiredEra valida "estar en esa era".
       if (tech.requiredEra != state.currentEra) return false;
    }

    // 2. Validar Tecnologías Requeridas
    for (var reqTechId in tech.requiredTechnologies) {
       if (!state.unlockedTechIds.contains(reqTechId)) return false;
    }

    // 3. Validar Recursos
    final resources = gameState.playerResources[playerIndex];
    if (resources.food < (tech.getAttribute('cost_food', defaultValue: 0) as num) || resources.wood < (tech.getAttribute('cost_wood', defaultValue: 0) as num) ||
        resources.gold < (tech.getAttribute('cost_gold', defaultValue: 0) as num) || resources.stone < (tech.getAttribute('cost_stone', defaultValue: 0) as num)) {
        return false;
    }

    return true;
  }

  void researchTechnology(int playerIndex, String techId) {
    if (!canResearch(playerIndex, techId)) return;
    
    final tech = GameDataService().getTech(techId);
    if (tech == null) return;
    
    final resources = gameState.playerResources[playerIndex];
    resources.food = (resources.food - (tech.getAttribute('cost_food', defaultValue: 0) as num)).toInt();
    resources.wood = (resources.wood - (tech.getAttribute('cost_wood', defaultValue: 0) as num)).toInt();
    resources.gold = (resources.gold - (tech.getAttribute('cost_gold', defaultValue: 0) as num)).toInt();
    resources.stone = (resources.stone - (tech.getAttribute('cost_stone', defaultValue: 0) as num)).toInt();
    
    playerTechStates[playerIndex].unlockedTechIds.add(tech.id);

    // Actualizar Era si la tecnología es de avance de era
    if (tech.category == 'era_advance' && tech.getAttribute('affected_stat') != null) {
       playerTechStates[playerIndex].currentEra = tech.getAttribute('affected_stat')!.toString();
    }
    
    final snapshot = GameDataService().snapshot;
    if (snapshot != null) {
       for (var effect in snapshot.technologyEffects) {
          if (effect['technology_id'] == tech.id) {
             String? entityId = effect['entity_id']?.toString();
             String? stat = effect['affected_stat']?.toString();
             double mult = (effect['multiplier'] as num?)?.toDouble() ?? 1.0;
             double bonus = (effect['bonus_value'] as num?)?.toDouble() ?? 0.0;
             
             if (entityId != null && stat != null) {
                // Evolución de Unidad (Upgrade)
                if (stat == 'upgrade_unit') {
                   var baseUnit = GameDataService().getUnit(entityId);
                   if (baseUnit != null && baseUnit.upgradesTo != null) {
                      var upgradedUnit = GameDataService().getUnit(baseUnit.upgradesTo!);
                      if (upgradedUnit != null) {
                         String oldName = baseUnit.name;
                         String newName = upgradedUnit.name;
                         
                         // Evolucionar todas las unidades en el mapa!
                         for (var e in gameState.entities.where((e) => e.playerIndex == playerIndex && e.name == oldName).toList()) {
                            e.name = newName;
                            e.maxHp = (upgradedUnit.getAttribute('hp', defaultValue: 100) as num).toInt();
                            e.hp = e.maxHp; // Curar al evolucionar (estilo age of empires)
                         }
                      }
                   }
                } else {
                   // Aplicar bono estadístico normal
                   String internalName = gameState.internalUnitNames[entityId] ?? entityId;
                   playerTechStates[playerIndex].addBonus(internalName, stat, mult, bonus);
                   
                   // Aplicación en tiempo real (ej: si aumenta la vida máxima, subirles la vida actual para no herirlos)
                   if (stat == 'max_health' && bonus > 0) {
                      for (var e in gameState.entities.where((e) => e.playerIndex == playerIndex && e.name == internalName).toList()) {
                         e.maxHp += bonus.toInt();
                         e.hp += bonus.toInt(); 
                      }
                   }
                }
             }
          }
       }
    }
    final pName = gameState.players[playerIndex].name;
    gameState.addEventLog('🔬 $pName investigó: ${tech.name}');
    debugPrint('Player $playerIndex investigó ${tech.name}');
    gameState.triggerUiUpdate();
  }
}
