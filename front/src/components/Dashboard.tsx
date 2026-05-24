"use client";

import React from 'react';
import { api } from '@/lib/api';
import { useDashboardState } from '@/hooks/useDashboardState';

// Modals
import SpriteConfiguratorModal from './modals/SpriteConfiguratorModal';
import EntityModal from './EntityModal';
import OverrideModal from './modals/OverrideModal';
import CivWizardModal from './modals/CivWizardModal';
import PromptModal from './ui/PromptModal';

// Dashboard Components
import Sidebar from './dashboard/Sidebar';
import DashboardHeader from './dashboard/DashboardHeader';
import EntityList from './dashboard/EntityList';
import EntityDetailsPane from './dashboard/EntityDetailsPane';

export default function Dashboard() {
  const state = useDashboardState();

  return (
    <div className="flex h-screen bg-zinc-950 text-zinc-200 overflow-hidden font-sans">
      {!state.selectedItem && (
         <Sidebar activeTab={state.activeTab} setActiveTab={state.setActiveTab as any} />
      )}

      <div className="flex-1 flex flex-col overflow-hidden relative">
         {state.selectedItem ? (
           <EntityDetailsPane 
             activeTab={state.activeTab}
             setActiveTab={state.setActiveTab as any}
             selectedItem={state.selectedItem}
             setSelectedItem={state.setSelectedItem}
             availableItems={state.availableItems}
             selectedCivId={state.selectedCivId}
             setSelectedCivId={state.setSelectedCivId}
             setEditingItem={state.setEditingItem}
             setIsModalOpen={state.setIsModalOpen}
             relations={state.relations}
             fetchRelations={state.fetchRelations}
             fetchAvailableItems={state.fetchAvailableItems}
             handleSave={state.handleSave}
             addRelation={state.addRelation}
             removeRelation={state.removeRelation}
             setCurrentOverrideItem={state.setCurrentOverrideItem}
             setIsOverrideModalOpen={state.setIsOverrideModalOpen}
             setPromptModal={state.setPromptModal}
             setPromptValues={state.setPromptValues}
             api={api}
           />
         ) : (
           <>
             <DashboardHeader 
               activeTab={state.activeTab}
               dataLength={state.filteredData.length}
               searchTerm={state.searchTerm}
               setSearchTerm={state.setSearchTerm}
               onAddClick={() => { state.setEditingItem({}); state.setIsModalOpen(true); }}
             />
             <main className="flex-1 overflow-auto p-6 scrollbar-hide z-0">
               <EntityList 
                 loading={state.loading}
                 activeTab={state.activeTab}
                 filteredData={state.filteredData}
                 setSelectedItem={state.setSelectedItem}
                 setEditingItem={state.setEditingItem}
                 setIsModalOpen={state.setIsModalOpen}
               />
             </main>
           </>
         )}
      </div>

      <EntityModal
        isOpen={state.isModalOpen}
        onClose={() => { state.setIsModalOpen(false); state.setEditingItem(null); }}
        editingItem={state.editingItem}
        setEditingItem={state.setEditingItem}
        handleSave={state.handleSave}
        activeTab={state.activeTab}
        data={state.data}
        availableItems={state.availableItems}
      />

      <OverrideModal 
        isOpen={state.isOverrideModalOpen}
        onClose={() => { state.setIsOverrideModalOpen(false); state.setCurrentOverrideItem(null); }}
        currentOverrideItem={state.currentOverrideItem}
        selectedItem={state.selectedItem}
        relations={state.relations}
        api={api}
        fetchRelations={state.fetchRelations}
        addRelation={state.addRelation}
        removeRelation={state.removeRelation}
        setCurrentSpriteField={state.setCurrentSpriteField}
        setIsSpriteModalOpen={state.setIsSpriteModalOpen}
      />

      <SpriteConfiguratorModal 
         isOpen={state.isSpriteModalOpen}
         onClose={() => { state.setIsSpriteModalOpen(false); state.setCurrentSpriteField(null); }}
         onSelect={(path: any) => {
            if (state.currentOverrideItem) {
                const override = state.relations.unifiedOverrides?.find((o: any) => 
                  o.entity_type === state.currentOverrideItem?.type && 
                  o.entity_id === state.currentOverrideItem?.item.id && 
                  o.stat_key === state.currentSpriteField
                );
                
                if (override) {
                  api.update('game_civilization_overrides', override.id, { stat_value: path }).then(() => state.fetchRelations());
                } else {
                  state.addRelation('game_civilization_overrides', {
                    civilization_id: state.selectedItem?.id,
                    entity_type: state.currentOverrideItem.type,
                    entity_id: state.currentOverrideItem.item.id,
                    stat_key: state.currentSpriteField,
                    stat_value: path
                  }).then(() => state.fetchRelations());
                }
            } else {
               state.handleSave({ ...state.selectedItem, [state.currentSpriteField as string]: path });
            }
            state.setIsSpriteModalOpen(false);
            state.setCurrentSpriteField(null);
         }}
      />

      <PromptModal 
         modal={state.promptModal}
         setModal={state.setPromptModal}
         values={state.promptValues}
         setValues={state.setPromptValues}
      />

      <CivWizardModal 
        isOpen={state.isCivWizardOpen}
        onClose={() => state.setIsCivWizardOpen(false)}
        api={api}
        onComplete={() => state.fetchData()}
      />
    </div>
  );
}
