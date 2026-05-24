import { Injectable, ConflictException } from '@nestjs/common';
import { SupabaseService } from '../supabase.service';
import { GameSnapshotService } from '../game-snapshot/game-snapshot.service';

@Injectable()
export class GameDataService {
  constructor(
    private supabaseService: SupabaseService,
    private snapshotService: GameSnapshotService,
  ) {}

  async findAll(table: string) {
    const { data, error } = await this.supabaseService.getClient()
      .from(table)
      .select('*');
    if (error) throw error;
    return data;
  }

  async findOne(table: string, id: string) {
    const { data, error } = await this.supabaseService.getClient()
      .from(table)
      .select('*')
      .eq('id', id)
      .single();
    if (error) throw error;
    return data;
  }

  async create(table: string, payload: any) {
    const { data, error } = await this.supabaseService.getClient()
      .from(table)
      .insert(payload)
      .select()
      .single();
    
    if (error) {
      if (error.code === '23505') {
        throw new ConflictException('Un elemento con este ID ya existe.');
      }
      throw error;
    }
    this.snapshotService.invalidateCache();
    return data;
  }

  async update(table: string, id: string, payload: any) {
    const { data, error } = await this.supabaseService.getClient()
      .from(table)
      .update(payload)
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    this.snapshotService.invalidateCache();
    return data;
  }

  async remove(table: string, id: string) {
    const { error } = await this.supabaseService.getClient()
      .from(table)
      .delete()
      .eq('id', id);
    if (error) throw error;
    this.snapshotService.invalidateCache();
    return { deleted: true };
  }

  // Specialized methods for relations
  async getRelations(table: string, id: string, relationTable: string, joinField: string) {
    const { data, error } = await this.supabaseService.getClient()
      .from(relationTable)
      .select('*')
      .eq(joinField, id);
    if (error) throw error;
    return data;
  }

  async addRelation(table: string, payload: any) {
    const { data, error } = await this.supabaseService.getClient()
      .from(table)
      .insert(payload)
      .select();
    
    if (error) {
      if (error.code === '23505') {
        throw new ConflictException('Este vínculo ya existe.');
      }
      throw error;
    }
    this.snapshotService.invalidateCache();
    return data;
  }

  async removeRelation(table: string, query: any) {
    const { error } = await this.supabaseService.getClient()
      .from(table)
      .delete()
      .match(query);
    if (error) throw error;
    this.snapshotService.invalidateCache();
    return { deleted: true };
  }
}
