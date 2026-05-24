import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/pixel_button.dart';
import '../game/models/game_models.dart';
import '../game/engine/map_generator.dart';
import '../services/game_data_service.dart';
import 'game_screen.dart';

enum GameMode { onlineTeams, vsIA, onlineFFA }

class GameConfigScreen extends StatefulWidget {
  const GameConfigScreen({super.key});

  @override
  State<GameConfigScreen> createState() => _GameConfigScreenState();
}

class _GameConfigScreenState extends State<GameConfigScreen> {
  GameMode _selectedMode = GameMode.vsIA;
  
  // VS IA Settings
  int _aiCount = 1;
  final List<String> _difficulties = ['Fácil', 'Normal', 'Difícil'];

  String _playerCivId = '';
  bool _spectatorMode = false;
  late List<Map<String, dynamic>> _aiSettings;

  @override
  void initState() {
    super.initState();
    _aiSettings = List.generate(7, (index) => {
      'difficulty': 'Normal',
      'civId': '',
    });

    // Initialize player civ from loaded data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameData = Provider.of<GameDataService>(context, listen: false);
      if (gameData.isLoaded && gameData.civilizations.isNotEmpty) {
        setState(() {
          _playerCivId = gameData.civilizations.first.id;
          for (var ai in _aiSettings) {
            ai['civId'] = gameData.civilizations.first.id;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameDataService>(context);
    
    // Auto-initialize civ IDs when data finishes loading
    if (gameData.isLoaded && _playerCivId.isEmpty && gameData.civilizations.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _playerCivId = gameData.civilizations.first.id;
          for (var ai in _aiSettings) {
            if (ai['civId'] == '') ai['civId'] = gameData.civilizations.first.id;
          }
        });
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background pattern
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(
                  painter: GridPainter(),
                ),
              ),
            ),
            
            if (gameData.isLoading)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFFFD700)),
                    const SizedBox(height: 16),
                    Text('Sincronizando datos del juego...', 
                      style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white54)),
                  ],
                ),
              )
            else if (gameData.error != null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text('Error de conexión', style: GoogleFonts.pressStart2p(fontSize: 12, color: Colors.redAccent)),
                    const SizedBox(height: 8),
                    Text(gameData.error!, style: GoogleFonts.roboto(fontSize: 10, color: Colors.white54)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => gameData.loadSnapshot(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            else
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildModeSelector(),
                      const SizedBox(height: 20),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _buildConfigPanel(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFFD700), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        Text(
          'PREPARAR BATALLA',
          style: GoogleFonts.pressStart2p(
            fontSize: 18,
            color: const Color(0xFFFFD700),
            shadows: [const Shadow(color: Colors.black, offset: Offset(2, 2))],
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _modeButton('ONLINE EQUIPOS', GameMode.onlineTeams),
          _modeButton('VS IA (FFA)', GameMode.vsIA),
          _modeButton('ONLINE FFA', GameMode.onlineFFA),
        ],
      ),
    );
  }

  Widget _modeButton(String text, GameMode mode) {
    bool isSelected = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE94560) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigPanel() {
    return KeyedSubtree(
      key: ValueKey(_selectedMode),
      child: () {
        switch (_selectedMode) {
          case GameMode.vsIA:
            return _buildVsIAConfig();
          case GameMode.onlineTeams:
            return _buildOnlineTeamsConfig();
          case GameMode.onlineFFA:
            return _buildOnlineFFAConfig();
        }
      }(),
    );
  }

  Widget _buildVsIAConfig() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildSectionHeader('TU CONFIGURACIÓN'),
        _buildPlayerSlot(),
        const SizedBox(height: 24),
        _buildSectionHeader('OPONENTES IA'),
        _buildAICountSelector(),
        const SizedBox(height: 12),
        ...List.generate(_aiCount, (index) => _buildAISlot(index)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(width: 4, height: 16, color: const Color(0xFFE94560)),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSlot() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TÚ (HOST)', style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Liderando la civilización', style: GoogleFonts.roboto(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          _buildCivDropdown(_playerCivId, (val) => setState(() => _playerCivId = val!)),
          const SizedBox(width: 8),
          _buildSpectatorToggle(),
        ],
      ),
    );
  }

  Widget _buildSpectatorToggle() {
    return Column(
      children: [
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: _spectatorMode,
            onChanged: (v) => setState(() => _spectatorMode = v),
            activeColor: const Color(0xFFE94560),
          ),
        ),
        Text('SPECTATOR', style: GoogleFonts.pressStart2p(fontSize: 6, color: Colors.white54)),
      ],
    );
  }

  Widget _buildAICountSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('NÚMERO DE ENEMIGOS', style: GoogleFonts.roboto(color: Colors.white70)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white54),
                onPressed: _aiCount > 1 ? () => setState(() => _aiCount--) : null,
              ),
              Text('$_aiCount', style: GoogleFonts.pressStart2p(color: const Color(0xFFE94560), fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white54),
                onPressed: _aiCount < 7 ? () => setState(() => _aiCount++) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAISlot(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text('${index + 1}', style: GoogleFonts.pressStart2p(color: Colors.white24, fontSize: 10)),
          const SizedBox(width: 12),
          const Icon(Icons.computer, color: Colors.redAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDifficultyDropdown(index),
          ),
          const SizedBox(width: 12),
          _buildCivDropdown(_aiSettings[index]['civId'], (val) => setState(() => _aiSettings[index]['civId'] = val!)),
        ],
      ),
    );
  }

  Widget _buildDifficultyDropdown(int index) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _aiSettings[index]['difficulty'],
        dropdownColor: const Color(0xFF1a1a2e),
        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12),
        items: _difficulties.map((d) => DropdownMenuItem(value: d, child: Text(d.toUpperCase()))).toList(),
        onChanged: (val) => setState(() => _aiSettings[index]['difficulty'] = val!),
      ),
    );
  }

  Widget _buildCivDropdown(String currentId, Function(String?) onChanged) {
    final gameData = Provider.of<GameDataService>(context, listen: false);
    final civs = gameData.civilizations;
    // If the current value is not in the list, default to the first
    final validId = civs.any((c) => c.id == currentId) ? currentId : (civs.isNotEmpty ? civs.first.id : '');
    if (civs.isEmpty) {
      return const Text('...', style: TextStyle(color: Colors.white38));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validId,
          dropdownColor: const Color(0xFF1a1a2e),
          style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold),
          items: civs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name.toUpperCase()))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildOnlineTeamsConfig() {
    return Column(
      children: [
        _buildSectionHeader('EQUIPOS 2vs2'),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildTeamCard('EQUIPO A', [
                {'name': 'Tú', 'civ': _playerCivId, 'ready': true},
                {'name': 'Esperando...', 'civ': '-', 'ready': false},
              ], Colors.cyanAccent)),
              const SizedBox(width: 16),
              Expanded(child: _buildTeamCard('EQUIPO B', [
                {'name': 'Esperando...', 'civ': '-', 'ready': false},
                {'name': 'Esperando...', 'civ': '-', 'ready': false},
              ], Colors.orangeAccent)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamCard(String title, List<Map<String, dynamic>> members, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.pressStart2p(fontSize: 10, color: accentColor),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: members.length,
              itemBuilder: (context, i) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(members[i]['name'], style: GoogleFonts.orbitron(color: Colors.white, fontSize: 10)),
                    const SizedBox(height: 4),
                    Text(members[i]['civ'], style: GoogleFonts.roboto(color: Colors.white54, fontSize: 10)),
                    if (members[i]['ready'])
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineFFAConfig() {
    return Column(
      children: [
        _buildSectionHeader('LOBBY FFA (8 JUGADORES)'),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 8,
            itemBuilder: (context, i) => Container(
              decoration: BoxDecoration(
                color: i == 0 ? const Color(0xFFE94560).withOpacity(0.1) : Colors.black26,
                border: Border.all(color: i == 0 ? const Color(0xFFE94560) : Colors.white10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(i == 0 ? Icons.person : Icons.person_outline, 
                    color: i == 0 ? const Color(0xFFE94560) : Colors.white24),
                  const SizedBox(height: 4),
                  Text(i == 0 ? 'TÚ' : 'LIBRE', 
                    style: GoogleFonts.pressStart2p(fontSize: 8, color: i == 0 ? Colors.white : Colors.white24)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: PixelButton(
            text: 'ATRAS',
            color: Colors.grey[800]!,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: PixelButton(
            text: '¡A LA BATALLA!',
            color: const Color(0xFFE94560),
            onPressed: () => _startBattle(),
          ),
        ),
      ],
    );
  }

  void _startBattle() {
    final seed = GameMapGenerator.generateSeed();
    final diffMap = {
      'Fácil': AIDifficulty.easy,
      'Normal': AIDifficulty.normal,
      'Difícil': AIDifficulty.hard,
    };

    final players = <PlayerConfig>[
      PlayerConfig(
        index: 0,
        teamIndex: 0,
        type: _spectatorMode ? PlayerType.ai : PlayerType.human,
        civId: _playerCivId,
        name: _spectatorMode ? 'IA ESPECTADOR' : 'TÚ',
        colorIndex: 0,
      ),
      ...List.generate(_aiCount, (i) => PlayerConfig(
        index: i + 1,
        teamIndex: (i + 1) % 2,
        type: PlayerType.ai,
        civId: _aiSettings[i]['civId'] ?? _playerCivId,
        aiDifficulty: diffMap[_aiSettings[i]['difficulty']] ?? AIDifficulty.normal,
        name: 'IA ${i + 1}',
        colorIndex: i + 1,
      )),
    ];

    int calculatedMapSize = players.length <= 2 ? 60 : 60 + ((125 - 60) * (players.length - 2) / 6).round();

    final match = GameMatch(
      seed: seed,
      players: players,
      mapSize: calculatedMapSize,
      matchId: 'match_${DateTime.now().millisecondsSinceEpoch}',
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(match: match)),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    for (var i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble(), size.height), paint);
    }
    for (var i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i.toDouble()), Offset(size.width, i.toDouble()), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

