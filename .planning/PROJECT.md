# RTS_1 — PROJECT.md

## Visión
Sistema de administración web para un juego RTS que permite gestionar civilizaciones, unidades, edificios y tecnologías. Incluye generación y configuración de sprites integrada.

## Stack
- **Frontend:** Next.js 16 + TailwindCSS + TypeScript
- **Backend:** NestJS 11 (watch mode) en puerto 3002
- **Base de datos:** Supabase (PostgreSQL)
- **Storage:** Supabase Storage (por implementar para sprites)
- **Árbol Tecnológico:** ReactFlow (@xyflow/react)

## Restricciones
- No romper funcionalidad CRUD existente
- Mantener el sistema de overrides por civilización
- Compatibilidad con el esquema de Supabase actual
- No cambiar la arquitectura del backend (NestJS genérico)

## Objetivos v1 (este sprint)
1. Corregir bugs críticos (Base64, selectedCivId hardcodeado, botones muertos)
2. Refactorizar Dashboard.tsx en componentes modulares
3. Implementar subida de imágenes a Supabase Storage
4. Integrar generador de sprites (NanoBanana API + limpieza de fondo)
