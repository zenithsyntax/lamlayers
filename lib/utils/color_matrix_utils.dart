class ColorMatrixUtils {
  static List<double> createColorMatrix({
    double brightness = 0.0,
    double contrast = 0.0,
    double saturation = 0.0,
    double hue = 0.0,
  }) {
    // Base identity matrix
    List<double> matrix = [
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ];

    // Apply brightness
    for (int i = 0; i < 3; i++) {
      matrix[i * 5 + 4] = brightness * 255;
    }

    // Apply contrast
    double contrastValue = contrast + 1;
    for (int i = 0; i < 3; i++) {
      matrix[i * 5 + i] = contrastValue;
      matrix[i * 5 + 4] += (1 - contrastValue) * 128;
    }

    // Apply saturation
    double saturationValue = saturation + 1;
    double lumR = 0.299;
    double lumG = 0.587;
    double lumB = 0.114;

    matrix[0] = lumR * (1 - saturationValue) + saturationValue;
    matrix[1] = lumG * (1 - saturationValue);
    matrix[2] = lumB * (1 - saturationValue);
    matrix[5] = lumR * (1 - saturationValue);
    matrix[6] = lumG * (1 - saturationValue) + saturationValue;
    matrix[7] = lumB * (1 - saturationValue);
    matrix[10] = lumR * (1 - saturationValue);
    matrix[11] = lumG * (1 - saturationValue);
    matrix[12] = lumB * (1 - saturationValue) + saturationValue;

    return matrix;
  }
}