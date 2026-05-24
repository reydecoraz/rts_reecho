import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

const BUCKET = 'game-sprites';

/**
 * Upload a sprite image to Supabase Storage.
 * Returns the public URL of the uploaded image.
 */
export async function uploadSprite(file: File, path: string): Promise<string> {
  const { error } = await supabase.storage
    .from(BUCKET)
    .upload(path, file, { upsert: true, contentType: file.type });

  if (error) {
    throw new Error(`Error uploading sprite: ${error.message}`);
  }

  const { data: urlData } = supabase.storage
    .from(BUCKET)
    .getPublicUrl(path);

  return urlData.publicUrl;
}

/**
 * Upload a Blob (e.g. from AI generation) to Supabase Storage.
 */
export async function uploadBlob(blob: Blob, path: string, contentType = 'image/png'): Promise<string> {
  const { error } = await supabase.storage
    .from(BUCKET)
    .upload(path, blob, { upsert: true, contentType });

  if (error) {
    throw new Error(`Error uploading blob: ${error.message}`);
  }

  const { data: urlData } = supabase.storage
    .from(BUCKET)
    .getPublicUrl(path);

  return urlData.publicUrl;
}

/**
 * Delete a sprite from Supabase Storage.
 */
export async function deleteSprite(path: string): Promise<void> {
  const { error } = await supabase.storage
    .from(BUCKET)
    .remove([path]);

  if (error) {
    console.error('Error deleting sprite:', error.message);
  }
}
