/**
 * AI Sprite Generation Client
 * 
 * Supports multiple providers for sprite generation.
 * Currently configured for Stability AI (Stable Diffusion) which has a free tier.
 * 
 * SETUP:
 *   1. Go to https://platform.stability.ai/account/keys
 *   2. Create a free account and get your API key
 *   3. Add NEXT_PUBLIC_STABILITY_API_KEY=sk-... to .env.local
 * 
 * FREE TIER: 25 credits/month (enough for ~25 images)
 * 
 * ALTERNATIVE: If you prefer another provider, set NEXT_PUBLIC_SPRITE_PROVIDER to:
 *   - 'stability' (default) — Stability AI / Stable Diffusion
 *   - 'openai'   — DALL-E 3 (requires NEXT_PUBLIC_OPENAI_API_KEY)
 */

const PROVIDER = process.env.NEXT_PUBLIC_SPRITE_PROVIDER || 'stability';

// Stability AI config
const STABILITY_API_URL = 'https://api.stability.ai/v2beta/stable-image/generate/sd3';
const STABILITY_API_KEY = process.env.NEXT_PUBLIC_STABILITY_API_KEY || '';

// OpenAI config (alternative)
const OPENAI_API_KEY = process.env.NEXT_PUBLIC_OPENAI_API_KEY || '';

export interface SpriteGenerationOptions {
  prompt: string;
  width?: number;
  height?: number;
  style?: 'pixel_art' | 'isometric' | 'realistic' | 'cartoon';
  negativePrompt?: string;
}

const STYLE_SUFFIXES: Record<string, string> = {
  pixel_art: ', pixel art style, retro game sprite, clean edges, transparent background',
  isometric: ', isometric view, game asset, clean render, transparent background',
  realistic: ', realistic render, high detail, game asset, transparent background',
  cartoon: ', cartoon style, flat colors, game sprite, transparent background',
};

export function isSpriteGeneratorConfigured(): boolean {
  if (PROVIDER === 'stability') return !!STABILITY_API_KEY;
  if (PROVIDER === 'openai') return !!OPENAI_API_KEY;
  return false;
}

export function getProviderName(): string {
  if (PROVIDER === 'stability') return 'Stability AI';
  if (PROVIDER === 'openai') return 'DALL-E';
  return 'Unknown';
}

/**
 * Generate a sprite image using the configured AI provider.
 * Returns a Blob of the generated PNG.
 */
export async function generateSprite(options: SpriteGenerationOptions): Promise<Blob> {
  if (PROVIDER === 'stability') {
    return generateWithStability(options);
  } else if (PROVIDER === 'openai') {
    return generateWithOpenAI(options);
  }
  throw new Error(`Unknown sprite provider: ${PROVIDER}`);
}

/**
 * Generate using Stability AI (Stable Diffusion 3)
 */
async function generateWithStability(options: SpriteGenerationOptions): Promise<Blob> {
  if (!STABILITY_API_KEY) {
    throw new Error(
      'Stability AI API key not configured.\n' +
      '1. Go to https://platform.stability.ai/account/keys\n' +
      '2. Create a free account\n' +
      '3. Add NEXT_PUBLIC_STABILITY_API_KEY=sk-... to .env.local'
    );
  }

  const styleSuffix = STYLE_SUFFIXES[options.style || 'pixel_art'] || '';
  const fullPrompt = options.prompt + styleSuffix;

  const formData = new FormData();
  formData.append('prompt', fullPrompt);
  formData.append('output_format', 'png');
  
  if (options.negativePrompt) {
    formData.append('negative_prompt', options.negativePrompt);
  }

  const response = await fetch(STABILITY_API_URL, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${STABILITY_API_KEY}`,
      'Accept': 'image/*',
    },
    body: formData,
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(
      `Stability AI error (${response.status}): ${errorText}`
    );
  }

  return await response.blob();
}

/**
 * Generate using OpenAI DALL-E 3
 */
async function generateWithOpenAI(options: SpriteGenerationOptions): Promise<Blob> {
  if (!OPENAI_API_KEY) {
    throw new Error(
      'OpenAI API key not configured.\n' +
      'Add NEXT_PUBLIC_OPENAI_API_KEY=sk-... to .env.local'
    );
  }

  const styleSuffix = STYLE_SUFFIXES[options.style || 'pixel_art'] || '';
  const fullPrompt = options.prompt + styleSuffix;

  const response = await fetch('https://api.openai.com/v1/images/generations', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'dall-e-3',
      prompt: fullPrompt,
      n: 1,
      size: '1024x1024',
      response_format: 'url',
    }),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(
      `OpenAI API error (${response.status}): ${errorData.error?.message || response.statusText}`
    );
  }

  const data = await response.json();
  const imageUrl = data.data[0].url;
  
  // Download the image as blob
  const imageResponse = await fetch(imageUrl);
  return await imageResponse.blob();
}
