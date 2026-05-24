import 'dart:io';

void main() {
  final file = File('movil/lib/game/engine/game_state.dart');
  final lines = file.readAsLinesSync();
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.contains('entityBaseStats') && line.contains('!')) {
      print('Line ${i + 1}: $line');
    }
  }
}
