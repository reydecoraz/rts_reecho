import { Controller, Get, Post } from '@nestjs/common';
import { GameSnapshotService } from './game-snapshot.service';

/**
 * GameSnapshotController — Provides endpoints for the mobile client.
 *
 * GET  /api/game-snapshot   → Returns the full game configuration snapshot
 * POST /api/game-snapshot/invalidate → Clears the cache (called after admin edits)
 */
@Controller('api/game-snapshot')
export class GameSnapshotController {
  constructor(private readonly snapshotService: GameSnapshotService) {}

  @Get()
  getSnapshot() {
    return this.snapshotService.getSnapshot();
  }

  @Post('invalidate')
  invalidateCache() {
    return this.snapshotService.invalidateCache();
  }
}
