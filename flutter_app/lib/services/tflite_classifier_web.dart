
class TFLiteClassifier {
  static final TFLiteClassifier _instance = TFLiteClassifier._internal();
  factory TFLiteClassifier() => _instance;
  TFLiteClassifier._internal();

  bool get isInitialized => false;
  List<String> get classNames => [];

  Future<bool> initialize() async {
    print('TFLite not supported on web');
    return false;
  }

  Future<Map<String, dynamic>?> classifyImage(dynamic imageFile) async {
    print('TFLite not supported on web');
    return null;
  }

  void dispose() {}
}
