import 'dart:math';
import '../models/game_models.dart';

class MapGenerationResult {
  final List<List<MapTile>> tiles;
  final List<SpawnZone> spawnZones;
  final int seed;
  final int mapSize;

  MapGenerationResult({
    required this.tiles,
    required this.spawnZones,
    required this.seed,
    required this.mapSize,
  });
}

class GameMapGenerator {
  static const int DEFAULT_MAP_SIZE = 125;

  final int seed;
  final int playerCount;
  final int mapSize;
  late Random _rng;

  GameMapGenerator({
    required this.seed,
    required this.playerCount,
    this.mapSize = DEFAULT_MAP_SIZE,
  }) {
    _rng = Random(seed);
  }

  static int generateSeed() => Random().nextInt(999999999);

  /// Genera el mapa completo. Un grid NxN en isométrico ya forma un rombo (diamante) en pantalla.
  MapGenerationResult generate() {
    final tiles = _createBaseGrid();
    _placeLakes(tiles, 5 + _rng.nextInt(4)); // 5-8 lagos para el mapa más grande
    final spawnZones = _calculateSpawnZones(playerCount);
    _markSpawnZones(tiles, spawnZones);
    _placeForestClusters(tiles, spawnZones);
    _distributeGoldAndStoneDeposits(tiles, spawnZones);
    _ensureResourcesNearSpawns(tiles, spawnZones);
    _createMapBorders(tiles, spawnZones);

    return MapGenerationResult(
      tiles: tiles, spawnZones: spawnZones, seed: seed, mapSize: mapSize,
    );
  }

  List<List<MapTile>> _createBaseGrid() {
    return List.generate(mapSize,
      (row) => List.generate(mapSize,
        (col) => MapTile(col: col, row: row, type: TileType.grass),
      ),
    );
  }

  /// Lagos: clusters de agua agrupada (pocos y pequeños)
  void _placeLakes(List<List<MapTile>> tiles, int count) {
    final center = mapSize ~/ 2;
    final maxR = mapSize ~/ 2 - 6;
    int placed = 0;
    int attempts = 0;

    while (placed < count && attempts < 200) {
      attempts++;
      final angle = _rng.nextDouble() * 2 * pi;
      final dist = 4 + _rng.nextInt(maxR - 4);
      final lc = (center + dist * cos(angle)).round().clamp(3, mapSize - 4);
      final lr = (center + dist * sin(angle)).round().clamp(3, mapSize - 4);

      if (tiles[lr][lc].type != TileType.grass) continue;

      // Crear lago orgánico con flood-fill aleatorio
      final lakeSize = 6 + _rng.nextInt(8); // 6-13 tiles
      final queue = <List<int>>[[lc, lr]];
      final visited = <String>{};
      int filled = 0;

      while (queue.isNotEmpty && filled < lakeSize) {
        final pos = queue.removeAt(_rng.nextInt(queue.length));
        final key = '${pos[0]},${pos[1]}';
        if (visited.contains(key)) continue;
        visited.add(key);

        final c = pos[0], r = pos[1];
        if (c < 1 || c >= mapSize - 1 || r < 1 || r >= mapSize - 1) continue;
        if (tiles[r][c].type != TileType.grass && tiles[r][c].type != TileType.sand) continue;

        tiles[r][c].type = filled < 3 ? TileType.deepWater : TileType.water;
        tiles[r][c].isWalkable = false;
        filled++;

        // Expandir en 4 direcciones
        for (final d in [[-1,0],[1,0],[0,-1],[0,1]]) {
          if (_rng.nextDouble() < 0.7) {
            queue.add([c + d[0], r + d[1]]);
          }
        }
      }
      if (filled > 3) placed++;
    }
  }

  /// Bosques: ~40% de densidad máxima, priorizando bordes y agua, dejando caminos libres entre jugadores
  void _placeForestClusters(List<List<MapTile>> tiles, List<SpawnZone> zones) {
    // 40% como máximo, variando entre 25% y 40%
    double forestDensity = 0.25 + _rng.nextDouble() * 0.15;
    int targetForestCount = (mapSize * mapSize * forestDensity).round();
    int placed = 0;
    int attempts = 0;
    
    final center = mapSize / 2.0;
    final maxR = mapSize / 2.0;

    while (placed < targetForestCount && attempts < 20000) {
      attempts++;
      
      final col = _rng.nextInt(mapSize);
      final row = _rng.nextInt(mapSize);
      
      if (tiles[row][col].type != TileType.grass) continue;
      
      // Probabilidad basada en distancia al borde y proximidad al agua
      double distToCenter = sqrt(pow(col - center, 2) + pow(row - center, 2));
      bool nearWater = _isNearWater(tiles, col, row, 4);
      
      double probability = 0.05; // Base baja para el centro
      probability += (distToCenter / maxR) * 0.7; // Mayor probabilidad hacia los bordes
      if (nearWater) probability += 0.4; // Gran bonus si está cerca del agua
      
      if (_rng.nextDouble() > probability) continue;
      
      // Dejar amplios espacios alrededor de las zonas de aparición para caminos
      if (_isNearSpawn(col, row, zones, 14)) continue;
      if (_isNearPathToCenter(col, row, zones, 5.0)) continue; // Caminos centrales libres

      int clusterSize = 20 + _rng.nextInt(80); // Bosques mucho más grandes (20-100 árboles)
      placed += _growOrganicCluster(tiles, col, row, zones, clusterSize);
    }
  }

  bool _isNearWater(List<List<MapTile>> tiles, int col, int row, int radius) {
    for (int r = row - radius; r <= row + radius; r++) {
      for (int c = col - radius; c <= col + radius; c++) {
        if (r >= 0 && r < mapSize && c >= 0 && c < mapSize) {
           if (tiles[r][c].isWater) return true;
        }
      }
    }
    return false;
  }

  int _growOrganicCluster(List<List<MapTile>> tiles, int startCol, int startRow,
      List<SpawnZone> zones, int targetSize) {
    final queue = <List<int>>[[startCol, startRow]];
    final visited = <String>{};
    int placed = 0;

    while (queue.isNotEmpty && placed < targetSize) {
      final idx = _rng.nextInt(queue.length);
      final pos = queue.removeAt(idx);
      final key = '${pos[0]},${pos[1]}';
      if (visited.contains(key)) continue;
      visited.add(key);

      final c = pos[0], r = pos[1];
      if (c < 1 || c >= mapSize - 1 || r < 1 || r >= mapSize - 1) continue;
      if (tiles[r][c].type != TileType.grass) continue;
      
      // Respetar caminos y zonas de spawn (radio 14)
      if (_isNearSpawn(c, r, zones, 14)) continue;
      if (_isNearPathToCenter(c, r, zones, 5.0)) continue;

      tiles[r][c].type = TileType.forest;
      tiles[r][c].resource = ResourceNode(
        type: ResourceType.wood,
        amount: 100,
        maxAmount: 100,
      );
      tiles[r][c].isWalkable = false;
      placed++;

      // Expandir orgánicamente
      final dirs = [[-1,0],[1,0],[0,-1],[0,1],[-1,-1],[-1,1],[1,-1],[1,1]];
      for (final d in dirs) {
        if (_rng.nextDouble() < 0.55) { // Alta probabilidad de expansión para mantener el cluster denso
          queue.add([c + d[0], r + d[1]]);
        }
      }
    }
    return placed;
  }

  /// Oro y Piedra: Se generan juntas en agrupaciones para concentrar los puntos de interés
  void _distributeGoldAndStoneDeposits(List<List<MapTile>> tiles, List<SpawnZone> zones) {
    int resourceClusters = (mapSize * mapSize * 0.004).round().clamp(3, 25);
    int placed = 0, attempts = 0;

    while (placed < resourceClusters && attempts < 2000) {
      attempts++;
      final col = _rng.nextInt(mapSize);
      final row = _rng.nextInt(mapSize);
      if (tiles[row][col].type != TileType.grass) continue;
      if (_isNearSpawn(col, row, zones, 8)) continue;
      if (_isNearPathToCenter(col, row, zones, 4.0)) continue;

      // Colocar cluster de oro
      int goldSize = 3 + _rng.nextInt(4); // 3 a 6 vetas de oro
      _growResourceCluster(tiles, col, row, zones, goldSize, TileType.goldDeposit, ResourceType.gold, 300, 600);
      
      // Buscar una celda vacía cercana al oro para colocar el cluster de piedra
      for (int i = 0; i < 20; i++) {
        int dist = 3 + _rng.nextInt(4); // 3 a 6 cuadros de distancia del oro
        double angle = _rng.nextDouble() * 2 * pi;
        int sc = (col + dist * cos(angle)).round();
        int sr = (row + dist * sin(angle)).round();

        if (sc >= 0 && sc < mapSize && sr >= 0 && sr < mapSize) {
          if (tiles[sr][sc].type == TileType.grass && !_isNearPathToCenter(sc, sr, zones, 4.0)) {
            int stoneSize = 4 + _rng.nextInt(5); // 4 a 8 vetas de piedra
            _growResourceCluster(tiles, sc, sr, zones, stoneSize, TileType.mountain, ResourceType.stone, 400, 800);
            break; // Terminamos de colocar la piedra para este grupo
          }
        }
      }
      
      placed++;
    }
  }

  void _growResourceCluster(List<List<MapTile>> tiles, int startCol, int startRow,
      List<SpawnZone> zones, int targetSize, TileType tType, ResourceType rType, int baseAmt, int maxAmt) {
    final queue = <List<int>>[[startCol, startRow]];
    int placed = 0;
    while (queue.isNotEmpty && placed < targetSize) {
      final pos = queue.removeAt(_rng.nextInt(queue.length));
      final c = pos[0], r = pos[1];
      if (c < 1 || c >= mapSize - 1 || r < 1 || r >= mapSize - 1) continue;
      if (tiles[r][c].type != TileType.grass) continue;
      if (_isNearPathToCenter(c, r, zones, 4.0)) continue;

      tiles[r][c].type = tType;
      tiles[r][c].isWalkable = false;
      tiles[r][c].resource = ResourceNode(
        type: rType, amount: baseAmt + _rng.nextInt(maxAmt - baseAmt), maxAmount: maxAmt,
      );
      placed++;

      for (final d in [[-1,0],[1,0],[0,-1],[0,1],[-1,-1],[-1,1],[1,-1],[1,1]]) {
        if (_rng.nextDouble() < 0.6) queue.add([c + d[0], r + d[1]]);
      }
    }
  }

  List<SpawnZone> _calculateSpawnZones(int count) {
    final zones = <SpawnZone>[];
    final center = mapSize / 2;
    final radius = mapSize * 0.42; // Cerca del borde
    
    // Rotación aleatoria inicial para que el patrón no sea siempre el mismo
    final rotOff = _rng.nextDouble() * 2 * pi;

    for (int i = 0; i < count; i++) {
      // Repartir 360 grados (2*pi) entre la cantidad de jugadores equitativamente
      final angle = (i * 2 * pi / count) + rotOff;
      
      final col = (center + radius * cos(angle)).round().clamp(4, mapSize - 5);
      final row = (center + radius * sin(angle)).round().clamp(4, mapSize - 5);
      zones.add(SpawnZone(playerIndex: i, centerCol: col, centerRow: row, radius: 3));
    }
    return zones;
  }

  void _markSpawnZones(List<List<MapTile>> tiles, List<SpawnZone> zones) {
    for (final zone in zones) {
      for (int dr = -zone.radius; dr <= zone.radius; dr++) {
        for (int dc = -zone.radius; dc <= zone.radius; dc++) {
          final r = (zone.centerRow + dr).clamp(0, mapSize - 1);
          final c = (zone.centerCol + dc).clamp(0, mapSize - 1);
          if (sqrt(dr * dr + dc * dc) <= zone.radius) {
            tiles[r][c].type = TileType.grass;
            tiles[r][c].isWalkable = true;
            tiles[r][c].resource = null;
          }
        }
      }
      tiles[zone.centerRow.clamp(0, mapSize - 1)][zone.centerCol.clamp(0, mapSize - 1)].type = TileType.spawn;
    }
  }

  void _ensureResourcesNearSpawns(List<List<MapTile>> tiles, List<SpawnZone> zones) {
    for (final zone in zones) {
      bool hasWood = false, hasGold = false, hasStone = false;
      for (int dr = -8; dr <= 8; dr++) {
        for (int dc = -8; dc <= 8; dc++) {
          final r = (zone.centerRow + dr).clamp(0, mapSize - 1);
          final c = (zone.centerCol + dc).clamp(0, mapSize - 1);
          if (tiles[r][c].resource?.type == ResourceType.wood) hasWood = true;
          if (tiles[r][c].resource?.type == ResourceType.gold) hasGold = true;
          if (tiles[r][c].resource?.type == ResourceType.stone) hasStone = true;
        }
      }
      if (!hasWood) _placeNearSpawn(tiles, zone, zones, TileType.forest, ResourceType.wood, 250, 500);
      if (!hasGold) _placeNearSpawn(tiles, zone, zones, TileType.goldDeposit, ResourceType.gold, 200, 400);
      if (!hasStone) _placeNearSpawn(tiles, zone, zones, TileType.mountain, ResourceType.stone, 300, 600);
      
      // Siempre añadir algunos arbustos de bayas cerca del inicio (exactamente a radio 4 como pidió el usuario)
      _placeNearSpawn(tiles, zone, zones, TileType.berryBush, ResourceType.food, 150, 300, minD: 4, maxD: 5);
    }
  }

  void _placeNearSpawn(List<List<MapTile>> tiles, SpawnZone zone, List<SpawnZone> allZones,
      TileType tType, ResourceType rType, int amount, int maxAmt, {int minD = 4, int maxD = 9}) {
    for (int dist = minD; dist <= maxD; dist++) {
      for (int a = 0; a < 16; a++) { // 16 ángulos para buscar mejor
        final c = (zone.centerCol + (dist * cos(a * pi / 8)).round()).clamp(0, mapSize - 1);
        final r = (zone.centerRow + (dist * sin(a * pi / 8)).round()).clamp(0, mapSize - 1);
        
        if (tiles[r][c].type == TileType.grass && !_isNearPathToCenter(c, r, allZones, 4.0)) {
          if (tType == TileType.forest) {
            _growOrganicCluster(tiles, c, r, allZones, 15 + _rng.nextInt(10)); // Bosque de 15-25 árboles
          } else if (tType == TileType.berryBush) {
            int clusterSize = 3 + _rng.nextInt(2); // 3 a 4 arbustos
            _growResourceCluster(tiles, c, r, allZones, clusterSize, tType, rType, amount, maxAmt);
          } else {
            int clusterSize = 4 + _rng.nextInt(3); // 4 a 6 vetas de mineral
            _growResourceCluster(tiles, c, r, allZones, clusterSize, tType, rType, amount, maxAmt);
          }
          return;
        }
      }
    }
  }

  bool _isNearSpawn(int col, int row, List<SpawnZone> zones, int minDist) {
    for (final z in zones) {
      if (sqrt(pow(col - z.centerCol, 2) + pow(row - z.centerRow, 2)) < minDist) return true;
    }
    return false;
  }

  bool _isNearPathToCenter(int col, int row, List<SpawnZone> zones, double pathWidth) {
    final double centerCol = mapSize / 2.0;
    final double centerRow = mapSize / 2.0;
    for (final z in zones) {
      double dist = _distancePointToSegment(
        col.toDouble(), row.toDouble(), 
        z.centerCol.toDouble(), z.centerRow.toDouble(), 
        centerCol, centerRow
      );
      if (dist <= pathWidth) return true;
    }
    return false;
  }

  double _distancePointToSegment(double px, double py, double x1, double y1, double x2, double y2) {
    double l2 = pow(x2 - x1, 2).toDouble() + pow(y2 - y1, 2).toDouble();
    if (l2 == 0) return sqrt(pow(px - x1, 2) + pow(py - y1, 2));
    double t = ((px - x1) * (x2 - x1) + (py - y1) * (y2 - y1)) / l2;
    t = t.clamp(0.0, 1.0);
    double projX = x1 + t * (x2 - x1);
    double projY = y1 + t * (y2 - y1);
    return sqrt(pow(px - projX, 2) + pow(py - projY, 2));
  }

  void _createMapBorders(List<List<MapTile>> tiles, List<SpawnZone> zones) {
    const int borderThickness = 3; // Grosor del muro de árboles en el borde
    
    for (int r = 0; r < mapSize; r++) {
      for (int c = 0; c < mapSize; c++) {
        // Si estamos en el borde exterior
        if (r < borderThickness || r >= mapSize - borderThickness ||
            c < borderThickness || c >= mapSize - borderThickness) {
          
          // Solo colocar árboles si no interfiere con la zona segura del jugador
          if (!_isNearSpawn(c, r, zones, 6)) {
            tiles[r][c].type = TileType.forest;
            tiles[r][c].resource = ResourceNode(
              type: ResourceType.wood,
              amount: 100,
              maxAmount: 100,
            );
            tiles[r][c].isWalkable = false;
          }
        }
      }
    }
  }
}
