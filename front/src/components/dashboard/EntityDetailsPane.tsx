import React from 'react';
import { ArrowLeft, Database, Info, Sparkles, Trash2, Plus, TrendingUp, AlertTriangle, Share2, FlaskConical } from 'lucide-react';
import { TABLES, TAB_ICONS } from '@/lib/constants';
import TechTreeEditor from '../editors/TechTreeEditor';
import { AdvancedEffectSection, ProductionBonusSection, AdvancedProductionSection } from '../editors/AdvancedSections';

interface EntityDetailsPaneProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
  selectedItem: any;
  setSelectedItem: (item: any) => void;
  availableItems: any;
  selectedCivId: string;
  setSelectedCivId: (id: string) => void;
  setEditingItem: (item: any) => void;
  setIsModalOpen: (open: boolean) => void;
  relations: any;
  fetchRelations: () => void;
  fetchAvailableItems: () => void;
  handleSave: (item: any) => void;
  addRelation: (table: string, payload: any) => Promise<any>;
  removeRelation: (table: string, payload: any) => Promise<any>;
  setCurrentOverrideItem: (item: any) => void;
  setIsOverrideModalOpen: (open: boolean) => void;
  setPromptModal: (modal: any) => void;
  setPromptValues: (values: any) => void;
  api: any;
}

export default function EntityDetailsPane({
  activeTab, setActiveTab, selectedItem, setSelectedItem, availableItems, selectedCivId, setSelectedCivId,
  setEditingItem, setIsModalOpen, relations, fetchRelations, fetchAvailableItems, handleSave,
  addRelation, removeRelation, setCurrentOverrideItem, setIsOverrideModalOpen, setPromptModal, setPromptValues, api
}: EntityDetailsPaneProps) {

  return (
    <div className="flex-1 flex flex-col overflow-hidden relative">
      <div className="absolute top-[-10%] right-[-10%] w-[40%] h-[40%] bg-yellow-600/10 blur-[120px] rounded-full pointer-events-none" />
      <div className="absolute bottom-[-10%] left-[-10%] w-[30%] h-[30%] bg-green-600/5 blur-[100px] rounded-full pointer-events-none" />

      <header className="h-24 glass border-b border-zinc-900 flex items-center justify-between px-6 shrink-0 z-10">
        <div className="flex items-center gap-6">
          <button onClick={() => setSelectedItem(null)} className="p-3 hover:bg-zinc-900 rounded-sm transition-all group">
            <ArrowLeft className="w-6 h-6 group-hover:-translate-x-1 transition-transform" />
          </button>
          <div className="flex items-center gap-4">
            <div className="p-3 bg-yellow-600/20 rounded-sm border border-yellow-500/30 text-yellow-400">
              {TAB_ICONS[activeTab]}
            </div>
            <div>
              <h2 className="text-2xl font-black tracking-tight text-zinc-50">{selectedItem.name || selectedItem.id}</h2>
              <div className="flex items-center gap-2 mt-1">
                <span className="text-[10px] text-yellow-400 font-black uppercase tracking-widest">{activeTab.slice(0, -1)}</span>
                <span className="w-1 h-1 bg-gray-700 rounded-full" />
                <span className="text-[10px] text-zinc-400 font-bold">{selectedItem.category || 'General'}</span>
              </div>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-4">
          {activeTab !== 'civilizations' && (
            <div className="flex items-center gap-3 bg-zinc-900 p-1.5 rounded-sm border border-zinc-900">
              <span className="text-[10px] font-black uppercase tracking-widest text-zinc-400 ml-3">Contexto Civ:</span>
              <select 
                value={selectedCivId}
                onChange={(e) => setSelectedCivId(e.target.value)}
                className="bg-transparent border-0 text-xs font-bold px-4 py-2 rounded-sm outline-none text-emerald-400 focus:ring-1 focus:ring-green-500/50"
              >
                {availableItems.civs?.map((c: any) => (
                  <option key={c.id} value={c.id} className="bg-zinc-900">{c.name}</option>
                ))}
              </select>
            </div>
          )}
          <button 
            onClick={() => { setEditingItem({...selectedItem}); setIsModalOpen(true); }}
            className="bg-yellow-600 hover:bg-yellow-500 text-zinc-50 px-6 py-3 rounded-sm font-black text-xs uppercase tracking-widest transition-all shadow-lg shadow-yellow-900/40"
          >
            Editar Perfil
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6 scrollbar-hide z-0">
        <div className="max-w-7xl mx-auto space-y-10">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            <section className="lg:col-span-4 glass p-8 rounded-sm relative overflow-hidden group border-zinc-900">
              <div className="absolute top-0 right-0 p-8 opacity-5 group-hover:opacity-10 transition-opacity">
                <Database className="w-32 h-32" />
              </div>
              <h3 className="text-lg font-black mb-8 flex items-center gap-3 text-zinc-50">
                <Info className="w-5 h-5 text-yellow-400" />
                Atributos Core
              </h3>
              <div className="space-y-4">
                {Object.entries(selectedItem).filter(([k]) => k !== 'bonuses' && k !== 'description').slice(0, 10).map(([key, value]) => (
                  <div key={key} className="flex justify-between items-center py-3 border-b border-zinc-900 last:border-0 group/item">
                    <span className="text-[10px] text-zinc-400 font-black uppercase tracking-widest group-hover/item:text-yellow-400 transition-colors">{key.replace(/_/g, ' ')}</span>
                    {key === 'required_technologies' && Array.isArray(value) ? (
                      <div className="flex flex-wrap gap-1.5 justify-end max-w-[60%]">
                        {value.length > 0 ? (
                          value.map((techId: string) => {
                            const techObj = availableItems.techs?.find((t: any) => t.id === techId);
                            return (
                              <span key={techId} className="text-[9px] font-bold text-yellow-400 bg-yellow-500/10 border border-yellow-500/25 px-2.5 py-1 rounded-full">
                                {techObj ? techObj.name : techId}
                              </span>
                            );
                          })
                        ) : (
                          <span className="text-xs text-zinc-400 font-medium italic">Ninguna</span>
                        )}
                      </div>
                    ) : (
                      <span className="text-sm text-zinc-300 font-mono font-bold bg-zinc-900 px-3 py-1 rounded-sm">
                        {typeof value === 'object' ? JSON.stringify(value) : String(value || '-')}
                      </span>
                    )}
                  </div>
                ))}
              </div>
            </section>

            <div className="lg:col-span-8 space-y-10">
               {activeTab === 'civilizations' && (
                 <section className="glass p-8 rounded-sm border-zinc-900">
                    <div className="flex justify-between items-center mb-8">
                      <h3 className="text-lg font-black flex items-center gap-3 text-zinc-50">
                        <Sparkles className="w-5 h-5 text-amber-400" />
                        Bonos de Facción
                      </h3>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {(selectedItem.bonuses || []).map((bonus: any, idx: number) => (
                        <div key={idx} className="bg-zinc-900 p-6 rounded-sm border border-zinc-900 hover:border-amber-500/30 transition-all group relative">
                          <p className="text-sm font-black text-amber-400 mb-2">{bonus.name || 'Bonus'}</p>
                          <p className="text-xs text-gray-400 leading-relaxed font-medium">{bonus.description}</p>
                          <button 
                            onClick={async () => {
                              const newBonuses = selectedItem.bonuses.filter((_: any, i: number) => i !== idx);
                              const updated = await api.update(TABLES.civilizations, selectedItem.id, { bonuses: newBonuses });
                              setSelectedItem(updated);
                            }}
                            className="absolute top-4 right-4 opacity-0 group-hover:opacity-100 p-2 text-red-500/50 hover:text-red-500 hover:bg-red-500/10 rounded-sm transition-all"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      ))}
                      <button 
                        onClick={() => {
                          setPromptValues({});
                          setPromptModal({
                            title: 'Nuevo Bonus de Facción',
                            fields: [
                              { key: 'name', label: 'Nombre del Bonus', placeholder: 'Ej: Legiones Reforzadas' },
                              { key: 'description', label: 'Descripción', placeholder: 'Describe el efecto del bonus...' }
                            ],
                            onConfirm: async (values: any) => {
                              if (values.name && values.description) {
                                const newBonuses = [...(selectedItem.bonuses || []), { name: values.name, description: values.description }];
                                const updated = await api.update(TABLES.civilizations, selectedItem.id, { bonuses: newBonuses });
                                setSelectedItem(updated);
                              }
                              setPromptModal(null);
                            }
                          });
                        }}
                        className="h-full min-h-[120px] flex flex-col items-center justify-center gap-3 border-2 border-dashed border-zinc-900 rounded-sm text-zinc-400 hover:text-yellow-400 hover:border-yellow-500/30 hover:bg-yellow-500/5 transition-all group"
                      >
                        <Plus className="w-6 h-6 group-hover:scale-110 transition-transform" />
                        <span className="text-[10px] font-black uppercase tracking-widest">Nuevo Bonus</span>
                      </button>
                    </div>
                  </section>
               )}

               {(activeTab !== 'civilizations') && (
                 <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <section className="glass p-6 rounded-sm border-zinc-900 space-y-8">
                       <div className="flex items-center gap-4">
                         <div className="p-3 bg-purple-600/20 rounded-sm text-purple-400">
                           <TrendingUp className="w-5 h-5" />
                         </div>
                         <div>
                           <h3 className="text-xl font-black text-zinc-50 italic">Línea de Evolución</h3>
                           <p className="text-[10px] text-zinc-400 font-black uppercase tracking-widest">¿En qué se convierte este elemento al subir de nivel?</p>
                         </div>
                       </div>
                       
                       <div className="space-y-4">
                         <label className="text-[10px] font-black text-zinc-400 uppercase tracking-widest block ml-2">Evoluciona a:</label>
                         <select 
                           value={selectedItem.upgrades_to || ''}
                           onChange={(e) => handleSave({ ...selectedItem, upgrades_to: e.target.value || null })}
                           className="w-full bg-zinc-900 border border-zinc-800 rounded-sm px-6 py-4 text-sm font-bold focus:border-purple-500 outline-none transition-all text-zinc-100"
                         >
                           <option value="">(Sin evolución)</option>
                           {availableItems[activeTab as keyof typeof availableItems]?.filter((i: any) => i.id !== selectedItem.id).map((i: any) => (
                             <option key={i.id} value={i.id}>{i.name}</option>
                           ))}
                         </select>
                         {selectedItem.upgrades_to && (
                           <p className="text-[9px] text-purple-400 font-black uppercase italic animate-pulse">
                             Sustituirá a {selectedItem.name} en el juego final.
                           </p>
                         )}
                       </div>
                    </section>

                    <section className="glass p-6 rounded-sm border-zinc-900 space-y-8">
                       <div className="flex items-center gap-4">
                         <div className="p-3 bg-yellow-600/20 rounded-sm text-yellow-400">
                           <AlertTriangle className="w-5 h-5" />
                         </div>
                         <div>
                           <h3 className="text-xl font-black text-zinc-50 italic">Condiciones Requeridas</h3>
                           <p className="text-[10px] text-zinc-400 font-black uppercase tracking-widest">Edificios o mejoras necesarias para desbloquear</p>
                         </div>
                       </div>

                       <div className="space-y-4">
                          <div className="max-h-[150px] overflow-y-auto space-y-2 pr-2 scrollbar-hide">
                            {relations.requirements?.length > 0 ? (
                              relations.requirements.map((req: any) => {
                                const rName = availableItems.buildings?.find((b: any) => b.id === req.required_entity_id)?.name || 
                                             availableItems.techs?.find((t: any) => t.id === req.required_entity_id)?.name || 
                                             req.required_entity_id;
                                return (
                                  <div key={req.id} className="flex items-center justify-between p-4 bg-zinc-900/40 rounded-sm border border-zinc-900 group">
                                    <div className="flex items-center gap-3">
                                      <div className="w-1.5 h-1.5 bg-yellow-500 rounded-full" />
                                      <span className="text-xs font-black text-zinc-50">{rName}</span>
                                      <span className="text-[8px] bg-zinc-900 px-2 py-0.5 rounded text-zinc-400 uppercase">{req.required_entity_type}</span>
                                    </div>
                                    <button 
                                      onClick={() => removeRelation('game_requirements', { id: req.id })}
                                      className="opacity-0 group-hover:opacity-100 p-2 hover:bg-red-500/20 text-red-500 rounded-sm transition-all"
                                    >
                                      <Trash2 className="w-4 h-4" />
                                    </button>
                                  </div>
                                );
                              })
                            ) : (
                              <div className="p-6 border-2 border-dashed border-zinc-900 rounded-sm text-center">
                                <p className="text-[9px] font-black text-gray-600 uppercase tracking-widest">Sin requisitos adicionales</p>
                              </div>
                            )}
                          </div>

                          <div className="flex gap-2">
                             <select id="new-req-type" className="bg-zinc-900 border border-zinc-800 rounded-sm px-4 py-3 text-[10px] font-bold outline-none text-zinc-100">
                               <option value="building">Edificio</option>
                               <option value="technology">Mejora</option>
                             </select>
                             <select id="new-req-id" className="flex-1 bg-zinc-900 border border-zinc-800 rounded-sm px-4 py-3 text-[10px] font-bold outline-none text-zinc-100">
                               <option value="">Seleccionar...</option>
                               {(availableItems.buildings || []).concat(availableItems.techs || []).map((i: any) => (
                                 <option key={i.id} value={i.id}>{i.name}</option>
                               ))}
                             </select>
                             <button 
                              onClick={() => {
                                const typeEl = document.getElementById('new-req-type') as HTMLSelectElement;
                                const idEl = document.getElementById('new-req-id') as HTMLSelectElement;
                                if (idEl.value) {
                                  addRelation('game_requirements', {
                                    entity_id: selectedItem.id,
                                    entity_type: activeTab.slice(0, -1),
                                    required_entity_id: idEl.value,
                                    required_entity_type: typeEl.value,
                                    civilization_id: selectedCivId
                                  });
                                }
                              }}
                              className="bg-yellow-600 p-3 rounded-sm hover:bg-yellow-500 transition-all shadow-lg shadow-yellow-900/40"
                             >
                               <Plus className="w-5 h-5 text-zinc-50" />
                             </button>
                          </div>
                       </div>
                    </section>
                 </div>
               )}

               {activeTab === 'technologies' && (
                 <AdvancedEffectSection 
                    title="Efectos de Investigación"
                    subtitle="Define a qué unidades y categorías afecta esta mejora"
                    effects={relations.effects || []}
                    civs={availableItems.civs || []}
                    units={availableItems.units || []}
                    selectedCivId={selectedCivId}
                    onAdd={(eff: any) => addRelation('game_technology_effects', { ...eff, technology_id: selectedItem.id })}
                    onRemove={(id: any) => removeRelation('game_technology_effects', { id })}
                 />
               )}

               {activeTab === 'buildings' && (
                 <ProductionBonusSection 
                    title="Bonos de Entrenamiento"
                    subtitle="Bonos automáticos para unidades producidas aquí"
                    bonuses={relations.bonuses || []}
                    civs={availableItems.civs || []}
                    selectedCivId={selectedCivId}
                    onAdd={(bonus: any) => addRelation('building_production_bonuses', { ...bonus, building_id: selectedItem.id })}
                    onRemove={(id: any) => removeRelation('building_production_bonuses', { id })}
                 />
               )}
            </div>
          </div>

          <div className="space-y-10">
            {activeTab === 'civilizations' && (
               <div className="space-y-10">
                  <section className="space-y-6">
                    <div className="flex items-center gap-4">
                      <div className="p-3 bg-yellow-600/20 rounded-sm text-yellow-400">
                        <Share2 className="w-5 h-5" />
                      </div>
                      <div>
                        <h3 className="text-xl font-black text-zinc-50 italic">Diseñador de Árbol Tecnológico</h3>
                        <p className="text-[10px] text-zinc-400 font-black uppercase tracking-widest">Gestiona visualmente las dependencias de producción e investigación</p>
                      </div>
                    </div>
                    <TechTreeEditor 
                      civilization={selectedItem}
                      relations={relations}
                      available={availableItems}
                      onAddRelation={addRelation}
                      onRemoveRelation={removeRelation}
                      onUpdateItem={async (type: any, id: string, payload: any) => {
                        if (type === 'select') {
                          setActiveTab(payload.type);
                          const item = availableItems[payload.type as keyof typeof availableItems].find((i: any) => i.id === id);
                          if (item) setSelectedItem(item);
                          return;
                        }
                        await api.update(TABLES[type as keyof typeof TABLES], id, payload);
                        fetchRelations();
                        fetchAvailableItems();
                      }}
                    />
                  </section>

                  <section className="glass p-6 rounded-sm border-zinc-900 space-y-12">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-6">
                        <div className="bg-yellow-600 p-4 rounded-sm shadow-xl shadow-yellow-900/40">
                          <FlaskConical className="w-6 h-6 text-zinc-50" />
                        </div>
                        <div>
                          <h3 className="text-xl font-black text-zinc-50 italic tracking-tight uppercase">Laboratorio de Personalización</h3>
                          <p className="text-[10px] text-yellow-400 font-black uppercase tracking-[0.4em] mt-2">Ajustes de balance y atributos exclusivos por facción</p>
                        </div>
                      </div>
                    </div>

                    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                      {['building', 'unit', 'technology'].map(type => { 
                        const availableKey = type === 'technology' ? 'techs' : (type === 'technology' ? 'technologies' : `${type}s`);
                        const plural = type === 'technology' ? 'technologies' : `${type}s`;
                        return (
                        <div key={type} className="space-y-6">
                           <div className="flex items-center gap-4 px-4">
                             <span className="text-[10px] font-black uppercase tracking-[0.3em] text-zinc-400">{type === 'technology' ? 'Investigaciones' : plural}</span>
                             <div className="h-px bg-zinc-900 flex-1" />
                           </div>

                           <div className="space-y-4">
                              {availableItems[(availableKey as keyof typeof availableItems)]?.filter((item: any) => {
                                if (type === 'building') return (relations.buildings || []).some((b: any) => b.building_id === item.id);
                                if (type === 'unit') return (relations.units || []).some((u: any) => u.unit_id === item.id) || (relations.production || []).some((p: any) => p.unit_id === item.id);
                                if (type === 'technology') return (relations.researches_civ || []).some((r: any) => r.technology_id === item.id);
                                return true;
                              }).map((item: any) => (
                                <div key={item.id} className="bg-zinc-900/40 border border-zinc-900 rounded-sm p-6 space-y-4 group">
                                  <div className="flex items-center justify-between">
                                    <h4 className="text-sm font-black text-zinc-50 uppercase tracking-wider">{item.name}</h4>
                                    <button 
                                      onClick={() => {
                                        setCurrentOverrideItem({ type, item });
                                        setIsOverrideModalOpen(true);
                                      }}
                                      className="p-2 hover:bg-white/10 rounded-sm text-zinc-400 hover:text-yellow-400 transition-all flex items-center gap-2 text-[10px] font-black uppercase tracking-widest"
                                    >
                                      Ajustar Atributos <Plus className="w-3.5 h-3.5" />
                                    </button>
                                  </div>

                                  <div className="space-y-2">
                                    {relations.unifiedOverrides?.filter((o: any) => o.entity_type === type && o.entity_id === item.id).map((ov: any) => (
                                      <div key={ov.id} className="flex items-center justify-between bg-black/20 px-4 py-2.5 rounded-sm border border-zinc-900 text-[9px] group/item">
                                        <div className="flex items-center gap-3">
                                          <span className="text-zinc-400 uppercase font-black">{ov.stat_key}:</span>
                                          <span className="text-emerald-400 font-bold">{ov.stat_value}</span>
                                        </div>
                                        <button 
                                          onClick={() => removeRelation('game_civilization_overrides', { id: ov.id })}
                                          className="opacity-0 group-hover/item:opacity-100 text-red-500 hover:scale-110 transition-all"
                                        >
                                          <Trash2 className="w-3.5 h-3.5" />
                                        </button>
                                      </div>
                                    ))}
                                  </div>
                                </div>
                              ))}
                           </div>
                        </div>
                       );
                     })}
                    </div>
                  </section>
               </div>
            )}

            {(activeTab === 'buildings') && (
              <div className="grid grid-cols-1 gap-6">
                <AdvancedProductionSection 
                  title="Líneas de Producción"
                  subtitle={`Unidades que se pueden crear en este edificio para ${availableItems.civs?.find((c: any) => c.id === selectedCivId)?.name}`}
                  items={relations.produces || []}
                  available={availableItems.units || []}
                  civId={selectedCivId}
                  onAdd={(unitId: any) => addRelation('building_produces_units', { building_id: selectedItem.id, unit_id: unitId, civilization_id: selectedCivId })}
                  onRemove={(unitId: any) => removeRelation('building_produces_units', { building_id: selectedItem.id, unit_id: unitId, civilization_id: selectedCivId })}
                />
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
