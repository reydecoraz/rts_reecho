import React, { useState } from 'react';
import { Zap, X, Plus, Layers, Users, Trash2, TrendingUp, Box, Save, ChevronRight } from 'lucide-react';

export function AdvancedEffectSection({ title, subtitle, effects, civs, units, selectedCivId, onAdd, onRemove }: any) {
  const [isAdding, setIsAdding] = useState(false);
  const [newEff, setNewEff] = useState({ target_type: 'unit', target_id: '', stat_key: '', multiplier: 1.0, bonus_flat: 0, civilization_id: selectedCivId });

  return (
    <section className="glass p-10 rounded-[3rem] border-white/5 relative">
      <div className="flex justify-between items-start mb-10">
        <div className="flex items-center gap-5">
          <div className="p-4 bg-indigo-600/20 rounded-2xl border border-indigo-500/30 text-indigo-400">
            <Zap className="w-6 h-6" />
          </div>
          <div>
            <h3 className="text-xl font-black text-white tracking-tight italic">{title}</h3>
            <p className="text-[10px] text-gray-500 mt-1 font-black uppercase tracking-[0.2em]">{subtitle}</p>
          </div>
        </div>
        <button 
          onClick={() => setIsAdding(!isAdding)}
          className="bg-white/5 hover:bg-white/10 p-3 rounded-2xl border border-white/10 transition-all"
        >
          {isAdding ? <X className="w-5 h-5" /> : <Plus className="w-5 h-5" />}
        </button>
      </div>

      {isAdding && (
        <div className="mb-10 p-8 bg-white/2 rounded-[2rem] border border-white/5 grid grid-cols-2 md:grid-cols-3 gap-6 animate-in slide-in-from-top-4">
          <div className="space-y-2">
            <label className="text-[9px] font-black text-gray-500 uppercase tracking-widest ml-1">Tipo de Target</label>
            <select 
              className="w-full bg-[#06070a] border border-white/5 rounded-xl px-4 py-3 text-xs font-bold outline-none focus:border-indigo-500"
              value={newEff.target_type}
              onChange={(e) => setNewEff({...newEff, target_type: e.target.value})}
            >
              <option value="unit">Unidad Específica</option>
              <option value="category">Categoría (Tipo)</option>
              <option value="global">Global (Todo)</option>
            </select>
          </div>
          <div className="space-y-2">
            <label className="text-[9px] font-black text-gray-500 uppercase tracking-widest ml-1">Target ID / Nombre</label>
            {newEff.target_type === 'unit' ? (
              <select 
                className="w-full bg-[#06070a] border border-white/5 rounded-xl px-4 py-3 text-xs font-bold outline-none focus:border-indigo-500"
                value={newEff.target_id}
                onChange={(e) => setNewEff({...newEff, target_id: e.target.value})}
              >
                <option value="">Seleccionar Unidad...</option>
                {units?.map((u: any) => <option key={u.id} value={u.id}>{u.name}</option>)}
              </select>
            ) : (
              <input 
                type="text"
                placeholder="Ej: Infantería, Arquería..."
                className="w-full bg-[#06070a] border border-white/5 rounded-xl px-4 py-3 text-xs font-bold outline-none focus:border-indigo-500"
                value={newEff.target_id}
                onChange={(e) => setNewEff({...newEff, target_id: e.target.value})}
              />
            )}
          </div>
          <div className="space-y-2">
            <label className="text-[9px] font-black text-gray-500 uppercase tracking-widest ml-1">Stat a Modificar</label>
            <input 
              type="text"
              placeholder="Ej: attack, range, speed..."
              className="w-full bg-[#06070a] border border-white/5 rounded-xl px-4 py-3 text-xs font-bold outline-none focus:border-indigo-500"
              value={newEff.stat_key}
              onChange={(e) => setNewEff({...newEff, stat_key: e.target.value})}
            />
          </div>
          <div className="flex gap-4 col-span-full justify-end">
             <button 
              onClick={() => { onAdd({...newEff, civilization_id: selectedCivId}); setIsAdding(false); }}
              className="bg-indigo-600 text-white px-8 py-3 rounded-xl text-[10px] font-black uppercase tracking-widest hover:bg-indigo-500 transition-all"
            >
              Aplicar Regla
            </button>
          </div>
        </div>
      )}

      <div className="space-y-4">
        {effects?.map((eff: any) => (
          <div key={eff.id} className="flex items-center justify-between bg-white/2 border border-white/5 p-6 rounded-3xl group hover:border-indigo-500/30 transition-all">
            <div className="flex items-center gap-6">
              <div className="p-3 bg-white/5 rounded-2xl">
                {eff.target_type === 'category' ? <Layers className="w-5 h-5 text-emerald-400" /> : <Users className="w-5 h-5 text-indigo-400" />}
              </div>
              <div>
                <p className="text-sm font-black text-white">
                  {eff.target_type === 'global' ? 'Global' : eff.target_id}
                  <span className="text-[10px] text-gray-600 font-bold ml-2 uppercase">({eff.target_type})</span>
                </p>
                <p className="text-[10px] text-indigo-400 font-black uppercase tracking-widest mt-1">
                  {eff.stat_key}: {eff.multiplier !== 1 ? `x${eff.multiplier}` : ''} {eff.bonus_flat > 0 ? `+${eff.bonus_flat}` : ''}
                </p>
              </div>
            </div>
            <button 
              onClick={() => onRemove(eff.id)}
              className="opacity-0 group-hover:opacity-100 p-2 text-red-500/50 hover:text-red-500 hover:bg-red-500/10 rounded-xl transition-all"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        ))}
        {effects?.length === 0 && (
          <div className="py-12 border-2 border-dashed border-white/5 rounded-[2rem] flex flex-col items-center justify-center text-gray-600 italic text-xs">
            No hay efectos definidos para esta tecnología en el contexto actual.
          </div>
        )}
      </div>
    </section>
  );
}

export function ProductionBonusSection({ title, subtitle, bonuses, civs, selectedCivId, onAdd, onRemove }: any) {
  const [isAdding, setIsAdding] = useState(false);
  const [newBonus, setNewBonus] = useState({ stat_key: '', multiplier: 1.0, bonus_flat: 0, civilization_id: selectedCivId });

  return (
    <section className="glass p-10 rounded-[3rem] border-white/5">
       <div className="flex justify-between items-start mb-10">
        <div className="flex items-center gap-5">
          <div className="p-4 bg-amber-600/20 rounded-2xl border border-amber-500/30 text-amber-400">
            <TrendingUp className="w-6 h-6" />
          </div>
          <div>
            <h3 className="text-xl font-black text-white tracking-tight italic">{title}</h3>
            <p className="text-[10px] text-gray-500 mt-1 font-black uppercase tracking-[0.2em]">{subtitle}</p>
          </div>
        </div>
        <button onClick={() => setIsAdding(!isAdding)} className="bg-white/5 hover:bg-white/10 p-3 rounded-2xl transition-all">
          {isAdding ? <X className="w-5 h-5" /> : <Plus className="w-5 h-5" />}
        </button>
      </div>

      {isAdding && (
         <div className="mb-10 p-8 bg-white/2 rounded-[2rem] border border-white/5 grid grid-cols-2 md:grid-cols-4 gap-6 animate-in slide-in-from-top-4">
            <div className="space-y-2 col-span-2">
              <label className="text-[9px] font-black text-gray-500 uppercase tracking-widest">Estadística</label>
              <input type="text" placeholder="Ej: attack, health..." className="w-full bg-[#06070a] border border-white/5 rounded-xl px-4 py-3 text-xs font-bold" value={newBonus.stat_key} onChange={e => setNewBonus({...newBonus, stat_key: e.target.value})}/>
            </div>
            <div className="space-y-2">
              <label className="text-[9px] font-black text-gray-500 uppercase tracking-widest">Flat</label>
              <input type="number" className="w-full bg-[#06070a] border border-white/5 rounded-xl px-4 py-3 text-xs font-bold" value={newBonus.bonus_flat} onChange={e => setNewBonus({...newBonus, bonus_flat: Number(e.target.value)})}/>
            </div>
            <div className="flex items-end">
              <button onClick={() => { onAdd({...newBonus, civilization_id: selectedCivId}); setIsAdding(false); }} className="w-full bg-amber-600 text-white py-3 rounded-xl text-[10px] font-black uppercase">Vincular Bono</button>
            </div>
         </div>
      )}

      <div className="space-y-4">
        {bonuses?.filter((b: any) => b.civilization_id === selectedCivId).map((b: any) => (
          <div key={b.id} className="flex items-center justify-between bg-white/2 border border-white/5 p-6 rounded-3xl group">
             <div className="flex items-center gap-6">
                <div className="w-12 h-12 bg-amber-600/10 rounded-2xl flex items-center justify-center text-amber-400 font-black">
                  {b.stat_key.slice(0, 2).toUpperCase()}
                </div>
                <div>
                   <p className="text-sm font-black text-white uppercase">{b.stat_key.replace('_', ' ')}</p>
                   <p className="text-[10px] text-amber-500 font-bold uppercase tracking-widest mt-1">Bono: +{b.bonus_flat}</p>
                </div>
             </div>
             <button onClick={() => onRemove(b.id)} className="opacity-0 group-hover:opacity-100 p-2 text-red-500/50 hover:text-red-500 transition-all">
                <Trash2 className="w-4 h-4" />
             </button>
          </div>
        ))}
      </div>
    </section>
  );
}

export function AdvancedProductionSection({ title, subtitle, items, available, civId, onAdd, onRemove }: any) {
  const [isAdding, setIsAdding] = useState(false);
  const [selectedUnit, setSelectedUnit] = useState('');

  return (
    <section className="glass p-10 rounded-[4rem] border-white/5">
      <div className="flex justify-between items-start mb-12">
        <div className="flex items-center gap-6">
          <div className="p-5 bg-emerald-600/20 rounded-[1.5rem] border border-emerald-500/30 text-emerald-400 animate-pulse">
            <Box className="w-8 h-8" />
          </div>
          <div>
            <h3 className="text-2xl font-black text-white tracking-tight italic">{title}</h3>
            <p className="text-[10px] text-gray-500 mt-1 font-black uppercase tracking-[0.3em]">{subtitle}</p>
          </div>
        </div>
        {!isAdding ? (
          <button 
            onClick={() => setIsAdding(true)}
            className="flex items-center gap-3 bg-emerald-600 hover:bg-emerald-500 text-white px-8 py-4 rounded-2xl text-xs font-black uppercase tracking-widest transition-all shadow-lg shadow-emerald-900/20"
          >
            <Plus className="w-5 h-5" />
            <span>Configurar Producción</span>
          </button>
        ) : (
          <div className="flex gap-4 animate-in fade-in slide-in-from-right-4">
            <select 
              className="bg-[#06070a] border border-white/10 rounded-2xl text-xs font-bold px-6 py-4 outline-none text-emerald-400 min-w-[200px]"
              value={selectedUnit}
              onChange={(e) => setSelectedUnit(e.target.value)}
            >
              <option value="">Seleccionar Unidad...</option>
              {available?.map((a: any) => <option key={a.id} value={a.id} className="bg-[#0f111a]">{a.name}</option>)}
            </select>
            <button onClick={() => { if (selectedUnit) onAdd(selectedUnit); setIsAdding(false); setSelectedUnit(''); }} className="p-4 bg-emerald-600 text-white rounded-2xl hover:bg-emerald-500 transition-all">
              <Save className="w-6 h-6" />
            </button>
            <button onClick={() => setIsAdding(false)} className="p-4 bg-white/5 text-gray-400 rounded-2xl hover:bg-white/10 transition-all border border-white/5">
              <X className="w-6 h-6" />
            </button>
          </div>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {items?.map((rel: any, idx: number) => {
          const detail = available?.find((a: any) => a.id === rel.unit_id);
          return (
            <div key={idx} className="flex items-center justify-between bg-white/2 border border-white/5 p-6 rounded-[2.5rem] group hover:border-emerald-500/30 hover:bg-emerald-500/5 transition-all">
               <div className="flex items-center gap-5">
                  <div className="w-12 h-12 bg-[#06070a] rounded-2xl flex items-center justify-center text-[10px] text-emerald-500 font-black border border-white/5 group-hover:scale-110 transition-transform">
                    {String(idx + 1).padStart(2, '0')}
                  </div>
                  <div>
                    <p className="text-sm font-black text-white tracking-wide">{detail?.name || rel.unit_id}</p>
                    <p className="text-[10px] text-gray-500 font-bold uppercase mt-1">Estatus: Activo</p>
                  </div>
               </div>
               <button onClick={() => onRemove(rel.unit_id)} className="opacity-0 group-hover:opacity-100 p-3 text-red-500/30 hover:text-red-500 transition-all">
                  <Trash2 className="w-5 h-5" />
               </button>
            </div>
          );
        })}
      </div>
    </section>
  );
}

export function ComplexRelationSection({ title, subtitle, items, available, accent }: any) {
  return (
    <section className="glass p-10 rounded-[3rem] border-white/5">
      <h3 className="text-lg font-black text-white mb-2 italic">{title}</h3>
      <p className="text-[10px] text-gray-500 mb-8 font-black uppercase tracking-widest">{subtitle}</p>
      <div className="space-y-3">
        {items?.map((rel: any, idx: number) => {
          const id = rel.unit_id || rel.building_id || rel.technology_id;
          const detail = available?.find((a: any) => a.id === id);
          return (
            <div key={idx} className="flex items-center justify-between bg-white/2 p-5 rounded-2xl border border-white/5">
              <span className="text-xs font-bold text-gray-300">{detail?.name || id}</span>
              <ChevronRight className={`w-4 h-4 text-${accent}-500/50`} />
            </div>
          );
        })}
      </div>
    </section>
  );
}
