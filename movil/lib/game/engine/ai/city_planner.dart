import 'dart:math';
import '../../models/game_models.dart';
import 'pathfinding_manager.dart';
// Configurable minimum distance from Town Center for new buildings
const double _minDistanceFromTC = 4.0; // tiles

// Block configuration constants
const int _blockWidth = 3; // width in tiles for a building block (e.g., 3 tiles)
const int _blockHeight = 2; // height in tiles for a building block (e.g., 2 tiles)
const int _corridorWidth = 2; // minimum corridor width between blocks
// =====================================================================
// CITY PLANNER (El Urbanista)
// Evita que la IA construya edificios en lugares que bloqueen el paso
// o que se auto-encierre.
// =====================================================================

class CityPlanner {
  final List<List<MapTile>> mapGrid;
  final List<GameEntity> myEntities;
  
  CityPlanner(this.mapGrid, this.myEntities);

   /// Encuentra un espacio libre y válido para construir.
  MapTile? findSafeBuildSpot(int tcCol, int tcRow, int radiusSearch, {bool ignoreMinDistance = false}) {
    List<MapTile> candidateTiles = _getEmptyGrassTiles(tcCol, tcRow, radiusSearch, ignoreMinDistance: ignoreMinDistance);

    for (var candidate in candidateTiles) {
      // 1. Verificamos que el lugar esté bajo la visión de la IA (Niebla de guerra) - Omitido para asegurar la expansión de la IA
      bool isVisible = true;
      if (!isVisible) continue;

      // 2. Aquí está la magia: Simulamos que la casilla está Ocupada (Muro falso).
      candidate.isWalkable = false;

      // 3. Verificamos si, con esta casilla tapada, los aldeanos todavía podrían 
      // caminar desde el Town Center hacia puntos de interés (bosques, mina, etc.).
      bool isPathBlocked = _doesBuildingBlockCrucialPaths(tcCol, tcRow, candidate);

      // Deshacemos la simulación
      candidate.isWalkable = true;

      if (!isPathBlocked) {
        // Encontramos un lugar que NO encierra a nuestra IA. ¡Es perfecto!
        return candidate;
      }
    }

    return null; // No encontró lugar seguro y visible en este radio.
  }

  List<MapTile> _getEmptyGrassTiles(int cCol, int cRow, int radius, {bool ignoreMinDistance = false}) {
    List<MapTile> tiles = [];
    int mapSize = mapGrid.length;
    for (int r = cRow - radius; r <= cRow + radius; r++) {
      for (int c = cCol - radius; c <= cCol + radius; c++) {
        if (r >= 0 && r < mapSize && c >= 0 && c < mapSize) {
          final tile = mapGrid[r][c];
          // Debe ser pasto, sin agua y sin recursos
          if (tile.isWalkable && !tile.hasResource && !tile.isWater) {
             // CRÍTICO: Verificar que no haya ya una entidad en esta posición exacta
             bool isOccupiedByEntity = myEntities.any((e) => e.col.round() == c && e.row.round() == r);
             if (isOccupiedByEntity) continue;

             // Evitar construir directamente pegado al centro para dejar caminos de paso
             // A menos que sea una granja (ignoreMinDistance = true)
             double dist = sqrt(pow(c - cCol, 2) + pow(r - cRow, 2));
             if (ignoreMinDistance || dist > _minDistanceFromTC) {
                tiles.add(tile);
             }
          }
        }
      }
    }
    // Ordenar por distancia al centro para construir de cerca a lejos
    tiles.sort((a, b) {
       double distA = pow(a.col - cCol, 2) + pow(a.row - cRow, 2).toDouble();
       double distB = pow(b.col - cCol, 2) + pow(b.row - cRow, 2).toDouble();
       return distA.compareTo(distB);
    });
    return tiles;
  }

  /// Genera un bloque de edificios (p.ej., 5 casas o 3 edificios) con corredores alrededor.
  /// Devuelve la posición del tile superior‑izquierdo del bloque encontrado, o null si no hay espacio.
  MapTile? findSafeBuildBlock(int tcCol, int tcRow, int radiusSearch) {
    // Reutilizamos la lógica de buscar tiles vacíos pero ahora buscamos un rectángulo completo.
    for (int r = tcRow - radiusSearch; r <= tcRow + radiusSearch; r++) {
      for (int c = tcCol - radiusSearch; c <= tcCol + radiusSearch; c++) {
        // Verificar que el rectángulo cabe dentro del mapa.
        if (r < 0 || c < 0) continue;
        if (r + _blockHeight > mapGrid.length || c + _blockWidth > mapGrid.length) continue;
        // Comprobar cada tile del bloque.
        bool blockOk = true;
        for (int br = 0; br < _blockHeight && blockOk; br++) {
          for (int bc = 0; bc < _blockWidth && blockOk; bc++) {
            final tile = mapGrid[r + br][c + bc];
            double dist = sqrt(pow(c + bc - tcCol, 2) + pow(r + br - tcRow, 2));
            
            // Verificar si hay una entidad
            bool isOccupiedByEntity = myEntities.any((e) => e.col.round() == (c + bc) && e.row.round() == (r + br));

            if (!(tile.isWalkable && !tile.hasResource && !tile.isWater && dist > _minDistanceFromTC && !isOccupiedByEntity)) {
              blockOk = false;
            }
          }
        }
        if (!blockOk) continue;
        // Verificar corredores alrededor del bloque.
        for (int br = -_corridorWidth; br < _blockHeight + _corridorWidth && blockOk; br++) {
          for (int bc = -_corridorWidth; bc < _blockWidth + _corridorWidth && blockOk; bc++) {
            // Saltar los tiles que pertenecen al bloque interno.
            if (br >= 0 && br < _blockHeight && bc >= 0 && bc < _blockWidth) continue;
            int checkR = r + br;
            int checkC = c + bc;
            if (checkR < 0 || checkC < 0 || checkR >= mapGrid.length || checkC >= mapGrid.length) continue;
            final corridorTile = mapGrid[checkR][checkC];
            if (!corridorTile.isWalkable || corridorTile.hasResource || corridorTile.isWater) {
              blockOk = false;
            }
          }
        }
        if (!blockOk) continue;
        // Simular ocupación del bloque y validar que no bloquea caminos críticos.
        List<MapTile> original = [];
        for (int br = 0; br < _blockHeight; br++) {
          for (int bc = 0; bc < _blockWidth; bc++) {
            final t = mapGrid[r + br][c + bc];
            original.add(t);
            t.isWalkable = false;
          }
        }
        bool blocksPath = _doesBuildingBlockCrucialPaths(tcCol, tcRow, mapGrid[r][c]);
        // Restaurar.
        for (final t in original) {
          t.isWalkable = true;
        }
        if (!blocksPath) {
          // Devolver el primer tile del bloque como punto de referencia.
          return mapGrid[r][c];
        }
      }
    }
    return null;
  }



  // -----------------------------------------------------------------
  // Helper: verifica si colocar un edificio bloquea caminos críticos
  // -----------------------------------------------------------------
  bool _doesBuildingBlockCrucialPaths(int tcCol, int tcRow, MapTile candidate) {
    // Si no hay camino desde el TC hasta la casilla candidata (antes de construir),
    // significa que la zona es inaccesible.
    var path = PathfindingManager.findPath(
        mapGrid, tcCol, tcRow, candidate.col, candidate.row);
    if (path.isEmpty) return true; // Zona Inaccesible
    return false;
  }

  /// Busca un lugar de construcción PRIORIZANDO la cercanía a uno o varios tipos de recurso.
  /// Útil para Campamentos Maderero (madera) o Mineros (oro/piedra).
  MapTile? findResourceBuildSpot(int tcCol, int tcRow, int radiusSearch, List<ResourceType> resourceTypes) {
    List<MapTile> candidateTiles = _getEmptyGrassTiles(tcCol, tcRow, radiusSearch);
    
    // 1. Filtrar solo las que son visibles - Relajado para permitir la construcción de campamentos lejanos de la IA
    List<MapTile> visibleCandidates = List.from(candidateTiles);
    if (visibleCandidates.isEmpty) return null;

    // 2. Puntuar las casillas según su cercanía al recurso deseado
    MapTile? bestSpot;
    double bestScore = double.maxFinite;

    for (var spot in visibleCandidates) {
      // Buscar el nodo de recurso más cercano a este spot dentro de un radio de 5
      double minResourceDist = double.maxFinite;
      for (int r = spot.row - 5; r <= spot.row + 5; r++) {
        for (int c = spot.col - 5; c <= spot.col + 5; c++) {
          if (r >= 0 && r < mapGrid.length && c >= 0 && c < mapGrid.length) {
            final t = mapGrid[r][c];
            if (t.resource != null && resourceTypes.contains(t.resource!.type)) {
              double d = sqrt(pow(t.col - spot.col, 2) + pow(t.row - spot.row, 2));
              if (d < minResourceDist) minResourceDist = d;
            }
          }
        }
      }

      // Solo considerar spots que tengan el recurso a menos de 6 tiles (margen ligeramente mayor)
      if (minResourceDist < 6.0) {
        // Validar que no bloquee caminos
        spot.isWalkable = false;
        bool blocks = _doesBuildingBlockCrucialPaths(tcCol, tcRow, spot);
        spot.isWalkable = true;

        if (!blocks && minResourceDist < bestScore) {
          bestScore = minResourceDist;
          bestSpot = spot;
        }
      }
    }

    // Si no encontró nada cerca del recurso, caer en la lógica normal
    return bestSpot ?? findSafeBuildSpot(tcCol, tcRow, radiusSearch);
  }
}
