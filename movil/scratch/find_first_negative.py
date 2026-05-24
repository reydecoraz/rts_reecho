
with open(r'c:\Users\rober\OneDrive\Escritorio\pruebasraras\RTS_1\rts_game\lib\game\engine\game_state.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

depth = 0
for i, line in enumerate(lines):
    line_no = i + 1
    depth += line.count('{')
    depth -= line.count('}')
    if depth < 0:
        print(f"FIRST NEGATIVE DEPTH at line {line_no}: {line.strip()}")
        # Check surrounding lines
        for j in range(max(0, i-5), min(len(lines), i+5)):
            print(f"{j+1}: {lines[j].strip()}")
        break
else:
    print("No negative depth found.")
