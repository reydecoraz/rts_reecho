import React from 'react';
import { 
  Shield, Sword, Home, FlaskConical, Settings2, Sparkles 
} from 'lucide-react';

export const TABLES = {
  civilizations: 'game_civilizations_data',
  buildings: 'game_buildings_data',
  units: 'game_units_data',
  heroes: 'game_heroes_data',
  technologies: 'game_technologies_data',
  attribute_definitions: 'game_attribute_definitions'
};

export const TAB_ICONS: Record<string, JSX.Element> = {
  civilizations: <Shield className="w-5 h-5" />,
  buildings: <Home className="w-5 h-5" />,
  units: <Sword className="w-5 h-5" />,
  heroes: <Sparkles className="w-5 h-5" />,
  technologies: <FlaskConical className="w-5 h-5" />,
  attribute_definitions: <Settings2 className="w-5 h-5" />
};
