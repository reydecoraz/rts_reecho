import 'dart:math';
import '../../models/game_models.dart';
import '../game_state.dart';

class CombatManager {
  final GameState state;
  final Random rand = Random();

  CombatManager(this.state);

  void spawnProjectile(GameEntity shooter, GameEntity target, int damage) {
    state.activeProjectiles.add(Projectile(
      id: 'proj_${shooter.id}_${state.gameTick}_${rand.nextInt(9999)}',
      startCol: shooter.col,
      startRow: shooter.row,
      targetCol: target.col,
      targetRow: target.row,
      damage: damage,
      targetEntityId: target.id,
      speed: 12.0,
      type: shooter.name == 'Arquero' ? 'arrow' : 'rock', 
    ));
  }

  // Not used right now since GameState updates projectiles itself, but we might migrate it.
}
