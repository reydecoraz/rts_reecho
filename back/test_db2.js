require('dotenv').config({ path: 'c:/Users/rober/OneDrive/Escritorio/pruebasraras/RTS_1/back/.env' });
const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);

async function run() {
  const { data: bldgs } = await supabase.from('game_buildings_data').select('*');
  const { data: civ_bldgs } = await supabase.from('civ_buildings').select('*');
  console.log("Buildings:", bldgs.map(b => `${b.id} | ${b.name} | ${b.category}`));
  console.log("Civ Buildings:", civ_bldgs.length);
}
run();
