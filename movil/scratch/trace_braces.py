
with open(r'c:\Users\rober\OneDrive\Escritorio\pruebasraras\RTS_1\rts_game\lib\game\engine\game_state.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

depth = 0
for i, line in enumerate(lines):
    line_no = i + 1
    depth += line.count('{')
    depth -= line.count('}')
    if depth == 0 or depth == 1:
        if '{' in line or '}' in line:
            print(f"Line {line_no} (Depth {depth}): {line.strip()}")
