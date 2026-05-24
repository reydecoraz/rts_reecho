import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flame/game.dart' hide Matrix4;
import '../game/engine/game_state.dart';
import '../game/engine/rts_flame_game.dart';
import '../game/models/game_models.dart';
import '../game/rendering/isometric_renderer.dart';
import '../services/game_data_service.dart';

class GameScreen extends StatefulWidget {
  final GameMatch match;
  const GameScreen({super.key, required this.match});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameState _gameState;
  Timer? _gameTimer;
  bool _isPaused = false;
  bool _showMinimap = true;
  Offset? _lastDragPos;
  double _lastScaleFactor = 1.0;
  final ValueNotifier<Offset> _joystickOffset = ValueNotifier<Offset>(Offset.zero);
  Timer? _joystickTimer;

  late AnimationController _hudCtrl;
  late Animation<double> _hudAnim;

  late RtsFlameGame _flameGame;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _gameState = GameState();
    _flameGame = RtsFlameGame(gameState: _gameState);
    _hudCtrl = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _hudAnim = CurvedAnimation(parent: _hudCtrl, curve: Curves.easeOutCubic);
    _initGame();
  }

  Future<void> _initGame() async {
    await _gameState.initializeMatch(widget.match);
    if (mounted) {
      _hudCtrl.forward();
      setState(() {}); // trigger first build after loading
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _gameTimer?.cancel();
    _joystickTimer?.cancel();
    _joystickOffset.dispose();
    _hudCtrl.dispose();
    _gameState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_gameState.isLoaded ? _buildLoading() : _buildGame(),
    );
  }

  // ─── LOADING ─────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0A0A1A), Color(0xFF1a1a2e)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 60, height: 60, child: CircularProgressIndicator(
              strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
            )),
            const SizedBox(height: 32),
            Text('GENERANDO MUNDO...', style: GoogleFonts.pressStart2p(
              color: const Color(0xFFFFD700), fontSize: 14,
              shadows: [const Shadow(color: Colors.black, offset: Offset(2, 2))],
            )),
            const SizedBox(height: 16),
            Text('Seed: ${widget.match.seed}', style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ─── GAME VIEW ───────────────────────────────────────────────────────
  Widget _buildGame() {
    return Stack(
      children: [
        // Mapa isométrico — FUERA de cualquier Consumer/ListenableBuilder
        // para que el GestureDetector no se recree al mover cámara
        _buildMapViewport(),
        // HUD — usa ListenableBuilder para actualizar solo lo necesario
        Positioned(top: 0, left: 0, right: 0, child: _buildTopHUD()),
        // Panel lateral izquierdo de registro de eventos
        Positioned(
          top: 52,
          left: 6,
          bottom: 160,
          width: 170,
          child: _buildEventLog(),
        ),
        // Info de selección (Entidad o Casilla)
        ListenableBuilder(
          listenable: _gameState,
          builder: (_, __) {
            return _buildSelectionInfo();
          },
        ),
        Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
        Positioned(bottom: 6, left: 6, child: _buildJoystick()),
        if (_showMinimap)
          Positioned(bottom: 6, right: 6, child: _buildMinimap()),
        if (_isPaused) _buildPauseOverlay(),
      ],
    );
  }

  // ─── MAP VIEWPORT ────────────────────────────────────────────────────
  Widget _buildMapViewport() {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _gameState.adjustZoom(event.scrollDelta.dy > 0 ? -0.1 : 0.1);
        }
      },
      child: GestureDetector(
        onScaleStart: (d) {
          _lastDragPos = d.focalPoint;
          _lastScaleFactor = _gameState.zoom;
        },
        onScaleUpdate: (d) {
          // Pinch zoom
          if (d.pointerCount >= 2) {
            final newZoom = _lastScaleFactor * d.scale;
            _gameState.adjustZoom(newZoom - _gameState.zoom);
          }
          // Pan de cámara
          if (_lastDragPos != null) {
            final delta = d.focalPoint - _lastDragPos!;
            _gameState.moveCamera(-delta.dx / _gameState.zoom, -delta.dy / _gameState.zoom);
            _lastDragPos = d.focalPoint;
          }
        },
        onScaleEnd: (_) => _lastDragPos = null,
        onTapUp: (d) {
          final size = MediaQuery.of(context).size;
          final tile = screenToTile(d.localPosition, _gameState, size);
          
          if (tile != null) {
            // Buscar cualquier entidad en esta cuadrícula (aliada o enemiga)
            final entity = _gameState.entities.firstWhere(
              (e) => e.col.round() == tile.col && e.row.round() == tile.row,
              orElse: () => GameEntity(id: 'none', playerIndex: -1, type: EntityType.unit, name: '', col: 0, row: 0),
            );

            if (entity.id != 'none') {
              // Si tenemos unidades seleccionadas y el toque es en un enemigo, ordenar movimiento hacia él para atacarlo
              if (_gameState.selectedEntities.isNotEmpty && entity.playerIndex != _gameState.humanPlayerIndex) {
                _gameState.commandMove(tile.col, tile.row);
              } else {
                // Seleccionar la entidad (sea aliada o enemiga)
                _gameState.selectEntity(entity, multi: _gameState.selectedEntities.isNotEmpty && entity.playerIndex == _gameState.humanPlayerIndex);
                _gameState.selectTile(tile);
              }
            } else {
              _gameState.selectTile(tile);
              // Si ya hay unidades seleccionadas, moverlas aquí
              if (_gameState.selectedEntities.isNotEmpty) {
                 _gameState.commandMove(tile.col, tile.row);
              } else {
                // Si no hay unidades seleccionadas, limpiar la selección de unidades al hacer clic en suelo vacío
                _gameState.selectedEntities.clear();
                _gameState.triggerUiUpdate();
              }
            }
          }
        },
        onLongPressStart: (d) {
          final size = MediaQuery.of(context).size;
          final tile = screenToTile(d.localPosition, _gameState, size);
          if (tile != null && _gameState.selectedEntities.isNotEmpty) {
             _gameState.commandMove(tile.col, tile.row);
          }
        },
        child: SizedBox.expand(
          child: GameWidget(game: _flameGame),
        ),
      ),
    );
  }

  // ─── TOP HUD ─────────────────────────────────────────────────────────
  Widget _buildTopHUD() {
    return ListenableBuilder(
      listenable: _gameState,
      builder: (_, __) {
        final res = _gameState.playerResources.isNotEmpty
            ? _gameState.playerResources[_gameState.humanPlayerIndex]
            : PlayerResources();
        return FadeTransition(
          opacity: _hudAnim,
          child: Container(
            padding: const EdgeInsets.only(top: 6, left: 8, right: 8, bottom: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.85), Colors.transparent],
              ),
            ),
            child: Row(
              children: [
                _hudBtn(Icons.pause, () { _flameGame.pauseEngine(); setState(() => _isPaused = true); }),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _resChip('🌲', res.wood, const Color(0xFF4CAF50)),
                      const SizedBox(width: 6),
                      _resChip('⛏️', res.gold, const Color(0xFFFFD700)),
                      const SizedBox(width: 6),
                      _resChip('🪨', res.stone, const Color(0xFF90A4AE)),
                      const SizedBox(width: 6),
                      _resChip('🌾', res.food, const Color(0xFFFF8F00)),
                      const SizedBox(width: 6),
                      _resChip('👥', res.population, const Color(0xFFE91E63), suffix: '/${res.maxPopulation}'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54, borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(_gameState.elapsedTime,
                    style: GoogleFonts.pressStart2p(color: Colors.white70, fontSize: 10)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _resChip(String icon, int value, Color color, {String? suffix}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 3),
        Text('$value${suffix ?? ''}', style: GoogleFonts.robotoMono(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _hudBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.black54, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }

  // ─── MINIMAP ─────────────────────────────────────────────────────────
  Widget _buildMinimap() {
    return Opacity(
      opacity: 0.50,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(1.0, 0.6) // Aplastar verticalmente
          ..rotateZ(pi / 4), // Rotar 45 grados para hacer el rombo
        child: Container(
          width: 120, height: 120, // Tamaño interno de la cuadrícula
          decoration: BoxDecoration(
            color: Colors.black87,
            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.7), width: 2.0),
          ),
          child: CustomPaint(painter: _MinimapPainter(
            gameState: _gameState,
            viewportSize: MediaQuery.of(context).size,
          )),
        ),
      ),
    );
  }

  // ─── TILE INFO ───────────────────────────────────────────────────────
  Widget _buildTileInfo(MapTile tile) {
    final names = {
      TileType.grass: 'PRADERA', TileType.forest: 'BOSQUE',
      TileType.goldDeposit: 'VETA DE ORO', TileType.water: 'AGUA',
      TileType.deepWater: 'MAR PROFUNDO', TileType.sand: 'ARENA',
      TileType.hill: 'COLINA', TileType.spawn: 'ZONA DE INICIO',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87, border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(names[tile.type] ?? 'DESCONOCIDO', style: GoogleFonts.pressStart2p(color: const Color(0xFFFFD700), fontSize: 9)),
        Text('(${tile.col}, ${tile.row})', style: GoogleFonts.robotoMono(color: Colors.white54, fontSize: 10)),
        if (tile.hasResource) ...[
          const SizedBox(height: 4),
          Text('${tile.resource!.type.name}: ${tile.resource!.amount}',
            style: GoogleFonts.robotoMono(color: Colors.greenAccent, fontSize: 10)),
        ],
      ]),
    );
  }

  Widget _buildSelectionInfo() {
    if (_gameState.selectedEntities.isNotEmpty) {
      final entity = _gameState.selectedEntities.first;
      final ownerName = entity.playerIndex >= 0 && entity.playerIndex < _gameState.players.length
          ? _gameState.players[entity.playerIndex].name
          : 'Desconocido';
      
      final stateNames = {
        EntityState.idle: 'Inactivo',
        EntityState.moving: 'Marchando',
        EntityState.movingToResource: 'Buscando recursos',
        EntityState.gathering: 'Recolectando',
        EntityState.returningToTC: 'Entregando recursos',
        EntityState.attacking: 'En combate',
        EntityState.fleeing: 'Huyendo',
      };

      final roleNames = {
        'wood': 'Leñador 🌲',
        'gold': 'Minero ⛏️',
        'food': 'Recolector 🌾',
        'stone': 'Cantero 🪨',
      };

      final isWorker = entity.name.toLowerCase().contains('aldeano') || entity.name.toLowerCase().contains('worker');

      return Positioned(
        bottom: 102,
        left: 6,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    entity.type == EntityType.building ? Icons.foundation : Icons.person,
                    color: const Color(0xFFFFD700),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entity.name.toUpperCase(),
                    style: GoogleFonts.pressStart2p(color: const Color(0xFFFFD700), fontSize: 9),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Dueño: $ownerName',
                style: GoogleFonts.roboto(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                'Vida: ${entity.hp}/${entity.maxHp}',
                style: GoogleFonts.robotoMono(
                  color: entity.hp > entity.maxHp * 0.5 ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (entity.type == EntityType.unit) ...[
                const SizedBox(height: 2),
                Text(
                  'Estado: ${stateNames[entity.state] ?? entity.state.name}',
                  style: GoogleFonts.roboto(color: Colors.white54, fontSize: 10),
                ),
                if (isWorker && entity.workerRole.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Rol: ${roleNames[entity.workerRole] ?? entity.workerRole}',
                    style: GoogleFonts.roboto(color: Colors.cyanAccent, fontSize: 10),
                  ),
                ],
              ],
              const SizedBox(height: 4),
              Text(
                'Pos: (${entity.col.round()}, ${entity.row.round()})',
                style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 9),
              ),
            ],
          ),
        ),
      );
    }

    if (_gameState.selectedTile != null) {
      return Positioned(
        bottom: 102,
        left: 6,
        child: _buildTileInfo(_gameState.selectedTile!),
      );
    }

    return const SizedBox.shrink();
  }

  // ─── BOTTOM BAR ──────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter, end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.9), Colors.transparent],
        ),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _actionBtn('RECOLECTAR', Icons.nature, const Color(0xFF4CAF50), () {
          if (_gameState.selectedTile?.hasResource == true)
            _gameState.gatherResource(_gameState.humanPlayerIndex, _gameState.selectedTile!);
        }),
        const SizedBox(width: 8),
        _actionBtn('CONSTRUIR', Icons.foundation, const Color(0xFF1565C0), () => _snack('EDIFICIOS — PRÓXIMAMENTE')),
        const SizedBox(width: 8),
        _actionBtn('RECLUTAR', Icons.military_tech, const Color(0xFFE94560), () => _snack('TROPAS — PRÓXIMAMENTE')),
        const SizedBox(width: 8),
        _actionBtn('INVESTIGAR', Icons.science, const Color(0xFFAB47BC), () => _showResearchDialog()),
      ]),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center,
            style: GoogleFonts.pressStart2p(color: Colors.white70, fontSize: 5)),
        ]),
      ),
    );
  }

  Widget _buildEventLog() {
    return ListenableBuilder(
      listenable: _gameState,
      builder: (_, __) {
        if (_gameState.eventLogs.isEmpty) return const SizedBox.shrink();
        return Container(
          width: 170,
          alignment: Alignment.topLeft,
          child: ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white, Colors.transparent],
                stops: [0.0, 0.7, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: min(_gameState.eventLogs.length, 6),
              itemBuilder: (context, index) {
                final log = _gameState.eventLogs[index];
                final isCombat = log.contains('⚔️');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCombat 
                          ? Colors.red[900]!.withOpacity(0.4) 
                          : Colors.purple[900]!.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isCombat 
                            ? Colors.redAccent.withOpacity(0.3) 
                            : Colors.purpleAccent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      log,
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 5.2,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showResearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return ListenableBuilder(
          listenable: _gameState,
          builder: (context, _) {
            final pIdx = _gameState.humanPlayerIndex;
            final techState = _gameState.playerTechStates[pIdx];
            final resources = _gameState.playerResources[pIdx];
            final snapshot = GameDataService().snapshot;
            final techs = snapshot?.technologies ?? [];

            // Classify technologies
            final currentEraName = techState.currentEra == 'stone'
                ? 'EDAD DE PIEDRA'
                : techState.currentEra == 'bronze'
                    ? 'EDAD DE BRONCE'
                    : 'EDAD DE HIERRO';

            return AlertDialog(
              backgroundColor: const Color(0xFF0F0F23).withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFAB47BC), width: 2),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.science, color: Color(0xFFAB47BC)),
                      const SizedBox(width: 12),
                      Text(
                        'TECNOLOGÍAS',
                        style: GoogleFonts.pressStart2p(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFAB47BC).withOpacity(0.5)),
                    ),
                    child: Text(
                      currentEraName,
                      style: GoogleFonts.pressStart2p(
                        color: const Color(0xFFAB47BC),
                        fontSize: 8,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                height: 380,
                child: ListView.builder(
                  itemCount: techs.length,
                  itemBuilder: (context, index) {
                    final tech = techs[index];
                    final isUnlocked = techState.unlockedTechIds.contains(tech.id);
                    final canRes = _gameState.techManager.canResearch(pIdx, tech.id);
                    
                    // Cost values
                    final foodCost = (tech.getAttribute('cost_food', defaultValue: 0) as num).toInt();
                    final woodCost = (tech.getAttribute('cost_wood', defaultValue: 0) as num).toInt();
                    final goldCost = (tech.getAttribute('cost_gold', defaultValue: 0) as num).toInt();
                    final stoneCost = (tech.getAttribute('cost_stone', defaultValue: 0) as num).toInt();

                    final eraRequirements = tech.requiredEra == 'stone'
                        ? 'EDAD DE PIEDRA'
                        : tech.requiredEra == 'bronze'
                            ? 'EDAD DE BRONCE'
                            : 'EDAD DE HIERRO';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? Colors.green.withOpacity(0.1)
                            : canRes
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black26,
                        border: Border.all(
                          color: isUnlocked
                              ? Colors.green.withOpacity(0.5)
                              : canRes
                                  ? const Color(0xFFAB47BC).withOpacity(0.4)
                                  : Colors.white12,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  tech.name,
                                  style: GoogleFonts.pressStart2p(
                                    color: isUnlocked ? Colors.greenAccent : Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              if (isUnlocked)
                                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20)
                              else
                                ElevatedButton(
                                  onPressed: canRes
                                      ? () {
                                          _gameState.techManager.researchTechnology(pIdx, tech.id);
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFAB47BC),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.white10,
                                    disabledForegroundColor: Colors.white24,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: Text(
                                    'INVESTIGAR',
                                    style: GoogleFonts.pressStart2p(fontSize: 7),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tech.description ?? 'Sin descripción',
                            style: GoogleFonts.roboto(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Costos
                              Row(
                                children: [
                                  if (foodCost > 0) _costMiniChip('🌾', foodCost, resources.food >= foodCost),
                                  if (woodCost > 0) _costMiniChip('🌲', woodCost, resources.wood >= woodCost),
                                  if (goldCost > 0) _costMiniChip('⛏️', goldCost, resources.gold >= goldCost),
                                  if (stoneCost > 0) _costMiniChip('🪨', stoneCost, resources.stone >= stoneCost),
                                ],
                              ),
                              // Era requerida
                              Text(
                                'Req: $eraRequirements',
                                style: GoogleFonts.pressStart2p(
                                  color: tech.requiredEra == techState.currentEra
                                      ? Colors.white38
                                      : Colors.redAccent.withOpacity(0.7),
                                  fontSize: 6,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CERRAR',
                    style: GoogleFonts.pressStart2p(
                      color: const Color(0xFFAB47BC),
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _costMiniChip(String icon, int value, bool met) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: met ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 2),
          Text(
            '$value',
            style: GoogleFonts.robotoMono(
              color: met ? Colors.greenAccent : Colors.redAccent,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFF1a1a2e),
      content: Text(msg, style: GoogleFonts.pressStart2p(fontSize: 8)),
      duration: const Duration(seconds: 1),
    ));
  }

  // ─── PAUSE ───────────────────────────────────────────────────────────
  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('⏸ PAUSA', style: GoogleFonts.pressStart2p(
            color: const Color(0xFFFFD700), fontSize: 28,
            shadows: [const Shadow(color: Colors.black, offset: Offset(3, 3))],
          )),
          const SizedBox(height: 40),
          _menuBtn('CONTINUAR', const Color(0xFF4CAF50), () { _flameGame.resumeEngine(); setState(() => _isPaused = false); }),
          const SizedBox(height: 16),
          _menuBtn('MINIMAPA', Colors.white24, () { _flameGame.resumeEngine(); setState(() { _showMinimap = !_showMinimap; _isPaused = false; }); }),
          const SizedBox(height: 16),
          _menuBtn('INFO DEL MAPA', Colors.white24, () { _showMapInfo(); _flameGame.resumeEngine(); setState(() => _isPaused = false); }),
          const SizedBox(height: 32),
          _menuBtn('ABANDONAR', const Color(0xFFE94560), () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ]),
      ),
    );
  }

  Widget _menuBtn(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240, padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          border: Border.all(color: color.withOpacity(0.6), width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text, textAlign: TextAlign.center,
          style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 10)),
      ),
    );
  }

  void _showMapInfo() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1a1a2e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFFFD700))),
      title: Text('INFO DEL MAPA', style: GoogleFonts.pressStart2p(color: const Color(0xFFFFD700), fontSize: 12)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _row('Seed', '${_gameState.seed}'),
        _row('Tamaño', '${_gameState.mapSize}x${_gameState.mapSize}'),
        _row('Jugadores', '${_gameState.players.length}'),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context),
        child: Text('CERRAR', style: GoogleFonts.pressStart2p(color: const Color(0xFFFFD700), fontSize: 9)))],
    ));
  }

  Widget _row(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: GoogleFonts.roboto(color: Colors.white54, fontSize: 13)),
      Text(v, style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 13)),
    ]));

  // ─── JOYSTICK DE NAVEGACIÓN ─────────────────────────────────────────

  void _onJoystickPanUpdate(DragUpdateDetails details) {
    final currentOffset = _joystickOffset.value;
    final newOffset = currentOffset + details.delta;
    final distance = newOffset.distance;
    const maxRadius = 30.0;
    if (distance <= maxRadius) {
      _joystickOffset.value = newOffset;
    } else {
      _joystickOffset.value = Offset(
        (newOffset.dx / distance) * maxRadius,
        (newOffset.dy / distance) * maxRadius,
      );
    }
    _startJoystickTimer();
  }

  void _onJoystickPanEnd() {
    _joystickOffset.value = Offset.zero;
    _joystickTimer?.cancel();
    _joystickTimer = null;
  }

  void _startJoystickTimer() {
    if (_joystickTimer != null) return;
    _joystickTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final offset = _joystickOffset.value;
      if (offset != Offset.zero) {
        // La velocidad es proporcional a la inclinación del joystick y adaptada al zoom actual.
        final speed = 0.70 / _gameState.zoom;
        _gameState.moveCamera(
          offset.dx * speed,
          offset.dy * speed,
        );
      } else {
        timer.cancel();
        _joystickTimer = null;
      }
    });
  }

  Widget _buildJoystick() {
    return GestureDetector(
      onPanStart: (details) {
        _onJoystickPanUpdate(DragUpdateDetails(
          globalPosition: details.globalPosition,
          localPosition: details.localPosition,
          delta: Offset.zero,
        ));
      },
      onPanUpdate: _onJoystickPanUpdate,
      onPanEnd: (_) => _onJoystickPanEnd(),
      onPanCancel: () => _onJoystickPanEnd(),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.50),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.60),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: ValueListenableBuilder<Offset>(
            valueListenable: _joystickOffset,
            builder: (context, offset, child) {
              return Transform.translate(
                offset: offset,
                child: child,
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFFF099),
                    Color(0xFFFFD700),
                    Color(0xFFB8860B),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black54,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── MINIMAP ───────────────────────────────────────────────────────────

class _MinimapPainter extends CustomPainter {
  final GameState gameState;
  final Size viewportSize;
  _MinimapPainter({required this.gameState, required this.viewportSize}) : super(repaint: gameState);

  @override
  void paint(Canvas canvas, Size size) {
    if (!gameState.isLoaded) return;
    final ms = gameState.mapSize;
    final tw = size.width / ms, th = size.height / ms;

    for (int r = 0; r < ms; r++) {
      for (int c = 0; c < ms; c++) {
        final tile = gameState.tiles[r][c];
        if (tile.type == TileType.empty) continue;
        
        bool isVisible = gameState.visibleMap.isNotEmpty && gameState.visibleMap[r][c];
        bool isExplored = gameState.exploredMap.isNotEmpty && gameState.exploredMap[r][c];
        
        Color color;
        if (!isExplored) {
          color = Colors.black;
        } else if (!isVisible) {
          color = _mc(tile).withOpacity(0.35);
        } else {
          color = _mc(tile);
        }

        canvas.drawRect(
          Rect.fromLTWH(c * tw, r * th, tw + 0.1, th + 0.1),
          Paint()..color = color,
        );
      }
    }

    // Dibujar unidades en el minimapa (solo si son visibles)
    for (var entity in gameState.entities) {
      int r = entity.row.round().clamp(0, ms - 1);
      int c = entity.col.round().clamp(0, ms - 1);
      bool isVisible = gameState.visibleMap.isEmpty || gameState.visibleMap[r][c];
      bool isAlly = gameState.players[entity.playerIndex].teamIndex == gameState.humanTeamIndex;

      if (isVisible || isAlly) {
        canvas.drawCircle(
          Offset(entity.col * tw, entity.row * th),
          entity.type == EntityType.building ? 2.0 : 1.0,
          Paint()..color = Color(playerColors[entity.playerIndex % playerColors.length]),
        );
      }
    }
    for (final s in gameState.spawnZones) {
      canvas.drawCircle(
        Offset(s.centerCol * tw + tw / 2, s.centerRow * th + th / 2), 3,
        Paint()..color = Color(playerColors[s.playerIndex % playerColors.length]),
      );
    }
    
    // Draw camera viewport (sin zoom, bloqueado a 1.0)
    final cx = gameState.cameraX;
    final cy = gameState.cameraY;
    
    // Esquinas en coordenadas del mundo
    final corners = [
      Offset(cx - viewportSize.width / 2, cy - viewportSize.height / 4),
      Offset(cx + viewportSize.width / 2, cy - viewportSize.height / 4),
      Offset(cx + viewportSize.width / 2, cy + viewportSize.height * 0.75),
      Offset(cx - viewportSize.width / 2, cy + viewportSize.height * 0.75),
    ];
    
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final wx = corners[i].dx;
      final wy = corners[i].dy;
      // Convert world space to map tile grid
      final col = (wx / 32.0 + wy / 16.0) / 2.0;
      final row = (wy / 16.0 - wx / 32.0) / 2.0;
      
      final mx = col * tw;
      final my = row * th;
      
      if (i == 0) path.moveTo(mx, my);
      else path.lineTo(mx, my);
    }
    path.close();
    
    canvas.drawPath(path, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
    );
  }

  Color _mc(MapTile t) {
    switch (t.type) {
      case TileType.grass: return const Color(0xFF4CAF50);
      case TileType.forest: return const Color(0xFF1B5E20);
      case TileType.goldDeposit: return const Color(0xFFFFD700);
      case TileType.water: return const Color(0xFF1565C0);
      case TileType.deepWater: return const Color(0xFF0D47A1);
      case TileType.sand: return const Color(0xFFFFD54F);
      case TileType.hill: return const Color(0xFF8BC34A);
      case TileType.spawn: return const Color(0xFF795548);
      default: return Colors.transparent;
    }
  }

  @override
  bool shouldRepaint(_MinimapPainter old) => true;
}
