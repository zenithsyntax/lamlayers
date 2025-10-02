# Image Stroke Processor

This Flutter implementation replicates the exact stroke method from your Python code, providing pixel-level stroke effects for PNG images with transparency.

## How It Works

The `ImageStrokeProcessor` class implements the same algorithm as your Python code:

1. **Load Image Pixels**: Converts the image to a 2D pixel array (RGBA format)
2. **Loop Through Pixels**: Iterates over every pixel in the original image
3. **Check Transparency**: For each pixel, checks if alpha != 0 (non-transparent)
4. **Draw Stroke in 8 Directions**: For non-transparent pixels, draws stroke pixels in:
   - Right (`pixelsBack[r, c + k]`)
   - Left (`pixelsBack[r, c - k]`)
   - Down (`pixelsBack[r + k, c]`)
   - Up (`pixelsBack[r - k, c]`)
   - Main diagonal down-right (`pixelsBack[r + k, c + k]`)
   - Main diagonal up-left (`pixelsBack[r - k, c - k]`)
   - Secondary diagonal up-right (`pixelsBack[r + k, c - k]`)
   - Secondary diagonal down-left (`pixelsBack[r - k, c + k]`)
5. **Repeat for Stroke Width**: The loop repeats `k` times (1 to strokeWidth)
6. **Paste Original**: Finally pastes the original image on top (like your Python code)

## Python vs Flutter Comparison

### Python Code (Your Original)
```python
for i in range(brain.size[0]):
    for j in range(brain.size[1]):
        r, c = i+200, j+200 
        if(pixelsBrain[i,j][3]!=0): # checking alpha
            for k in range(30): # stroke width loop
                pixelsBack[r, c + k] = (0, 0, 0, 255)     # right
                pixelsBack[r, c - k] = (0, 0, 0, 255)     # left
                pixelsBack[r + k, c] = (0, 0, 0, 255)     # down
                pixelsBack[r - k, c] = (0, 0, 0, 255)     # up
                pixelsBack[r + k, c + k] = (0, 0, 0, 255) # main diagonal down
                pixelsBack[r - k, c - k] = (0, 0, 0, 255) # main diagonal up
                pixelsBack[r + k, c - k] = (0, 0, 0, 255) # secondary diagonal (/) down
                pixelsBack[r - k, c + k] = (0, 0, 0, 255) # secondary diagonal (/) up
```

### Flutter Code (This Implementation)
```dart
for (int y = 0; y < originalHeight; y++) {
  for (int x = 0; x < originalWidth; x++) {
    final int originalIndex = (y * originalWidth + x) * 4;
    
    if (originalPixels[originalIndex + 3] != 0) { // checking alpha
      final int centerX = x + offsetX;
      final int centerY = y + offsetY;
      
      for (int k = 1; k <= strokeWidth; k++) { // stroke width loop
        final List<List<int>> directions = [
          [centerX, centerY + k],     // right
          [centerX, centerY - k],     // left  
          [centerX + k, centerY],     // down
          [centerX - k, centerY],     // up
          [centerX + k, centerY + k], // main diagonal down
          [centerX - k, centerY - k], // main diagonal up
          [centerX + k, centerY - k], // secondary diagonal (/) down
          [centerX - k, centerY + k], // secondary diagonal (/) up
        ];
        
        // Draw stroke pixels...
      }
    }
  }
}
```

## Usage

### Basic Usage
```dart
import 'package:lamlayers/utils/image_stroke_processor.dart';

// Apply stroke to a ui.Image
final ui.Image strokedImage = await ImageStrokeProcessor.addStrokeToImage(
  originalImage,
  strokeWidth: 30,
  strokeColor: const ui.Color(0xFF000000), // Black
);

// Apply stroke to image from bytes
final ui.Image strokedImage = await ImageStrokeProcessor.addStrokeToImageFromBytes(
  imageBytes,
  strokeWidth: 30,
  strokeColor: const ui.Color(0xFF000000),
);

// Apply stroke to image file
final ui.Image strokedImage = await ImageStrokeProcessor.addStrokeToImageFile(
  File('path/to/image.png'),
  strokeWidth: 30,
  strokeColor: const ui.Color(0xFF000000),
);
```

### In Poster Maker Screen

The stroke functionality is integrated into the poster maker screen:

1. Select an image on the canvas
2. Click the "Add Stroke" button in the image options panel
3. Adjust stroke width (1-100 pixels) and color
4. Click "Apply Stroke"

The stroke effect will be applied and the image will be updated on the canvas.

## Parameters

- **strokeWidth**: Number of pixels for stroke thickness (default: 30, matches Python example)
- **strokeColor**: Color of the stroke (default: black, matches Python example)

## Technical Details

- Uses `ui.decodeImageFromPixels` for efficient pixel manipulation
- Handles RGBA pixel format (4 bytes per pixel)
- Creates expanded canvas to accommodate stroke padding
- Preserves original image transparency
- Maintains image quality through lossless processing

## Performance

The algorithm processes each pixel individually, similar to the Python implementation. For large images, processing time scales with:
- Image dimensions (width × height)
- Stroke width
- Number of non-transparent pixels

## Example Output

Just like your Python code, this creates a stroke effect that:
- Follows the exact edges of non-transparent pixels
- Creates uniform stroke width in all directions
- Preserves the original image on top of the stroke
- Works with any PNG image containing transparency
