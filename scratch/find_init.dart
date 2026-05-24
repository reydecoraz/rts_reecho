import 'dart:io';

void main() {
  final file = File('movil/lib/game/engine/game_state.dart');
  final lines = file.readAsLinesSync();
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('initializeMatch')) {
      print('initializeMatch is at line ${i + 1}');
    }
  }
}
