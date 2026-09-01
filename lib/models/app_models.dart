// مدل شیء شناسایی شده
class DetectedObject {
  final String id;
  final String label;
  final double confidence;
  final double x; // درصد نسبت به عرض تصویر (0.0 تا 1.0)
  final double y; // درصد نسبت به طول تصویر (0.0 تا 1.0)

  DetectedObject({
    required this.id,
    required this.label,
    required this.confidence,
    required this.x,
    required this.y,
  });
}

// مدل دسته‌بندی کالاها
class CountingCategory {
  final String id;
  final String title;
  final String modelPath;
  final String labelPath;

  CountingCategory({
    required this.id,
    required this.title,
    required this.modelPath,
    required this.labelPath,
  });
}

// لیست دسته‌بندی‌های پیش‌فرض
final List<CountingCategory> appCategories = [
  CountingCategory(
    id: 'general',
    title: 'اشیاء عمومی',
    modelPath: 'assets/models/yolov8n.tflite',
    labelPath: 'assets/models/labels.txt',
  ),
  CountingCategory(
    id: 'pills',
    title: 'قرص و دارو',
    modelPath: 'assets/models/pills.tflite',
    labelPath: 'assets/models/labels.txt',
  ),
  CountingCategory(
    id: 'pipes',
    title: 'لوله و میلگرد',
    modelPath: 'assets/models/pipes.tflite',
    labelPath: 'assets/models/labels.txt',
  ),
  CountingCategory(
    id: 'timber',
    title: 'چوب و الوار',
    modelPath: 'assets/models/timber.tflite',
    labelPath: 'assets/models/labels.txt',
  ),
];
