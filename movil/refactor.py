import re

file_path = "lib/game/engine/game_state.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Imports a agregar
imports = """import 'package:flutter/material.dart';
import 'managers/tech_tree_manager.dart';
import 'managers/physics_manager.dart';
import 'managers/combat_manager.dart';
import 'managers/vision_manager.dart';
import 'managers/production_manager.dart';
import 'managers/ai_manager.dart';
"""

# Insertar imports después del último import original
# Buscamos el último import
import_matches = list(re.finditer(r"^import\s+.*?;", content, re.MULTILINE))
if import_matches:
    last_import = import_matches[-1]
    insert_pos = last_import.end()
    content = content[:insert_pos] + "\n" + imports + content[insert_pos:]

# Agregar las instancias de los managers al inicio de GameState
managers_decl = """
  late final TechTreeManager techManager;
  late final PhysicsManager physicsManager;
  late final CombatManager combatManager;
  late final VisionManager visionManager;
  late final ProductionManager productionManager;
  late final AiManager aiManager;
  
  GameState() {
    techManager = TechTreeManager(this);
    physicsManager = PhysicsManager(this);
    combatManager = CombatManager(this);
    visionManager = VisionManager(this);
    productionManager = ProductionManager(this);
    aiManager = AiManager(this);
  }

  void triggerUiUpdate() => notifyListeners();

"""

# Insertar dentro de la clase GameState
class_match = re.search(r"class GameState extends ChangeNotifier\s*{", content)
if class_match:
    insert_pos = class_match.end()
    content = content[:insert_pos] + managers_decl + content[insert_pos:]

# Reemplazar getter de visibleMap
# Encontrar: "List<List<bool>> visibleMap = [];"
# y borrar _initVisibleMap si existe
content = re.sub(r"List<List<bool>> visibleMap = \[\];", "List<List<bool>> get visibleMap => visionManager.visibleMap;", content)

# Reemplazar métodos por delegados:

# getUnitStat
content = re.sub(r"double getUnitStat\(GameEntity entity, String statKey, double baseValue\) \{.*?\n  \}", 
                 r"double getUnitStat(GameEntity entity, String statKey, double baseValue) => techManager.getUnitStat(entity, statKey, baseValue);", 
                 content, flags=re.DOTALL)

# researchTechnology
content = re.sub(r"void researchTechnology\(int playerIndex, String techName\) \{.*?\n  \}", 
                 r"void researchTechnology(int playerIndex, String techName) => techManager.researchTechnology(playerIndex, techName);", 
                 content, flags=re.DOTALL)

# spawnProjectile
content = re.sub(r"void spawnProjectile\(GameEntity attacker, GameEntity target\) \{.*?\n  \}", 
                 r"void spawnProjectile(GameEntity attacker, GameEntity target) => combatManager.spawnProjectile(attacker, target, 10);", 
                 content, flags=re.DOTALL)

# _updateVisibility
content = re.sub(r"void _updateVisibility\(\) \{.*?\n  \}", 
                 r"void _updateVisibility() => visionManager.updateVisibility();", 
                 content, flags=re.DOTALL)

# _updateProduction
content = re.sub(r"void _updateProduction\(double dt\) \{.*?\n  \}", 
                 r"void _updateProduction(double dt) => productionManager.updateProduction(dt);", 
                 content, flags=re.DOTALL)

# _simulatePhysics
content = re.sub(r"void _simulatePhysics\(double dt\) \{.*?\n  \}", 
                 r"void _simulatePhysics(double dt) => physicsManager.simulatePhysics(dt);", 
                 content, flags=re.DOTALL)

# _processServerTick
content = re.sub(r"void _processServerTick\(\) \{.*?\n  \}", 
                 r"void _processServerTick() => aiManager.processServerTick();", 
                 content, flags=re.DOTALL)

# _autoAssignIdleWorkers
content = re.sub(r"void _autoAssignIdleWorkers\(\) \{.*?\n  \}", 
                 r"void _autoAssignIdleWorkers() => aiManager.autoAssignIdleWorkers();", 
                 content, flags=re.DOTALL)

# _moveAlongPath
content = re.sub(r"void _moveAlongPath\(GameEntity entity, double speed, double dt\) \{.*?\n  \}", 
                 r"// _moveAlongPath movido a physicsManager", 
                 content, flags=re.DOTALL)

# _sendToClosestDropoff
content = re.sub(r"void _sendToClosestDropoff\(GameEntity entity\) \{.*?\n  \}", 
                 r"// _sendToClosestDropoff movido a physicsManager", 
                 content, flags=re.DOTALL)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("game_state.dart refactorizado con éxito.")
