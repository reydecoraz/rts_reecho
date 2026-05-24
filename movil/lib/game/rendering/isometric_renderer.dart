import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_models.dart';
import '../engine/game_state.dart';
import '../../services/game_data_service.dart';

class IsometricRenderer extends CustomPainter {
  final GameState gameState;
  final Size viewportSize;

  static const double TILE_WIDTH = 64.0;
  static const double TILE_HEIGHT = 32.0;

  IsometricRenderer({required this.gameState, required this.viewportSize})
      : super(repaint: gameState); // Repinta automáticamente con ChangeNotifier

  @override
  void paint(Canvas canvas, Size size) {
    if (!gameState.isLoaded) return;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 4);
    // Zoom bloqueado a 1.0 para máxima performance
    canvas.translate(-gameState.cameraX, -gameState.cameraY);

    final tiles = gameState.tiles;
    final mapSize = gameState.mapSize;

    // Calcular límites de culling (dibujar solo lo visible)
    // El área visible en coordenadas del mundo centradas en la cámara
    double viewLeft = gameState.cameraX - size.width / 2 - TILE_WIDTH;
    double viewRight = gameState.cameraX + size.width / 2 + TILE_WIDTH;
    double viewTop = gameState.cameraY - size.height / 4 - TILE_HEIGHT;
    double viewBottom = gameState.cameraY + size.height * 0.75 + TILE_HEIGHT;

    for (int row = 0; row < mapSize; row++) {
      for (int col = 0; col < mapSize; col++) {
        final tile = tiles[row][col];
        if (tile.type == TileType.empty) continue; 

        final pos = Offset(
          (col - row) * (TILE_WIDTH / 2),
          (col + row) * (TILE_HEIGHT / 2),
        );

        // 1. Culling: saltar si está fuera de la pantalla
        if (pos.dx < viewLeft || pos.dx > viewRight || pos.dy < viewTop || pos.dy > viewBottom) {
          continue;
        }

        // 2. Fog of War
        bool isVisible = gameState.showPostGameMap || (gameState.visibleMap.isNotEmpty && gameState.visibleMap[row][col]);
        bool isExplored = gameState.showPostGameMap || (gameState.exploredMap.isNotEmpty && gameState.exploredMap[row][col]);
        
        _paintTile(canvas, tile, pos, isVisible, isExplored);
      }
    }

    _paintEntities(canvas, viewLeft, viewRight, viewTop, viewBottom);
    _paintProjectiles(canvas, viewLeft, viewRight, viewTop, viewBottom);

    canvas.restore();
  }

  void _paintProjectiles(Canvas canvas, double vL, double vR, double vT, double vB) {
    for (var projectile in gameState.activeProjectiles) {
      double dx = projectile.targetCol - projectile.startCol;
      double dy = projectile.targetRow - projectile.startRow;
      double totalDist = sqrt(dx * dx + dy * dy);

      double curDx = projectile.col - projectile.startCol;
      double curDy = projectile.row - projectile.startRow;
      double curDist = sqrt(curDx * curDx + curDy * curDy);

      double t = totalDist > 0 ? (curDist / totalDist).clamp(0.0, 1.0) : 1.0;
      double arcHeight = 40.0 * t * (1.0 - t); // Parabolic 3D height

      final currentScreenPos = Offset(
        (projectile.col - projectile.row) * (TILE_WIDTH / 2),
        (projectile.col + projectile.row) * (TILE_HEIGHT / 2) - arcHeight,
      );

      // Culling de proyectiles
      if (currentScreenPos.dx < vL || currentScreenPos.dx > vR || currentScreenPos.dy < vT || currentScreenPos.dy > vB) continue;

      // Calcular ángulo de vuelo en pantalla
      double screenDx = (dx - dy) * (TILE_WIDTH / 2);
      // Incluir cambio de la parábola para el ángulo
      double dt = 0.01;
      double nextArcHeight = 40.0 * (t + dt) * (1.0 - (t + dt));
      double dArcHeight = nextArcHeight - arcHeight;
      double screenDy = (dx + dy) * (TILE_HEIGHT / 2) - dArcHeight;

      double angle = atan2(screenDy, screenDx);

      canvas.save();
      canvas.translate(currentScreenPos.dx, currentScreenPos.dy);
      canvas.rotate(angle);

      // Dibujar cuerpo de la flecha (marrón elegante)
      final arrowPaint = Paint()
        ..color = const Color(0xFF8B4513)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(-8, 0), const Offset(8, 0), arrowPaint);

      // Dibujar punta de flecha de oro
      final headPaint = Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.fill;
      final headPath = Path()
        ..moveTo(8, 0)
        ..lineTo(4, -3)
        ..lineTo(4, 3)
        ..close();
      canvas.drawPath(headPath, headPaint);

      // Dibujar plumas traseras (blancas)
      final tailPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 1.5;
      canvas.drawLine(const Offset(-8, 0), const Offset(-11, -3), tailPaint);
      canvas.drawLine(const Offset(-8, 0), const Offset(-11, 3), tailPaint);

      canvas.restore();
    }
  }

  void _paintEntities(Canvas canvas, double vL, double vR, double vT, double vB) {
    // Clasificar granjas y otras entidades
    final farms = <GameEntity>[];
    final otherEntities = <GameEntity>[];
    
    for (var entity in gameState.entities) {
      bool isFarm = false;
      if (entity.type == EntityType.building) {
        String? category = GameDataService().getBuildingByName(entity.name)?.category;
        if (category == 'farm' || entity.name.toLowerCase().contains('farm') || entity.name.contains('Granja')) {
          isFarm = true;
        }
      }
      if (isFarm) {
        farms.add(entity);
      } else {
        otherEntities.add(entity);
      }
    }

    // 1. Dibujar granjas primero (al nivel del terreno, para que no oculten a los aldeanos)
    for (var entity in farms) {
      _paintSingleEntity(canvas, entity, vL, vR, vT, vB);
    }

    // 2. Dibujar el resto de las entidades (unidades y edificios altos) ordenadas por profundidad (col + row)
    // para un apilamiento isométrico perfecto de atrás hacia adelante
    final sortedOthers = List<GameEntity>.from(otherEntities)
      ..sort((a, b) => (a.col + a.row).compareTo(b.col + b.row));

    for (var entity in sortedOthers) {
      _paintSingleEntity(canvas, entity, vL, vR, vT, vB);
    }
  }

  void _paintSingleEntity(Canvas canvas, GameEntity entity, double vL, double vR, double vT, double vB) {
    final pos = Offset(
      (entity.col - entity.row) * (TILE_WIDTH / 2),
      (entity.col + entity.row) * (TILE_HEIGHT / 2),
    );

    // Culling de entidades
    if (pos.dx < vL || pos.dx > vR || pos.dy < vT || pos.dy > vB) return;

    // Fog of War: No dibujar enemigos si no son visibles
    int r = entity.row.round().clamp(0, gameState.mapSize - 1);
    int c = entity.col.round().clamp(0, gameState.mapSize - 1);
    bool isVisible = gameState.showPostGameMap || gameState.visibleMap.isEmpty || gameState.visibleMap[r][c];
    
    // Aliados siempre visibles (el mapa ya los incluye), pero forzamos por si acaso
    bool isAlly = gameState.players[entity.playerIndex].teamIndex == gameState.humanTeamIndex;
    if (!isVisible && !isAlly) return;

    final pColor = Color(playerColors[entity.playerIndex % playerColors.length]);

    if (entity.type == EntityType.building) {
      var stats = entityBaseStats[entity.name];
      if (stats != null && stats.spriteImage != null) {
        // Dibujar Sprite de Edificio de forma completamente dinámica (desplazado hacia abajo +10px)
        final image = stats.spriteImage!;
        final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
        // Un edificio ocupa un área mayor, lo dibujamos escalado de 64x64
        final dst = Rect.fromCenter(center: Offset(pos.dx, pos.dy - 14), width: 64, height: 64);
        canvas.drawImageRect(image, src, dst, Paint());
      } else {
        String? category = GameDataService().getBuildingByName(entity.name)?.category;
        if (category == 'town_center') {
          _paintTownCenter(canvas, pos, pColor);
        } else if (category == 'farm') {
          _paintFarm(canvas, pos);
        } else if (category == 'military_barracks') {
          _paintBarracks(canvas, pos, pColor);
        } else if (category == 'military_archery') {
          _paintArchery(canvas, pos, pColor);
        } else if (category == 'house') {
          _paintHouse(canvas, pos, pColor);
        } else {
          // Genérico (desplazado hacia abajo +10px)
          canvas.drawRect(Rect.fromLTWH(pos.dx - 12, pos.dy - 14, 24, 24), Paint()..color = pColor.withOpacity(0.9));
        }
      }
      
      _paintHpBar(canvas, pos.dx, pos.dy - 25, entity.hp, entity.maxHp);
      _paintText(canvas, entity.name, pos.dx, pos.dy - 35);
    } else {
      // --- Pintar Aura de color del jugador (Círculo difuminado en el suelo) ---
      final auraPaint = Paint()
        ..color = pColor.withOpacity(0.18)
        ..style = PaintingStyle.fill;
      final auraBorderPaint = Paint()
        ..color = pColor.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      
      final auraRect = Rect.fromCenter(center: Offset(pos.dx, pos.dy), width: 22, height: 11);
      canvas.drawOval(auraRect, auraPaint);
      canvas.drawOval(auraRect, auraBorderPaint);

      var stats = entityBaseStats[entity.name];
      if (stats != null && stats.spriteImage != null) {
        // Dibujar Sprite (desplazado hacia abajo +6px)
        final image = stats.spriteImage!;
        // Escalar el sprite para que encaje en el tile (aprox 32x32 o 64x64)
        final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
        // Ajustamos tamaño base: 32x32
        final dst = Rect.fromCenter(center: Offset(pos.dx, pos.dy - 10), width: 32, height: 32);
        canvas.drawImageRect(image, src, dst, Paint());
      } else {
        String? category = GameDataService().getUnitByName(entity.name)?.category;
        if (category == 'military_infantry') {
          // Triángulo (Infantería - desplazado hacia abajo +6px)
          final path = Path()..moveTo(pos.dx, pos.dy - 10)..lineTo(pos.dx + 7, pos.dy + 2)..lineTo(pos.dx - 7, pos.dy + 2)..close();
          canvas.drawPath(path, Paint()..color = pColor);
          canvas.drawPath(path, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1);
        } else if (category == 'military_archer') {
          // Cuadrado (Arquero - desplazado hacia abajo +6px)
          canvas.drawRect(Rect.fromCenter(center: Offset(pos.dx, pos.dy - 4), width: 10, height: 10), Paint()..color = pColor);
          canvas.drawRect(Rect.fromCenter(center: Offset(pos.dx, pos.dy - 4), width: 10, height: 10), Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1);
        } else if (category == 'military_cavalry') {
          // Rombo Grande (Caballería - desplazado hacia abajo +6px)
          final path = Path()..moveTo(pos.dx, pos.dy - 12)..lineTo(pos.dx + 8, pos.dy - 4)..lineTo(pos.dx, pos.dy + 4)..lineTo(pos.dx - 8, pos.dy - 4)..close();
          canvas.drawPath(path, Paint()..color = pColor);
          canvas.drawPath(path, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1);
        } else {
          // Círculo (Aldeano - desplazado hacia abajo +6px)
          canvas.drawCircle(Offset(pos.dx, pos.dy - 2), 6, Paint()..color = pColor);
          canvas.drawCircle(Offset(pos.dx, pos.dy - 2), 6, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1);
        }
      }
      _paintHpBar(canvas, pos.dx, pos.dy - 12, entity.hp, entity.maxHp);

      // Dibujar Indicador de Selección (Círculo en el suelo)
      if (gameState.selectedEntities.contains(entity)) {
        final sPaint = Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawOval(Rect.fromCenter(center: Offset(pos.dx, pos.dy), width: 24, height: 12), sPaint);
      }
    }
  }

  void _paintHpBar(Canvas canvas, double cx, double cy, int hp, int maxHp) {
    double ratio = hp / maxHp;
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: 20, height: 4), Paint()..color = Colors.red);
    canvas.drawRect(Rect.fromLTWH(cx - 10, cy - 2, 20 * ratio, 4), Paint()..color = Colors.green);
  }

  void _paintText(Canvas canvas, String text, double cx, double cy) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, backgroundColor: Colors.black54)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  void _paintTile(Canvas canvas, MapTile tile, Offset pos, bool isVisible, bool isExplored) {
    final colors = _getTileColors(tile);
    final isSelected = gameState.selectedTile == tile;

    // Pintar niebla total si no es explorado en absoluto
    if (!isExplored) {
      final fogPath = Path()
        ..moveTo(pos.dx, pos.dy - TILE_HEIGHT / 2)
        ..lineTo(pos.dx + TILE_WIDTH / 2, pos.dy)
        ..lineTo(pos.dx, pos.dy + TILE_HEIGHT / 2)
        ..lineTo(pos.dx - TILE_WIDTH / 2, pos.dy)
        ..close();
      canvas.drawPath(fogPath, Paint()..color = Colors.black);
      return; 
    }

    // Rombo isométrico (cara superior)
    final path = Path()
      ..moveTo(pos.dx, pos.dy - TILE_HEIGHT / 2)
      ..lineTo(pos.dx + TILE_WIDTH / 2, pos.dy)
      ..lineTo(pos.dx, pos.dy + TILE_HEIGHT / 2)
      ..lineTo(pos.dx - TILE_WIDTH / 2, pos.dy)
      ..close();

    canvas.drawPath(path, Paint()..color = colors.top);

    // Caras laterales (profundidad) — no en agua
    if (!tile.isWater) {
      final depth = 6.0;
      final leftFace = Path()
        ..moveTo(pos.dx - TILE_WIDTH / 2, pos.dy)
        ..lineTo(pos.dx, pos.dy + TILE_HEIGHT / 2)
        ..lineTo(pos.dx, pos.dy + TILE_HEIGHT / 2 + depth)
        ..lineTo(pos.dx - TILE_WIDTH / 2, pos.dy + depth)
        ..close();
      canvas.drawPath(leftFace, Paint()..color = colors.left);

      final rightFace = Path()
        ..moveTo(pos.dx, pos.dy + TILE_HEIGHT / 2)
        ..lineTo(pos.dx + TILE_WIDTH / 2, pos.dy)
        ..lineTo(pos.dx + TILE_WIDTH / 2, pos.dy + depth)
        ..lineTo(pos.dx, pos.dy + TILE_HEIGHT / 2 + depth)
        ..close();
      canvas.drawPath(rightFace, Paint()..color = colors.right);
    }

    // Borde
    canvas.drawPath(path, Paint()
      ..color = isSelected ? Colors.yellowAccent.withOpacity(0.9) : Colors.black.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 0.5);

    // Decoraciones
    if (tile.type == TileType.forest) _paintTree(canvas, pos);
    if (tile.type == TileType.goldDeposit) _paintGoldVein(canvas, pos);
    if (tile.type == TileType.mountain) _paintStoneVein(canvas, pos);
    if (tile.type == TileType.water || tile.type == TileType.deepWater) {
      _paintWaterShimmer(canvas, pos);
    }
    if (tile.type == TileType.spawn) _paintSpawnMarker(canvas, tile, pos);
    if (tile.type == TileType.berryBush) _paintBerryBush(canvas, pos);

    // Si está explorado pero no es visible actualmente, aplicar una capa de niebla translúcida
    if (!isVisible) {
      canvas.drawPath(path, Paint()..color = Colors.black.withOpacity(0.48));
    }
  }

  void _paintTree(Canvas canvas, Offset pos) {
    canvas.drawRect(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy - 8), width: 3, height: 7),
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.drawCircle(Offset(pos.dx, pos.dy - 17), 8, Paint()..color = const Color(0xFF2E7D32));
    canvas.drawCircle(Offset(pos.dx - 4, pos.dy - 13), 6, Paint()..color = const Color(0xFF388E3C));
    canvas.drawCircle(Offset(pos.dx + 4, pos.dy - 13), 6, Paint()..color = const Color(0xFF43A047));
  }

  void _paintGoldVein(Canvas canvas, Offset pos) {
    final g1 = Paint()..color = const Color(0xFFFFD700);
    final g2 = Paint()..color = const Color(0xFFFFF176); // Más brillante
    for (final o in [const Offset(-4,-7), const Offset(0,-11), const Offset(4,-7), const Offset(-2,-4), const Offset(3,-4)]) {
      canvas.drawCircle(Offset(pos.dx + o.dx, pos.dy + o.dy), 2.5, g1);
      canvas.drawCircle(Offset(pos.dx + o.dx, pos.dy + o.dy), 1.0, g2); // Brillo
    }
  }

  void _paintBerryBush(Canvas canvas, Offset pos) {
    final bushPaint = Paint()..color = const Color(0xFF2E7D32);
    final berryPaint = Paint()..color = Colors.red;
    
    // Dibujar el arbusto como círculos agrupados
    canvas.drawCircle(Offset(pos.dx, pos.dy - 5), 7, bushPaint);
    canvas.drawCircle(Offset(pos.dx - 5, pos.dy - 3), 6, bushPaint);
    canvas.drawCircle(Offset(pos.dx + 5, pos.dy - 3), 6, bushPaint);
    
    // Dibujar algunas bayas rojas
    for (var o in [const Offset(-3,-6), const Offset(2,-8), const Offset(4,-2), const Offset(-4,-2), const Offset(0,-2)]) {
      canvas.drawCircle(Offset(pos.dx + o.dx, pos.dy + o.dy), 1.5, berryPaint);
    }
  }

  void _paintStoneVein(Canvas canvas, Offset pos) {
    final s1 = Paint()..color = const Color(0xFFCFD8DC);
    final s2 = Paint()..color = const Color(0xFF90A4AE);
    for (final o in [const Offset(-5,-6), const Offset(1,-10), const Offset(5,-5), const Offset(-1,-3), const Offset(4,-2)]) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(pos.dx + o.dx, pos.dy + o.dy), width: 4, height: 5),
        o.dx < 0 ? s1 : s2,
      );
    }
  }

  void _paintWaterShimmer(Canvas canvas, Offset pos) {
    final p = Paint()..color = Colors.white.withOpacity(0.15)..strokeWidth = 1;
    canvas.drawLine(Offset(pos.dx - 7, pos.dy - 1), Offset(pos.dx - 2, pos.dy - 1), p);
    canvas.drawLine(Offset(pos.dx + 2, pos.dy + 2), Offset(pos.dx + 7, pos.dy + 2), p);
  }

  void _paintSpawnMarker(Canvas canvas, MapTile tile, Offset pos) {
    final spawn = gameState.spawnZones.firstWhere(
      (z) => z.centerCol == tile.col && z.centerRow == tile.row,
      orElse: () => SpawnZone(playerIndex: 0, centerCol: 0, centerRow: 0),
    );
    final pColor = Color(playerColors[spawn.playerIndex % playerColors.length]);

    canvas.drawLine(Offset(pos.dx, pos.dy - 4), Offset(pos.dx, pos.dy - 20),
      Paint()..color = Colors.white70..strokeWidth = 1.5);
    canvas.drawRect(Rect.fromLTWH(pos.dx, pos.dy - 20, 8, 5), Paint()..color = pColor);

    final tp = TextPainter(
      text: TextSpan(text: '${spawn.playerIndex + 1}',
        style: const TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx + 1, pos.dy - 19));
  }

  _TC _getTileColors(MapTile tile) {
    switch (tile.type) {
      case TileType.grass:
        return const _TC(Color(0xFF4CAF50), Color(0xFF388E3C), Color(0xFF2E7D32));
      case TileType.forest:
        return const _TC(Color(0xFF2E7D32), Color(0xFF1B5E20), Color(0xFF1B5E20));
      case TileType.goldDeposit:
        return const _TC(Color(0xFF5C5C3D), Color(0xFF3D3D2A), Color(0xFF2E2E1F));
      case TileType.water:
        return const _TC(Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF0D47A1));
      case TileType.deepWater:
        return const _TC(Color(0xFF0D47A1), Color(0xFF01579B), Color(0xFF01579B));
      case TileType.sand:
        return const _TC(Color(0xFFFFD54F), Color(0xFFFF8F00), Color(0xFFE65100));
      case TileType.hill:
        return const _TC(Color(0xFF8BC34A), Color(0xFF558B2F), Color(0xFF33691E));
      case TileType.spawn:
        return const _TC(Color(0xFF795548), Color(0xFF5D4037), Color(0xFF4E342E));
      case TileType.mountain:
        return const _TC(Color(0xFF607D8B), Color(0xFF455A64), Color(0xFF37474F));
      case TileType.berryBush:
        return const _TC(Color(0xFF4CAF50), Color(0xFF388E3C), Color(0xFF2E7D32));
      case TileType.empty:
        return const _TC(Color(0x00000000), Color(0x00000000), Color(0x00000000));
    }
  }

  void _paintTownCenter(Canvas canvas, Offset pos, Color color) {
    // Cuerpo principal
    canvas.drawRect(Rect.fromLTWH(pos.dx - 20, pos.dy - 25, 40, 35), Paint()..color = Colors.grey[700]!);
    // Techo
    final roof = Path()..moveTo(pos.dx - 22, pos.dy - 25)..lineTo(pos.dx, pos.dy - 40)..lineTo(pos.dx + 22, pos.dy - 25)..close();
    canvas.drawPath(roof, Paint()..color = color);
    // Puerta
    canvas.drawRect(Rect.fromLTWH(pos.dx - 6, pos.dy - 2, 12, 12), Paint()..color = Colors.black87);
  }

  void _paintFarm(Canvas canvas, Offset pos) {
    // Terreno arado
    final field = Path()
      ..moveTo(pos.dx, pos.dy - TILE_HEIGHT / 2)
      ..lineTo(pos.dx + TILE_WIDTH / 2, pos.dy)
      ..lineTo(pos.dx, pos.dy + TILE_HEIGHT / 2)
      ..lineTo(pos.dx - TILE_WIDTH / 2, pos.dy)
      ..close();
    canvas.drawPath(field, Paint()..color = const Color(0xFF795548));
    
    // Surcos de trigo
    final wheat = Paint()..color = const Color(0xFFFFD54F)..strokeWidth = 1;
    for (double i = -10; i <= 10; i += 5) {
      canvas.drawLine(Offset(pos.dx + i, pos.dy - 5), Offset(pos.dx + i + 2, pos.dy + 5), wheat);
    }
  }

  void _paintBarracks(Canvas canvas, Offset pos, Color color) {
    canvas.drawRect(Rect.fromLTWH(pos.dx - 15, pos.dy - 15, 30, 25), Paint()..color = Colors.brown[400]!);
    canvas.drawRect(Rect.fromLTWH(pos.dx - 15, pos.dy - 20, 30, 8), Paint()..color = color); // Techo del color del jugador
  }

  void _paintArchery(Canvas canvas, Offset pos, Color color) {
    canvas.drawRect(Rect.fromLTWH(pos.dx - 20, pos.dy - 5, 40, 15), Paint()..color = Colors.brown[300]!);
    // Diana
    canvas.drawCircle(Offset(pos.dx + 10, pos.dy + 2), 4, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(pos.dx + 10, pos.dy + 2), 2, Paint()..color = Colors.red);
  }

  void _paintHouse(Canvas canvas, Offset pos, Color color) {
    canvas.drawRect(Rect.fromLTWH(pos.dx - 10, pos.dy - 5, 20, 15), Paint()..color = Colors.grey[300]!);
    final roof = Path()..moveTo(pos.dx - 12, pos.dy - 5)..lineTo(pos.dx, pos.dy - 12)..lineTo(pos.dx + 12, pos.dy - 5)..close();
    canvas.drawPath(roof, Paint()..color = color);
  }

  @override
  bool shouldRepaint(IsometricRenderer oldDelegate) => true; 
}

class _TC {
  final Color top, left, right;
  const _TC(this.top, this.left, this.right);
}

/// Convierte posición de pantalla a coordenadas de tile isométrico
MapTile? screenToTile(Offset screenPos, GameState gameState, Size viewportSize) {
  final worldX = (screenPos.dx - viewportSize.width / 2) + gameState.cameraX;
  final worldY = (screenPos.dy - viewportSize.height / 4) + gameState.cameraY;

  final col = ((worldX / (IsometricRenderer.TILE_WIDTH / 2) + worldY / (IsometricRenderer.TILE_HEIGHT / 2)) / 2).round();
  final row = ((worldY / (IsometricRenderer.TILE_HEIGHT / 2) - worldX / (IsometricRenderer.TILE_WIDTH / 2)) / 2).round();

  if (col < 0 || col >= gameState.mapSize || row < 0 || row >= gameState.mapSize) return null;
  final tile = gameState.tiles[row][col];
  return tile.type == TileType.empty ? null : tile;
}
