
with open(r'c:\Users\rober\OneDrive\Escritorio\pruebasraras\RTS_1\rts_game\lib\game\engine\game_state.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

depth = 0
for i, line in enumerate(lines):
    depth += line.count('{')
    depth -= line.count('}')
    if depth <= 0 and i > 15 and i < len(lines)-2:
        print(f"ERROR: Line {i+1} hits depth {depth}: {line.strip()}")
        # Find where the class closed
        break
else:
    print("No premature closures found in GameState class.")
