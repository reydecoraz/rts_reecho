"""
RTS Sprite Tool — Local background removal service using rembg.
Runs on port 5050. Provides:
  POST /remove-bg  — accepts an image, returns it with transparent background
  GET  /health      — health check

Install: pip install rembg flask flask-cors pillow
Run:     python server.py
"""
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from rembg import remove
from PIL import Image
import io

app = Flask(__name__)
CORS(app)

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "service": "rembg-local"})

@app.route('/remove-bg', methods=['POST'])
def remove_bg():
    if 'image' not in request.files:
        return jsonify({"error": "No image file provided. Use form field 'image'."}), 400

    file = request.files['image']

    try:
        input_bytes = file.read()
        output_bytes = remove(input_bytes)

        # Ensure output is PNG with alpha channel
        img = Image.open(io.BytesIO(output_bytes))
        if img.mode != 'RGBA':
            img = img.convert('RGBA')

        output_buffer = io.BytesIO()
        img.save(output_buffer, format='PNG')
        output_buffer.seek(0)

        return send_file(
            output_buffer,
            mimetype='image/png',
            as_attachment=False,
            download_name='sprite_nobg.png'
        )
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/remove-bg-batch', methods=['POST'])
def remove_bg_batch():
    """Process multiple images at once. Send as multipart form with fields image_0, image_1, etc."""
    results = []
    idx = 0
    while f'image_{idx}' in request.files:
        file = request.files[f'image_{idx}']
        try:
            input_bytes = file.read()
            output_bytes = remove(input_bytes)
            img = Image.open(io.BytesIO(output_bytes))
            if img.mode != 'RGBA':
                img = img.convert('RGBA')
            output_buffer = io.BytesIO()
            img.save(output_buffer, format='PNG')
            results.append({
                "index": idx,
                "filename": file.filename,
                "size": output_buffer.tell(),
                "status": "ok"
            })
        except Exception as e:
            results.append({
                "index": idx,
                "filename": file.filename,
                "error": str(e),
                "status": "error"
            })
        idx += 1

    return jsonify({"processed": len(results), "results": results})

if __name__ == '__main__':
    print("[RTS Sprite Tool] Background Removal Service")
    print("   Endpoint: http://localhost:5050/remove-bg")
    print("   Health:   http://localhost:5050/health")
    app.run(host='0.0.0.0', port=5050, debug=True)
