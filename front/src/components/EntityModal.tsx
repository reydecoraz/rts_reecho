import React from 'react';
import { X, Check, Zap, Save, Settings2, Trash2 } from 'lucide-react';

interface EntityModalProps {
  isOpen: boolean;
  onClose: () => void;
  editingItem: any;
  setEditingItem: (item: any) => void;
  handleSave: (e: React.FormEvent) => void;
  activeTab: string;
  data: any[];
  availableItems?: any;
}

export default function EntityModal({
  isOpen,
  onClose,
  editingItem,
  setEditingItem,
  handleSave,
  activeTab,
  data,
  availableItems = {}
}: EntityModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-zinc-950/90 backdrop-blur-2xl flex items-center justify-center p-6 z-[100] animate-in fade-in duration-500">
      <div className="bg-zinc-900 border border-zinc-800 w-full max-w-4xl rounded-sm shadow-2xl shadow-yellow-900/20 overflow-hidden animate-in zoom-in-95 duration-300">
        <div className="p-6 border-b border-zinc-900 flex justify-between items-center bg-zinc-900/40">
          <div>
            <h3 className="text-xl font-black text-zinc-50 italic tracking-tight">
              {editingItem?.id ? 'MODIFICAR CORE' : 'NUEVO REGISTRO'}
            </h3>
            <p className="text-[10px] text-yellow-500 mt-2 font-black uppercase tracking-[0.3em]">Módulo Dinámico • {activeTab}</p>
          </div>
          <button onClick={onClose} className="p-4 hover:bg-zinc-900 rounded-sm transition-all text-zinc-400 hover:text-zinc-50 border border-transparent hover:border-zinc-800">
            <X className="w-8 h-8" />
          </button>
        </div>
        
        <form onSubmit={handleSave} className="p-6 space-y-10">
          <div className="grid grid-cols-2 gap-6 max-h-[55vh] overflow-y-auto px-4 scrollbar-hide">
            {Object.keys(data[0] || { id: '', name: '', description: '' }).map((key) => (
              <div key={key} className={key === 'description' || key === 'lore' || key === 'bonuses' || key === 'base_attributes' || (activeTab === 'technologies' && key === 'required_technologies') ? 'col-span-2' : ''}>
                <label className="block text-[10px] font-black text-zinc-400 uppercase tracking-[0.2em] mb-4 ml-1">
                  {key.replace('_', ' ')}
                </label>
                {key === 'description' || key === 'lore' ? (
                  <textarea
                    value={editingItem[key] || ''}
                    onChange={(e) => setEditingItem({ ...editingItem, [key]: e.target.value })}
                    className="w-full bg-zinc-900 border border-zinc-900 rounded-[2rem] px-8 py-6 text-sm focus:border-yellow-500 focus:ring-2 focus:ring-yellow-500/10 outline-none h-40 resize-none transition-all placeholder:text-gray-700 font-medium text-zinc-50"
                    placeholder={`Definir ${key.replace('_', ' ')} del motor...`}
                  />
                ) : key === 'bonuses' ? (
                  <div className="text-[10px] text-amber-500 font-black uppercase tracking-[0.2em] p-8 bg-amber-500/5 rounded-[2rem] border border-amber-500/20 flex items-center gap-4">
                    <Zap className="w-5 h-5" />
                    Los bonus de facción se gestionan desde la consola de vinculación avanzada.
                  </div>
                ) : key === 'base_attributes' ? (
                  <div className="space-y-4 p-6 bg-zinc-900 border border-zinc-900 rounded-[2rem]">
                     <div className="flex justify-between items-center mb-6">
                        <label className="text-[10px] font-black text-zinc-400 uppercase tracking-[0.2em] flex items-center gap-2">
                           <Settings2 className="w-4 h-4 text-yellow-400" />
                           Atributos Dinámicos
                        </label>
                        <div className="flex gap-2">
                           <select id="new-attr-select" className="bg-zinc-900 border border-zinc-800 rounded-sm px-3 py-1.5 text-[10px] font-bold outline-none text-zinc-50">
                              <option value="">Añadir atributo...</option>
                              {availableItems.attributeDefs?.map((def: any) => (
                                <option key={def.code} value={def.code}>{def.icon || ''} {def.name} ({def.code})</option>
                              ))}
                           </select>
                           <button
                              type="button"
                              onClick={() => {
                                const select = document.getElementById('new-attr-select') as HTMLSelectElement;
                                if (select.value) {
                                   setEditingItem({
                                      ...editingItem,
                                      base_attributes: {
                                         ...(editingItem.base_attributes || {}),
                                         [select.value]: ''
                                      }
                                   });
                                   select.value = '';
                                }
                              }}
                              className="bg-yellow-600 hover:bg-yellow-500 text-zinc-50 px-4 py-1.5 rounded-sm font-black text-[9px] uppercase tracking-widest transition-all"
                           >
                              Añadir
                           </button>
                        </div>
                     </div>
                     <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {Object.entries(editingItem.base_attributes || {}).map(([attrKey, attrVal]) => {
                           const def = availableItems.attributeDefs?.find((d: any) => d.code === attrKey);
                           return (
                              <div key={attrKey} className="flex items-center gap-3 bg-black/20 p-3 rounded-sm border border-zinc-900 group/attr">
                                 <div className="shrink-0 w-10 h-10 flex items-center justify-center bg-zinc-900 rounded-sm text-lg">
                                    {def?.icon || '⚙️'}
                                 </div>
                                 <div className="flex-1">
                                    <p className="text-[9px] font-black text-zinc-400 uppercase">{def?.name || attrKey}</p>
                                    <input
                                       type={def?.type === 'number' ? 'number' : 'text'}
                                       value={attrVal as any}
                                       onChange={(e) => {
                                          const val = def?.type === 'number' ? Number(e.target.value) : e.target.value;
                                          setEditingItem({
                                             ...editingItem,
                                             base_attributes: {
                                                ...editingItem.base_attributes,
                                                [attrKey]: val
                                             }
                                          });
                                       }}
                                       className="w-full bg-transparent border-b border-zinc-800 focus:border-yellow-500 outline-none text-sm font-bold text-zinc-50 py-1 transition-all"
                                       placeholder={def?.type === 'number' ? '0' : 'Valor'}
                                    />
                                 </div>
                                 <button
                                    type="button"
                                    onClick={() => {
                                       const newAttrs = { ...editingItem.base_attributes };
                                       delete newAttrs[attrKey];
                                       setEditingItem({ ...editingItem, base_attributes: newAttrs });
                                    }}
                                    className="opacity-0 group-hover/attr:opacity-100 p-2 text-red-500 hover:bg-red-500/20 rounded-sm transition-all shrink-0"
                                 >
                                    <Trash2 className="w-4 h-4" />
                                 </button>
                              </div>
                           );
                        })}
                        {Object.keys(editingItem.base_attributes || {}).length === 0 && (
                           <div className="col-span-full text-center py-8 text-gray-600 text-[10px] font-black uppercase tracking-widest border border-dashed border-zinc-900 rounded-sm">
                              Sin atributos dinámicos configurados
                           </div>
                        )}
                     </div>
                  </div>
                ) : (activeTab === 'technologies' && key === 'required_technologies') ? (
                  <div className="space-y-4">
                    <div className="flex flex-wrap gap-2 mb-2">
                      {(() => {
                        const currentSelected = Array.isArray(editingItem[key])
                          ? editingItem[key]
                          : typeof editingItem[key] === 'string'
                          ? editingItem[key].replace(/[{}]/g, '').split(',').map((s: string) => s.trim()).filter(Boolean)
                          : [];

                        if (currentSelected.length === 0) {
                          return <span className="text-xs text-zinc-400 italic">Ninguna tecnología requerida seleccionada</span>;
                        }

                        return currentSelected.map((techId: string) => {
                          const techObj = availableItems.techs?.find((t: any) => t.id === techId) || 
                                          data.find((t: any) => t.id === techId);
                          return (
                            <span 
                              key={techId} 
                              className="inline-flex items-center gap-2 bg-yellow-500/10 border border-yellow-500/30 text-yellow-400 px-4 py-2 rounded-full text-xs font-bold"
                            >
                              {techObj ? techObj.name : techId}
                              <button
                                type="button"
                                onClick={() => {
                                  const nextSelected = currentSelected.filter((id: string) => id !== techId);
                                  setEditingItem({
                                    ...editingItem,
                                    [key]: nextSelected
                                  });
                                }}
                                className="hover:text-red-400 transition-colors"
                              >
                                <X className="w-3.5 h-3.5" />
                              </button>
                            </span>
                          );
                        });
                      })()}
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3 p-6 bg-zinc-900 border border-zinc-900 rounded-[2rem] max-h-[220px] overflow-y-auto scrollbar-hide">
                      {(availableItems.techs || data || [])
                        .filter((item: any) => item.id !== editingItem.id)
                        .map((tech: any) => {
                          const currentSelected = Array.isArray(editingItem[key])
                            ? editingItem[key]
                            : typeof editingItem[key] === 'string'
                            ? editingItem[key].replace(/[{}]/g, '').split(',').map((s: string) => s.trim()).filter(Boolean)
                            : [];

                          const isSelected = currentSelected.includes(tech.id);

                          return (
                            <button
                              type="button"
                              key={tech.id}
                              onClick={() => {
                                const nextSelected = isSelected
                                  ? currentSelected.filter((id: string) => id !== tech.id)
                                  : [...currentSelected, tech.id];
                                
                                setEditingItem({
                                  ...editingItem,
                                  [key]: nextSelected
                                });
                              }}
                              className={`flex items-center justify-between p-4 rounded-sm border transition-all text-left ${
                                isSelected
                                  ? 'bg-yellow-600/20 border-yellow-500 text-yellow-400'
                                  : 'bg-zinc-900 border-zinc-900 text-gray-400 hover:border-zinc-800'
                              }`}
                            >
                              <div className="truncate pr-2">
                                <p className="text-xs font-bold leading-tight truncate">{tech.name || tech.id}</p>
                                <p className="text-[9px] text-zinc-400 truncate mt-1">{tech.description || 'Sin descripción'}</p>
                              </div>
                              <div className={`shrink-0 w-5 h-5 rounded-sm border flex items-center justify-center transition-all ${
                                isSelected
                                  ? 'bg-yellow-600 border-yellow-400 text-zinc-50 scale-110'
                                  : 'border-white/20'
                              }`}>
                                {isSelected && <Check className="w-3 h-3 stroke-[3]" />}
                              </div>
                            </button>
                          );
                        })}
                    </div>
                  </div>
                ) : (
                  <input
                    type={typeof (data[0] || {})[key] === 'number' ? 'number' : 'text'}
                    value={editingItem[key] || ''}
                    onChange={(e) => setEditingItem({ ...editingItem, [key]: e.target.value })}
                    className="w-full bg-zinc-900 border border-zinc-900 rounded-sm px-8 py-3 text-sm focus:border-yellow-500 focus:ring-2 focus:ring-yellow-500/10 outline-none transition-all font-bold text-zinc-50"
                    disabled={key === 'id' && data.some(i => i.id === editingItem.id)}
                  />
                )}
              </div>
            ))}
          </div>

          <div className="pt-10 border-t border-zinc-900 flex justify-end gap-6">
            <button 
              type="button"
              onClick={onClose}
              className="px-6 py-3 rounded-sm font-black text-[10px] text-zinc-400 hover:text-zinc-50 hover:bg-zinc-900 uppercase tracking-[0.3em] transition-all"
            >
              Cancelar
            </button>
            <button 
              type="submit"
              className="flex items-center gap-4 bg-yellow-600 hover:bg-yellow-500 text-zinc-50 px-12 py-3 rounded-sm font-black text-[10px] uppercase tracking-[0.3em] transition-all shadow-2xl shadow-yellow-900/40"
            >
              <Save className="w-5 h-5" />
              <span>Sincronizar Cambios</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
