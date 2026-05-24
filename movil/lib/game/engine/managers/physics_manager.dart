import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_models.dart';
import '../game_state.dart';
import '../ai/pathfinding_manager.dart';
import '../spatial_grid.dart';
import '../../../services/game_data_service.dart';

class PhysicsManager {
  final GameState state;
  final Random rand = Random();

  PhysicsManager(this.state);

  bool _isMilitaryUnit(String name) {
     var unit = GameDataService().getUnitByName(name);
     return unit != null && unit.category != 'worker' && unit.category != 'civilian' && unit.category != 'building';
  }

  void simulatePhysics(double dt) {
    final physicsDt = dt.clamp(0.0, 0.033); 
    final toRemove = <GameEntity>[]; 
    
    // --- Lógica de la Marcha (Sincronización de velocidad de grupos) ---
    final playersMovingUnits = <int, List<GameEntity>>{};
    for (var entity in state.entities) {
      if (entity.type == EntityType.unit && 
          (entity.state == EntityState.moving || 
           entity.state == EntityState.movingToResource || 
           entity.state == EntityState.attacking)) {
        playersMovingUnits.putIfAbsent(entity.playerIndex, () => []).add(entity);
      }
    }

    for (var pIdx in playersMovingUnits.keys) {
      final units = playersMovingUnits[pIdx]!;
      if (units.length <= 1) continue;

      final visited = <String>{};
      for (var u1 in units) {
        if (visited.contains(u1.id)) continue;
        
        final cluster = <GameEntity>[u1];
        final queue = [u1];
        visited.add(u1.id);

        while (queue.isNotEmpty) {
          final current = queue.removeAt(0);
          for (var u2 in units) {
            if (!visited.contains(u2.id)) {
              double dx = current.col - u2.col;
              double dy = current.row - u2.row;
              double dist = sqrt(dx*dx + dy*dy);
              if (dist <= 6.0) { // Radio de proximidad de grupo de 6 casillas
                visited.add(u2.id);
                cluster.add(u2);
                queue.add(u2);
              }
            }
          }
        }

        if (cluster.length >= 2) {
          double slowestSpeed = 999.0;
          for (var u in cluster) {
            double baseSpd = (GameDataService().getUnitByName(u.name)?.movementSpeed ?? 0.57) * 3.5;
            double unitSpeed = state.techManager.getUnitStat(u, 'movement_speed', baseSpd);
            if (unitSpeed < slowestSpeed) slowestSpeed = unitSpeed;
          }
          
          for (var u in cluster) {
            u.groupSpeed = slowestSpeed;
          }
        }
      }
    }

    final grid = SpatialGrid(state.mapSize, cellSize: 4);
    
    for (var entity in state.entities) {
      grid.insert(entity);
    }

    for (var ei in state.entities) {
      if (ei.type != EntityType.unit) continue;
      
      final neighbors = grid.getNearby(ei, 0.7);
      for (var ej in neighbors) {
        double dx = ei.col - ej.col;
        double dy = ei.row - ej.row;
        
        double dist2 = dx*dx + dy*dy;
        double radiusSum = 0.6; 
        
        if (dist2 < radiusSum * radiusSum && dist2 > 0.0001) {
          double dist = sqrt(dist2);
          bool isAllied = ei.playerIndex == ej.playerIndex;
          bool isFighting = ei.state == EntityState.attacking || ej.state == EntityState.attacking;
          double pushFactor = isAllied ? 0.4 : (isFighting ? 0.3 : 0.8); 
          
          double pushX = (dx / dist) * pushFactor * physicsDt;
          double pushY = (dy / dist) * pushFactor * physicsDt;
          
          double newCol = ei.col + pushX;
          double newRow = ei.row + pushY;
          
          int gridCol = newCol.round().clamp(0, state.mapSize - 1);
          int gridRow = newRow.round().clamp(0, state.mapSize - 1);
          
          final targetTile = state.tiles[gridRow][gridCol];
          if (targetTile.isWalkable && !targetTile.isWater) {
            ei.col = newCol;
            ei.row = newRow;
          } else {
            // Intentar deslizamiento horizontal únicamente
            int gridColOnly = (ei.col + pushX).round().clamp(0, state.mapSize - 1);
            if (state.tiles[ei.row.round().clamp(0, state.mapSize - 1)][gridColOnly].isWalkable) {
              ei.col += pushX;
            }
            // Intentar deslizamiento vertical únicamente
            int gridRowOnly = (ei.row + pushY).round().clamp(0, state.mapSize - 1);
            if (state.tiles[gridRowOnly][ei.col.round().clamp(0, state.mapSize - 1)].isWalkable) {
              ei.row += pushY;
            }
          }
        }
      }
    }

    for (var entity in List<GameEntity>.from(state.entities)) {
      if (entity.pathTimer > 0) entity.pathTimer -= dt;
      if (entity.type != EntityType.unit) continue;

      if (entity.state == EntityState.idle) {
        entity.groupSpeed = null;
        entity.stuckTimer = 0; 
      } else if (entity.state == EntityState.moving || 
                 entity.state == EntityState.movingToResource || 
                 entity.state == EntityState.returningToTC ||
                 entity.state == EntityState.attacking) {
        
        double distMoved = sqrt(pow(entity.col - entity.lastCol, 2) + pow(entity.row - entity.lastRow, 2));
        if (distMoved < 0.005) {
          entity.stuckTimer += dt;
        } else {
          entity.stuckTimer = 0;
        }
        
        if (entity.stuckTimer > 1.5) {
          entity.stuckTimer = 0;
          entity.currentPath.clear();
          entity.pathTimer = 0.5;
          
          double rx = (rand.nextDouble() - 0.5) * 0.8;
          double ry = (rand.nextDouble() - 0.5) * 0.8;
          double newCol = entity.col + rx;
          double newRow = entity.row + ry;
          int gridCol = newCol.round().clamp(0, state.mapSize - 1);
          int gridRow = newRow.round().clamp(0, state.mapSize - 1);
          
          if (state.tiles[gridRow][gridCol].isWalkable && !state.tiles[gridRow][gridCol].isWater) {
            entity.col = newCol;
            entity.row = newRow;
          }
          
          if (entity.state != EntityState.attacking) {
            entity.state = EntityState.idle;
          }
        }
      }
      
      entity.lastCol = entity.col;
      entity.lastRow = entity.row;

      double baseSpd = (GameDataService().getUnitByName(entity.name)?.movementSpeed ?? 0.57) * 3.5;
      double unitBaseSpeed = state.techManager.getUnitStat(entity, 'movement_speed', baseSpd);

      if (_isMilitaryUnit(entity.name) && entity.state != EntityState.attacking && entity.pathTimer <= 0) {
          GameEntity? targetEnemy;
          double minD2 = 64.0; 
          for (var e in state.entities) {
            if (e.playerIndex != entity.playerIndex) {
               double dx = e.col - entity.col;
               if (dx.abs() > 8.0) continue;
               double dy = e.row - entity.row;
               if (dy.abs() > 8.0) continue;

               double d2 = dx*dx + dy*dy;
               if (e.type == EntityType.unit) d2 *= 0.5; 
               
               if (d2 <= minD2) { minD2 = d2; targetEnemy = e; }
            }
          }
          if (targetEnemy != null) {
            entity.pathTimer = 1.0; 
            entity.currentPath = PathfindingManager.findPath(state.tiles, entity.col.round(), entity.row.round(), targetEnemy.col.round(), targetEnemy.row.round());
            entity.state = EntityState.attacking;
            entity.assignedResourceTile = null;
            entity.actionTimer = 0.0;
            continue; 
          }
      }

      switch (entity.state) {
        case EntityState.idle:
          if (_isMilitaryUnit(entity.name)) {
             if (state.players[entity.playerIndex].type == PlayerType.human) {
                break; // Soldados humanos se quedan parados custodiando, no atacan globalmente solos
             }
             var mySoldiers = state.entities.where((e) => e.playerIndex == entity.playerIndex && _isMilitaryUnit(e.name)).toList();
             int requiredArmySize = 3 + (state.gameTick ~/ 100).clamp(0, 30).toInt();
             
             if (mySoldiers.length >= requiredArmySize && entity.pathTimer <= 0) { 
                GameEntity? targetEnemy;
                double minD2 = double.maxFinite;
                for (var e in state.entities) {
                  if (e.playerIndex != entity.playerIndex) {
                    double dx = e.col - entity.col;
                    double dy = e.row - entity.row;
                    double d2 = dx*dx + dy*dy;
                    if (d2 < minD2) { minD2 = d2; targetEnemy = e; }
                  }
                }
                if (targetEnemy != null) {
                  entity.pathTimer = 1.0; 
                  entity.currentPath = PathfindingManager.findPath(state.tiles, entity.col.round(), entity.row.round(), targetEnemy.col.round(), targetEnemy.row.round());
                  entity.state = EntityState.attacking;
                  entity.actionTimer = 0.0;
                }
             }
             break; 
          }

          if (entity.pathTimer > 0) break;

          if (entity.carriedResource > 0) {
            sendToClosestDropoff(entity);
            if (entity.state == EntityState.returningToTC) break;
          }

          var currentTile = state.tiles[entity.row.round().clamp(0, state.mapSize-1)][entity.col.round().clamp(0, state.mapSize-1)];
          if (!currentTile.isWalkable || currentTile.isWater) {
             final dirs = [[0,-1],[0,1],[-1,0],[1,0],[-1,-1],[1,-1],[-1,1],[1,1]];
             for (var d in dirs) {
                int nr = entity.row.round() + d[1];
                int nc = entity.col.round() + d[0];
                if (nr >= 0 && nr < state.mapSize && nc >= 0 && nc < state.mapSize) {
                   if (state.tiles[nr][nc].isWalkable && !state.tiles[nr][nc].hasResource && !state.tiles[nr][nc].isWater) {
                      entity.col = nc.toDouble();
                      entity.row = nr.toDouble();
                      break;
                   }
                }
             }
          }

          MapTile? closestResource;
          if (entity.assignedResourceTile != null && entity.assignedResourceTile!.hasResource) {
             closestResource = entity.assignedResourceTile;
          } else {
             // Si el jugador es humano y no tiene un recurso asignado (o el que tenía se agotó),
             // NO debe buscar automáticamente otro recurso de forma proactiva.
             if (state.players[entity.playerIndex].type == PlayerType.human) {
                entity.assignedResourceTile = null;
                entity.targetResourceTile = null;
                break; // Se queda parado inactivo
             }

            if (entity.workerRole == 'food') {
              // 1. Buscar una granja aliada terminada que no esté ocupada por otro aldeano
              GameEntity? freeFarm;
              for (var b in state.entities) {
                if (b.playerIndex == entity.playerIndex && 
                    b.type == EntityType.building && 
                    (b.name.contains('Granja') || GameDataService().getBuildingByName(b.name)?.category == 'farm') && 
                    b.hp == b.maxHp) {
                  
                  // Verificar si ya hay otro aldeano asignado a esta granja
                  bool isOccupied = state.entities.any((other) => 
                    other.playerIndex == entity.playerIndex && 
                    other.type == EntityType.unit && 
                    other != entity && 
                    other.assignedResourceTile?.col == b.col.round() && 
                    other.assignedResourceTile?.row == b.row.round()
                  );
                  if (!isOccupied) {
                    freeFarm = b;
                    break;
                  }
                }
              }
              
              if (freeFarm != null) {
                closestResource = state.tiles[freeFarm.row.round().clamp(0, state.mapSize-1)][freeFarm.col.round().clamp(0, state.mapSize-1)];
                entity.assignedResourceTile = closestResource;
              } else {
                // Fallback a arbustos de bayas en la cache
                double minD = double.maxFinite;
                for (var tile in state.resourceCache) {
                  if (tile.resource != null && tile.resource!.type == ResourceType.food && tile.type == TileType.berryBush) {
                    double dx = tile.col - entity.col;
                    double dy = tile.row - entity.row;
                    double d2 = dx*dx + dy*dy;
                    if (d2 < minD) { minD = d2; closestResource = tile; }
                  }
                }
              }
            } else {
              double minD = double.maxFinite;
              for (var tile in state.resourceCache) {
                  if (tile.resource == null) continue;
                  bool matchesRole = false;
                  if (entity.workerRole == 'wood' && tile.resource!.type == ResourceType.wood) matchesRole = true;
                  if (entity.workerRole == 'gold' && tile.resource!.type == ResourceType.gold) matchesRole = true;
                  if (entity.workerRole == 'stone' && tile.resource!.type == ResourceType.stone) matchesRole = true;
                  
                  if (matchesRole) {
                    double dx = tile.col - entity.col;
                    double dy = tile.row - entity.row;
                    double d2 = dx*dx + dy*dy; 
                    if (d2 < minD) { minD = d2; closestResource = tile; }
                  }
              }
            }
          }

          if (closestResource != null) {
            final path = PathfindingManager.findPath(state.tiles, entity.col.round(), entity.row.round(), closestResource.col, closestResource.row);
            if (path.isNotEmpty) {
              entity.assignedResourceTile = closestResource;
              entity.targetResourceTile = closestResource;
              entity.currentPath = path;
              entity.state = EntityState.movingToResource;
            } else {
              entity.assignedResourceTile = null;
              entity.pathTimer = 1.5; 
              
              double rx = (rand.nextDouble() - 0.5) * 2;
              double ry = (rand.nextDouble() - 0.5) * 2;
              int targetCol = (entity.col + rx).round().clamp(0, state.mapSize - 1);
              int targetRow = (entity.row + ry).round().clamp(0, state.mapSize - 1);
              if (state.tiles[targetRow][targetCol].isWalkable) {
                entity.currentPath = [Offset(targetCol.toDouble(), targetRow.toDouble())];
                entity.state = EntityState.moving;
              }
            }
          } else {
            entity.assignedResourceTile = null;
            entity.pathTimer = 2.0; 
            
            double rx = (rand.nextDouble() - 0.5) * 4;
            double ry = (rand.nextDouble() - 0.5) * 4;
            int targetCol = (entity.col + rx).round().clamp(0, state.mapSize - 1);
            int targetRow = (entity.row + ry).round().clamp(0, state.mapSize - 1);
            if (state.tiles[targetRow][targetCol].isWalkable) {
              entity.currentPath = PathfindingManager.findPath(state.tiles, entity.col.round(), entity.row.round(), targetCol, targetRow);
              if (entity.currentPath.isNotEmpty) entity.state = EntityState.moving;
            }
          }
          break;

        case EntityState.moving:
          if (entity.currentPath.isNotEmpty) {
            moveAlongPath(entity, unitBaseSpeed, physicsDt);
          } else {
            entity.state = EntityState.idle;
          }
          break;

        case EntityState.movingToResource:
          if (entity.targetResourceTile != null) {
            if (!entity.targetResourceTile!.hasResource) {
              entity.targetResourceTile = null;
              entity.assignedResourceTile = null;
              entity.currentPath.clear();
              entity.state = EntityState.idle;
              break;
            }

            double dx = entity.targetResourceTile!.col - entity.col;
            double dy = entity.targetResourceTile!.row - entity.row;
            double distToResource = sqrt(dx*dx + dy*dy);

            double gatheringDist = (entity.workerRole == 'food') ? 0.2 : 1.5;

            if (distToResource <= gatheringDist) { 
              entity.currentPath.clear();
              entity.state = EntityState.gathering;
              entity.actionTimer = 0.0;
            } else if (entity.currentPath.isNotEmpty) {
              moveAlongPath(entity, unitBaseSpeed, physicsDt);
            } else {
              entity.targetResourceTile = null;
              entity.state = EntityState.idle;
              entity.pathTimer = 0.5;
            }
          }
          break;

         case EntityState.gathering:
          entity.actionTimer += dt;
          if (entity.actionTimer >= 0.5) { 
            entity.actionTimer = 0.0;
            
            if (entity.targetResourceTile?.hasResource == true) {
              int amountToTake = 2;
              if (entity.targetResourceTile!.resource!.amount < amountToTake) {
                amountToTake = entity.targetResourceTile!.resource!.amount;
              }
              
              entity.targetResourceTile!.resource!.amount -= amountToTake;
              entity.carriedResource += amountToTake;

              if (entity.targetResourceTile!.resource!.amount <= 0) {
                entity.targetResourceTile!.resource = null;
                entity.targetResourceTile!.type = TileType.grass;
                entity.targetResourceTile!.isWalkable = true;
                state.resourceCache.remove(entity.targetResourceTile);
                
                sendToClosestDropoff(entity);
                break;
              }
            } else {
              entity.targetResourceTile = null;
              entity.assignedResourceTile = null;
              if (entity.carriedResource > 0) {
                sendToClosestDropoff(entity);
              } else {
                entity.state = EntityState.idle;
              }
              break;
            }

            if (entity.carriedResource >= entity.maxCarryCapacity) {
               sendToClosestDropoff(entity);
            }
          }
          break;

        case EntityState.returningToTC:
          if (entity.targetResourceTile != null) {
            double dx = entity.targetResourceTile!.col - entity.col;
            double dy = entity.targetResourceTile!.row - entity.row;
            double distToDropoff = sqrt(dx * dx + dy * dy);

            if (distToDropoff <= 1.8) { 
              entity.currentPath.clear();
               int pIdx = entity.playerIndex;
               bool hasStats = pIdx >= 0 && pIdx < state.playerStats.length;
               if (entity.workerRole == 'wood') {
                 state.playerResources[entity.playerIndex].wood += entity.carriedResource;
                 if (hasStats) state.playerStats[pIdx].woodGathered += entity.carriedResource;
               } else if (entity.workerRole == 'food') {
                 state.playerResources[entity.playerIndex].food += entity.carriedResource;
                 if (hasStats) state.playerStats[pIdx].foodGathered += entity.carriedResource;
               } else if (entity.workerRole == 'stone') {
                 state.playerResources[entity.playerIndex].stone += entity.carriedResource;
                 if (hasStats) state.playerStats[pIdx].stoneGathered += entity.carriedResource;
               } else {
                 state.playerResources[entity.playerIndex].gold += entity.carriedResource;
                 if (hasStats) state.playerStats[pIdx].goldGathered += entity.carriedResource;
               }
               entity.carriedResource = 0;
               entity.targetResourceTile = null;
               entity.state = EntityState.idle; 
            } else if (entity.currentPath.isNotEmpty) {
              moveAlongPath(entity, unitBaseSpeed, physicsDt);
            } else {
              entity.targetResourceTile = null;
              entity.state = EntityState.idle;
              entity.pathTimer = 0.5;
            }
          } else {
            entity.state = EntityState.idle;
          }
          break;

        case EntityState.attacking:
          if (entity.currentPath.isNotEmpty) {
             moveAlongPath(entity, unitBaseSpeed, physicsDt);
          } else {
             entity.actionTimer += dt;
             double baseAtkSpd = 1.0;
             double atkSpd = state.techManager.getUnitStat(entity, 'attack_speed', baseAtkSpd);
             if (entity.actionTimer >= atkSpd) {
                entity.actionTimer = 0.0;
                GameEntity? targetEnemy;
                double minD2 = double.maxFinite;
                for (var e in state.entities) {
                  if (e.playerIndex != entity.playerIndex) {
                     double dx = e.col - entity.col;
                     double dy = e.row - entity.row;
                     double d2 = dx*dx + dy*dy;
                     if (d2 < minD2) { minD2 = d2; targetEnemy = e; }
                  }
                }

                if (targetEnemy != null) {
                   double baseRange = GameDataService().getUnitByName(entity.name)?.attackRange ?? 1.5;
                   double range = state.techManager.getUnitStat(entity, 'attack_range', baseRange);
                   if (minD2 <= range * range) {
                      var uConfig = GameDataService().getUnitByName(entity.name);
                      int baseDamage = 5;
                      if (uConfig != null) {
                        int melee = uConfig.meleeAttack.toInt();
                        int ranged = uConfig.rangedAttack.toInt();
                        if (melee > 0) {
                          baseDamage = melee;
                        } else if (ranged > 0) {
                          baseDamage = ranged;
                        }
                      }
                      int damage = state.techManager.getUnitStat(entity, 'melee_attack', baseDamage.toDouble()).toInt();
                      
                      state.notifyCombatStarted(entity.playerIndex, targetEnemy.playerIndex);
                      if (range > 2.0) {
                        state.combatManager.spawnProjectile(entity, targetEnemy, damage);
                      } else {
                        targetEnemy.hp -= damage;
                        state.callForHelp(targetEnemy, entity);
                      }
                      if (targetEnemy.hp <= 0) {
                        toRemove.add(targetEnemy);
                        int killerIdx = entity.playerIndex;
                        if (killerIdx >= 0 && killerIdx < state.playerStats.length) {
                          if (targetEnemy.type == EntityType.unit) {
                            state.playerStats[killerIdx].unitsKilled++;
                          } else if (targetEnemy.type == EntityType.building) {
                            state.playerStats[killerIdx].buildingsDestroyed++;
                          }
                        }
                      }
                   } else {
                      if (entity.pathTimer <= 0) {
                        entity.currentPath = PathfindingManager.findPath(state.tiles, entity.col.round(), entity.row.round(), targetEnemy.col.round(), targetEnemy.row.round());
                        entity.pathTimer = 1.0;
                      }
                   }
                } else {
                   entity.state = EntityState.idle;
                }
             }
          }
          break;
        case EntityState.fleeing:
          break;
      }
    }

    if (toRemove.isNotEmpty) {
      state.entities.removeWhere(toRemove.contains);
    }
  }

  void moveAlongPath(GameEntity entity, double speed, double dt) {
    if (entity.currentPath.isEmpty) return;
    final target = entity.currentPath.first;
    double dx = target.dx - entity.col;
    double dy = target.dy - entity.row;
    double dist = sqrt(dx * dx + dy * dy);

    double actualSpeed = entity.groupSpeed ?? speed;

    if (dist < 0.1) {
      entity.col = target.dx;
      entity.row = target.dy;
      entity.currentPath.removeAt(0);
    } else {
      entity.col += (dx / dist) * actualSpeed * dt;
      entity.row += (dy / dist) * actualSpeed * dt;
    }
  }

  void sendToClosestDropoff(GameEntity entity) {
    String civId = state.players[entity.playerIndex].civId;
    String dropoffCategory = 'town_center';
    if (entity.workerRole == 'wood') dropoffCategory = 'resource_wood';
    else if (entity.workerRole == 'gold' || entity.workerRole == 'stone') dropoffCategory = 'resource_gold_stone';

    String tcName = GameDataService().getBuildingsForCiv(civId).where((b) => b.category == 'town_center').firstOrNull?.name ?? 'Centro Urbano';
    String? dropoffName = GameDataService().getBuildingsForCiv(civId).where((b) => b.category == dropoffCategory).firstOrNull?.name;
    
    if (dropoffName == null) {
      if (dropoffCategory == 'resource_wood') dropoffName = 'Campamento Maderero';
      else if (dropoffCategory == 'resource_gold_stone') dropoffName = 'Mina';
      else dropoffName = tcName;
    }

    GameEntity? closestDropoff;
    double minD = double.maxFinite;

    for (var b in state.entities) {
      if (b.playerIndex == entity.playerIndex && (b.name == dropoffName || b.name == tcName)) {
        double dx = b.col - entity.col;
        double dy = b.row - entity.row;
        double d2 = dx*dx + dy*dy;
        if (d2 < minD) { minD = d2; closestDropoff = b; }
      }
    }

    if (closestDropoff != null) {
      entity.targetResourceTile = state.tiles[closestDropoff.row.round().clamp(0, state.mapSize-1)][closestDropoff.col.round().clamp(0, state.mapSize-1)];
      entity.currentPath = PathfindingManager.findPath(
        state.tiles, entity.col.round(), entity.row.round(),
        closestDropoff.col.round(), closestDropoff.row.round()
      );
      if (entity.currentPath.isNotEmpty) {
        entity.state = EntityState.returningToTC;
      } else {
        debugPrint('WORKER STUCK: Dropoff is unreachable. Clearing carried resource.');
        entity.carriedResource = 0;
        entity.targetResourceTile = null;
        entity.state = EntityState.idle;
        entity.pathTimer = 1.0;
      }
    } else {
      debugPrint('WORKER STUCK: No dropoff found. Clearing carried resource.');
      entity.carriedResource = 0;
      entity.targetResourceTile = null;
      entity.state = EntityState.idle;
      entity.pathTimer = 1.0;
    }
  }
}
