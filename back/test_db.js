require('dotenv').config({ path: 'c:/Users/rober/OneDrive/Escritorio/pruebasraras/RTS_1/back/.env' });
const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);

async function run() {
  const { data, error } = await supabase.from('game_units_data').select('*');
  console.log(data);
}
run();
