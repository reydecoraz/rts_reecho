# Graph Report - .  (2026-05-21)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 976 nodes · 1027 edges · 113 communities (81 shown, 32 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 26 edges (avg confidence: 0.81)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 49|Community 49]]
- [[_COMMUNITY_Community 50|Community 50]]
- [[_COMMUNITY_Community 51|Community 51]]
- [[_COMMUNITY_Community 52|Community 52]]
- [[_COMMUNITY_Community 53|Community 53]]
- [[_COMMUNITY_Community 54|Community 54]]
- [[_COMMUNITY_Community 55|Community 55]]
- [[_COMMUNITY_Community 56|Community 56]]
- [[_COMMUNITY_Community 57|Community 57]]
- [[_COMMUNITY_Community 58|Community 58]]
- [[_COMMUNITY_Community 59|Community 59]]
- [[_COMMUNITY_Community 60|Community 60]]
- [[_COMMUNITY_Community 61|Community 61]]
- [[_COMMUNITY_Community 62|Community 62]]
- [[_COMMUNITY_Community 63|Community 63]]
- [[_COMMUNITY_Community 64|Community 64]]
- [[_COMMUNITY_Community 65|Community 65]]
- [[_COMMUNITY_Community 66|Community 66]]
- [[_COMMUNITY_Community 67|Community 67]]
- [[_COMMUNITY_Community 68|Community 68]]
- [[_COMMUNITY_Community 69|Community 69]]
- [[_COMMUNITY_Community 70|Community 70]]
- [[_COMMUNITY_Community 71|Community 71]]
- [[_COMMUNITY_Community 72|Community 72]]
- [[_COMMUNITY_Community 73|Community 73]]
- [[_COMMUNITY_Community 74|Community 74]]
- [[_COMMUNITY_Community 75|Community 75]]
- [[_COMMUNITY_Community 76|Community 76]]
- [[_COMMUNITY_Community 78|Community 78]]
- [[_COMMUNITY_Community 79|Community 79]]
- [[_COMMUNITY_Community 80|Community 80]]
- [[_COMMUNITY_Community 81|Community 81]]
- [[_COMMUNITY_Community 82|Community 82]]
- [[_COMMUNITY_Community 83|Community 83]]
- [[_COMMUNITY_Community 93|Community 93]]
- [[_COMMUNITY_Community 108|Community 108]]
- [[_COMMUNITY_Community 109|Community 109]]
- [[_COMMUNITY_Community 110|Community 110]]
- [[_COMMUNITY_Community 111|Community 111]]
- [[_COMMUNITY_Community 112|Community 112]]

## God Nodes (most connected - your core abstractions)
1. `compilerOptions` - 22 edges
2. `compilerOptions` - 16 edges
3. `FlutterEngine()` - 14 edges
4. `scripts` - 13 edges
5. `_MyApplication` - 13 edges
6. `PluginRegistrar()` - 12 edges
7. `jest` - 9 edges
8. `package:flutter/material.dart` - 9 edges
9. `BinaryMessengerImpl()` - 9 edges
10. `../models/game_models.dart` - 8 edges

## Surprising Connections (you probably didn't know these)
- `Web-Mobile Synchronization Integrated` --references--> `GameSnapshotController`  [INFERRED]
  .planning/STATE.md → back/src/game-snapshot/game-snapshot.controller.ts
- `GameDataService (Flutter)` --calls--> `GameSnapshotController`  [INFERRED]
  movil/lib/services/game_data_service.dart → back/src/game-snapshot/game-snapshot.controller.ts
- `main()` --calls--> `removeBackground()`  [EXTRACTED]
  scratch/process_assets.py → front/src/lib/backgroundRemover.ts
- `main()` --calls--> `_MyApplication`  [INFERRED]
  movil/linux/runner/main.cc → movil/linux/runner/my_application.cc
- `flutter()` --calls--> `DecodeMessageInternal()`  [INFERRED]
  movil/windows/flutter/ephemeral/cpp_client_wrapper/include/flutter/message_codec.h → movil/windows/flutter/ephemeral/cpp_client_wrapper/standard_codec.cc

## Communities (113 total, 32 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.05
Nodes (43): AIDirector, _evaluateMilitary, _evaluatePopulation, _executeAttackRun, _think, update, CityPlanner, _doesBuildingBlockCrucialPaths (+35 more)

### Community 1 - "Community 1"
Cohesion: 0.05
Nodes (41): ai/city_planner.dart, ai/pathfinding_manager.dart, DefaultFirebaseOptions, UnsupportedError, adjustZoom, _autoAssignIdleWorkers, _callForHelp, _centerCameraOnTile (+33 more)

### Community 2 - "Community 2"
Cohesion: 0.05
Nodes (40): _actionBtn, build, _buildBottomBar, _buildGame, _buildLoading, _buildMapViewport, _buildMinimap, _buildPauseOverlay (+32 more)

### Community 3 - "Community 3"
Cohesion: 0.05
Nodes (39): build, _buildActionButtons, _buildAICountSelector, _buildAISlot, _buildCivDropdown, _buildConfigPanel, _buildDifficultyDropdown, _buildHeader (+31 more)

### Community 4 - "Community 4"
Cohesion: 0.05
Nodes (33): _getTileColors, IsometricRenderer, paint, _paintArchery, _paintBarracks, _paintBerryBush, _paintEntities, _paintFarm (+25 more)

### Community 5 - "Community 5"
Cohesion: 0.11
Nodes (20): FlutterWindow(), OnCreate(), Create(), Destroy(), EnableFullDpiSupportIfAvailable(), GetClientArea(), GetThisFromHandle(), GetWindowClass() (+12 more)

### Community 6 - "Community 6"
Cohesion: 0.06
Nodes (27): registerPlugins, _PluginRegistrant, register, main, main, dart:io, package:app_links_linux/app_links_linux.dart, package:app_links_web/app_links_web.dart (+19 more)

### Community 7 - "Community 7"
Cohesion: 0.07
Nodes (26): dependencies, axios, clsx, lucide-react, next, react, react-dom, react-hot-toast (+18 more)

### Community 8 - "Community 8"
Cohesion: 0.07
Nodes (12): fl_register_plugins(), RegisterGeneratedPlugins(), FlutterAppDelegate, FlutterImplicitEngineDelegate, NSWindow, AppDelegate, -registerWithRegistry, main() (+4 more)

### Community 9 - "Community 9"
Cohesion: 0.09
Nodes (22): assets, ar, cc, ld, windows, c_compiler, link_mode_preference, target_architecture (+14 more)

### Community 10 - "Community 10"
Cohesion: 0.09
Nodes (23): devDependencies, eslint, eslint-config-prettier, @eslint/eslintrc, @eslint/js, eslint-plugin-prettier, globals, @nestjs/cli (+15 more)

### Community 11 - "Community 11"
Cohesion: 0.09
Nodes (22): compilerOptions, allowSyntheticDefaultImports, baseUrl, declaration, emitDecoratorMetadata, esModuleInterop, experimentalDecorators, forceConsistentCasingInFileNames (+14 more)

### Community 13 - "Community 13"
Cohesion: 0.10
Nodes (20): target_ndk_api, assets, ar, cc, ld, android, c_compiler, link_mode_preference (+12 more)

### Community 14 - "Community 14"
Cohesion: 0.10
Nodes (19): compilerOptions, allowJs, esModuleInterop, incremental, isolatedModules, jsx, lib, module (+11 more)

### Community 15 - "Community 15"
Cohesion: 0.15
Nodes (9): AdvancedEffectSection(), AdvancedProductionSection(), ComplexRelationSection(), ProductionBonusSection(), CivWizardModalProps, TAB_ICONS, TABLES, OverrideModalProps (+1 more)

### Community 16 - "Community 16"
Cohesion: 0.11
Nodes (8): BuildingConfig, BuildingProduction, CivilizationConfig, CivOverride, GameDataService, GameSnapshot, TechConfig, UnitConfig

### Community 17 - "Community 17"
Cohesion: 0.12
Nodes (16): addBonus, CivBaseStats, EntityBaseStats, GameEntity, GameMatch, getBonusValue, getMultiplier, MapTile (+8 more)

### Community 18 - "Community 18"
Cohesion: 0.26
Nodes (15): DecodeMessageInternal(), DecodeMethodCallInternal(), EncodedTypeForValue(), EncodeErrorEnvelopeInternal(), EncodeMethodCallInternal(), EncodeSuccessEnvelopeInternal(), ReadSize(), ReadValue() (+7 more)

### Community 20 - "Community 20"
Cohesion: 0.15
Nodes (13): scripts, build, format, lint, start, start:debug, start:dev, start:prod (+5 more)

### Community 21 - "Community 21"
Cohesion: 0.17
Nodes (4): ResizeChannel(), SetChannelWarnsOnOverflow(), Resize(), SetWarnsOnOverflow()

### Community 22 - "Community 22"
Cohesion: 0.18
Nodes (8): ACTIONS, CONSTRUCTION_STAGES, DAMAGE_STAGES, DIRECTIONS, TabId, supabase, uploadBlob(), uploadSprite()

### Community 23 - "Community 23"
Cohesion: 0.17
Nodes (11): build, CircularProgressIndicator, Container, MainMenuScreen, Positioned, Scaffold, SizedBox, game_config_screen.dart (+3 more)

### Community 24 - "Community 24"
Cohesion: 0.29
Nodes (9): GeneratorState, SpriteGeneratorProps, generateSprite(), generateWithOpenAI(), generateWithStability(), getProviderName(), isSpriteGeneratorConfigured(), SpriteGenerationOptions (+1 more)

### Community 25 - "Community 25"
Cohesion: 0.18
Nodes (10): enter, execute, exit, update, WorkerGatheringState, WorkerIdleState, WorkerMovingToResourceState, WorkerReturningState (+2 more)

### Community 26 - "Community 26"
Cohesion: 0.18
Nodes (10): build, main, MaterialApp, RTSGame, firebase_options.dart, package:flutter/services.dart, package:google_fonts/google_fonts.dart, screens/main_menu.dart (+2 more)

### Community 27 - "Community 27"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 28 - "Community 28"
Cohesion: 0.18
Nodes (10): content, dashboardPath, detailViewLines, fs, importsLines, lines, listViewLines, modalsLines (+2 more)

### Community 29 - "Community 29"
Cohesion: 0.20
Nodes (9): assets, config, build_asset_types, linking_enabled, out_dir_shared, out_file, package_name, package_root (+1 more)

### Community 30 - "Community 30"
Cohesion: 0.22
Nodes (4): TextureRegistrarImpl(), GetInstance(), OnRegistrarDestroyed(), PluginRegistrar()

### Community 34 - "Community 34"
Cohesion: 0.22
Nodes (9): jest, collectCoverageFrom, coverageDirectory, moduleFileExtensions, rootDir, testEnvironment, testRegex, transform (+1 more)

### Community 35 - "Community 35"
Cohesion: 0.25
Nodes (8): dependencies, @nestjs/common, @nestjs/config, @nestjs/core, @nestjs/platform-express, reflect-metadata, rxjs, @supabase/supabase-js

### Community 37 - "Community 37"
Cohesion: 0.25
Nodes (7): configVersion, flutterRoot, flutterVersion, generator, generatorVersion, packages, pubCache

### Community 38 - "Community 38"
Cohesion: 0.25
Nodes (7): changeState, enter, execute, exit, UnitFSM, UnitState, update

### Community 39 - "Community 39"
Cohesion: 0.25
Nodes (4): flask, pillow, rembg, rembg_service/requirements.txt

### Community 40 - "Community 40"
Cohesion: 0.29
Nodes (6): client, configuration_version, project_info, project_id, project_number, storage_bucket

### Community 41 - "Community 41"
Cohesion: 0.29
Nodes (6): author, description, license, name, private, version

### Community 43 - "Community 43"
Cohesion: 0.43
Nodes (5): isRembgAvailable(), removeBackground(), removeBackgroundFromFile(), main(), upload_to_supabase()

### Community 44 - "Community 44"
Cohesion: 0.43
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 46 - "Community 46"
Cohesion: 0.29
Nodes (6): moduleFileExtensions, rootDir, testEnvironment, testRegex, transform, ^.+\\.(t|j)s$

### Community 47 - "Community 47"
Cohesion: 0.40
Nodes (4): images, info, author, version

### Community 48 - "Community 48"
Cohesion: 0.33
Nodes (5): build_end, build_start, code_assets, data_assets, dependencies

### Community 49 - "Community 49"
Cohesion: 0.33
Nodes (5): collection, compilerOptions, deleteOutDir, $schema, sourceRoot

### Community 51 - "Community 51"
Cohesion: 0.33
Nodes (5): build_end, build_start, code_assets, data_assets, dependencies

### Community 52 - "Community 52"
Cohesion: 0.33
Nodes (5): build_end, build_start, code_assets, data_assets, dependencies

### Community 53 - "Community 53"
Cohesion: 0.33
Nodes (5): build_end, build_start, code_assets, data_assets, dependencies

### Community 54 - "Community 54"
Cohesion: 0.33
Nodes (3): GameSnapshotController, GameDataService (Flutter), Web-Mobile Synchronization Integrated

### Community 55 - "Community 55"
Cohesion: 0.33
Nodes (3): RTS Sprite Tool — Local background removal service using rembg. Runs on port 505, Process multiple images at once. Send as multipart form with fields image_0, ima, remove_bg_batch()

### Community 56 - "Community 56"
Cohesion: 0.40
Nodes (4): images, info, author, version

### Community 57 - "Community 57"
Cohesion: 0.40
Nodes (5): Flutter Dependencies, NestJS 11, Supabase (PostgreSQL), Next.js 16 + TailwindCSS, RTS Web Admin Vision

### Community 59 - "Community 59"
Cohesion: 0.50
Nodes (3): assets_for_linking, status, timestamp

### Community 60 - "Community 60"
Cohesion: 0.50
Nodes (3): assets_for_linking, status, timestamp

### Community 61 - "Community 61"
Cohesion: 0.50
Nodes (3): assets_for_linking, status, timestamp

### Community 63 - "Community 63"
Cohesion: 0.50
Nodes (4): Centro Urbano Building, Cuartel Building, Establo Building, Caballero Unit

### Community 65 - "Community 65"
Cohesion: 0.50
Nodes (3): configVersion, packages, roots

## Knowledge Gaps
- **562 isolated node(s):** `fs`, `path`, `dashboardPath`, `content`, `lines` (+557 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **32 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 4` to `Community 0`, `Community 1`, `Community 2`, `Community 3`, `Community 23`, `Community 26`?**
  _High betweenness centrality (0.036) - this node is a cross-community bridge._
- **Why does `package:supabase_flutter/supabase_flutter.dart` connect `Community 1` to `Community 16`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **Why does `../models/game_models.dart` connect `Community 0` to `Community 1`, `Community 4`, `Community 25`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._
- **What connects `fs`, `path`, `dashboardPath` to the rest of the system?**
  _565 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.04609929078014184 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.045454545454545456 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.04878048780487805 - nodes in this community are weakly interconnected._