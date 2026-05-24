
with open(r'c:\Users\rober\OneDrive\Escritorio\pruebasraras\RTS_1\rts_game\lib\game\engine\game_state.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

depth = 0
for i, line in enumerate(lines):
    line_no = i + 1
    depth += line.count('{')
    depth -= line.count('}')
    if line_no >= 590 and line_no <= 610:
        print(f"Line {line_no}: Depth {depth} | Content: {line.strip()}")
    if line_no >= 1260:
        print(f"Line {line_no}: Depth {depth} | Content: {line.strip()}")
