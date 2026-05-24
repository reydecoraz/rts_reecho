"use client";

import React, { useCallback, useMemo, useEffect, useState } from 'react';
import { 
  ReactFlow, 
  MiniMap, 
  Controls, 
  Background, 
  useNodesState, 
  useEdgesState, 
  addEdge,
  Handle,
  Position,
  MarkerType,
  Connection,
  Edge,
  Panel
} from '@xyflow/react';
import '@xyflow/react/dist/style.css';
import { 
  Trash2, Zap, Plus, 
  ChevronRight, ArrowRightCircle, AlertTriangle, Settings2,
  TrendingUp, Activity, Layers, Database
} from 'lucide-react';
import { BuildingNode, UnitNode, TechNode, EraLaneNode } from './TechTreeNodes';

const nodeTypes = {
  building: BuildingNode,
  unit: UnitNode,
  technology: TechNode,
  eraLane: EraLaneNode
};

const ERAS = [
  { id: 'stone', label: 'EDAD DE PIEDRA', x: 0, color: 'rgba(148, 163, 184, 0.03)' },
  { id: 'bronze', label: 'EDAD DE BRONCE', x: 800, color: 'rgba(245, 158, 11, 0.03)' },
  { id: 'iron', label: 'EDAD DE HIERRO', x: 1600, color: 'rgba(99, 102, 241, 0.03)' },
  { id: 'imperial', label: 'EDAD IMPERIAL', x: 2400, color: 'rgba(16, 185, 129, 0.03)' },
];

export default function TechTreeEditor({ civilization, relations, available, onAddRelation, onRemoveRelation, onUpdateItem }: any) {
  const [nodes, setNodes, onNodesChange] = useNodesState<any>([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState<any>([]);
  const [visibleGroups, setVisibleGroups] = useState({ buildings: true, units: true, technologies: true });
  const [lastUpdate, setLastUpdate] = useState<{name: string, era: string} | null>(null);

  // Transform data into Nodes and Edges ONLY when civilization or groups change
  useEffect(() => {
    const newNodes: any[] = [];
    const newEdges: any[] = [];

    // 0. Background Lanes
    ERAS.forEach((era) => {
      newNodes.push({
        id: `lane-${era.id}`,
        type: 'eraLane',
        data: { label: era.label, color: era.color },
        position: { x: era.x, y: -200 },
        draggable: false,
        selectable: false,
        zIndex: -1,
      });
    });

    // Helper to get X position by era
    const getX = (era: string, offset: number = 0) => {
      const eraIdx = ERAS.findIndex(e => e.id === era);
      const baseX = eraIdx !== -1 ? ERAS[eraIdx].x : 0;
      return baseX + 100 + (offset * 30);
    };

    // 1. Buildings
    if (visibleGroups.buildings) {
      const civBuildings = relations.buildings || [];
      civBuildings.forEach((b: any, idx: number) => {
        const detail = available.buildings.find((d: any) => d.id === b.building_id);
        const era = detail?.required_era || 'stone';
        newNodes.push({
          id: `b-${b.building_id}`,
          type: 'building',
          data: { label: detail?.name || b.building_id, era, raw: detail },
          position: { x: getX(era), y: 100 + (idx * 200) },
        });

        // Add Building Upgrade/Evolution Edges
        if (detail?.upgrades_to) {
          newEdges.push({
            id: `evo-b-${b.building_id}`,
            source: `b-${b.building_id}`,
            target: `b-${detail.upgrades_to}`,
            type: 'default',
            label: 'evoluciona',
            animated: true,
            style: { stroke: '#a855f7', strokeWidth: 4 },
            markerEnd: { type: MarkerType.ArrowClosed, color: '#a855f7' },
          });
        }
      });
    }

    // 2. Units
    if (visibleGroups.units) {
      const production = relations.production || [];
      available.units.forEach((unit: any, idx: number) => {
        const era = unit.required_era || 'stone';
        newNodes.push({
          id: `u-${unit.id}`,
          type: 'unit',
          data: { label: unit.name, era, raw: unit },
          position: { x: getX(era, 15), y: 500 + (idx * 150) },
        });

        // Add Unit Upgrade Edges
        if (unit.upgrades_to) {
          newEdges.push({
            id: `evo-u-${unit.id}`,
            source: `u-${unit.id}`,
            target: `u-${unit.upgrades_to}`,
            type: 'smoothstep',
            label: 'evolución',
            animated: true,
            style: { stroke: '#a855f7', strokeWidth: 4 },
            markerEnd: { type: MarkerType.ArrowClosed, color: '#a855f7' },
          });
        }
      });

      // Production Edges
      production.forEach((p: any) => {
        if (visibleGroups.buildings) {
          newEdges.push({
            id: `prod-${p.building_id}-${p.unit_id}`,
            source: `b-${p.building_id}`,
            target: `u-${p.unit_id}`,
            label: 'produce',
            animated: true,
            style: { stroke: '#10b981', strokeWidth: 2, opacity: 0.8 },
            markerEnd: { type: MarkerType.ArrowClosed, color: '#10b981' },
          });
        }
      });
    }

    // 3. Technologies
    if (visibleGroups.technologies) {
      available.techs.forEach((tech: any, idx: number) => {
        const era = tech.required_era || 'stone';
        newNodes.push({
          id: `t-${tech.id}`,
          type: 'technology',
          data: { label: tech.name, era, raw: tech },
          position: { x: getX(era, 25), y: 1000 + (idx * 120) },
        });
      });

      // Research Edges
      const researches = relations.researches_civ || [];
      researches.forEach((r: any) => {
        if (visibleGroups.buildings) {
          newEdges.push({
            id: `res-${r.building_id}-${r.technology_id}`,
            source: `b-${r.building_id}`,
            target: `t-${r.technology_id}`,
            label: 'investiga',
            animated: true,
            style: { stroke: '#f59e0b', strokeWidth: 2, opacity: 0.8 },
            markerEnd: { type: MarkerType.ArrowClosed, color: '#f59e0b' },
          });
        }
      });
    }

    // 4. Requirements (Multi-conditional)
    const requirements = relations.requirements || [];
    requirements.forEach((req: any) => {
      const sourcePrefix = req.required_entity_type === 'building' ? 'b-' : req.required_entity_type === 'technology' ? 't-' : 'u-';
      const targetPrefix = req.entity_type === 'building' ? 'b-' : req.entity_type === 'technology' ? 't-' : 'u-';
      
      newEdges.push({
        id: `req-${req.id}`,
        source: `${sourcePrefix}${req.required_entity_id}`,
        target: `${targetPrefix}${req.entity_id}`,
        label: 'requiere',
        style: { stroke: '#6366f1', strokeWidth: 2, strokeDasharray: '5,5' },
        markerEnd: { type: MarkerType.ArrowClosed, color: '#6366f1' },
      });
    });

    setNodes(newNodes);
    setEdges(newEdges);
  }, [civilization.id, visibleGroups]); // Only update on civ change or visibility change

  const onConnect = useCallback(
    (params: Connection) => {
      const sourceId = params.source?.split('-')[1];
      const targetId = params.target?.split('-')[1];
      const sourcePrefix = params.source?.split('-')[0];
      const targetPrefix = params.target?.split('-')[0];

      // Smart connection logic
      if (sourcePrefix === 'b' && targetPrefix === 'u') {
        onAddRelation('building_produces_units', { building_id: sourceId, unit_id: targetId, civilization_id: civilization.id });
      } else if (sourcePrefix === 'b' && targetPrefix === 't') {
        onAddRelation('building_researches', { building_id: sourceId, technology_id: targetId, civilization_id: civilization.id });
      } else if (sourcePrefix === 'u' && targetPrefix === 'u') {
        onUpdateItem('units', sourceId, { upgrades_to: targetId });
      } else if (sourcePrefix === 'b' && targetPrefix === 'b') {
        onUpdateItem('buildings', sourceId, { upgrades_to: targetId });
      } else {
        const entityType = targetPrefix === 'b' ? 'building' : targetPrefix === 'u' ? 'unit' : 'technology';
        const reqType = sourcePrefix === 'b' ? 'building' : sourcePrefix === 'u' ? 'unit' : 'technology';
        onAddRelation('game_requirements', { 
          entity_id: targetId, 
          entity_type: entityType, 
          required_entity_id: sourceId, 
          required_entity_type: reqType, 
          civilization_id: civilization.id 
        });
      }
    },
    [civilization, onAddRelation, onUpdateItem]
  );

  const onEdgeClick = (event: React.MouseEvent, edge: Edge) => {
    if (confirm('¿Eliminar este vínculo?')) {
      if (edge.id.startsWith('req-')) {
        onRemoveRelation('game_requirements', { id: edge.id.replace('req-', '') });
      } else if (edge.id.startsWith('prod-')) {
         onRemoveRelation('building_produces_units', { building_id: edge.source.replace('b-', ''), unit_id: edge.target.replace('u-', ''), civilization_id: civilization.id });
      } else if (edge.id.startsWith('res-')) {
         onRemoveRelation('building_researches', { building_id: edge.source.replace('b-', ''), technology_id: edge.target.replace('t-', ''), civilization_id: civilization.id });
      } else if (edge.id.startsWith('evo-')) {
         const type = edge.source.startsWith('b-') ? 'buildings' : 'units';
         onUpdateItem(type, edge.source.split('-')[1], { upgrades_to: null });
      }
    }
  };

  const onNodeClick = (_: any, node: any) => {
    if (node.type === 'eraLane') return;
    const type = node.id.startsWith('b-') ? 'buildings' : node.id.startsWith('u-') ? 'units' : 'technologies';
    const id = node.id.split('-')[1];
    onUpdateItem('select', id, { type });
  };

  const onNodeDragStop = (event: any, node: any) => {
    if (node.type === 'eraLane') return;
    const x = node.position.x;
    const era = ERAS.find((e, i) => {
      const nextX = ERAS[i+1]?.x || 9999;
      return x >= e.x && x < nextX;
    });

    if (era && era.id !== node.data.era) {
        const type = node.id.startsWith('b-') ? 'buildings' : node.id.startsWith('u-') ? 'units' : 'technologies';
        const id = node.id.split('-')[1];
        onUpdateItem(type, id, { required_era: era.id });
        
        setNodes(nds => nds.map(n => n.id === node.id ? { ...n, data: { ...n.data, era: era.id } } : n));
        setLastUpdate({ name: node.data.label, era: era.label });
        setTimeout(() => setLastUpdate(null), 3000);
    }
  };

  return (
    <div className="w-full h-[800px] glass rounded-[4rem] border-white/5 overflow-hidden relative flex flex-col shadow-2xl">
      {lastUpdate && (
        <div className="absolute top-32 left-1/2 -translate-x-1/2 z-[100] animate-in slide-in-from-top-10 duration-700">
          <div className="bg-indigo-600/90 backdrop-blur-2xl border border-indigo-400/30 px-10 py-4 rounded-[2rem] shadow-2xl flex items-center gap-5">
            <div className="w-8 h-8 bg-white/20 rounded-full flex items-center justify-center">
              <Zap className="w-4 h-4 text-white" />
            </div>
            <p className="text-xs font-black text-white uppercase tracking-widest italic">
              {lastUpdate.name} <ArrowRightCircle className="inline w-4 h-4 mx-2" /> {lastUpdate.era}
            </p>
          </div>
        </div>
      )}

      <div className="p-10 border-b border-white/5 flex items-center justify-between bg-white/2 z-20">
        <div className="flex items-center gap-6">
          <div className="bg-indigo-600 p-4 rounded-3xl shadow-lg shadow-indigo-900/40">
              <Database className="w-6 h-6 text-white" />
          </div>
          <div>
            <h3 className="text-2xl font-black text-white italic tracking-tight">Arquitecto Supremo RTS</h3>
            <p className="text-[10px] text-indigo-400 font-black uppercase tracking-[0.4em] mt-1">Sincronización de Dependencias y Evoluciones</p>
          </div>
        </div>

        <div className="flex items-center gap-4 bg-black/40 p-2.5 rounded-[2.5rem] border border-white/10">
           {['buildings', 'units', 'technologies'].map(group => (
             <button 
              key={group}
              onClick={() => setVisibleGroups({...visibleGroups, [group]: !visibleGroups[group as keyof typeof visibleGroups]})}
              className={`px-8 py-3.5 rounded-[1.5rem] text-[10px] font-black uppercase tracking-widest transition-all duration-500 ${visibleGroups[group as keyof typeof visibleGroups] ? 'bg-indigo-600 text-white shadow-xl shadow-indigo-900/30' : 'text-gray-600 hover:text-gray-400'}`}
             >
              {group === 'technologies' ? 'Mejoras' : group === 'buildings' ? 'Edificios' : 'Unidades'}
             </button>
           ))}
        </div>
      </div>

      <div className="flex-1 relative">
        <ReactFlow
          nodes={nodes}
          edges={edges}
          onNodesChange={onNodesChange}
          onEdgesChange={onEdgesChange}
          onConnect={onConnect}
          onEdgeClick={onEdgeClick}
          onNodeClick={onNodeClick}
          onNodeDragStop={onNodeDragStop}
          nodeTypes={nodeTypes}
          onInit={(instance) => instance.fitView()}
          className="bg-[#06070a]"
          zoomOnScroll={false}
          panOnScroll={true}
          preventScrolling={true}
        >
          <Background color="#161925" gap={40} size={1} />
          
          <Panel position="top-right" className="m-6 flex flex-col gap-4">
             <div className="glass p-6 rounded-3xl border-white/10 space-y-4 min-w-[200px]">
                <p className="text-[10px] font-black text-indigo-400 uppercase tracking-widest">Leyenda de Vínculos</p>
                <div className="space-y-3">
                   <div className="flex items-center gap-3"><div className="w-8 h-0.5 bg-emerald-500" /> <span className="text-[9px] font-bold text-gray-400">Producción</span></div>
                   <div className="flex items-center gap-3"><div className="w-8 h-0.5 bg-amber-500" /> <span className="text-[9px] font-bold text-gray-400">Investigación</span></div>
                   <div className="flex items-center gap-3"><div className="w-8 h-1 bg-purple-500" /> <span className="text-[9px] font-bold text-gray-400">Evolución</span></div>
                   <div className="flex items-center gap-3"><div className="w-8 h-0.5 bg-indigo-500 border-t border-dashed" /> <span className="text-[9px] font-bold text-gray-400">Requisito</span></div>
                </div>
             </div>
          </Panel>

          <Controls className="!bg-[#0f111a] !border-white/10 !fill-white" />
          <MiniMap 
              nodeColor={(n: any) => {
                  if (n.type === 'building') return '#6366f1';
                  if (n.type === 'unit') return '#10b981';
                  if (n.type === 'technology') return '#f59e0b';
                  return 'transparent';
              }} 
              maskColor="rgba(6, 7, 10, 0.8)"
              className="!bg-[#0f111a] !border-white/10 !rounded-3xl"
          />
        </ReactFlow>
      </div>
    </div>
  );
}
