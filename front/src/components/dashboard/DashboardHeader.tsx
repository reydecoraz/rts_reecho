import React from 'react';
import { Search, Plus } from 'lucide-react';

interface DashboardHeaderProps {
  activeTab: string;
  dataLength: number;
  searchTerm: string;
  setSearchTerm: (term: string) => void;
  onAddClick: () => void;
}

export default function DashboardHeader({ 
  activeTab, 
  dataLength, 
  searchTerm, 
  setSearchTerm,
  onAddClick
}: DashboardHeaderProps) {
  return (
    <header className="h-28 glass border-b border-zinc-900 flex items-center justify-between px-12 shrink-0 z-10">
      <div>
        <h2 className="text-4xl font-black capitalize tracking-tight italic flex items-center gap-4">
          {activeTab}
          <span className="text-yellow-600">.</span>
        </h2>
        <div className="flex items-center gap-2 mt-2">
          <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
          <p className="text-[10px] text-zinc-400 font-bold uppercase tracking-widest">Base de Datos Activa • {dataLength} Registros</p>
        </div>
      </div>

      <div className="flex items-center gap-6">
        <div className="relative group">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-zinc-400 group-focus-within:text-yellow-400 transition-colors" />
          <input 
            type="text" 
            placeholder="Buscar en el motor..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="bg-zinc-900 border border-zinc-900 rounded-sm pl-12 pr-6 py-3.5 text-xs font-bold w-64 focus:bg-white/10 focus:border-yellow-500/50 outline-none transition-all placeholder:text-gray-600"
          />
        </div>
        <button 
          onClick={onAddClick}
          className="flex items-center gap-3 bg-yellow-600 hover:bg-yellow-500 text-zinc-50 px-8 py-4 rounded-sm font-black text-xs uppercase tracking-widest transition-all shadow-xl shadow-yellow-900/40 hover:scale-105 active:scale-95"
        >
          <Plus className="w-5 h-5" />
          <span>Añadir Nuevo</span>
        </button>
      </div>
    </header>
  );
}
