import React from 'react';

interface PromptModalProps {
  modal: any;
  setModal: (modal: any) => void;
  values: any;
  setValues: (values: any) => void;
}

export default function PromptModal({ modal, setModal, values, setValues }: PromptModalProps) {
  if (!modal) return null;

  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center p-4 z-50">
      <div className="bg-zinc-900 border border-zinc-800 p-8 rounded-sm max-w-md w-full shadow-2xl">
        <h3 className="text-xl font-black text-white mb-6 uppercase tracking-widest">{modal.title}</h3>
        <div className="space-y-4">
          {modal.fields.map((f: any) => (
            <div key={f.key}>
              <label className="text-[10px] font-black text-zinc-400 uppercase tracking-widest block mb-2">{f.label}</label>
              {f.key === 'description' ? (
                <textarea 
                  className="w-full bg-zinc-950 border border-zinc-800 rounded-sm p-4 text-sm font-medium focus:border-yellow-500 outline-none h-24 resize-none"
                  placeholder={f.placeholder}
                  value={values[f.key] || ''}
                  onChange={e => setValues({...values, [f.key]: e.target.value})}
                />
              ) : (
                <input 
                  type="text" 
                  className="w-full bg-zinc-950 border border-zinc-800 rounded-sm p-4 text-sm font-medium focus:border-yellow-500 outline-none"
                  placeholder={f.placeholder}
                  value={values[f.key] || ''}
                  onChange={e => setValues({...values, [f.key]: e.target.value})}
                />
              )}
            </div>
          ))}
        </div>
        <div className="flex justify-end gap-4 mt-8">
          <button 
            onClick={() => setModal(null)}
            className="px-6 py-3 text-xs font-black uppercase tracking-widest text-zinc-500 hover:text-white transition-colors"
          >
            Cancelar
          </button>
          <button 
            onClick={() => modal.onConfirm(values)}
            className="px-6 py-3 bg-yellow-600 hover:bg-yellow-500 text-black text-xs font-black uppercase tracking-widest rounded-sm transition-colors"
          >
            Confirmar
          </button>
        </div>
      </div>
    </div>
  );
}
