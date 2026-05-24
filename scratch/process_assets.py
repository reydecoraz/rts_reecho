import os
import requests
import json

# Configurations
REMBG_URL = "http://localhost:5050"
SUPABASE_URL = "https://tpjaebcovdpkhqgcsewk.supabase.co"
# Anon key from front/.env.local
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRwamFlYmNvdmRwa2hxZ2NzZXdrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ0NjI4MjksImV4cCI6MjA4MDAzODgyOX0.s1e1eWutnBPWqRa_gwtyi2pWVT5-PlIcmS46ZtKDkQ0"
BUCKET_NAME = "game-sprites"

# Directory where Gemini saved the generated images
BRAIN_DIR = r"C:\Users\rober\.gemini\antigravity\brain\8186bb6b-460b-4781-a0f1-61fd62ce1025"

# Entity mappings
ENTITIES = {
    "hero_julius_caesar_unit": {
        "file": "julius_caesar_sprite_1778474203397.png",
        "table": "game_units_data",
        "path": "civ_romans/units/hero_julius_caesar_unit/sprite.png"
    },
    "hero_cleopatra_unit": {
        "file": "cleopatra_sprite_1778474215545.png",
        "table": "game_units_data",
        "path": "civ_egyptians/units/hero_cleopatra_unit/sprite.png"
    },
    "soldado_espada": {
        "file": "soldado_espada_sprite_1778474230432.png",
        "table": "game_units_data",
        "path": "civ_romans/units/soldado_espada/sprite.png"
    },
    "lancero": {
        "file": "lancero_sprite_1778474242164.png",
        "table": "game_units_data",
        "path": "civ_romans/units/lancero/sprite.png"
    },
    "unit_egy_chariot": {
        "file": "chariot_sprite_1778474260795.png",
        "table": "game_units_data",
        "path": "civ_egyptians/units/unit_egy_chariot/sprite.png"
    },
    "unit_egy_medjay": {
        "file": "medjay_sprite_1778474273681.png",
        "table": "game_units_data",
        "path": "civ_egyptians/units/unit_egy_medjay/sprite.png"
    },
    "arquero": {
        "file": "arquero_sprite_1778474286275.png",
        "table": "game_units_data",
        "path": "shared/units/arquero/sprite.png"
    },
    "caballero": {
        "file": "caballero_sprite_1778474302573.png",
        "table": "game_units_data",
        "path": "shared/units/caballero/sprite.png"
    },
    "aldeano": {
        "file": "aldeano_sprite_1778474319173.png",
        "table": "game_units_data",
        "path": "shared/units/aldeano/sprite.png"
    },
    "carreta": {
        "file": "carreta_sprite_1778474335642.png",
        "table": "game_units_data",
        "path": "shared/units/carreta/sprite.png"
    },
    "building_centro_urbano": {
        "file": "centro_urbano_sprite_1778474347566.png",
        "table": "game_buildings_data",
        "path": "shared/buildings/building_centro_urbano/sprite.png"
    },
    "building_cuartel": {
        "file": "cuartel_sprite_1778474360277.png",
        "table": "game_buildings_data",
        "path": "shared/buildings/building_cuartel/sprite.png"
    },
    "building_galeria_de_tiro": {
        "file": "archery_range_sprite_1778474375969.png",
        "table": "game_buildings_data",
        "path": "shared/buildings/building_galeria_de_tiro/sprite.png"
    },
    "building_establo": {
        "file": "stable_sprite_1778474388685.png",
        "table": "game_buildings_data",
        "path": "shared/buildings/building_establo/sprite.png"
    },
    "building_torre_defensa": {
        "file": "watchtower_sprite_1778474402822.png",
        "table": "game_buildings_data",
        "path": "shared/buildings/building_torre_defensa/sprite.png"
    },
    "building_granja": {
        "file": "farm_sprite_1778474417593.png",
        "table": "game_buildings_data",
        "path": "shared/buildings/building_granja/sprite.png"
    },
    "building_mina": {
        "file": "mining_camp_sprite_1778474434928.png",
        "table": "game_buildings_data",
        "path": "shared/buildings/building_mina/sprite.png"
    },
}

# Standard reuses for other database records
REUSES = {
    # Buildings without direct sprites
    "building_campamento_maderero": ("building_mina", "shared/buildings/building_campamento_maderero/sprite.png"),
    "building_casa": ("building_establo", "shared/buildings/building_casa/sprite.png"),
    "building_mercado": ("building_centro_urbano", "shared/buildings/building_mercado/sprite.png"),
    "building_taller_de_asedio": ("building_cuartel", "shared/buildings/building_taller_de_asedio/sprite.png"),
    "building_muro": ("building_torre_defensa", "shared/buildings/building_muro/sprite.png"),
    
    # Other Heroes
    "hero_achilles_unit": ("hero_julius_caesar_unit", "shared/units/hero_achilles_unit/sprite.png"),
    "hero_confucius_unit": ("hero_julius_caesar_unit", "shared/units/hero_confucius_unit/sprite.png"),
    "hero_ragnar_unit": ("hero_julius_caesar_unit", "shared/units/hero_ragnar_unit/sprite.png"),
}

def remove_background(input_path, output_path):
    print(f"Removing background from {input_path}...")
    try:
        with open(input_path, 'rb') as f:
            files = {'image': ('input.png', f, 'image/png')}
            res = requests.post(f"{REMBG_URL}/remove-bg", files=files)
            if res.status_code == 200:
                with open(output_path, 'wb') as out_f:
                    out_f.write(res.content)
                print(f"Success! Cleaned image saved to {output_path}")
                return True
            else:
                print(f"Error from rembg-service ({res.status_code}): {res.text}")
                return False
    except Exception as e:
        print(f"Exception during background removal: {e}")
        return False

def upload_to_supabase(file_path, storage_path):
    print(f"Uploading {file_path} to Supabase Storage at {storage_path}...")
    try:
        url = f"{SUPABASE_URL}/storage/v1/object/{BUCKET_NAME}/{storage_path}"
        headers = {
            "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
            "apikey": SUPABASE_ANON_KEY,
            "Content-Type": "image/png"
        }
        with open(file_path, 'rb') as f:
            res = requests.post(url, headers=headers, data=f)
            # 200 or 400 with duplicate error (we want upsert if possible, so we can try PUT if POST fails)
            if res.status_code == 200:
                public_url = f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET_NAME}/{storage_path}"
                print(f"Upload success! Public URL: {public_url}")
                return public_url
            else:
                # Let's try PUT (upsert)
                print(f"POST upload code {res.status_code}. Trying PUT...")
                res_put = requests.put(url, headers=headers, data=f)
                if res_put.status_code == 200:
                    public_url = f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET_NAME}/{storage_path}"
                    print(f"PUT Upload success! Public URL: {public_url}")
                    return public_url
                else:
                    print(f"Upload failed: POST ({res.status_code}): {res.text}, PUT ({res_put.status_code}): {res_put.text}")
                    return None
    except Exception as e:
        print(f"Exception during Supabase upload: {e}")
        return None

def main():
    os.makedirs("scratch/cleaned_sprites", exist_ok=True)
    sql_updates = []
    
    print("--- STEP 1: Processing primary generated sprites ---")
    for entity_id, info in ENTITIES.items():
        original_file = os.path.join(BRAIN_DIR, info["file"])
        cleaned_file = os.path.join("scratch/cleaned_sprites", f"{entity_id}_clean.png")
        
        if not os.path.exists(original_file):
            print(f"WARNING: Original file {original_file} not found!")
            continue
            
        success = remove_background(original_file, cleaned_file)
        if not success:
            print(f"Falling back to original file for {entity_id} without background removal...")
            cleaned_file = original_file
            
        public_url = upload_to_supabase(cleaned_file, info["path"])
        if public_url:
            sql = f"UPDATE {info['table']} SET sprite_url = '{public_url}' WHERE id = '{entity_id}';"
            sql_updates.append(sql)
            
    print("\n--- STEP 2: Processing reuses ---")
    for entity_id, (source_id, storage_path) in REUSES.items():
        # Find original or cleaned file of the source_id
        source_info = ENTITIES.get(source_id)
        if not source_info:
            continue
            
        cleaned_file = os.path.join("scratch/cleaned_sprites", f"{source_id}_clean.png")
        if not os.path.exists(cleaned_file):
            cleaned_file = os.path.join(BRAIN_DIR, source_info["file"])
            
        if not os.path.exists(cleaned_file):
            print(f"WARNING: Source file for reuse {entity_id} not found!")
            continue
            
        # Upload the same file to the new path
        public_url = upload_to_supabase(cleaned_file, storage_path)
        if public_url:
            table = "game_units_data" if "unit" in entity_id or "aldeano" in entity_id or "arquero" in entity_id or "caballero" in entity_id or "carreta" in entity_id or "lancero" in entity_id or "soldado" in entity_id else "game_buildings_data"
            sql = f"UPDATE {table} SET sprite_url = '{public_url}' WHERE id = '{entity_id}';"
            sql_updates.append(sql)
            
    print("\n--- STEP 3: Writing SQL Update File ---")
    with open("scratch/update_sprites.sql", "w", encoding="utf-8") as f:
        f.write("\n".join(sql_updates))
    print("SQL file generated successfully at scratch/update_sprites.sql!")
    print("Please execute the SQL commands to update the database.")

if __name__ == "__main__":
    main()
