/**
 * Background Removal Client
 * Connects to the local rembg Python service running on port 5050.
 */

const REMBG_URL = process.env.NEXT_PUBLIC_REMBG_URL || 'http://localhost:5050';

/**
 * Check if the rembg service is running.
 */
export async function isRembgAvailable(): Promise<boolean> {
  try {
    const res = await fetch(`${REMBG_URL}/health`, { signal: AbortSignal.timeout(2000) });
    return res.ok;
  } catch {
    return false;
  }
}

/**
 * Remove the background from an image.
 * Sends the image to the local rembg service and returns a transparent PNG Blob.
 */
export async function removeBackground(imageBlob: Blob): Promise<Blob> {
  const formData = new FormData();
  formData.append('image', imageBlob, 'input.png');

  const response = await fetch(`${REMBG_URL}/remove-bg`, {
    method: 'POST',
    body: formData,
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(
      `Background removal failed (${response.status}): ${errorData.error || response.statusText}`
    );
  }

  return await response.blob();
}

/**
 * Remove background from a File object (convenience wrapper).
 */
export async function removeBackgroundFromFile(file: File): Promise<Blob> {
  return removeBackground(file);
}
