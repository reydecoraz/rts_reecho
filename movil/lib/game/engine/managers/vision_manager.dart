import '../game_state.dart';

class VisionManager {
  final GameState state;
  List<List<bool>> visibleMap = [];
  List<List<bool>> exploredMap = [];

  VisionManager(this.state);

  void initVisibleMap() {
    visibleMap = List.generate(state.mapSize, (_) => List.generate(state.mapSize, (_) => false));
    exploredMap = List.generate(state.mapSize, (_) => List.generate(state.mapSize, (_) => false));
  }

  void updateVisibility() {
    for (int r = 0; r < state.mapSize; r++) {
      for (int c = 0; c < state.mapSize; c++) {
        visibleMap[r][c] = false;
      }
    }

    if (state.players.isEmpty) {
      for (int r = 0; r < state.mapSize; r++) {
        for (int c = 0; c < state.mapSize; c++) {
          visibleMap[r][c] = true;
          exploredMap[r][c] = true;
        }
      }
      return;
    }

    int myTeam = state.humanTeamIndex;
    for (var entity in state.entities) {
      final pIdx = entity.playerIndex;
      if (pIdx >= 0 && pIdx < state.players.length) {
        if (state.players[pIdx].teamIndex == myTeam) {
          int r = entity.row.round().clamp(0, state.mapSize - 1);
          int c = entity.col.round().clamp(0, state.mapSize - 1);

          int visionRange = state.techManager.getUnitStat(entity, 'vision_range', entity.visionRadius.toDouble()).toInt();

          for (int vr = -visionRange; vr <= visionRange; vr++) {
            for (int vc = -visionRange; vc <= visionRange; vc++) {
              if (vr * vr + vc * vc <= visionRange * visionRange) {
                int nr = r + vr;
                int nc = c + vc;
                if (nr >= 0 && nr < state.mapSize && nc >= 0 && nc < state.mapSize) {
                  visibleMap[nr][nc] = true;
                  exploredMap[nr][nc] = true;
                }
              }
            }
          }
        }
      }
    }
  }
}
