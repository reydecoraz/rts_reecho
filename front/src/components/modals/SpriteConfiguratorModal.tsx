"use client";

import React, { useState, useMemo, useRef } from 'react';
import { Sparkles, X, Upload, Image as LucideImage, Layers, Hammer, Flame, Beaker, Zap, Info } from 'lucide-react';
import SpriteGenerator from '../editors/SpriteGenerator';
import { uploadSprite } from '@/lib/supabaseStorage';
import toast from 'react-hot-toast';

// ─── Types ───────────────────────────────────────────────────────
interface SpriteConfiguratorModalProps {
  isOpen: boolean;
  onClose: () => void;
  entityType: string;
  entityName: string;
  entityId: string;
  civId: string;
  spriteConfig: any;
  onUpdateConfig: (category: string, subKey: string, value: any) => Promise<void>;
}

type TabId = 'generate' | 'default' | 'animations' | 'stages';

const DIRECTIONS = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'] as const;
const ACTIONS = ['idle', 'walk', 'attack', 'death'] as const;
const CONSTRUCTION_STAGES = [0, 25, 50, 75, 100] as const;
const DAMAGE_STAGES = [100, 75, 50, 25] as const;

// ─── Reusable Upload Slot ────────────────────────────────────────
function UploadSlot({ 
  currentUrl, label, accent = 'indigo', size = 'md',
  onUpload, onUrlChange, icon: Icon 
}: {
  currentUrl: string;
  label: string;
  accent?: string;
  size?: 'sm' | 'md' | 'lg';
  onUpload: (file: File) => void;
  onUrlChange: (url: string) => void;
  icon?: React.ElementType;
}) {
  const fileRef = useRef<HTMLInputElement>(null);
  const sizeMap = { sm: 'w-16 h-16', md: 'w-24 h-24', lg: 'w-32 h-32' };
  const accentMap: Record<string, string> = {
    indigo: 'border-indigo-500/40 bg-indigo-600/20 text-indigo-400',
    emerald: 'border-emerald-500/40 bg-emerald-600/20 text-emerald-400',
    red: 'border-red-500/40 bg-red-600/20 text-red-400',
    amber: 'border-amber-500/40 bg-amber-600/20 text-amber-400',
  };

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <span className="text-[9px] font-black text-gray-500 uppercase tracking-widest">{label}</span>
        {currentUrl && <span className="text-[8px] font-bold text-emerald-500">✓ Asignado</span>}
      </div>
      <div 
        onDragOver={(e) => { e.preventDefault(); e.stopPropagation(); }}
        onDrop={(e) => {
          e.preventDefault(); e.stopPropagation();
          const file = e.dataTransfer.files?.[0];
          if (file) onUpload(file);
        }}
        onClick={() => fileRef.current?.click()}
        className={`${sizeMap[size]} bg-[#06070a] rounded-2xl border border-white/5 hover:${accentMap[accent].split(' ')[0]} cursor-pointer flex items-center justify-center relative overflow-hidden group transition-all`}
      >
        {currentUrl ? (
          <img src={currentUrl} alt={label} className="w-full h-full object-contain p-2" />
        ) : Icon ? (
          <Icon className={`w-8 h-8 text-gray-700 group-hover:text-${accent}-400 transition-colors`} />
        ) : (
          <LucideImage className="w-8 h-8 text-gray-700" />
        )}
        <div className={`absolute inset-0 ${accentMap[accent].split(' ')[1]} opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center justify-center gap-1`}>
          <Upload className="w-4 h-4 text-white" />
          <span className="text-[7px] text-white/80 font-black uppercase">Subir</span>
        </div>
        <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={(e) => { const f = e.target.files?.[0]; if (f) onUpload(f); }} />
      </div>
      <input 
        type="text"
        placeholder="URL del sprite"
        className={`w-full bg-white/3 border border-white/5 rounded-xl px-3 py-2 text-[9px] font-bold outline-none focus:border-${accent}-500 transition-all text-${accent}-400 placeholder:text-gray-700`}
        defaultValue={currentUrl}
        key={currentUrl}
        onBlur={(e) => onUrlChange(e.target.value)}
      />
    </div>
  );
}

// ─── Main Component ──────────────────────────────────────────────
export default function SpriteConfiguratorModal({
  isOpen, onClose, entityType, entityName, entityId, civId,
  spriteConfig, onUpdateConfig
}: SpriteConfiguratorModalProps) {
  const isUnit = entityType === 'unit' || entityType === 'units';
  const isBuilding = entityType === 'building' || entityType === 'buildings';

  const tabs: { id: TabId; label: string; icon: React.ElementType }[] = useMemo(() => {
    const base: { id: TabId; label: string; icon: React.ElementType }[] = [
      { id: 'generate', label: 'AI Generator', icon: Sparkles },
      { id: 'default', label: 'Sprite Base', icon: LucideImage },
    ];
    if (isUnit) base.push({ id: 'animations', label: 'Animaciones', icon: Layers });
    if (isBuilding) base.push({ id: 'stages', label: 'Etapas', icon: Hammer });
    return base;
  }, [isUnit, isBuilding]);

  const [activeTab, setActiveTab] = useState<TabId>('generate');

  const handleUpload = async (file: File, category: string, subKey: string) => {
    try {
      const safeName = subKey.replace(/\./g, '_');
      const ext = file.name.split('.').pop() || 'png';
      const path = `${civId}/${entityType}/${entityId}/${category}_${safeName}.${ext}`;
      const url = await uploadSprite(file, path);
      await onUpdateConfig(category, subKey, url);
      toast.success('Sprite subido');
    } catch (err: any) {
      toast.error('Error: ' + (err.message || 'Upload failed'));
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-[#06070a]/98 backdrop-blur-3xl flex items-center justify-center p-8 z-[300] animate-in fade-in duration-300">
      <div className="bg-[#0f111a] border border-white/10 w-full max-w-6xl rounded-[3rem] shadow-2xl shadow-indigo-900/40 overflow-hidden flex flex-col max-h-[90vh]">
        
        {/* ─── Header ─── */}
        <div className="p-8 border-b border-white/5 flex justify-between items-center bg-white/2 shrink-0">
          <div className="flex items-center gap-6">
            <div className="bg-emerald-600 p-4 rounded-2xl shadow-xl shadow-emerald-900/40">
              <Sparkles className="w-7 h-7 text-white" />
            </div>
            <div>
              <h3 className="text-2xl font-black text-white italic tracking-tighter uppercase">Sprite Configurator</h3>
              <p className="text-[10px] text-emerald-500 mt-1 font-black uppercase tracking-[0.3em]">
                {entityName} • {isUnit ? 'Unidad' : isBuilding ? 'Edificio' : 'Tecnología'}
              </p>
            </div>
          </div>
          <button onClick={onClose} className="p-4 hover:bg-white/5 rounded-2xl transition-all text-gray-500 hover:text-white">
            <X className="w-8 h-8" />
          </button>
        </div>

        {/* ─── Tab Bar ─── */}
        <div className="px-8 pt-6 shrink-0 flex gap-2 bg-white/1">
          {tabs.map(tab => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex items-center gap-2 px-6 py-3 rounded-t-2xl text-[10px] font-black uppercase tracking-widest transition-all border-b-2 ${
                activeTab === tab.id
                  ? 'bg-white/5 text-white border-indigo-500'
                  : 'text-gray-600 hover:text-gray-400 border-transparent hover:bg-white/2'
              }`}
            >
              <tab.icon className="w-4 h-4" />
              {tab.label}
            </button>
          ))}
        </div>

        {/* ─── Content ─── */}
        <div className="flex-1 overflow-y-auto p-8 scrollbar-hide">
          
          {/* TAB: AI Generator */}
          {activeTab === 'generate' && (
            <SpriteGenerator
              onSpriteReady={(url) => onUpdateConfig('meta', 'default_url', url)}
              civId={civId}
              entityType={entityType}
              entityId={entityId}
              fieldKey="default"
            />
          )}

          {/* TAB: Default Sprite */}
          {activeTab === 'default' && (
            <div className="space-y-8">
              <div className="p-8 bg-indigo-600/5 border border-indigo-500/20 rounded-3xl flex items-center gap-8">
                <UploadSlot
                  currentUrl={spriteConfig?.default_url || ''}
                  label="Master Default Sprite"
                  accent="indigo"
                  size="lg"
                  onUpload={(f) => handleUpload(f, 'meta', 'default_url')}
                  onUrlChange={(url) => onUpdateConfig('meta', 'default_url', url)}
                />
                <div className="flex-1 space-y-3">
                  <h4 className="text-lg font-black text-white uppercase italic tracking-wide">Sprite Principal</h4>
                  <p className="text-[10px] text-gray-500 font-bold leading-relaxed">
                    Este sprite se usa como fallback en todos los estados. Es el sprite que se mostrará si no hay 
                    animaciones específicas configuradas. Ideal para testing rápido.
                  </p>
                  <div className="flex items-center gap-2 text-[9px] text-indigo-400 font-bold">
                    <Info className="w-3 h-3" />
                    Puedes generarlo con IA en la pestaña "AI Generator"
                  </div>
                </div>
              </div>

              {/* Tech-specific sprites */}
              {!isUnit && !isBuilding && (
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                  <div className="p-6 bg-white/2 border border-white/5 rounded-3xl">
                    <UploadSlot
                      currentUrl={spriteConfig?.tech_icon || ''}
                      label="Tech Tree Icon"
                      accent="amber"
                      size="md"
                      icon={Beaker}
                      onUpload={(f) => handleUpload(f, 'meta', 'tech_icon')}
                      onUrlChange={(url) => onUpdateConfig('meta', 'tech_icon', url)}
                    />
                  </div>
                  <div className="p-6 bg-white/2 border border-white/5 rounded-3xl">
                    <UploadSlot
                      currentUrl={spriteConfig?.particle_fx_url || ''}
                      label="Particle FX Overlay"
                      accent="amber"
                      size="md"
                      icon={Zap}
                      onUpload={(f) => handleUpload(f, 'meta', 'particle_fx_url')}
                      onUrlChange={(url) => onUpdateConfig('meta', 'particle_fx_url', url)}
                    />
                  </div>
                  <div className="p-6 bg-white/2 border border-white/5 rounded-3xl">
                    <UploadSlot
                      currentUrl={spriteConfig?.hud_banner_url || ''}
                      label="HUD Banner"
                      accent="amber"
                      size="md"
                      icon={Sparkles}
                      onUpload={(f) => handleUpload(f, 'meta', 'hud_banner_url')}
                      onUrlChange={(url) => onUpdateConfig('meta', 'hud_banner_url', url)}
                    />
                  </div>
                </div>
              )}
            </div>
          )}

          {/* TAB: Unit Animations */}
          {activeTab === 'animations' && isUnit && (
            <div className="space-y-12">
              {ACTIONS.map(action => (
                <div key={action} className="space-y-6">
                  <div className="flex items-center gap-3">
                    <div className="h-[2px] flex-1 bg-white/5" />
                    <h4 className="text-lg font-black text-indigo-400 uppercase italic tracking-widest">{action}</h4>
                    <div className="h-[2px] flex-1 bg-white/5" />
                  </div>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    {DIRECTIONS.map(dir => (
                      <div key={dir} className="p-4 bg-white/2 border border-white/5 rounded-2xl hover:border-indigo-500/30 transition-all">
                        <UploadSlot
                          currentUrl={spriteConfig?.animations?.[action]?.[dir] || ''}
                          label={`Dir ${dir}`}
                          accent="indigo"
                          size="sm"
                          onUpload={(f) => handleUpload(f, 'animations', `${action}.${dir}`)}
                          onUrlChange={(url) => onUpdateConfig('animations', `${action}.${dir}`, url)}
                        />
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* TAB: Building Stages */}
          {activeTab === 'stages' && isBuilding && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
              {/* Construction */}
              <div className="space-y-6">
                <div className="flex items-center gap-3">
                  <Hammer className="w-5 h-5 text-emerald-400" />
                  <h4 className="text-lg font-black text-emerald-400 uppercase italic tracking-wide">Construcción</h4>
                </div>
                <div className="space-y-4">
                  {CONSTRUCTION_STAGES.map(stage => (
                    <div key={stage} className="flex items-center gap-4 p-4 bg-white/2 border border-white/5 rounded-2xl hover:border-emerald-500/30 transition-all">
                      <div className="w-12 h-12 bg-emerald-600/10 rounded-xl flex items-center justify-center text-emerald-400 font-black text-sm shrink-0">
                        {stage}%
                      </div>
                      <div className="flex-1">
                        <UploadSlot
                          currentUrl={spriteConfig?.construction?.[stage] || ''}
                          label={`Etapa ${stage}%`}
                          accent="emerald"
                          size="sm"
                          onUpload={(f) => handleUpload(f, 'construction', String(stage))}
                          onUrlChange={(url) => onUpdateConfig('construction', String(stage), url)}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Damage */}
              <div className="space-y-6">
                <div className="flex items-center gap-3">
                  <Flame className="w-5 h-5 text-red-400" />
                  <h4 className="text-lg font-black text-red-400 uppercase italic tracking-wide">Niveles de Daño</h4>
                </div>
                <div className="space-y-4">
                  {DAMAGE_STAGES.map(stage => (
                    <div key={stage} className="flex items-center gap-4 p-4 bg-white/2 border border-white/5 rounded-2xl hover:border-red-500/30 transition-all">
                      <div className="w-12 h-12 bg-red-600/10 rounded-xl flex items-center justify-center text-red-400 font-black text-sm shrink-0">
                        {stage}%
                      </div>
                      <div className="flex-1">
                        <UploadSlot
                          currentUrl={spriteConfig?.damage?.[stage] || ''}
                          label={`HP ${stage}%`}
                          accent="red"
                          size="sm"
                          onUpload={(f) => handleUpload(f, 'damage', String(stage))}
                          onUrlChange={(url) => onUpdateConfig('damage', String(stage), url)}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>

        {/* ─── Footer ─── */}
        <div className="p-6 border-t border-white/5 bg-white/2 flex justify-between items-center shrink-0">
          <div className="flex items-center gap-3 text-[9px] font-bold text-gray-600">
            <Info className="w-4 h-4 text-indigo-500" />
            Sprites recomendados: 64×64 (unidades) • 256×256 (edificios)
          </div>
          <button 
            onClick={onClose} 
            className="bg-indigo-600 hover:bg-indigo-500 text-white px-10 py-4 rounded-2xl font-black text-[10px] uppercase tracking-[0.2em] transition-all shadow-lg shadow-indigo-900/40"
          >
            Guardar y Cerrar
          </button>
        </div>
      </div>
    </div>
  );
}
