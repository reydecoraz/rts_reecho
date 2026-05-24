import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_models.dart';

// Nodo para el algoritmo A*
class AStarNode {
  final int col;
  final int row;
  double g = 0; // Costo desde el inicio
  double h = 0; // Heurística (distancia estimada al objetivo)
  AStarNode? parent;

  AStarNode(this.col, this.row);
  double get f => g + h;
}

class PathfindingManager {
  static List<Offset> findPath(List<List<MapTile>> grid, int startCol, int startRow, int targetCol, int targetRow) {
    int mapSize = grid.length;
    if (startCol < 0 || startCol >= mapSize || startRow < 0 || startRow >= mapSize ||
        targetCol < 0 || targetCol >= mapSize || targetRow < 0 || targetRow >= mapSize) {
      return [];
    }
    
    // Redirigir destino a casilla transitable adyacente si la original no es transitable (bosques, oro, etc.)
    if (!grid[targetRow][targetCol].isWalkable || grid[targetRow][targetCol].isWater) {
      double minD2 = double.maxFinite;
      int bestCol = targetCol;
      int bestRow = targetRow;
      bool foundAdj = false;

      final dirs = [[0,-1],[0,1],[-1,0],[1,0],[-1,-1],[1,-1],[-1,1],[1,1]];
      for (var d in dirs) {
        int nc = targetCol + d[0];
        int nr = targetRow + d[1];
        if (nc >= 0 && nc < mapSize && nr >= 0 && nr < mapSize) {
          final adjTile = grid[nr][nc];
          if (adjTile.isWalkable && !adjTile.isWater) {
            double dx = nc - startCol;
            double dy = nr - startRow;
            double d2 = dx*dx + dy*dy;
            if (d2 < minD2) {
              minD2 = d2;
              bestCol = nc;
              bestRow = nr;
              foundAdj = true;
            }
          }
        }
      }
      if (foundAdj) {
        targetCol = bestCol;
        targetRow = bestRow;
      }
    }
    
    if (startCol == targetCol && startRow == targetRow) return [];

    final BinaryHeap openList = BinaryHeap();
    final Map<String, AStarNode> openNodes = {};
    final Set<String> closedSet = {};

    AStarNode startNode = AStarNode(startCol, startRow);
    startNode.h = heuristic(startCol, startRow, targetCol, targetRow);
    openList.push(startNode);
    openNodes['$startCol,$startRow'] = startNode;

    int iterations = 0;
    const int maxIterations = 5000; // Aumentado para mayor robustez en bosques densos

    while (openList.isNotEmpty) {
      iterations++;
      if (iterations > maxIterations) break;

      AStarNode currentNode = openList.pop()!;
      String posKey = '${currentNode.col},${currentNode.row}';
      openNodes.remove(posKey);
      closedSet.add(posKey);

      if (currentNode.col == targetCol && currentNode.row == targetRow) {
        return _reconstructPath(currentNode);
      }

      final directions = [[0,-1],[0,1],[-1,0],[1,0],[-1,-1],[1,-1],[-1,1],[1,1]];
      for (var dir in directions) {
        int nx = currentNode.col + dir[0];
        int ny = currentNode.row + dir[1];

        if (nx < 0 || nx >= mapSize || ny < 0 || ny >= mapSize) continue;
        
        String nKey = '$nx,$ny';
        if (closedSet.contains(nKey)) continue;

        final tile = grid[ny][nx];
        bool isWalkable = (tile.isWalkable && !tile.isWater) || (nx == targetCol && ny == targetRow);
        if (!isWalkable) continue;

        // Diagonal blocking
        if (dir[0] != 0 && dir[1] != 0) {
          if (!grid[currentNode.row][nx].isWalkable || !grid[ny][currentNode.col].isWalkable) continue;
        }

        double moveCost = (dir[0] != 0 && dir[1] != 0) ? 1.414 : 1.0;
        double tentativeG = currentNode.g + moveCost;

        AStarNode? neighbor = openNodes[nKey];
        if (neighbor == null) {
          neighbor = AStarNode(nx, ny);
          neighbor.parent = currentNode;
          neighbor.g = tentativeG;
          neighbor.h = heuristic(nx, ny, targetCol, targetRow);
          openList.push(neighbor);
          openNodes[nKey] = neighbor;
        } else if (tentativeG < neighbor.g) {
          neighbor.parent = currentNode;
          neighbor.g = tentativeG;
          openList.update(neighbor);
        }
      }
    }
    return [];
  }

  static double heuristic(int colA, int rowA, int colB, int rowB) {
    // Octile distance: El mejor para grid con 8 direcciones (diagonales)
    double dx = (colA - colB).abs().toDouble();
    double dy = (rowA - rowB).abs().toDouble();
    double f = 1.414 - 1; // Costo extra de diagonal (sqrt(2) - 1)
    return (dx < dy) ? (f * dx + dy) : (f * dy + dx);
  }

  static List<Offset> _reconstructPath(AStarNode endNode) {
    List<Offset> path = [];
    AStarNode? current = endNode;
    while (current != null) {
      path.add(Offset(current.col.toDouble(), current.row.toDouble()));
      current = current.parent;
    }
    path = path.reversed.toList();
    if (path.length > 1) path.removeAt(0);
    return path;
  }
}

// Implementación mínima de Binary Heap para rendimiento máximo en Dart
class BinaryHeap {
  final List<AStarNode> _nodes = [];

  bool get isEmpty => _nodes.isEmpty;
  bool get isNotEmpty => _nodes.isNotEmpty;

  void push(AStarNode node) {
    _nodes.add(node);
    _bubbleUp(_nodes.length - 1);
  }

  AStarNode? pop() {
    if (_nodes.isEmpty) return null;
    if (_nodes.length == 1) return _nodes.removeLast();
    final min = _nodes[0];
    _nodes[0] = _nodes.removeLast();
    _bubbleDown(0);
    return min;
  }

  void update(AStarNode node) {
    int index = _nodes.indexOf(node);
    if (index != -1) _bubbleUp(index);
  }

  void _bubbleUp(int index) {
    while (index > 0) {
      int parentIndex = (index - 1) ~/ 2;
      if (_nodes[index].f >= _nodes[parentIndex].f) break;
      final temp = _nodes[index];
      _nodes[index] = _nodes[parentIndex];
      _nodes[parentIndex] = temp;
      index = parentIndex;
    }
  }

  void _bubbleDown(int index) {
    while (true) {
      int left = 2 * index + 1;
      int right = 2 * index + 2;
      int smallest = index;
      if (left < _nodes.length && _nodes[left].f < _nodes[smallest].f) smallest = left;
      if (right < _nodes.length && _nodes[right].f < _nodes[smallest].f) smallest = right;
      if (smallest == index) break;
      final temp = _nodes[index];
      _nodes[index] = _nodes[smallest];
      _nodes[smallest] = temp;
      index = smallest;
    }
  }
}
