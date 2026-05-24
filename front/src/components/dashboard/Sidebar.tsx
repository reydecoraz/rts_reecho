import React from 'react';
import { Layers, Database } from 'lucide-react';
import { TABLES, TAB_ICONS } from '@/lib/constants';

interface SidebarProps {
  activeTab: string;
  setActiveTab: (tab: any) => void;
}

export default function Sidebar({ activeTab, setActiveTab }: SidebarProps) {
  return (
    <aside className="w-80 glass border-r border-zinc-900 flex flex-col shrink-0 z-20">
        <div className="p-6 flex items-center gap-4">
          <div className="bg-yellow-600 p-3 rounded-[1.25rem] shadow-xl shadow-yellow-900/30 animate-float">
            <Layers className="text-zinc-50 w-6 h-6" />
          </div>
          <div>
            <h1 className="text-2xl font-black tracking-tight text-zinc-50 italic">RTS ENGINE</h1>
            <p className="text-[10px] text-yellow-500 font-black uppercase tracking-[0.3em]">Core Manager</p>
          </div>
        </div>
        
        <nav className="flex-1 px-6 space-y-4 mt-10">
          {Object.keys(TABLES).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`w-full flex items-center gap-5 px-6 py-3 rounded-sm transition-all duration-500 group relative overflow-hidden ${
                activeTab === tab 
                ? 'tab-active text-zinc-50 scale-105' 
                : 'text-zinc-400 hover:bg-zinc-900 hover:text-gray-300'
              }`}
            >
              <span className={activeTab === tab ? 'text-zinc-50' : 'text-gray-600 group-hover:text-yellow-400 transition-colors'}>
                {TAB_ICONS[tab as keyof typeof TABLES]}
              </span>
              <span className="capitalize font-black tracking-widest text-xs">{tab}</span>
              {activeTab === tab && <div className="absolute right-0 w-1 h-8 bg-white rounded-full mr-2" />}
            </button>
          ))}
        </nav>

        <div className="p-6 border-t border-zinc-900">
          <div className="flex items-center gap-4 text-xs text-zinc-400 group cursor-pointer hover:text-gray-300 transition-all">
            <div className="p-2.5 bg-zinc-900 rounded-sm group-hover:bg-yellow-600/20 group-hover:text-yellow-400 transition-all">
              <Database className="w-4 h-4" />
            </div>
            <div>
              <p className="font-bold">Sync Activa</p>
              <p className="text-[10px] text-green-500">Conectado al Core</p>
            </div>
          </div>
        </div>
    </aside>
  );
}
