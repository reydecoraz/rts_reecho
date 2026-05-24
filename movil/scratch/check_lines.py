
import sys
content = open(r'c:\Users\rober\OneDrive\Escritorio\pruebasraras\RTS_1\rts_game\lib\game\engine\game_state.dart', encoding='utf-8').read()
lines = content.split('\n')
for i in range(175, 195):
    print(f"{i+1}: {repr(lines[i])}")
