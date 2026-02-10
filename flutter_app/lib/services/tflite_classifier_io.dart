import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// TensorFlow Lite classifier for lost and found items
/// Runs inference directly on device - no server needed
class TFLiteClassifier {
  static final TFLiteClassifier _instance = TFLiteClassifier._internal();
  factory TFLiteClassifier() => _instance;
  TFLiteClassifier._internal();

  Interpreter? _interpreter;
  List<String> _classNames = [];
  bool _isInitialized = false;

  // Model configuration
  static const String _modelPath =
      'assets/ml/lost_and_found_classifier1.tflite';
  static const String _labelsPath = 'assets/ml/class_names.txt';
  static const int _inputSize = 224;
  static const double _confThreshold = 0.65;
  static const double _marginThreshold = 0.20;

  // Category mapping from ML classes to backend enum
  static const Map<String, String> _mlToBackendCategory = {
    'backpack': 'ACCESSORIES',
    'bottle': 'OTHERS',
    'headphone': 'ELECTRONIC',
    'laptop': 'ELECTRONIC',
    'mobile phone': 'ELECTRONIC',
    'wallet': 'ACCESSORIES',
    'watch': 'ACCESSORIES',
    'other': 'OTHERS',
  };

  bool get isInitialized => _isInitialized;
  List<String> get classNames => _classNames;

  /// Initialize the TFLite model
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Load model
      _interpreter = await Interpreter.fromAsset(_modelPath);

      // Load class names
      final labelsData = await rootBundle.loadString(_labelsPath);
      _classNames = labelsData
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      _isInitialized = true;
      print('TFLite classifier initialized with ${_classNames.length} classes');
      return true;
    } catch (e) {
      print('Failed to initialize TFLite classifier: $e');
      return false;
    }
  }

  /// Classify an image file
  /// Returns: {predictedClass, confidence, backendCategory, allProbabilities}
  Future<Map<String, dynamic>?> classifyImage(dynamic imageFile) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    try {
      final file = imageFile as File;
      // Read and preprocess image
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Resize to model input size
      final resized =
          img.copyResize(image, width: _inputSize, height: _inputSize);

      // Convert to float32 input tensor with MobileNetV2 preprocessing
      // MobileNetV2 expects values in [-1, 1]
      final input = _preprocessImage(resized);

      // Run inference
      final output =
          List.filled(_classNames.length, 0.0).reshape([1, _classNames.length]);
      _interpreter!.run(input, output);

      // Get predictions
      final predictions = (output[0] as List<double>);

      // Build probabilities map
      final allProbabilities = <String, double>{};
      for (int i = 0; i < _classNames.length; i++) {
        allProbabilities[_classNames[i]] = predictions[i];
      }

      // Get top-2 predictions
      final sorted = List.generate(_classNames.length, (i) => i)
        ..sort((a, b) => predictions[b].compareTo(predictions[a]));

      final top1Idx = sorted[0];
      final top2Idx = sorted[1];
      final top1Score = predictions[top1Idx];
      final top2Score = predictions[top2Idx];

      // Open-set decision
      String predictedClass;
      if (top1Score < _confThreshold ||
          (top1Score - top2Score) < _marginThreshold) {
        predictedClass = 'Other';
      } else {
        predictedClass = _classNames[top1Idx];
      }

      // Map to backend category
      final backendCategory = _mlToBackendCategory[predictedClass] ?? 'OTHERS';

      return {
        'success': true,
        'predictedClass': predictedClass,
        'confidence': top1Score,
        'backendCategory': backendCategory,
        'allProbabilities': allProbabilities,
      };
    } catch (e) {
      print('TFLite classification error: $e');
      return null;
    }
  }

  /// Preprocess image for EfficientNetB0
  /// EfficientNet expects pixel values in [0, 255] range (no normalization)
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = image.getPixel(x, y);
            // EfficientNet preprocessing: pixel values as-is (0-255)
            return [
              pixel.r.toDouble(),
              pixel.g.toDouble(),
              pixel.b.toDouble(),
            ];
          },
        ),
      ),
    );
    return input;
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
