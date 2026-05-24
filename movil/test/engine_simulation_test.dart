import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:rts_isometric_game/game/engine/game_state.dart';
import 'package:rts_isometric_game/game/models/game_models.dart';

void main() {
  test('Engine dry run execution', () async {
    print('Starting engine test...');

    final match = GameMatch(
      seed: 12345,
      players: [
        PlayerConfig(
          index: 0,
          teamIndex: 0,
          type: PlayerType.human,
          civId: 'romans',
          name: 'Player 1',
          colorIndex: 0,
        ),
        PlayerConfig(
          index: 1,
          teamIndex: 1,
          type: PlayerType.ai,
          civId: 'vikings',
          name: 'AI 1',
          colorIndex: 1,
        ),
      ],
      mapSize: 125,
      matchId: 'test_match_id',
    );

    final gameState = GameState();
    
    try {
      print('Calling initializeMatch...');
      await gameState.initializeMatch(match);
      print('initializeMatch completed successfully!');
      
      print('Running 100 engine updates to simulate ticks...');
      for (int i = 0; i < 100; i++) {
        // simulate 16ms frames
        gameState.update(0.016);
        
        // also simulate some ticks
        if (i % 30 == 0) {
          print('Frame $i completed...');
        }
      }
      print('All engine updates completed successfully without crashing!');
    } catch (e, stack) {
      print('CRITICAL EXCEPTION CAUGHT:');
      print(e);
      print(stack);
      fail('Engine crashed during dry run simulation: $e');
    }
  });
}
