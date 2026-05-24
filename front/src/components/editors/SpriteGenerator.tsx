"use client";

import React, { useState, useEffect } from 'react';
import { Sparkles, Wand2, Eraser, Download, Check, AlertTriangle, Loader2, RefreshCw } from 'lucide-react';
import { generateSprite, isSpriteGeneratorConfigured, getProviderName, SpriteGenerationOptions } from '@/lib/spriteAI';
import { removeBackground, isRembgAvailable } from '@/lib/backgroundRemover';
import { uploadBlob } from '@/lib/supabaseStorage';

interface SpriteGeneratorProps {
  onSpriteReady: (url: string) => void;
  civId: string;
  entityType: string;
  entityId: string;
  fieldKey: string;
}

type GeneratorState = 'idle' | 'generating' | 'generated' | 'removing_bg' | 'bg_removed' | 'uploading' | 'done' | 'error';

export default function SpriteGenerator({ onSpriteReady, civId, entityType, entityId, fieldKey }: SpriteGeneratorProps) {
  const [prompt, setPrompt] = useState('');
  const [style, setStyle] = useState<SpriteGenerationOptions['style']>('pixel_art');
  const [size, setSize] = useState(512);
  const [negativePrompt, setNegativePrompt] = useState('');
  const [state, setState] = useState<GeneratorState>('idle');
  const [error, setError] = useState('');
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [currentBlob, setCurrentBlob] = useState<Blob | null>(null);
  const [aiReady, setAiReady] = useState(false);
  const [aiProviderName, setAiProviderName] = useState('AI');
  const [rembgReady, setRembgReady] = useState(false);
  const [showAdvanced, setShowAdvanced] = useState(false);

  useEffect(() => {
    setAiReady(isSpriteGeneratorConfigured());
    setAiProviderName(getProviderName());
    isRembgAvailable().then(setRembgReady);
  }, []);

  const handleGenerate = async () => {
    if (!prompt.trim()) return;
    setState('generating');
    setError('');
    try {
      const blob = await generateSprite({
        prompt: prompt.trim(),
        width: size,
        height: size,
        style,
        negativePrompt: negativePrompt || undefined,
      });
      setCurrentBlob(blob);
      setPreviewUrl(URL.createObjectURL(blob));
      setState('generated');
    } catch (err: any) {
      setError(err.message);
      setState('error');
    }
  };

  const handleRemoveBg = async () => {
    if (!currentBlob) return;
    setState('removing_bg');
    setError('');
    try {
      const cleanBlob = await removeBackground(currentBlob);
      setCurrentBlob(cleanBlob);
      if (previewUrl) URL.revokeObjectURL(previewUrl);
      setPreviewUrl(URL.createObjectURL(cleanBlob));
      setState('bg_removed');
    } catch (err: any) {
      setError(err.message);
      setState('error');
    }
  };

  const handleUploadFromFile = async (file: File) => {
    setCurrentBlob(file);
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    setPreviewUrl(URL.createObjectURL(file));
    setState('generated');
    setError('');
  };

  const handleUseSprite = async () => {
    if (!currentBlob) return;
    setState('uploading');
    setError('');
    try {
      const safeName = fieldKey.replace(/\./g, '_');
      const path = `${civId}/${entityType}/${entityId}/ai_${safeName}_${Date.now()}.png`;
      const publicUrl = await uploadBlob(currentBlob, path);
      setState('done');
      onSpriteReady(publicUrl);
    } catch (err: any) {
      setError(err.message);
      setState('error');
    }
  };

  const handleReset = () => {
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    setPreviewUrl(null);
    setCurrentBlob(null);
    setState('idle');
    setError('');
  };

  return (
    <div className="space-y-8 p-10 bg-gradient-to-br from-violet-600/5 via-transparent to-emerald-600/5 border border-white/5 rounded-[3rem]">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-5">
          <div className="bg-gradient-to-br from-violet-600 to-indigo-600 p-4 rounded-2xl shadow-xl shadow-violet-900/30">
            <Wand2 className="w-6 h-6 text-white" />
          </div>
          <div>
            <h4 className="text-xl font-black text-white uppercase italic tracking-wide">AI Sprite Generator</h4>
            <p className="text-[10px] text-violet-400 font-black uppercase tracking-[0.4em] mt-1">
              Genera y limpia sprites con IA
            </p>
          </div>
        </div>
        <div className="flex gap-3">
          <div className={`flex items-center gap-2 px-4 py-2 rounded-xl text-[9px] font-black uppercase tracking-widest border ${aiReady ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400' : 'bg-amber-500/10 border-amber-500/30 text-amber-400'}`}>
            <div className={`w-2 h-2 rounded-full ${aiReady ? 'bg-emerald-500' : 'bg-amber-500 animate-pulse'}`} />
            {aiProviderName} {aiReady ? 'Ready' : 'No Key'}
          </div>
          <div className={`flex items-center gap-2 px-4 py-2 rounded-xl text-[9px] font-black uppercase tracking-widest border ${rembgReady ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400' : 'bg-gray-500/10 border-gray-500/30 text-gray-500'}`}>
            <div className={`w-2 h-2 rounded-full ${rembgReady ? 'bg-emerald-500' : 'bg-gray-600'}`} />
            Rembg {rembgReady ? 'Online' : 'Offline'}
          </div>
        </div>
      </div>

      {/* Input Section */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
        <div className="lg:col-span-8 space-y-4">
          <div className="space-y-2">
            <label className="text-[10px] font-black text-gray-500 uppercase tracking-[0.3em] ml-1">Prompt de generación</label>
            <textarea
              value={prompt}
              onChange={(e) => setPrompt(e.target.value)}
              placeholder="Ej: medieval warrior with sword and shield, isometric view, pixel art style, clean edges..."
              className="w-full bg-white/5 border border-white/5 rounded-2xl px-6 py-4 text-sm focus:border-violet-500 focus:ring-2 focus:ring-violet-500/10 outline-none transition-all font-bold text-white resize-none h-24 placeholder:text-gray-600"
            />
          </div>
          
          <button 
            onClick={() => setShowAdvanced(!showAdvanced)}
            className="text-[9px] font-black text-gray-600 uppercase tracking-widest hover:text-violet-400 transition-colors"
          >
            {showAdvanced ? '▾ Ocultar opciones' : '▸ Opciones avanzadas'}
          </button>

          {showAdvanced && (
            <div className="grid grid-cols-3 gap-4 animate-in slide-in-from-top-2">
              <div className="space-y-2">
                <label className="text-[9px] font-black text-gray-600 uppercase tracking-widest ml-1">Estilo</label>
                <select
                  value={style}
                  onChange={(e) => setStyle(e.target.value as SpriteGenerationOptions['style'])}
                  className="w-full bg-white/5 border border-white/5 rounded-xl px-4 py-3 text-xs font-bold text-white outline-none focus:border-violet-500"
                >
                  <option value="pixel_art" className="bg-[#0f111a]">Pixel Art</option>
                  <option value="isometric" className="bg-[#0f111a]">Isométrico</option>
                  <option value="realistic" className="bg-[#0f111a]">Realista</option>
                  <option value="cartoon" className="bg-[#0f111a]">Cartoon</option>
                </select>
              </div>
              <div className="space-y-2">
                <label className="text-[9px] font-black text-gray-600 uppercase tracking-widest ml-1">Tamaño</label>
                <select
                  value={size}
                  onChange={(e) => setSize(Number(e.target.value))}
                  className="w-full bg-white/5 border border-white/5 rounded-xl px-4 py-3 text-xs font-bold text-white outline-none focus:border-violet-500"
                >
                  <option value={256} className="bg-[#0f111a]">256×256</option>
                  <option value={512} className="bg-[#0f111a]">512×512</option>
                  <option value={1024} className="bg-[#0f111a]">1024×1024</option>
                </select>
              </div>
              <div className="space-y-2">
                <label className="text-[9px] font-black text-gray-600 uppercase tracking-widest ml-1">Negative Prompt</label>
                <input
                  type="text"
                  value={negativePrompt}
                  onChange={(e) => setNegativePrompt(e.target.value)}
                  placeholder="blurry, watermark..."
                  className="w-full bg-white/5 border border-white/5 rounded-xl px-4 py-3 text-xs font-bold text-white outline-none focus:border-violet-500 placeholder:text-gray-700"
                />
              </div>
            </div>
          )}
        </div>

        {/* Preview Area */}
        <div className="lg:col-span-4">
          <div className="aspect-square bg-[#06070a] rounded-3xl border border-white/5 flex items-center justify-center overflow-hidden relative group">
            {previewUrl ? (
              <img src={previewUrl} alt="Preview" className="w-full h-full object-contain p-4" />
            ) : (
              <div className="flex flex-col items-center gap-4 text-gray-700">
                <Sparkles className="w-12 h-12" />
                <p className="text-[9px] font-black uppercase tracking-widest">Preview</p>
              </div>
            )}

            {/* Loading Overlay */}
            {['generating', 'removing_bg', 'uploading'].includes(state) && (
              <div className="absolute inset-0 bg-[#06070a]/80 backdrop-blur-sm flex flex-col items-center justify-center gap-4">
                <Loader2 className="w-10 h-10 text-violet-400 animate-spin" />
                <p className="text-[10px] font-black text-violet-400 uppercase tracking-widest animate-pulse">
                  {state === 'generating' && 'Generando sprite...'}
                  {state === 'removing_bg' && 'Limpiando fondo...'}
                  {state === 'uploading' && 'Subiendo a storage...'}
                </p>
              </div>
            )}

            {/* Done Overlay */}
            {state === 'done' && (
              <div className="absolute inset-0 bg-emerald-600/20 backdrop-blur-sm flex flex-col items-center justify-center gap-3">
                <Check className="w-12 h-12 text-emerald-400" />
                <p className="text-[10px] font-black text-emerald-400 uppercase tracking-widest">¡Sprite asignado!</p>
              </div>
            )}

            {/* Upload from file fallback */}
            {state === 'idle' && (
              <label className="absolute bottom-3 left-3 right-3 bg-white/5 hover:bg-white/10 border border-white/5 rounded-xl py-2 text-center cursor-pointer transition-all opacity-0 group-hover:opacity-100">
                <span className="text-[8px] font-black text-gray-400 uppercase tracking-widest">O sube una imagen</span>
                <input type="file" accept="image/*" className="hidden" onChange={(e) => { const f = e.target.files?.[0]; if (f) handleUploadFromFile(f); }} />
              </label>
            )}
          </div>
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className="flex items-center gap-4 p-5 bg-red-500/10 border border-red-500/20 rounded-2xl">
          <AlertTriangle className="w-5 h-5 text-red-400 shrink-0" />
          <p className="text-xs text-red-400 font-bold">{error}</p>
        </div>
      )}

      {/* Action Buttons */}
      <div className="flex items-center gap-4 flex-wrap">
        {(state === 'idle' || state === 'error') && (
          <button
            onClick={handleGenerate}
            disabled={!prompt.trim() || !aiReady}
            className="flex items-center gap-3 bg-gradient-to-r from-violet-600 to-indigo-600 hover:from-violet-500 hover:to-indigo-500 disabled:from-gray-700 disabled:to-gray-700 disabled:cursor-not-allowed text-white px-8 py-4 rounded-2xl font-black text-[10px] uppercase tracking-widest transition-all shadow-xl shadow-violet-900/30"
          >
            <Wand2 className="w-4 h-4" />
            {aiReady ? 'Generar Sprite' : 'API Key requerida'}
          </button>
        )}

        {(state === 'generated' || state === 'error') && currentBlob && (
          <>
            <button
              onClick={handleRemoveBg}
              disabled={!rembgReady}
              className="flex items-center gap-3 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 disabled:from-gray-700 disabled:to-gray-700 disabled:cursor-not-allowed text-white px-8 py-4 rounded-2xl font-black text-[10px] uppercase tracking-widest transition-all shadow-xl shadow-emerald-900/30"
            >
              <Eraser className="w-4 h-4" />
              {rembgReady ? 'Limpiar Fondo' : 'Rembg offline'}
            </button>
            <button
              onClick={handleUseSprite}
              className="flex items-center gap-3 bg-white/5 hover:bg-white/10 text-white px-8 py-4 rounded-2xl font-black text-[10px] uppercase tracking-widest transition-all border border-white/10"
            >
              <Check className="w-4 h-4" />
              Usar sin limpiar
            </button>
          </>
        )}

        {state === 'bg_removed' && (
          <button
            onClick={handleUseSprite}
            className="flex items-center gap-3 bg-gradient-to-r from-indigo-600 to-violet-600 hover:from-indigo-500 hover:to-violet-500 text-white px-10 py-4 rounded-2xl font-black text-[10px] uppercase tracking-widest transition-all shadow-xl shadow-indigo-900/30"
          >
            <Check className="w-4 h-4" />
            Usar este sprite
          </button>
        )}

        {(state === 'generated' || state === 'bg_removed') && (
          <button
            onClick={handleReset}
            className="flex items-center gap-3 text-gray-500 hover:text-white px-6 py-4 rounded-2xl font-black text-[10px] uppercase tracking-widest transition-all"
          >
            <RefreshCw className="w-4 h-4" />
            Empezar de nuevo
          </button>
        )}

        {state === 'done' && (
          <button
            onClick={handleReset}
            className="flex items-center gap-3 bg-white/5 hover:bg-white/10 text-emerald-400 px-8 py-4 rounded-2xl font-black text-[10px] uppercase tracking-widest transition-all border border-emerald-500/20"
          >
            <RefreshCw className="w-4 h-4" />
            Generar otro
          </button>
        )}
      </div>
    </div>
  );
}
