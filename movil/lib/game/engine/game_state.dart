// =====================================================================
// GAME STATE — RTS Isométrico
// Estado reactivo del juego usando ChangeNotifier
// Gestiona: mapa, jugadores, recursos, tiempo, cámara
// =====================================================================

import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/game_data_service.dart';
import '../models/game_models.dart';
import 'ai/pathfinding_manager.dart';
import 'ai/city_planner.dart';
import 'map_generator.dart';
import 'spatial_grid.dart';
import 'package:flutter/material.dart';
import 'managers/tech_tree_manager.dart';
import 'managers/physics_manager.dart';
import 'managers/combat_manager.dart';
import 'managers/vision_manager.dart';
import 'managers/production_manager.dart';
import 'ai/ai_director.dart';


final Map<String, ui.Image> _uiImageCache = {};
final Map<String, Future<ui.Image>> _activeImageDownloads = {};

Future<ui.Image> loadImageFromUrl(String url) {
  if (_uiImageCache.containsKey(url)) {
    return Future.value(_uiImageCache[url]!);
  }
  if (_activeImageDownloads.containsKey(url)) {
    return _activeImageDownloads[url]!;
  }
  
  final Future<ui.Image> downloadFuture = () async {
    final imageProvider = NetworkImage(url);
    final completer = Completer<ImageInfo>();
    final stream = imageProvider.resolve(const ImageConfiguration());
    
    ImageStreamListener? listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool syncCall) {
        _uiImageCache[url] = info.image;
        completer.complete(info);
        stream.removeListener(listener!);
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        completer.completeError(exception, stackTrace);
        stream.removeListener(listener!);
      },
    );
    
    stream.addListener(listener);
    final imageInfo = await completer.future;
    _activeImageDownloads.remove(url);
    return imageInfo.image;
  }();
  
  _activeImageDownloads[url] = downloadFuture;
  return downloadFuture;
}

class GameState extends ChangeNotifier {
  late final TechTreeManager techManager;
  late final PhysicsManager physicsManager;
  late final CombatManager combatManager;
  late final VisionManager visionManager;
  late final ProductionManager productionManager;
  late final AiDirector aiDirector;
  
  GameState() {
    techManager = TechTreeManager(this);
    physicsManager = PhysicsManager(this);
    combatManager = CombatManager(this);
    visionManager = VisionManager(this);
    productionManager = ProductionManager(this);
    aiDirector = AiDirector(this);
  }

  void triggerUiUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }


  // ─── Mapa ──────────────────────────────────────────────────────────
  late MapGenerationResult _mapData;
  bool _isLoaded = false;
  int get mapSize => _mapData.mapSize;
  List<List<MapTile>> get tiles => _mapData.tiles;
  List<SpawnZone> get spawnZones => _mapData.spawnZones;
  bool get isLoaded => _isLoaded;
  int get seed => _isLoaded ? _mapData.seed : 0;
  
  // Caché de recursos para optimización de rendimiento
  List<MapTile> _resourceCache = []; 
  List<MapTile> get resourceCache => _resourceCache;

  // ─── Jugadores ─────────────────────────────────────────────────────
  late List<PlayerConfig> players;
  late List<PlayerResources> playerResources;
  int humanPlayerIndex = 0;

  // Matriz de Visibilidad (Niebla de Guerra)
  List<List<bool>> get visibleMap => visionManager.visibleMap;
  List<List<bool>> get exploredMap => visionManager.exploredMap;
  int get humanTeamIndex => players.isEmpty ? 0 : players[humanPlayerIndex].teamIndex;

  // ─── Entidades Vivas ───────────────────────────────────────────────
  List<GameEntity> entities = [];
  List<GameEntity> selectedEntities = []; // Nuevas entidades seleccionadas por el usuario
  List<Projectile> activeProjectiles = []; // Proyectiles activos de arquería


  // ─── Cámara ────────────────────────────────────────────────────────
  double cameraX = 0;
  double cameraY = 0;
  double zoom = 1.0;
  static const double MIN_ZOOM = 0.4;
  static const double MAX_ZOOM = 2.0;

  // ─── Relaciones Dinamicas de Produccion (Data-Driven) ────────────
  Map<String, List<String>> buildingProduces = {};
  Map<String, String> internalUnitNames = {}; // Mapeo de ID de Supabase -> Nombre Interno del Engine
  
  // ─── Estado Tecnológico por Jugador ───────────────────────────────
  List<PlayerTechState> playerTechStates = [];

  // ─── Registro de Eventos en Tiempo Real ─────────────────────────────
  final List<String> eventLogs = [];
  final Map<String, double> lastCombatLogTimes = {};

  void addEventLog(String message) {
    eventLogs.insert(0, message);
    if (eventLogs.length > 25) {
      eventLogs.removeLast();
    }
    triggerUiUpdate();
  }

  void notifyCombatStarted(int attackerIndex, int defenderIndex) {
    if (attackerIndex == defenderIndex) return; // No auto-ataque
    if (attackerIndex < 0 || attackerIndex >= players.length) return;
    if (defenderIndex < 0 || defenderIndex >= players.length) return;

    final key = attackerIndex < defenderIndex 
        ? '${attackerIndex}_vs_${defenderIndex}' 
        : '${defenderIndex}_vs_${attackerIndex}';
        
    final lastTime = lastCombatLogTimes[key] ?? -999.0;
    if (_elapsedTime - lastTime > 12.0) { // Cooldown de 12 segundos para evitar spam
      lastCombatLogTimes[key] = _elapsedTime;
      final attackerName = players[attackerIndex].name;
      final defenderName = players[defenderIndex].name;
      addEventLog('⚔️ Combate: $attackerName vs $defenderName');
    }
  }

  // ─── Helpers de Atributos Tecnológicos ───────────────────────────
  double getUnitStat(GameEntity entity, String statKey, double baseValue) => techManager.getUnitStat(entity, statKey, baseValue);

  void researchTechnology(int playerIndex, String techName) => techManager.researchTechnology(playerIndex, techName);

  // ─── Sistema de combate ───────────────────────────────────────────────
  double _elapsedTime = 0.0;
  double _lastServerTick = 0.0;
  double _accumulatedTickTime = 0.0; // Para lógica de 0.5s (Server Tick)
  double _accumulatedLogicTime = 0.0; // Para lógica de 0.1s (Logic Tick)
  int _gameTick = 0; // Se mantiene como contador, pero no controla el tiempo
  int get gameTick => _gameTick;
  String get elapsedTime {
    final secs = _elapsedTime.toInt();
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static const int _blockWidth = 3;
  static const int _blockHeight = 2;
  static const int SERVER_TICK_RATE = 2;
  bool isGameOver = false;

  // ─── Selección ─────────────────────────────────────────────────────
  MapTile? selectedTile;
  final Random rand = Random();
  final List<double> aiDecisionTimers = List.generate(8, (_) => Random().nextDouble() * 2.5);

  // ─── Inicialización ────────────────────────────────────────────────

  Future<void> initializeMatch(GameMatch match) async {
    _isLoaded = false;
    notifyListeners();

    // 0. Cargar estadísticas actualizadas desde Supabase
    try {
      await _loadStatsFromSupabase();
    } catch (e) {
      debugPrint('Error cargando estadísticas de Supabase: $e');
    }

    // Generar el mapa en background
    await Future.delayed(const Duration(milliseconds: 50)); // permite que la UI muestre loading
    final generator = GameMapGenerator(
      seed: match.seed,
      playerCount: match.players.length,
      mapSize: match.mapSize,
    );
    _mapData = generator.generate();
    
    // Inicializar mapa de visibilidad
    visionManager.initVisibleMap();

    players = match.players;
    playerResources = List.generate(
      match.players.length,
      (i) => PlayerResources.fromCivId(match.players[i].civId),
    );
    playerTechStates = List.generate(
      match.players.length,
      (_) => PlayerTechState(),
    );

    // Centrar cámara en el spawn del jugador humano
    final humanSpawn = spawnZones.firstWhere(
      (z) => z.playerIndex == humanPlayerIndex,
      orElse: () => spawnZones.first,
    );
    _centerCameraOnTile(humanSpawn.centerCol, humanSpawn.centerRow);

    // [Simulación Visual MVP] Crear un Centro Urbano por cada jugador y 5 aldeanos iniciales
    for (var sp in spawnZones) {
      String civId = players[sp.playerIndex].civId;
      String tcName = GameDataService().getBuildingsForCiv(civId).where((b) => b.category == 'town_center').firstOrNull?.name ?? 'Centro Urbano';
      String workerName = GameDataService().getUnitsForCiv(civId).where((u) => u.category == 'worker').firstOrNull?.name ?? 'Aldeano';

      // Bloquear la casilla física en el mapa para evitar que se construya encima
      tiles[sp.centerRow][sp.centerCol].isWalkable = false;

      // Crear el Centro Urbano
      final tc = GameEntity(
        id: 'tc_${sp.playerIndex}',
        playerIndex: sp.playerIndex,
        type: EntityType.building,
        name: tcName,
        col: sp.centerCol.toDouble(),
        row: sp.centerRow.toDouble(),
        hp: entityBaseStats[tcName]?.maxHp ?? 1000,
        maxHp: entityBaseStats[tcName]?.maxHp ?? 1000,
      );
      entities.add(tc);

      // Spawnear 5 aldeanos alrededor del TC
      for (int i = 0; i < 5; i++) {
        double angle = rand.nextDouble() * 2 * pi;
        double dist = 2.5 + rand.nextDouble();
        var worker = GameEntity(
          id: 'worker_${sp.playerIndex}_init_$i',
          playerIndex: sp.playerIndex,
          type: EntityType.unit,
          name: workerName,
          col: sp.centerCol.toDouble() + cos(angle) * dist,
          row: sp.centerRow.toDouble() + sin(angle) * dist,
          hp: entityBaseStats[workerName]?.maxHp ?? 50,
          maxHp: entityBaseStats[workerName]?.maxHp ?? 50,
        );
        // Distribución inicial de roles: 2 a comida, 1 a madera, 1 a oro y 1 a piedra
        if (i < 2) worker.workerRole = 'food';
        else if (i == 2) worker.workerRole = 'wood';
        else if (i == 3) worker.workerRole = 'gold';
        else worker.workerRole = 'stone';
        
        // Evitar sobrecarga de pathfinding al iniciar el juego (stagger)
        worker.pathTimer = rand.nextDouble() * 3.5;
        
        entities.add(worker);
      }
    }

    _isLoaded = true;
    _rebuildResourceCache();
    _updateVisibility();
    notifyListeners();
  }

  void _rebuildResourceCache() {
    _resourceCache.clear();
    for (int r = 0; r < mapSize; r++) {
      for (int c = 0; c < mapSize; c++) {
        if (tiles[r][c].hasResource) {
          _resourceCache.add(tiles[r][c]);
        }
      }
    }
  }

  void _centerCameraOnTile(int col, int row) {
    // Convertir coordenadas iso a pantalla (lógica base, ajustar con tile size)
    final tileW = 64.0;
    final tileH = 32.0;
    cameraX = (col - row) * (tileW / 2) - 200;
    cameraY = (col + row) * (tileH / 2) - 300;
  }

  // ─── Actualización de recursos ─────────────────────────────────────

  // ─── Actualización (60 FPS) ─────────────────────────────────────────

  void update(double dt) {
    if (isGameOver) return;
    
    try {
      // 1. Acumular tiempo transcurrido
      _elapsedTime += dt;
      _accumulatedTickTime += dt;

      // 2. Ejecutar lógica de "Server Tick" cada 0.5 segundos (Producción e IA Macro)
      if (_accumulatedTickTime >= 0.5) {
        _accumulatedTickTime -= 0.5;
        _gameTick++; // Un tick cada 0.5s para el reloj y módulos
        _processServerTick();
        _gatherPassiveResources();
        _updateVisibility();
      }

      // 3. Ejecutar física y producción en cada frame (usando dt real)
      _simulatePhysics(dt);
      _updateProduction(dt);
      
      // Actualizar contadores de población
      _updatePopulationCounters();
      
      // Actualizar proyectiles activos y aplicar daño al impactar
      for (var p in activeProjectiles) {
        p.update(dt);
        if (p.isDead) {
          final target = entities.where((e) => e.id == p.targetEntityId).firstOrNull;
          if (target != null) {
            target.hp -= p.damage;
            final shooterId = p.id.split('_')[1];
            final attacker = entities.where((e) => e.id == shooterId).firstOrNull;
            if (attacker != null) {
              callForHelp(target, attacker);
            }
            if (target.hp <= 0) {
              entities.remove(target);
            }
          }
        }
      }
      activeProjectiles.removeWhere((p) => p.isDead);
      
      notifyListeners();
    } catch (e, stack) {
      debugPrint('Error crítico en el bucle de actualización del juego: $e\n$stack');
    }
  }

  void _updatePopulationCounters() {
    if (players.isEmpty || playerResources.isEmpty) return;
    for (int i = 0; i < players.length; i++) {
      if (i >= playerResources.length) break;
      playerResources[i].population = currentPopulation(i);
      playerResources[i].maxPopulation = maxPopulation(i);
    }
  }

  void _updateProduction(double dt) => productionManager.updateProduction(dt);

  void _updateVisibility() => visionManager.updateVisibility();

  // Valida si un jugador puede construir un edificio según su civilización
  bool canBuild(int pIdx, String buildingName) {
     if (pIdx < 0 || pIdx >= players.length) return false;
     String civId = players[pIdx].civId;
     var allowed = GameDataService().getBuildingsForCiv(civId);
     return allowed.any((b) => b.name == buildingName);
  }

  void spawnProjectile(GameEntity attacker, GameEntity target) => combatManager.spawnProjectile(attacker, target, 10);

  int maxPopulation(int pIdx) {
    if (pIdx < 0 || pIdx >= players.length) return 10;
    String civId = players[pIdx].civId;
    String houseName = GameDataService().getBuildingsForCiv(civId).where((b) => b.category == 'house').firstOrNull?.name ?? 'Casa';
    String tcName = GameDataService().getBuildingsForCiv(civId).where((b) => b.category == 'town_center').firstOrNull?.name ?? 'Centro Urbano';

    int houses = entities.where((e) => e.playerIndex == pIdx && e.name == houseName && e.hp >= e.maxHp * 0.15).length;
    int tcs = entities.where((e) => e.playerIndex == pIdx && e.name == tcName && e.hp >= e.maxHp * 0.15).length;
    return (tcs * 5) + (houses * 5);
  }

  int currentPopulation(int pIdx) {
    return entities.where((e) => e.playerIndex == pIdx && e.type == EntityType.unit).length;
  }

  void _autoAssignIdleWorkers() => aiDirector.economy.assignIdleWorkersGlobal();

  void _processServerTick() => aiDirector.processServerTick();

  /// Busca automáticamente trabajo para aldeanos que no están haciendo nada

  void _simulatePhysics(double dt) => physicsManager.simulatePhysics(dt);

  // _moveAlongPath movido a physicsManager

  // _sendToClosestDropoff movido a physicsManager

  void _gatherPassiveResources() {
    // Por ahora: los edificios darán recursos, aquí solo simulamos
    for (int i = 0; i < playerResources.length; i++) {
      playerResources[i].food += 2;
    }
  }

  // -----------------------------------------------------------------
  // Helper methods for defensive coordination
  // -----------------------------------------------------------------

  void callForHelp(GameEntity victim, GameEntity attacker) {
    double helpRadius = 6.0;
    int maxAttackersOnVictim = 4;

    String civId = players.firstWhere((p) => p.index == victim.playerIndex, orElse: () => players[0]).civId;
    String workerName = GameDataService().getUnitsForCiv(civId).where((u) => u.category == 'worker').firstOrNull?.name ?? 'Aldeano';
    String tcName = GameDataService().getBuildingsForCiv(civId).where((b) => b.category == 'town_center').firstOrNull?.name ?? 'Centro Urbano';

    bool isMilBldg = GameDataService().getBuildingByName(victim.name)?.category?.startsWith('military') ?? false;
    bool isMilUnit(String name) => GameDataService().getUnitByName(name)?.category != 'worker' && GameDataService().getUnitByName(name)?.category != 'civilian';

    // 1. Lógica de Importancia del Edificio
    if (victim.type == EntityType.building) {
      if (victim.name == tcName) {
        helpRadius = 12.0; // Radio masivo para defender la capital
        maxAttackersOnVictim = 12;
      } else if (isMilBldg) {
        helpRadius = 8.0; // Radio alto para edificios militares
        maxAttackersOnVictim = 8;
      } else {
        helpRadius = 5.0; // Radio normal
        maxAttackersOnVictim = 4;
      }
    }

    // 2. Lógica de Reacción Militar (Si atacan a un soldado, el grupo reacciona)
    if (victim.type == EntityType.unit && isMilUnit(victim.name)) {
      helpRadius = 15.0; // Radio de "conciencia de grupo" ampliado para soldados
      maxAttackersOnVictim = 10;
    }

    // 3. Lógica de Huida (Si la unidad está siendo apaleada por muchos)
    if (victim.type == EntityType.unit && victim.state != EntityState.fleeing) {
      int gangingEnemies = entities.where((e) => 
        e.playerIndex != victim.playerIndex && 
        e.type == EntityType.unit &&
        sqrt(pow(e.col - victim.col, 2) + pow(e.row - victim.row, 2)) <= 2.5
      ).length;

      if (gangingEnemies >= 3) {
        // ¡Pánico! Buscar el TC o un edificio aliado para refugiarse
        GameEntity? refuge = entities.where((e) => 
          e.playerIndex == victim.playerIndex && 
          e.type == EntityType.building
        ).firstOrNull; // El primero suele ser el TC o el más viejo
        
        if (refuge != null) {
          victim.currentPath = PathfindingManager.findPath(
            tiles, victim.col.round(), victim.row.round(), refuge.col.round(), refuge.row.round()
          );
           victim.state = EntityState.fleeing;
           victim.assignedResourceTile = null;
           return; // Si huye, no pide ayuda para atacar, ya está a salvo (o intentándolo)
        }
      }
    }

    // 3. Llamada a Aliados cercanos
    List<GameEntity> allies = entities.where((e) =>
        e.type == EntityType.unit &&
        e.playerIndex == victim.playerIndex &&
        e != victim &&
        e.state != EntityState.fleeing // Los que huyen no vuelven
    ).toList();

    for (var ally in allies) {
      double d = sqrt(pow(ally.col - victim.col, 2) + pow(ally.row - victim.row, 2));
      if (d <= helpRadius) {
        // Las unidades militares SIEMPRE acuden. 
        // Los aldeanos SOLO acuden si están muy cerca (defensa propia/territorial)
        bool isMilitary = isMilUnit(ally.name);
        bool isCloseVillager = ally.name == workerName && d < 6.0;
        
        bool canReact = (ally.state == EntityState.idle || ally.state == EntityState.gathering || ally.state == EntityState.movingToResource) ||
                        (isMilitary && (ally.state == EntityState.attacking || ally.state == EntityState.moving));

        if ((isMilitary || isCloseVillager) && canReact) {
          // Solo acudir si no hay ya demasiada gente defendiendo
          int currentDefenders = entities.where((e) =>
              e.playerIndex == victim.playerIndex &&
              e.state == EntityState.attacking &&
              sqrt(pow(e.col - attacker.col, 2) + pow(e.row - attacker.row, 2)) <= 2.0).length;

          if (currentDefenders < maxAttackersOnVictim) {
            ally.currentPath = PathfindingManager.findPath(
                tiles, ally.col.round(), ally.row.round(), attacker.col.round(), attacker.row.round());
            ally.state = EntityState.attacking;
            ally.assignedResourceTile = null;
            ally.actionTimer = 0.0;
          }
        }
      }
    }
  }

  void gatherResource(int playerIndex, MapTile tile) {
    if (!tile.hasResource) return;
    final resource = tile.resource!;
    final res = playerResources[playerIndex];
    final amount = 10;

    if (resource.amount <= 0) return;
    resource.amount -= amount;

    switch (resource.type) {
      case ResourceType.wood:
        res.wood += amount;
        break;
      case ResourceType.gold:
        res.gold += amount;
        break;
      case ResourceType.stone:
        res.stone += amount;
        break;
      case ResourceType.food:
        res.food += amount;
        break;
    }

    if (resource.amount <= 0) {
      tile.resource = null;
      tile.type = TileType.grass; // El recurso se agota
    }

    notifyListeners();
  }

  // ─── Cámara ────────────────────────────────────────────────────────

  void moveCamera(double dx, double dy) {
    cameraX += dx;
    cameraY += dy;
    notifyListeners();
  }

  void adjustZoom(double delta) {
    zoom = (zoom + delta).clamp(MIN_ZOOM, MAX_ZOOM);
    notifyListeners();
  }

  // ─── Selección de tile ─────────────────────────────────────────────

  void selectTile(MapTile? tile) {
    selectedTile = tile;
    notifyListeners();
  }
  // ─── Comandos de Unidades ──────────────────────────────────────────
  
  void selectEntity(GameEntity entity, {bool multi = false}) {
    if (!multi) selectedEntities.clear();
    if (!selectedEntities.contains(entity)) {
      selectedEntities.add(entity);
    } else if (multi) {
      selectedEntities.remove(entity);
    }
    notifyListeners();
  }

  void commandMove(int col, int row) {
    if (selectedEntities.isEmpty) return;

    // 1. Identificar la unidad más lenta del grupo
    double slowestSpeed = 999.0;
    for (var entity in selectedEntities) {
       double baseSpeed = entityBaseStats[entity.name]?.speed ?? 2.0;
       if (baseSpeed < slowestSpeed) slowestSpeed = baseSpeed;
    }

    // 2. Calcular formación (Cuadrado)
    int count = selectedEntities.length;
    int gridSize = sqrt(count).ceil();
    
    for (int i = 0; i < count; i++) {
      int r = i ~/ gridSize;
      int c = i % gridSize;
      int targetCol = col + (c - gridSize ~/ 2);
      int targetRow = row + (r - gridSize ~/ 2);

      // Limitar a bordes del mapa
      targetCol = targetCol.clamp(0, mapSize - 1);
      targetRow = targetRow.clamp(0, mapSize - 1);

      var entity = selectedEntities[i];
      entity.groupSpeed = slowestSpeed; // Sincronizar velocidad
      entity.currentPath = PathfindingManager.findPath(
        tiles, entity.col.round(), entity.row.round(), targetCol, targetRow
      );
      entity.state = EntityState.moving; // Usar el nuevo estado de marcha
    }
    notifyListeners();
  }

  Future<void> _loadStatsFromSupabase() async {
    try {
      // Use the GameDataService singleton which already has the snapshot
      final gameData = GameDataService();
      
      // If snapshot isn't loaded yet, load it now
      if (!gameData.isLoaded) {
        await gameData.loadSnapshot();
      }

      final snapshot = gameData.snapshot;
      if (snapshot == null) {
        debugPrint('GameDataService snapshot is null, using defaults.');
        return;
      }

      // 1. Load Unit stats
      internalUnitNames.clear();

      for (var unit in snapshot.units) {
        String internalName = unit.name;
        var stats = EntityBaseStats(
          maxHp: unit.maxHealth,
          speed: unit.movementSpeed * 3.5,
          attackRange: unit.attackRange,
          attackDamage: unit.meleeAttack.toInt() > 0 
              ? unit.meleeAttack.toInt() 
              : unit.rangedAttack.toInt(),
          creationTime: unit.productionTime.toDouble(),
          spriteUrl: unit.spriteUrl,
          costFood: unit.costFood,
          costWood: unit.costWood,
          costGold: unit.costGold,
          costStone: unit.costStone,
          populationCost: unit.populationCost,
        );
        
        if (unit.spriteUrl != null && unit.spriteUrl!.isNotEmpty) {
           loadImageFromUrl(unit.spriteUrl!).then((img) {
             final currentStats = entityBaseStats[internalName];
             if (currentStats != null) {
               currentStats.spriteImage = img;
             } else {
               stats.spriteImage = img;
             }
             triggerUiUpdate();
             debugPrint('Sprite background-loaded for $internalName');
           }).catchError((e) {
             debugPrint('Error background loading sprite for $internalName: $e');
           });
        }
        
        entityBaseStats[internalName] = stats;
        internalUnitNames[unit.id] = internalName;
      }

      // 2. Load Building stats
      for (var building in snapshot.buildings) {
        String internalName = building.name;
        var stats = EntityBaseStats(
          maxHp: building.maxHealth,
          creationTime: building.constructionTime.toDouble(),
          attackDamage: building.rangedAttack.toInt(),
          attackRange: building.attackRange,
          spriteUrl: building.spriteUrl,
          costWood: building.costWood,
          costStone: building.costStone,
          costGold: building.costGold,
        );
        
        if (building.spriteUrl != null && building.spriteUrl!.isNotEmpty) {
           loadImageFromUrl(building.spriteUrl!).then((img) {
             final currentStats = entityBaseStats[internalName];
             if (currentStats != null) {
               currentStats.spriteImage = img;
             } else {
               stats.spriteImage = img;
             }
             triggerUiUpdate();
             debugPrint('Building Sprite background-loaded for $internalName');
           }).catchError((e) {
             debugPrint('Error background loading building sprite for $internalName: $e');
           });
        }
        
        entityBaseStats[internalName] = stats;
      }

      // 3. Apply civilization-specific overrides
      for (var override in snapshot.overrides) {
        // Find which entities this override applies to
        String? entityName;
        if (override.entityType == 'unit') {
          final unit = snapshot.units.where((u) => u.id == override.entityId).firstOrNull;
          entityName = unit?.name;
        } else if (override.entityType == 'building') {
          final bld = snapshot.buildings.where((b) => b.id == override.entityId).firstOrNull;
          entityName = bld?.name;
        }

        if (entityName != null && entityBaseStats.containsKey(entityName)) {
          final base = entityBaseStats[entityName]!;
          
          if (override.statKey == 'sprite_config') {
            try {
              final config = jsonDecode(override.statValue);
              final defaultUrl = config['default_url'];
              if (defaultUrl != null && defaultUrl.isNotEmpty) {
                loadImageFromUrl(defaultUrl).then((newImage) {
                  final latestBase = entityBaseStats[entityName!] ?? base;
                  entityBaseStats[entityName!] = EntityBaseStats(
                    maxHp: latestBase.maxHp,
                    speed: latestBase.speed,
                    attackRange: latestBase.attackRange,
                    attackDamage: latestBase.attackDamage,
                    creationTime: latestBase.creationTime,
                    spriteUrl: defaultUrl,
                    spriteImage: newImage,
                    costFood: latestBase.costFood,
                    costWood: latestBase.costWood,
                    costGold: latestBase.costGold,
                    costStone: latestBase.costStone,
                    populationCost: latestBase.populationCost,
                  );
                  triggerUiUpdate();
                  debugPrint('Override Sprite background-loaded for $entityName');
                }).catchError((e) {
                  debugPrint('Error background loading override sprite for $entityName: $e');
                });
              }
            } catch (e) {
              debugPrint('Error parsing sprite_config JSON for $entityName: $e');
            }
            continue;
          }

          final val = double.tryParse(override.statValue);
          if (val != null) {
            entityBaseStats[entityName] = EntityBaseStats(
              maxHp: override.statKey == 'max_health' ? val.toInt() : base.maxHp,
              speed: override.statKey == 'movement_speed' ? val * 2.0 : base.speed,
              attackRange: override.statKey == 'attack_range' ? val : base.attackRange,
              attackDamage: override.statKey == 'melee_attack' || override.statKey == 'ranged_attack' 
                  ? val.toInt() : base.attackDamage,
              creationTime: override.statKey == 'production_time' || override.statKey == 'construction_time' 
                  ? val : base.creationTime,
              spriteUrl: base.spriteUrl,
              spriteImage: base.spriteImage,
              costFood: base.costFood,
              costWood: base.costWood,
              costGold: base.costGold,
              costStone: base.costStone,
              populationCost: base.populationCost,
            );
          }
        }
      }

      // 4. Mapear Producción Dinámica de Edificios -> Unidades
      buildingProduces.clear();
      Map<String, String> unitIdToInternalName = {};
      for (var unit in snapshot.units) {
        unitIdToInternalName[unit.id] = unit.name;
      }
      Map<String, String> buildingIdToInternalName = {};
      for (var building in snapshot.buildings) {
        buildingIdToInternalName[building.id] = building.name;
      }

      for (var prod in snapshot.buildingProductions) {
        String? bName = buildingIdToInternalName[prod.buildingId];
        String? uName = unitIdToInternalName[prod.unitId];
        if (bName != null && uName != null) {
          if (!buildingProduces.containsKey(bName)) {
            buildingProduces[bName] = [];
          }
          if (!buildingProduces[bName]!.contains(uName)) {
             buildingProduces[bName]!.add(uName);
          }
        }
      }

      debugPrint('Estadísticas sincronizadas: '
          '${snapshot.units.length} units, '
          '${snapshot.buildings.length} buildings, '
          '${snapshot.overrides.length} overrides aplicados. '
          '${buildingProduces.length} edificios con producción vinculada.');
    } catch (e) {
      debugPrint('Error cargando Supabase: $e');
    }
  }

}
