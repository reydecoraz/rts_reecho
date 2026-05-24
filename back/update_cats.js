require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);

async function run() {
  console.log("Updating buildings...");
  await supabase.from('game_buildings_data').update({ category: 'town_center' }).eq('name', 'Centro Urbano');
  await supabase.from('game_buildings_data').update({ category: 'house' }).eq('name', 'Casa');
  await supabase.from('game_buildings_data').update({ category: 'farm' }).eq('name', 'Granja');
  await supabase.from('game_buildings_data').update({ category: 'resource_wood' }).eq('name', 'Campamento Maderero');
  await supabase.from('game_buildings_data').update({ category: 'resource_gold_stone' }).eq('name', 'Mina');
  await supabase.from('game_buildings_data').update({ category: 'military_barracks' }).eq('name', 'Cuartel');
  await supabase.from('game_buildings_data').update({ category: 'military_archery' }).eq('name', 'Galería de Tiro');
  await supabase.from('game_buildings_data').update({ category: 'military_stable' }).eq('name', 'Establo');
  await supabase.from('game_buildings_data').update({ category: 'military_siege' }).eq('name', 'Taller de Asedio');
  await supabase.from('game_buildings_data').update({ category: 'defense_tower' }).eq('name', 'Torre de Defensa');
  await supabase.from('game_buildings_data').update({ category: 'defense_wall' }).eq('name', 'Muro');
  await supabase.from('game_buildings_data').update({ category: 'market' }).eq('name', 'Mercado');
  
  console.log("Updating units...");
  await supabase.from('game_units_data').update({ category: 'military_infantry' }).eq('name', 'Soldado con Espada');
  await supabase.from('game_units_data').update({ category: 'military_infantry' }).eq('name', 'Lancero');
  await supabase.from('game_units_data').update({ category: 'military_infantry' }).eq('name', 'Guerrero Khopesh');
  await supabase.from('game_units_data').update({ category: 'military_cavalry' }).eq('name', 'Caballero');
  await supabase.from('game_units_data').update({ category: 'military_cavalry' }).eq('name', 'Carro de Guerra Egipcio');
  await supabase.from('game_units_data').update({ category: 'military_archery' }).eq('name', 'Arquero');
  
  console.log("Done updating categories.");
}

run().catch(console.error);
