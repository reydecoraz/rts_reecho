import React from 'react';
import { Handle, Position } from '@xyflow/react';
import { Home, Sword, FlaskConical } from 'lucide-react';

export const BuildingNode = ({ data }: any) => (
  <div className="px-6 py-4 shadow-2xl rounded-3xl bg-[#161925] border-2 border-indigo-500/50 min-w-[200px] group relative">
    <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-1 bg-indigo-600 rounded-full text-[8px] font-black uppercase tracking-tighter text-white border border-white/20">
      {data.era}
    </div>
    <Handle type="target" position={Position.Top} className="w-3 h-3 !bg-indigo-400 border-2 border-[#161925]" />
    <div className="flex items-center gap-4">
      <div className="p-3 bg-indigo-600/20 rounded-2xl text-indigo-400">
        <Home className="w-5 h-5" />
      </div>
      <div>
        <p className="text-[10px] font-black text-indigo-500 uppercase tracking-widest">Edificio</p>
        <p className="text-sm font-black text-white">{data.label}</p>
      </div>
    </div>
    <Handle type="source" position={Position.Bottom} className="w-3 h-3 !bg-indigo-500 border-2 border-[#161925]" />
  </div>
);

export const UnitNode = ({ data }: any) => (
  <div className="px-6 py-4 shadow-2xl rounded-3xl bg-[#0f111a] border-2 border-emerald-500/30 min-w-[180px] relative">
    <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-1 bg-emerald-600 rounded-full text-[8px] font-black uppercase tracking-tighter text-white border border-white/20">
      {data.era}
    </div>
    <Handle type="target" position={Position.Top} className="w-3 h-3 !bg-emerald-500 border-2 border-[#0f111a]" />
    <div className="flex items-center gap-4">
      <div className="p-3 bg-emerald-600/10 rounded-2xl text-emerald-400">
        <Sword className="w-5 h-5" />
      </div>
      <div>
        <p className="text-[10px] font-black text-emerald-500/50 uppercase tracking-widest">Unidad</p>
        <p className="text-sm font-black text-white">{data.label}</p>
      </div>
    </div>
    <Handle type="source" position={Position.Bottom} className="w-3 h-3 !bg-emerald-500 border-2 border-[#0f111a]" />
  </div>
);

export const TechNode = ({ data }: any) => (
  <div className="px-6 py-4 shadow-2xl rounded-3xl bg-[#0f111a] border-2 border-amber-500/30 min-w-[180px] relative">
    <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-1 bg-amber-600 rounded-full text-[8px] font-black uppercase tracking-tighter text-white border border-white/20">
      {data.era}
    </div>
    <Handle type="target" position={Position.Top} className="w-3 h-3 !bg-amber-500 border-2 border-[#0f111a]" />
    <div className="flex items-center gap-4">
      <div className="p-3 bg-amber-600/10 rounded-2xl text-amber-400">
        <FlaskConical className="w-5 h-5" />
      </div>
      <div>
        <p className="text-[10px] font-black text-amber-500/50 uppercase tracking-widest">Mejora</p>
        <p className="text-sm font-black text-white">{data.label}</p>
      </div>
    </div>
    <Handle type="source" position={Position.Bottom} className="w-3 h-3 !bg-amber-500 border-2 border-[#0f111a]" />
  </div>
);

export const EraLaneNode = ({ data }: any) => (
  <div className="h-[2500px] border-r border-white/5 relative group/lane" style={{ width: '800px', backgroundColor: data.color }}>
     <div className="absolute top-10 left-1/2 -translate-x-1/2 flex flex-col items-center gap-3">
        <span className="text-[14px] font-black text-gray-500/30 tracking-[1em] whitespace-nowrap bg-black/20 px-8 py-3 rounded-full border border-white/5">
          {data.label}
        </span>
     </div>
  </div>
);
