import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { SupabaseService } from './supabase.service';
import { GameDataController } from './game-data/game-data.controller';
import { GameDataService } from './game-data/game-data.service';
import { GameSnapshotController } from './game-snapshot/game-snapshot.controller';
import { GameSnapshotService } from './game-snapshot/game-snapshot.service';

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true })],
  controllers: [AppController, GameDataController, GameSnapshotController],
  providers: [AppService, SupabaseService, GameDataService, GameSnapshotService],
})
export class AppModule {}
