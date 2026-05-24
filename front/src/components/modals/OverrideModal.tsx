import React from 'react';
import { X, FlaskConical, Image as LucideImage } from 'lucide-react';

interface OverrideModalProps {
  isOpen: boolean;
  onClose: () => void;
  currentOverrideItem: { type: string; item: any } | null;
  selectedItem: any;
  relations: any;
  api: any;
  fetchRelations: () => void;
  addRelation: (table: string, payload: any) => Promise<any>;
  removeRelation: (table: string, payload: any) => Promise<any>;
  setCurrentSpriteField: (field: string) => void;
  setIsSpriteModalOpen: (open: boolean) => void;
}

export default function OverrideModal({
  isOpen,
  onClose,
  currentOverrideItem,
  selectedItem,
  relations,
  api,
  fetchRelations,
  addRelation,
  removeRelation,
  setCurrentSpriteField,
  setIsSpriteModalOpen
}: OverrideModalProps) {
  if (!isOpen || !currentOverrideItem) return null;

  return (
    <div className="fixed inset-0 bg-[#06070a]/95 backdrop-blur-3xl flex items-center justify-center p-12 z-[200] animate-in fade-in duration-500">
      <div className="bg-[#0f111a] border border-white/10 w-full max-w-6xl rounded-[4rem] shadow-2xl shadow-indigo-900/30 overflow-hidden flex flex-col max-h-[90vh]">
        <div className="p-12 border-b border-white/5 flex justify-between items-center bg-white/2">
          <div className="flex items-center gap-8">
            <div className="bg-indigo-600 p-5 rounded-[2rem] shadow-xl shadow-indigo-900/40">
              <FlaskConical className="w-10 h-10 text-white" />
            </div>
            <div>
              <h3 className="text-4xl font-black text-white italic tracking-tighter uppercase">Balance de Atributos</h3>
              <p className="text-[10px] text-indigo-500 mt-2 font-black uppercase tracking-[0.4em]">
                {currentOverrideItem.type} • {currentOverrideItem.item.name} • {selectedItem.name}
              </p>
            </div>
          </div>
          <button onClick={onClose} className="p-5 hover:bg-white/5 rounded-3xl transition-all text-gray-500 hover:text-white">
            <X className="w-10 h-10" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-12 scrollbar-hide">
          <div className="space-y-12">
            {(() => {
              const activeType = (currentOverrideItem.type === 'unit' || currentOverrideItem.type === 'units')
                ? 'unit'
                : (currentOverrideItem.type === 'building' || currentOverrideItem.type === 'buildings')
                ? 'building'
                : 'technology';

              const GROUPS: Record<string, any> = {
                unit: {
                  costs: { title: '💰 Costos y Adiestramiento', keys: ['cost_food', 'cost_wood', 'cost_gold', 'cost_stone', 'cost_coal', 'production_time', 'population_cost'] },
                  combat: { title: '⚔️ Combate y Ofensiva', keys: ['melee_attack', 'ranged_attack', 'attack_speed', 'attack_range', 'accuracy', 'projectile_type'] },
                  defense: { title: '🛡️ Defensa y Movilidad', keys: ['max_health', 'movement_speed', 'melee_armor', 'ranged_armor', 'cavalry_armor'] }
                },
                building: {
                  costs: { title: '🏗️ Costos de Construcción', keys: ['cost_food', 'cost_wood', 'cost_gold', 'cost_stone', 'cost_coal', 'production_time'] },
                  structural: { title: '🏢 Resistencia y Armadura', keys: ['max_health', 'melee_armor', 'ranged_armor'] },
                  utility: { title: '✨ Soporte y Población', keys: ['population_cost'] }
                },
                technology: {
                  costs: { title: '🧪 Requerimientos de Investigación', keys: ['cost_food', 'cost_wood', 'cost_gold', 'cost_stone', 'cost_coal', 'research_time_seconds'] },
                  effect: { title: '⚡ Modificadores y Atributos Activos', keys: ['affected_stat', 'multiplier', 'bonus_value'] }
                }
              };

              const assignedKeys = Object.values(GROUPS[activeType] || {}).flatMap((g: any) => g.keys);
              const allKeys = Object.keys(currentOverrideItem.item).filter(key => 
                !['id', 'name', 'description', 'lore', 'bonuses', 'cost', 'required_era', 'upgrades_to', 'created_at'].includes(key)
              );
              const remainingKeys = allKeys.filter(k => !assignedKeys.includes(k));

              const finalGroups = {
                ...(GROUPS[activeType] || {}),
                ...(remainingKeys.length > 0 ? { other: { title: '⚙️ Otros Atributos', keys: remainingKeys } } : {})
              };

              return Object.entries(finalGroups).map(([groupKey, group]: [string, any]) => {
                const validKeys = group.keys.filter((k: string) => currentOverrideItem.item[k] !== undefined);
                if (validKeys.length === 0) return null;

                return (
                  <div key={groupKey} className="space-y-6">
                    <div className="flex items-center gap-4">
                      <h4 className="text-xs font-black uppercase tracking-[0.2em] text-indigo-400">{group.title}</h4>
                      <div className="h-px bg-white/5 flex-1" />
                    </div>

                    <div className="grid grid-cols-1 gap-4">
                      <div className="grid grid-cols-12 gap-6 px-8 mb-2">
                        <div className="col-span-4 text-[10px] font-black text-gray-600 uppercase tracking-widest">Atributo</div>
                        <div className="col-span-2 text-[10px] font-black text-gray-600 uppercase tracking-widest text-center">Base</div>
                        <div className="col-span-3 text-[10px] font-black text-gray-600 uppercase tracking-widest text-center">Bono de Facción</div>
                        <div className="col-span-3 text-[10px] font-black text-gray-600 uppercase tracking-widest text-right">Resultado Total</div>
                      </div>

                      {validKeys.map((key: string) => {
                        const baseVal = currentOverrideItem.item[key];
                        const override = relations.unifiedOverrides?.find((o: any) => 
                          o.entity_type === currentOverrideItem.type && 
                          o.entity_id === currentOverrideItem.item.id && 
                          o.stat_key === key
                        );
                        const bonusVal = override ? parseFloat(override.stat_value) : 0;
                        const isNumeric = (key === 'category' || key === 'projectile_type' || key === 'affected_stat') ? false : (typeof baseVal === 'number' || !isNaN(parseFloat(baseVal)));
                        const total = isNumeric ? (parseFloat(baseVal || 0) + bonusVal) : (override?.stat_value || baseVal);

                        return (
                          <div key={key} className="grid grid-cols-12 gap-6 items-center bg-white/2 p-6 rounded-3xl border border-white/5 hover:border-indigo-500/30 transition-all group">
                            <div className="col-span-4">
                               <span className="text-xs font-black text-gray-400 uppercase tracking-widest block">{key.replace(/_/g, ' ')}</span>
                            </div>
                            <div className="col-span-2 text-center">
                               <span className="text-sm font-bold text-gray-500">{baseVal || '-'}</span>
                            </div>
                            <div className="col-span-3">
                               <div className="flex items-center gap-4 bg-black/40 rounded-2xl p-2 border border-white/5 group-hover:border-indigo-500/20">
                                 {key === 'projectile_type' ? (
                                   <select 
                                     className="w-full bg-transparent border-none text-center text-sm font-black text-indigo-400 outline-none appearance-none cursor-pointer"
                                     defaultValue={override?.stat_value || ''}
                                     onChange={async (e) => {
                                       const newVal = e.target.value;
                                       if (override) {
                                         await api.update('game_civilization_overrides', override.id, { stat_value: newVal });
                                       } else {
                                         await addRelation('game_civilization_overrides', {
                                           civilization_id: selectedItem.id,
                                           entity_type: currentOverrideItem.type,
                                           entity_id: currentOverrideItem.item.id,
                                           stat_key: key,
                                           stat_value: newVal
                                         });
                                       }
                                       fetchRelations();
                                     }}
                                   >
                                     <option value="" className="bg-[#0f111a]">Original</option>
                                     {['none', 'arrow', 'bolt', 'stone', 'fireball', 'bullet', 'cannonball', 'javelin'].map(pt => (
                                       <option key={pt} value={pt} className="bg-[#0f111a] uppercase">{pt}</option>
                                     ))}
                                   </select>
                                 ) : key === 'affected_stat' ? (
                                   <select 
                                     className="w-full bg-transparent border-none text-center text-xs font-bold text-indigo-400 outline-none appearance-none cursor-pointer"
                                     value={override?.stat_value || ''}
                                     onChange={async (e) => {
                                       const newVal = e.target.value;
                                       if (override) {
                                         await api.update('game_civilization_overrides', override.id, { stat_value: newVal });
                                       } else {
                                         await addRelation('game_civilization_overrides', {
                                           civilization_id: selectedItem.id,
                                           entity_type: currentOverrideItem.type,
                                           entity_id: currentOverrideItem.item.id,
                                           stat_key: key,
                                           stat_value: newVal
                                         });
                                       }
                                       fetchRelations();
                                     }}
                                   >
                                     <option value="" className="bg-[#0f111a]">Original</option>
                                     {[
                                       { value: 'max_health', label: 'Salud Máxima' },
                                       { value: 'movement_speed', label: 'Velocidad' },
                                       { value: 'melee_attack', label: 'Ataque Melee' },
                                       { value: 'ranged_attack', label: 'Ataque Rango' },
                                       { value: 'attack_speed', label: 'Velocidad Ataque' },
                                       { value: 'attack_range', label: 'Rango de Ataque' },
                                       { value: 'melee_armor', label: 'Armadura Melee' },
                                       { value: 'ranged_armor', label: 'Armadura Rango' },
                                       { value: 'cavalry_armor', label: 'Armadura Anti-Cabal.' },
                                       { value: 'accuracy', label: 'Precisión' },
                                       { value: 'production_time', label: 'Tiempo Adiestramiento' },
                                       { value: 'infantry_speed', label: 'Vel. Infantería' },
                                       { value: 'cavalry_speed', label: 'Vel. Caballería' },
                                       { value: 'archer_range', label: 'Rango Arqueros' },
                                       { value: 'wood_gather_rate', label: 'Recol. Madera' },
                                       { value: 'gold_gather_rate', label: 'Recol. Oro' },
                                       { value: 'food_gather_rate', label: 'Recol. Alimento' }
                                     ].map(item => (
                                       <option key={item.value} value={item.value} className="bg-[#0f111a]">{item.label}</option>
                                     ))}
                                   </select>
                                 ) : key === 'category' ? (
                                   <div className="flex flex-wrap gap-1.5 p-2 w-full max-h-[120px] overflow-y-auto scrollbar-hide">
                                     {(currentOverrideItem.type === 'unit' || currentOverrideItem.type === 'units'
                                       ? ['Infanteria', 'Arqueria', 'Caballeria', 'Artilleria']
                                       : ['Military', 'Economic', 'Administrative', 'Defensive', 'Social', 'Support']
                                     ).map(cat => {
                                       const selectedCats = override?.stat_value ? override.stat_value.split(',').map((c: any) => c.trim()).filter(Boolean) : [];
                                       const isSelected = selectedCats.includes(cat);
                                       return (
                                         <button
                                           type="button"
                                           key={cat}
                                           onClick={async () => {
                                             const nextCats = isSelected 
                                               ? selectedCats.filter((c: any) => c !== cat)
                                               : [...selectedCats, cat];
                                             const newVal = nextCats.join(', ');
                                             if (override) {
                                               if (nextCats.length === 0) {
                                                 await removeRelation('game_civilization_overrides', { id: override.id });
                                               } else {
                                                 await api.update('game_civilization_overrides', override.id, { stat_value: newVal });
                                               }
                                             } else if (nextCats.length > 0) {
                                               await addRelation('game_civilization_overrides', {
                                                 civilization_id: selectedItem.id,
                                                 entity_type: currentOverrideItem.type,
                                                 entity_id: currentOverrideItem.item.id,
                                                 stat_key: key,
                                                 stat_value: newVal
                                               });
                                             }
                                             fetchRelations();
                                           }}
                                           className={`px-2 py-1 rounded-lg text-[8px] font-black uppercase tracking-wider transition-all border ${
                                             isSelected 
                                               ? 'bg-indigo-600/30 border-indigo-500 text-indigo-400' 
                                               : 'bg-white/5 border-white/5 text-gray-500 hover:border-white/10 hover:text-white'
                                           }`}
                                         >
                                           {cat}
                                         </button>
                                       );
                                     })}
                                   </div>
                                 ) : key.includes('sprite') || key.includes('icon') ? (
                                   <div className="flex-1 flex items-center gap-3">
                                     <div className="w-10 h-10 bg-black/40 rounded-xl border border-white/5 flex items-center justify-center overflow-hidden">
                                       {override?.stat_value ? (
                                         <div className="w-full h-full bg-indigo-500/20 flex items-center justify-center text-[8px] font-bold text-indigo-400">IMG</div>
                                       ) : (
                                         <LucideImage className="w-4 h-4 text-gray-700" />
                                       )}
                                     </div>
                                     <button 
                                       type="button"
                                       onClick={() => {
                                         setCurrentSpriteField(key);
                                         setIsSpriteModalOpen(true);
                                       }}
                                       className="flex-1 bg-white/5 hover:bg-white/10 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest text-gray-400 transition-all border border-white/5"
                                     >
                                       {override?.stat_value ? override.stat_value.split('/').pop() : 'Seleccionar Sprite'}
                                     </button>
                                   </div>
                                 ) : (
                                   <input 
                                     type="text"
                                     placeholder="+0.0"
                                     className="w-full bg-transparent border-none text-center text-sm font-black text-indigo-400 outline-none"
                                     defaultValue={override?.stat_value || ''}
                                     onBlur={async (e) => {
                                       const newVal = e.target.value;
                                       if (newVal === '') {
                                         if (override) await removeRelation('game_civilization_overrides', { id: override.id });
                                       } else {
                                         if (override) {
                                            await api.update('game_civilization_overrides', override.id, { stat_value: newVal });
                                         } else {
                                            await addRelation('game_civilization_overrides', {
                                              civilization_id: selectedItem.id,
                                              entity_type: currentOverrideItem.type,
                                              entity_id: currentOverrideItem.item.id,
                                              stat_key: key,
                                              stat_value: newVal
                                            });
                                         }
                                       }
                                       fetchRelations();
                                     }}
                                   />
                                 )}
                               </div>
                            </div>
                            <div className="col-span-3 text-right">
                               <div className={`text-xl font-black italic tracking-tighter ${override ? 'text-emerald-400 animate-pulse' : 'text-white'}`}>
                                  {isNumeric && typeof total === 'number' ? total.toFixed(1) : total}
                               </div>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                );
              });
            })()}
          </div>
        </div>

        <div className="p-12 border-t border-white/5 bg-white/2 flex justify-end">
          <button onClick={onClose} className="bg-indigo-600 hover:bg-indigo-500 text-white px-16 py-6 rounded-3xl font-black text-xs uppercase tracking-[0.3em] transition-all">
            Finalizar Balance
          </button>
        </div>
      </div>
    </div>
  );
}
