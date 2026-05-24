
content = open(r'c:\Users\rober\OneDrive\Escritorio\pruebasraras\RTS_1\rts_game\lib\game\engine\game_state.dart', encoding='utf-8').read()
print(f"Open: {content.count('{')}, Close: {content.count('}')}")
