# RTS_1 — STATE.md (Estado activo del proyecto)

Ultima actualizacion: 2026-05-10

## Estado Global
SINCRONIZACIÓN WEB→MÓVIL INTEGRADA

## Decisiones Tomadas
- Imagenes se suben a Supabase Storage (bucket: game-sprites, publico)
- Flujo de sprites: Opcion A integrado en web
- selectedCivId se inicializa con el primer civ de la DB
- Limpieza de fondo: rembg local (Python) corriendo en puerto 5050
- Todo local, solo Supabase como storage remoto
- AI Sprite generation: Stability AI (free tier) o OpenAI DALL-E
- NanoBanana era un scam, fue reemplazado por providers reales
- Toast notifications con react-hot-toast
- **NUEVO**: Civilization enum reemplazado por civId string en Flutter
- **NUEVO**: GameDataService singleton carga todo el snapshot de Supabase
- **NUEVO**: NestJS sirve GET /api/game-snapshot con cache de 5 min
- **NUEVO**: Cache se invalida automáticamente en cada mutación del admin

## Servicios Activos
- Frontend Next.js: http://localhost:3000
- Backend NestJS: http://localhost:3002
- Rembg Service: http://localhost:5050

## Setup de AI (pendiente API key)
1. Ir a https://platform.stability.ai/account/keys
2. Crear cuenta gratuita (25 credits/mes)
3. Agregar a front/.env.local:
   NEXT_PUBLIC_STABILITY_API_KEY=sk-tu_key_aqui

## Progreso por Fase

| Fase | Nombre | Estado |
|------|--------|--------|
| 1 | Fixes Criticos | ✅ COMPLETADA |
| 2 | Refactoring Dashboard | ✅ COMPLETADA |
| 3 | Supabase Storage | ✅ COMPLETADA |
| 4 | Sprite Generator (rembg + Stability AI) | ✅ COMPLETADA |
| 5 | Polish y UX (toasts) | ✅ COMPLETADA |
| 6 | Game Snapshot API (NestJS) | ✅ COMPLETADA |
| 7 | Flutter: Civs Dinámicas + Sync Completa | ✅ COMPLETADA |
| 8 | Flutter: Overrides por Civilización | ✅ COMPLETADA |
| 9 | Web Admin: Wizard "Crear Civilización" | ✅ COMPLETADA |

## Archivos Creados / Modificados

### Nuevos (Sprint Anterior)
- front/src/lib/supabaseStorage.ts - cliente Supabase Storage
- front/src/lib/spriteAI.ts - cliente Stability AI / OpenAI
- front/src/lib/backgroundRemover.ts - cliente rembg local
- front/src/components/SpriteGenerator.tsx - componente AI generation
- front/.env.local - variables de entorno frontend
- tools/rembg_service/server.py - servicio Python para rembg
- tools/rembg_service/requirements.txt - deps Python
- .planning/PROJECT.md, ROADMAP.md, STATE.md - GSD docs

### Nuevos (Sprint Sincronización)
- back/src/game-snapshot/game-snapshot.service.ts - snapshot completo con cache
- back/src/game-snapshot/game-snapshot.controller.ts - GET /api/game-snapshot
- movil/lib/services/game_data_service.dart - singleton que carga todas las tablas game_*

### Modificados (Sprint Sincronización)
- back/src/app.module.ts - registrado GameSnapshotController + Service
- back/src/game-data/game-data.service.ts - auto-invalida cache en cada mutación
- movil/lib/main.dart - registrado GameDataService como Provider
- movil/lib/game/models/game_models.dart - PlayerConfig usa civId string (no enum)
- movil/lib/screens/game_config_screen.dart - civs dinámicas desde Supabase
- movil/lib/game/engine/game_state.dart - _loadStatsFromSupabase usa GameDataService + overrides

### Supabase
- Bucket game-sprites creado (publico)
- RLS: public read, anon upload, anon update
- Dashboard ya usa tablas game_* (confirmado: no hay brecha de schema)

