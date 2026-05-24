import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../supabase.service';

/**
 * GameSnapshotService — Provides a single endpoint that returns ALL game
 * configuration needed for the mobile client to start a match.
 *
 * The snapshot is cached in-memory for 5 minutes to avoid hitting Supabase
 * on every match initialization request.
 */
@Injectable()
export class GameSnapshotService {
  private cache: { data: any; timestamp: number } | null = null;
  private readonly CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

  constructor(private supabaseService: SupabaseService) {}

  async getSnapshot() {
    // Return cached data if fresh
    if (this.cache && Date.now() - this.cache.timestamp < this.CACHE_TTL_MS) {
      return this.cache.data;
    }

    const client = this.supabaseService.getClient();

    // Fetch all game data tables in parallel
    const [
      civilizationsRes,
      unitsRes,
      buildingsRes,
      technologiesRes,
      heroesRes,
      attributeDefsRes,
      overridesRes,
      civUnitsRes,
      civBuildingsRes,
      civTechnologiesRes,
      civHeroesRes,
      buildProducesRes,
      buildResearchesRes,
      techEffectsRes,
      requirementsRes,
      productionBonusesRes,
      techAffectsUnitsRes,
    ] = await Promise.all([
      client.from('game_civilizations_data').select('*'),
      client.from('game_units_data').select('*'),
      client.from('game_buildings_data').select('*'),
      client.from('game_technologies_data').select('*'),
      client.from('game_heroes_data').select('*'),
      client.from('game_attribute_definitions').select('*'),
      client.from('game_civilization_overrides').select('*'),
      client.from('civ_units').select('*'),
      client.from('civ_buildings').select('*'),
      client.from('civ_technologies').select('*'),
      client.from('civ_heroes').select('*'),
      client.from('building_produces_units').select('*'),
      client.from('building_researches').select('*'),
      client.from('game_technology_effects').select('*'),
      client.from('game_requirements').select('*'),
      client.from('building_production_bonuses').select('*'),
      client.from('technology_affects_units').select('*'),
    ]);

    // Check for errors
    const results = [
      civilizationsRes, unitsRes, buildingsRes, technologiesRes, heroesRes, attributeDefsRes,
      overridesRes, civUnitsRes, civBuildingsRes, civTechnologiesRes, civHeroesRes,
      buildProducesRes, buildResearchesRes, techEffectsRes,
      requirementsRes, productionBonusesRes, techAffectsUnitsRes,
    ];
    for (const r of results) {
      if (r.error) {
        throw new Error(`Supabase query error: ${r.error.message}`);
      }
    }

    const snapshot = {
      version: Date.now(),
      attribute_definitions: attributeDefsRes.data,
      civilizations: civilizationsRes.data,
      units: unitsRes.data,
      buildings: buildingsRes.data,
      technologies: technologiesRes.data,
      heroes: heroesRes.data,
      overrides: overridesRes.data,
      civ_units: civUnitsRes.data,
      civ_buildings: civBuildingsRes.data,
      civ_technologies: civTechnologiesRes.data,
      civ_heroes: civHeroesRes.data,
      building_produces_units: buildProducesRes.data,
      building_researches: buildResearchesRes.data,
      technology_effects: techEffectsRes.data,
      requirements: requirementsRes.data,
      production_bonuses: productionBonusesRes.data,
      technology_affects_units: techAffectsUnitsRes.data,
    };

    // Cache the result
    this.cache = { data: snapshot, timestamp: Date.now() };

    return snapshot;
  }

  /**
   * Invalidate the cache — called when data is modified via the admin dashboard.
   */
  invalidateCache() {
    this.cache = null;
    return { invalidated: true };
  }
}
