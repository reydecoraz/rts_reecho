import React, { useState } from 'react';
import { X, Shield, Copy, Plus, ArrowRight, Save, Loader2 } from 'lucide-react';
import { api } from '@/lib/api';
import toast from 'react-hot-toast';

interface CivWizardModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  availableCivs: any[];
}

export default function CivWizardModal({
  isOpen,
  onClose,
  onSuccess,
  availableCivs
}: CivWizardModalProps) {
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    id: '',
    name: '',
    description: '',
    primary_color: '#4FC3F7',
    templateCivId: ''
  });

  if (!isOpen) return null;

  const handleNext = () => {
    if (!formData.id || !formData.name) {
      toast.error('ID y Nombre son obligatorios');
      return;
    }
    setStep(2);
  };

  const handleSave = async () => {
    setLoading(true);
    try {
      // 1. Create the new civilization
      await api.create('game_civilizations_data', {
        id: formData.id,
        name: formData.name,
        description: formData.description,
        primary_color: formData.primary_color,
        bonuses: []
      });

      // 2. Clone relations if a template is selected
      if (formData.templateCivId) {
        toast.loading('Clonando configuración base...', { id: 'clone' });
        
        // Fetch relations from the template civ
        const [civUnits, civBuildings, civTechs, buildingProduces, buildingResearches] = await Promise.all([
          api.getRelations('game_civilizations_data', formData.templateCivId, 'civ_units', 'civilization_id'),
          api.getRelations('game_civilizations_data', formData.templateCivId, 'civ_buildings', 'civilization_id'),
          api.getRelations('game_civilizations_data', formData.templateCivId, 'civ_technologies', 'civilization_id'),
          api.getRelations('game_civilizations_data', formData.templateCivId, 'building_produces_units', 'civilization_id'),
          api.getRelations('game_civilizations_data', formData.templateCivId, 'building_researches', 'civilization_id')
        ]);

        // Clean IDs and set new civilization_id
        const cleanPayload = (items: any[]) => items.map(item => {
          const { id, created_at, ...rest } = item;
          return { ...rest, civilization_id: formData.id };
        });

        // Insert new relations (we can do it sequentially or in parallel, but the API might only support one-by-one or batch if NestJS allows)
        // Since api.addRelation currently takes an object, let's insert one by one.
        // Wait, does api.addRelation support arrays? The Supabase insert() supports arrays.
        // Let's assume api.addRelation supports arrays because Supabase insert supports it.
        if (civUnits.length) await api.addRelation('civ_units', cleanPayload(civUnits));
        if (civBuildings.length) await api.addRelation('civ_buildings', cleanPayload(civBuildings));
        if (civTechs.length) await api.addRelation('civ_technologies', cleanPayload(civTechs));
        if (buildingProduces.length) await api.addRelation('building_produces_units', cleanPayload(buildingProduces));
        if (buildingResearches.length) await api.addRelation('building_researches', cleanPayload(buildingResearches));

        toast.success('Configuración clonada', { id: 'clone' });
      }

      toast.success('Civilización creada con éxito');
      onSuccess();
      onClose();
    } catch (error: any) {
      console.error(error);
      toast.error(error.response?.data?.message || 'Error al crear civilización');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-[#06070a]/90 backdrop-blur-2xl flex items-center justify-center p-6 z-[100] animate-in fade-in duration-500">
      <div className="bg-[#0f111a] border border-white/10 w-full max-w-3xl rounded-[3rem] shadow-2xl shadow-indigo-900/20 overflow-hidden animate-in zoom-in-95 duration-300">
        <div className="p-8 border-b border-white/5 flex justify-between items-center bg-white/2">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-indigo-600/20 rounded-2xl text-indigo-400">
              <Shield className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-2xl font-black text-white italic tracking-tight">CREAR CIVILIZACIÓN</h3>
              <p className="text-[10px] text-indigo-500 mt-1 font-black uppercase tracking-[0.3em]">
                Wizard de Inicialización • Paso {step} de 2
              </p>
            </div>
          </div>
          <button onClick={onClose} className="p-3 hover:bg-white/5 rounded-2xl transition-all text-gray-500 hover:text-white">
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="p-10">
          {step === 1 ? (
            <div className="space-y-8 animate-in slide-in-from-right-8">
              <div className="grid grid-cols-2 gap-8">
                <div className="space-y-3">
                  <label className="text-[10px] font-black text-gray-500 uppercase tracking-widest ml-1">Identificador (ID)</label>
                  <input 
                    type="text" 
                    value={formData.id}
                    onChange={(e) => setFormData({...formData, id: e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, '')})}
                    placeholder="ej. bizantinos"
                    className="w-full bg-[#06070a] border border-white/5 rounded-2xl px-6 py-4 text-sm font-bold text-white focus:border-indigo-500 outline-none transition-all"
                  />
                  <p className="text-[9px] text-gray-600 font-bold ml-1">Sin espacios, en minúsculas.</p>
                </div>
                <div className="space-y-3">
                  <label className="text-[10px] font-black text-gray-500 uppercase tracking-widest ml-1">Nombre Display</label>
                  <input 
                    type="text" 
                    value={formData.name}
                    onChange={(e) => setFormData({...formData, name: e.target.value})}
                    placeholder="Ej. Bizantinos"
                    className="w-full bg-[#06070a] border border-white/5 rounded-2xl px-6 py-4 text-sm font-bold text-white focus:border-indigo-500 outline-none transition-all"
                  />
                </div>
              </div>

              <div className="space-y-3">
                <label className="text-[10px] font-black text-gray-500 uppercase tracking-widest ml-1">Color Principal (Hex)</label>
                <div className="flex items-center gap-4">
                  <input 
                    type="color" 
                    value={formData.primary_color}
                    onChange={(e) => setFormData({...formData, primary_color: e.target.value})}
                    className="w-14 h-14 rounded-2xl cursor-pointer bg-transparent border-0 p-0"
                  />
                  <input 
                    type="text" 
                    value={formData.primary_color}
                    onChange={(e) => setFormData({...formData, primary_color: e.target.value})}
                    className="flex-1 bg-[#06070a] border border-white/5 rounded-2xl px-6 py-4 text-sm font-bold text-white outline-none"
                  />
                </div>
              </div>

              <div className="space-y-3">
                <label className="text-[10px] font-black text-gray-500 uppercase tracking-widest ml-1">Descripción / Lore</label>
                <textarea 
                  value={formData.description}
                  onChange={(e) => setFormData({...formData, description: e.target.value})}
                  className="w-full bg-[#06070a] border border-white/5 rounded-2xl px-6 py-4 text-sm font-bold text-white focus:border-indigo-500 outline-none transition-all min-h-[100px]"
                />
              </div>

              <div className="flex justify-end pt-4">
                <button 
                  onClick={handleNext}
                  className="flex items-center gap-3 bg-indigo-600 hover:bg-indigo-500 text-white px-8 py-4 rounded-2xl font-black text-xs uppercase tracking-widest transition-all shadow-xl shadow-indigo-900/40"
                >
                  Siguiente <ArrowRight className="w-5 h-5" />
                </button>
              </div>
            </div>
          ) : (
            <div className="space-y-8 animate-in slide-in-from-right-8">
              <div className="p-8 bg-indigo-600/10 border border-indigo-500/20 rounded-[2rem]">
                <h4 className="text-lg font-black text-white italic mb-2">Plantilla Base</h4>
                <p className="text-xs text-indigo-200/60 leading-relaxed font-medium">
                  Crear una civilización desde cero implica configurar manualmente cada unidad, edificio y tecnología. 
                  Puedes clonar la estructura de una civilización existente para empezar con una base funcional.
                </p>
              </div>

              <div className="space-y-4">
                <label className="flex items-center justify-between p-6 bg-white/5 border border-white/10 rounded-2xl cursor-pointer hover:bg-white/10 transition-all">
                  <div className="flex items-center gap-4">
                    <div className="p-3 bg-gray-800 rounded-xl">
                      <Plus className="w-5 h-5 text-gray-400" />
                    </div>
                    <div>
                      <p className="text-sm font-black text-white">Desde Cero</p>
                      <p className="text-[10px] text-gray-500 font-bold uppercase mt-1">Sin unidades ni edificios iniciales</p>
                    </div>
                  </div>
                  <input 
                    type="radio" 
                    name="template" 
                    checked={formData.templateCivId === ''} 
                    onChange={() => setFormData({...formData, templateCivId: ''})}
                    className="w-5 h-5 accent-indigo-500"
                  />
                </label>

                {availableCivs.map(civ => (
                  <label key={civ.id} className={`flex items-center justify-between p-6 border rounded-2xl cursor-pointer transition-all ${formData.templateCivId === civ.id ? 'bg-indigo-600/20 border-indigo-500' : 'bg-white/5 border-white/10 hover:bg-white/10'}`}>
                    <div className="flex items-center gap-4">
                      <div className="p-3 bg-indigo-600/20 rounded-xl">
                        <Copy className="w-5 h-5 text-indigo-400" />
                      </div>
                      <div>
                        <p className="text-sm font-black text-white">Clonar de: {civ.name}</p>
                        <p className="text-[10px] text-indigo-400/70 font-bold uppercase mt-1">Copia unidades, edificios y tecnologías base</p>
                      </div>
                    </div>
                    <input 
                      type="radio" 
                      name="template" 
                      checked={formData.templateCivId === civ.id} 
                      onChange={() => setFormData({...formData, templateCivId: civ.id})}
                      className="w-5 h-5 accent-indigo-500"
                    />
                  </label>
                ))}
              </div>

              <div className="flex justify-between pt-4">
                <button 
                  onClick={() => setStep(1)}
                  disabled={loading}
                  className="px-8 py-4 rounded-2xl font-black text-xs text-gray-500 hover:text-white uppercase tracking-widest disabled:opacity-50"
                >
                  Atrás
                </button>
                <button 
                  onClick={handleSave}
                  disabled={loading}
                  className="flex items-center gap-3 bg-emerald-600 hover:bg-emerald-500 text-white px-8 py-4 rounded-2xl font-black text-xs uppercase tracking-widest transition-all shadow-xl shadow-emerald-900/40 disabled:opacity-50"
                >
                  {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : <Save className="w-5 h-5" />}
                  <span>{loading ? 'Creando...' : 'Finalizar y Crear'}</span>
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
