
with open(r'c:\Users\rober\OneDrive\Escritorio\pruebasraras\RTS_1\rts_game\lib\game\engine\game_state.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

depth = 0
in_class = False
for i, line in enumerate(lines):
    line_no = i + 1
    depth += line.count('{')
    depth -= line.count('}')
    if "class GameState" in line:
        in_class = True
    if in_class and depth == 0 and line_no < len(lines):
        print(f"CLASS CLOSED PREMATURELY at line {line_no}: {line.strip()}")
        break
else:
    print("Class is properly closed at the end.")
