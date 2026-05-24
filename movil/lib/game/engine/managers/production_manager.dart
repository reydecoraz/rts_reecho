import 'dart:math';
import '../../models/game_models.dart';
import '../game_state.dart';
import '../../../services/game_data_service.dart';

class ProductionManager {
  final GameState state;
  final Random rand = Random();

  ProductionManager(this.state);

  void updateProduction(double dt) {
    for (var building in state.entities.where((e) => e.type == EntityType.building).toList()) {
      if (building.productionName != null) {
        building.productionTimer -= dt;
        if (building.productionTimer <= 0) {
          String name = building.productionName!;
          int pIdx = building.playerIndex;
          
          int baseHp = GameDataService().getUnitByName(name)?.maxHealth ?? 100;
          double hpMult = state.techManager.getUnitStat(GameEntity(id: '', playerIndex: pIdx, type: EntityType.unit, name: name, col:0, row:0, hp:1, maxHp: 1), 'max_health', baseHp.toDouble());
          int hp = hpMult.toInt(); 

          final newUnit = GameEntity(
            id: '${name.toLowerCase()}_${pIdx}_${rand.nextInt(9999)}',
            playerIndex: pIdx,
            type: EntityType.unit,
            name: name,
            col: building.col + 1,
            row: building.row + 1,
            hp: hp,
            maxHp: hp,
          );

          bool isWorker = GameDataService().getUnitByName(name)?.category == 'worker';
          if (isWorker) {
            int workersCount = state.entities.where((e) => e.playerIndex == pIdx && GameDataService().getUnitByName(e.name)?.category == 'worker').length;
            if (workersCount % 4 == 0) newUnit.workerRole = 'food';
            else if (workersCount % 4 == 1) newUnit.workerRole = 'wood';
            else if (workersCount % 4 == 2) newUnit.workerRole = 'gold';
            else newUnit.workerRole = 'stone';
          }

          state.entities.add(newUnit);
          if (pIdx >= 0 && pIdx < state.playerStats.length) {
            state.playerStats[pIdx].unitsTrained++;
          }
          building.productionName = null;
        }
      }
    }
  }
}
