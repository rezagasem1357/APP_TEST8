import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/app_models.dart';

class YoloService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  // بارگذاری مدل متناسب با دسته‌بندی انتخابی
  Future<void> loadModel(String modelPath, String labelPath) async {
    try {
      if (_interpreter != null) {
        _interpreter!.close();
      }

      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(modelPath, options: options);

      final labelData = await rootBundle.loadString(labelPath);
      _labels = labelData.split('\n').where((s) => s.isNotEmpty).toList();

      _isLoaded = true;
    } catch (e) {
      print("خطا در بارگذاری مدل ($modelPath): $e");
      _isLoaded = false;
    }
  }

  // پردازش تصویر و استخراج خروجی
  Future<List<DetectedObject>> runInference(String imagePath) async {
    if (!_isLoaded || _interpreter == null) return [];

    final bytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return [];

    // تغییر اندازه تصویر به ۶۴۰x۶۴۰ برای ورودی مدل YOLOv8
    final resizedImage = img.copyResize(image, width: 640, height: 640);

    // تبدیل پیکسل‌ها به تنسور [1, 640, 640, 3] و نرمال‌سازی
    var input = List.generate(
      1,
      (_) => List.generate(
        640,
        (y) => List.generate(640, (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      ),
    );

    // ساخت ماتریس خروجی استاندارد YOLOv8 با ابعاد [1, 84, 8400]
    var output = List.filled(1 * 84 * 8400, 0.0).reshape([1, 84, 8400]);

    // اجرای مدل
    _interpreter!.run(input, output);

    List<DetectedObject> results = [];
    final rawOutput = output[0] as List<List<double>>;

    // استخراج باکس‌ها با آستانه اطمینان بالای ۳۵ درصد
    for (int i = 0; i < 8400; i++) {
      double maxScore = 0.0;
      int maxClassIndex = -1;

      for (int c = 4; c < 84; c++) {
        if (rawOutput[c][i] > maxScore) {
          maxScore = rawOutput[c][i];
          maxClassIndex = c - 4;
        }
      }

      if (maxScore > 0.35) {
        double cx = rawOutput[0][i] / 640.0;
        double cy = rawOutput[1][i] / 640.0;

        String labelName =
            (maxClassIndex >= 0 && maxClassIndex < _labels.length)
            ? _labels[maxClassIndex]
            : 'Item';

        results.add(
          DetectedObject(
            id: '${DateTime.now().microsecondsSinceEpoch}_$i',
            label: labelName,
            confidence: maxScore,
            x: cx,
            y: cy,
          ),
        );
      }
    }

    return results;
  }

  void dispose() {
    _interpreter?.close();
  }
}
