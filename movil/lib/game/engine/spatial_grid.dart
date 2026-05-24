import 'package:flutter/material.dart';
import '../models/game_models.dart';

class SpatialGrid {
  final int mapSize;
  final int cellSize;
  late final int cols;
  late final int rows;
  late final List<List<List<GameEntity>>> grid;

  SpatialGrid(this.mapSize, {this.cellSize = 4}) {
    cols = (mapSize / cellSize).ceil();
    rows = (mapSize / cellSize).ceil();
    grid = List.generate(
      rows,
      (_) => List.generate(cols, (_) => []),
    );
  }

  void clear() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        grid[r][c].clear();
      }
    }
  }

  void insert(GameEntity entity) {
    if (entity.type != EntityType.unit) return;
    int c = (entity.col / cellSize).floor().clamp(0, cols - 1);
    int r = (entity.row / cellSize).floor().clamp(0, rows - 1);
    grid[r][c].add(entity);
  }

  List<GameEntity> getNearby(GameEntity entity, double radius) {
    List<GameEntity> result = [];
    int startC = ((entity.col - radius) / cellSize).floor().clamp(0, cols - 1);
    int endC = ((entity.col + radius) / cellSize).floor().clamp(0, cols - 1);
    int startR = ((entity.row - radius) / cellSize).floor().clamp(0, rows - 1);
    int endR = ((entity.row + radius) / cellSize).floor().clamp(0, rows - 1);

    for (int r = startR; r <= endR; r++) {
      for (int c = startC; c <= endC; c++) {
        for (var other in grid[r][c]) {
          if (other != entity) {
             result.add(other);
          }
        }
      }
    }
    return result;
  }
}
