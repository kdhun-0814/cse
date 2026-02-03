from PIL import Image
import os

def add_margin(input_path, output_path):
    try:
        img = Image.open(input_path).convert("RGBA")
        width, height = img.size
        
        # Determine canvas size (Square, slightly larger than max dimension to allow padding)
        # However, for Adaptive Icon, the LOGO itself must be ~66% of the canvas.
        # So Canvas Size = MaxDimension / 0.6
        max_dim = max(width, height)
        canvas_size = int(max_dim / 0.6)
        
        # Create transparent canvas
        canvas = Image.new('RGBA', (canvas_size, canvas_size), (255, 255, 255, 0))
        
        # Calculate center position
        x = (canvas_size - width) // 2
        y = (canvas_size - height) // 2
        
        # Paste original image
        canvas.paste(img, (x, y), img)
        
        # Resize to standard 512x512 for efficiency (optional, but good for build)
        canvas = canvas.resize((512, 512), Image.Resampling.LANCZOS)
        
        canvas.save(output_path)
        print(f"Created padded icon: {output_path}")
        
    except ImportError:
        print("Pillow not installed. Please install it: pip install Pillow")
        exit(1)
    except Exception as e:
        print(f"Error: {e}")
        exit(1)

if __name__ == "__main__":
    input_file = "app/assets/icon/foreground.png"
    output_file = "app/assets/icon/foreground_padded.png"
    
    # Adjust path if running from root or app
    if not os.path.exists(input_file):
        # Try adjusting for cwd
        if os.path.exists(f"../{input_file}"):
            input_file = f"../{input_file}"
            output_file = f"../{output_file}"
            
    add_margin(input_file, output_file)
