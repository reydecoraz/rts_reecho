
with open(r'c:\Users\rober\OneDrive\Escritorio\pruebasraras\RTS_1\rts_game\lib\game\engine\game_state.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

depth = 0
class_started = False
for i, line in enumerate(lines):
    line_no = i + 1
    if "class GameState" in line:
        class_started = True
    depth += line.count('{')
    depth -= line.count('}')
    if class_started and depth == 0:
        print(f"Class closed at line {line_no}: {line.strip()}")
        # break
    if depth < 0:
        print(f"Negative depth at line {line_no}: {line.strip()}")
        break
