import React from 'react';
import { Plus, Edit3 } from 'lucide-react';
import { TAB_ICONS } from '@/lib/constants';

interface EntityListProps {
  loading: boolean;
  activeTab: string;
  filteredData: any[];
  setSelectedItem: (item: any) => void;
  setEditingItem: (item: any) => void;
  setIsModalOpen: (isOpen: boolean) => void;
}

export default function EntityList({
  loading,
  activeTab,
  filteredData,
  setSelectedItem,
  setEditingItem,
  setIsModalOpen
}: EntityListProps) {
  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center h-full gap-6">
        <div className="relative">
           <div className="w-20 h-20 rounded-full border-2 border-yellow-500/20" />
           <div className="absolute inset-0 w-20 h-20 rounded-full border-t-2 border-yellow-500 animate-spin" />
        </div>
        <p className="text-zinc-400 font-black animate-pulse tracking-[0.4em] uppercase text-[10px]">Accediendo al Core...</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-2">
      {/* Encabezado de la lista */}
      <div className="hidden md:flex items-center px-6 py-3 bg-zinc-900 border border-zinc-800 rounded-sm text-[10px] font-black text-zinc-500 uppercase tracking-widest">
        <div className="w-16 flex justify-center">Tipo</div>
        <div className="flex-1">Nombre</div>
        <div className="flex-1 hidden lg:block">Descripción</div>
        <div className="w-32 text-right">Categoría / Era</div>
        <div className="w-24 text-center">Acciones</div>
      </div>
      
      {filteredData.map((item) => (
        <div 
          key={item.id} 
          onClick={() => setSelectedItem(item)}
          className="flex items-center bg-zinc-950/50 hover:bg-zinc-900 px-6 py-4 rounded-sm border border-zinc-900 hover:border-yellow-500/50 cursor-pointer group transition-all"
        >
          <div className="w-16 flex justify-center text-zinc-600 group-hover:text-yellow-500 transition-colors">
            {TAB_ICONS[activeTab]}
          </div>
          
          <div className="flex-1">
            <h3 className="text-sm font-black text-zinc-100 group-hover:text-yellow-400 transition-colors truncate">{item.name || item.id}</h3>
          </div>

          <div className="flex-1 hidden lg:block pr-4">
            <p className="text-xs text-zinc-500 truncate">{item.description || '-'}</p>
          </div>

          <div className="w-32 flex flex-col items-end gap-1">
            <span className="text-[9px] font-black uppercase tracking-wider text-yellow-600/80">
              {item.category || (activeTab === 'civilizations' ? 'Nación' : 'General')}
            </span>
            {item.required_era && (
              <span className="text-[8px] bg-zinc-900 text-zinc-400 px-2 py-0.5 rounded-sm uppercase tracking-tighter">
                {item.required_era}
              </span>
            )}
          </div>

          <div className="w-24 flex justify-end pl-6">
            <button 
              onClick={(e) => { e.stopPropagation(); setEditingItem({...item}); setIsModalOpen(true); }}
              className="p-2 bg-zinc-900 hover:bg-yellow-500 hover:text-black rounded-sm text-zinc-400 transition-all border border-zinc-800"
            >
              <Edit3 className="w-4 h-4" />
            </button>
          </div>
        </div>
      ))}
      
      {/* Quick Create Row */}
      <div 
        onClick={() => { setEditingItem({}); setIsModalOpen(true); }}
        className="flex items-center justify-center gap-3 bg-zinc-950 border border-dashed border-zinc-800 p-4 rounded-sm hover:border-yellow-500/50 hover:bg-yellow-500/10 cursor-pointer text-zinc-600 hover:text-yellow-400 transition-all group"
      >
        <Plus className="w-5 h-5 group-hover:scale-110 transition-transform" />
        <span className="font-black uppercase tracking-[0.2em] text-[10px]">Añadir {activeTab.slice(0, -1)}</span>
      </div>
    </div>
  );
}
