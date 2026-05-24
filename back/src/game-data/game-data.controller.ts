import { Controller, Get, Post, Patch, Delete, Param, Body, Query } from '@nestjs/common';
import { GameDataService } from './game-data.service';

@Controller('api/game-data')
export class GameDataController {
  constructor(private readonly gameDataService: GameDataService) {}

  @Get(':table/:id/relations')
  getRelations(
    @Param('table') table: string,
    @Param('id') id: string,
    @Query('relationTable') relationTable: string,
    @Query('joinField') joinField: string,
  ) {
    return this.gameDataService.getRelations(table, id, relationTable, joinField);
  }

  @Post('relations/:table')
  addRelation(@Param('table') table: string, @Body() payload: any) {
    return this.gameDataService.addRelation(table, payload);
  }

  @Delete('relations/:table')
  removeRelation(@Param('table') table: string, @Query() query: any) {
    return this.gameDataService.removeRelation(table, query);
  }

  @Get(':table')
  findAll(@Param('table') table: string) {
    return this.gameDataService.findAll(table);
  }

  @Get(':table/:id')
  findOne(@Param('table') table: string, @Param('id') id: string) {
    return this.gameDataService.findOne(table, id);
  }

  @Post(':table')
  create(@Param('table') table: string, @Body() payload: any) {
    return this.gameDataService.create(table, payload);
  }

  @Patch(':table/:id')
  update(@Param('table') table: string, @Param('id') id: string, @Body() payload: any) {
    return this.gameDataService.update(table, id, payload);
  }

  @Delete(':table/:id')
  remove(@Param('table') table: string, @Param('id') id: string) {
    return this.gameDataService.remove(table, id);
  }
}
