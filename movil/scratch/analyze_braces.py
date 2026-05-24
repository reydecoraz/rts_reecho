
import os

with open(r'c:\Users\rober\OneDrive\Escritorio\pruebasraras\RTS_1\rts_game\lib\game\engine\game_state.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

depth = 0
for i, line in enumerate(lines):
    line_no = i + 1
    old_depth = depth
    depth += line.count('{')
    depth -= line.count('}')
    if old_depth > 0 and depth == 0:
        print(f"Potential class/method close at line {line_no}")
    if depth < 0:
        print(f"Error: depth < 0 at line {line_no}")
        depth = 0

print(f"Final depth: {depth}")
