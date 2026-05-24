import { useState, useEffect, useMemo } from 'react';
import { api } from '@/lib/api';
import { uploadSprite } from '@/lib/supabaseStorage';
import toast from 'react-hot-toast';
import { TABLES } from '@/lib/constants';

export function useDashboardState() {
  const [activeTab, setActiveTab] = useState<keyof typeof TABLES>('civilizations');
  const [data, setData] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingItem, setEditingItem] = useState<any | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isOverrideModalOpen, setIsOverrideModalOpen] = useState(false);
  const [isSpriteModalOpen, setIsSpriteModalOpen] = useState(false);
  const [isCivWizardOpen, setIsCivWizardOpen] = useState(false);
  const [currentSpriteField, setCurrentSpriteField] = useState<string | null>(null);
  const [currentOverrideItem, setCurrentOverrideItem] = useState<{type: string, item: any} | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [promptModal, setPromptModal] = useState<any | null>(null);
  const [promptValues, setPromptValues] = useState<Record<string, string>>({});

  const [selectedItem, setSelectedItem] = useState<any | null>(null);
  const [selectedCivId, setSelectedCivId] = useState<string>('');
  const [relations, setRelations] = useState<{ [key: string]: any[] }>({});
  const [availableItems, setAvailableItems] = useState<{ [key: string]: any[] }>({});

  useEffect(() => {
    fetchData();
    fetchAvailableItems();
  }, [activeTab]);

  useEffect(() => {
    if (selectedItem) {
      fetchRelations();
    }
  }, [selectedItem, selectedCivId]);

  const fetchData = async () => {
    setLoading(true);
    try {
      const res = await api.get(TABLES[activeTab]);
      setData(res);
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchAvailableItems = async () => {
    try {
      const [units, buildings, techs, civs, heroes, attrDefs] = await Promise.all([
        api.get(TABLES.units),
        api.get(TABLES.buildings),
        api.get(TABLES.technologies),
        api.get(TABLES.civilizations),
        api.get(TABLES.heroes),
        api.get(TABLES.attribute_definitions)
      ]);
      setAvailableItems({ units, buildings, techs, civs, heroes, attributeDefs: attrDefs });
      setSelectedCivId(prev => prev || civs[0]?.id || '');
    } catch (error) {
      console.error('Error fetching available items:', error);
    }
  };

  const fetchRelations = async () => {
    if (!selectedItem) return;
    const rels: any = {};
    try {
      if (activeTab === 'civilizations') {
        rels.units = await api.getRelations(TABLES.civilizations, selectedItem.id, 'civ_units', 'civilization_id');
        rels.buildings = await api.getRelations(TABLES.civilizations, selectedItem.id, 'civ_buildings', 'civilization_id');
        rels.heroes = await api.getRelations(TABLES.civilizations, selectedItem.id, 'civ_heroes', 'civilization_id');
        rels.production = await api.getRelations(TABLES.civilizations, selectedItem.id, 'building_produces_units', 'civilization_id');
        rels.researches_civ = await api.getRelations(TABLES.civilizations, selectedItem.id, 'building_researches', 'civilization_id');
        rels.requirements = await api.getRelations(TABLES.civilizations, selectedItem.id, 'game_requirements', 'civilization_id');
        rels.productionBonuses = await api.getRelations(TABLES.civilizations, selectedItem.id, 'building_production_bonuses', 'civilization_id');
        rels.unifiedOverrides = await api.getRelations(TABLES.civilizations, selectedItem.id, 'game_civilization_overrides', 'civilization_id');
      } else if (activeTab === 'buildings') {
        rels.produces = (await api.getRelations(TABLES.buildings, selectedItem.id, 'building_produces_units', 'building_id'))
          .filter((r: any) => r.civilization_id === selectedCivId);
        rels.researches = (await api.getRelations(TABLES.buildings, selectedItem.id, 'building_researches', 'building_id'))
          .filter((r: any) => r.civilization_id === selectedCivId);
        rels.requirements = await api.getRelations(TABLES.buildings, selectedItem.id, 'game_requirements', 'entity_id');
        rels.bonuses = await api.getRelations(TABLES.buildings, selectedItem.id, 'building_production_bonuses', 'building_id');
      } else if (activeTab === 'technologies') {
        rels.effects = (await api.getRelations(TABLES.technologies, selectedItem.id, 'game_technology_effects', 'technology_id'))
          .filter((r: any) => !r.civilization_id || r.civilization_id === selectedCivId);
        rels.requirements = await api.getRelations(TABLES.technologies, selectedItem.id, 'game_requirements', 'entity_id');
      } else if (activeTab === 'units' || activeTab === 'heroes') {
        rels.requirements = await api.getRelations(TABLES[activeTab], selectedItem.id, 'game_requirements', 'entity_id');
      }
      setRelations(rels);
    } catch (error) {
      console.error('Error fetching relations:', error);
    }
  };

  const handleSave = async (e: any) => {
    if (e && typeof e.preventDefault === 'function') {
      e.preventDefault();
    }
    const itemToSave = (e && typeof e.preventDefault !== 'function') ? e : editingItem;
    try {
      if (itemToSave.id && data.find(i => i.id === itemToSave.id)) {
        await api.update(TABLES[activeTab], itemToSave.id, itemToSave);
      } else {
        await api.create(TABLES[activeTab], itemToSave);
      }
      setIsModalOpen(false);
      setEditingItem(null);
      fetchData();
      if (selectedItem && itemToSave.id === selectedItem.id) {
        setSelectedItem(itemToSave);
      }
      toast.success('Registro sincronizado correctamente');
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Error al guardar.');
    }
  };

  const addRelation = async (relTable: string, payload: any) => {
    try {
      await api.addRelation(relTable, payload);
      fetchRelations();
      toast.success('Vínculo creado');
    } catch (error) {
      toast.error('Error al vincular. Es posible que ya exista.');
    }
  };

  const updateDeepSpriteConfig = async (category: string, subKey: string, value: any) => {
    if (!currentOverrideItem) return;
    try {
      const override = relations.unifiedOverrides?.find((o: any) => 
        o.entity_type === currentOverrideItem.type && 
        o.entity_id === currentOverrideItem.item.id && 
        o.stat_key === 'sprite_config'
      );

      let config: any = {};
      if (override) {
        config = typeof override.stat_value === 'string' ? JSON.parse(override.stat_value) : override.stat_value;
      }

      if (category === 'meta') {
        config[subKey] = value;
      } else if (category === 'animations') {
        const [action, dir] = subKey.split('.');
        config.animations = config.animations || {};
        config.animations[action] = config.animations[action] || {};
        if (value === '') {
          delete config.animations[action][dir];
        } else {
          config.animations[action][dir] = value;
        }
      } else if (category === 'construction') {
        config.construction = config.construction || {};
        if (value === '') {
          delete config.construction[subKey];
        } else {
          config.construction[subKey] = value;
        }
      } else if (category === 'damage') {
        config.damage = config.damage || {};
        if (value === '') {
          delete config.damage[subKey];
        } else {
          config.damage[subKey] = value;
        }
      }

      if (override) {
        await api.update('game_civilization_overrides', override.id, { stat_value: JSON.stringify(config) });
      } else {
        await addRelation('game_civilization_overrides', {
          civilization_id: selectedItem.id,
          entity_type: currentOverrideItem.type,
          entity_id: currentOverrideItem.item.id,
          stat_key: 'sprite_config',
          stat_value: JSON.stringify(config)
        });
      }
      fetchRelations();
    } catch (error) {
      console.error('Error updating deep sprite config:', error);
    }
  };

  const handleImageUpload = async (file: File, category: string, subKey: string) => {
    try {
      const civId = selectedItem?.id || 'default';
      const entityId = currentOverrideItem?.item?.id || 'unknown';
      const entityType = currentOverrideItem?.type || 'misc';
      const safeName = subKey.replace(/\./g, '_');
      const ext = file.name.split('.').pop() || 'png';
      const path = `${civId}/${entityType}/${entityId}/${category}_${safeName}.${ext}`;

      const publicUrl = await uploadSprite(file, path);
      await updateDeepSpriteConfig(category, subKey, publicUrl);
      toast.success('Sprite subido correctamente');
    } catch (err: any) {
      console.error('Error uploading sprite:', err);
      toast.error('Error al subir sprite: ' + (err.message || 'Error desconocido'));
    }
  };

  const removeRelation = async (relTable: string, query: any) => {
    try {
      await api.removeRelation(relTable, query);
      fetchRelations();
    } catch (error) {
      console.error('Error removing relation:', error);
    }
  };

  const filteredData = useMemo(() => {
    return data.filter(item => 
      (item.name || item.id).toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [data, searchTerm]);

  return {
    activeTab, setActiveTab,
    data, loading,
    editingItem, setEditingItem,
    isModalOpen, setIsModalOpen,
    isOverrideModalOpen, setIsOverrideModalOpen,
    isSpriteModalOpen, setIsSpriteModalOpen,
    isCivWizardOpen, setIsCivWizardOpen,
    currentSpriteField, setCurrentSpriteField,
    currentOverrideItem, setCurrentOverrideItem,
    searchTerm, setSearchTerm,
    promptModal, setPromptModal,
    promptValues, setPromptValues,
    selectedItem, setSelectedItem,
    selectedCivId, setSelectedCivId,
    relations, availableItems,
    filteredData,
    fetchData, fetchAvailableItems, fetchRelations,
    handleSave, addRelation, removeRelation,
    updateDeepSpriteConfig, handleImageUpload
  };
}
