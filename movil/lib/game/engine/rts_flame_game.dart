import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'game_state.dart';
import '../rendering/isometric_renderer.dart';

class RtsFlameGame extends FlameGame {
  final GameState gameState;
  late final CustomPainterComponent mapPainter;

  RtsFlameGame({required this.gameState});

  @override
  Future<void> onLoad() async {
    // Para empezar la migración suavemente, primero usamos el CustomPainter existente dentro de Flame.
    // Esto nos da acceso al loop de Flame (update) y permite ir reemplazando piezas gradualmente.
    mapPainter = CustomPainterComponent(
      painter: IsometricRenderer(
        gameState: gameState,
        viewportSize: size.toSize(),
      ),
      size: size,
    );
    add(mapPainter);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Delega la lógica de negocio al GameState
    if (gameState.isLoaded && !gameState.isGameOver) {
      gameState.update(dt);
    }
  }
  
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
       mapPainter.size = size;
       // Hay que recrear el painter con el nuevo viewport size
       mapPainter.painter = IsometricRenderer(
         gameState: gameState,
         viewportSize: size.toSize(),
       );
    }
  }
}
