import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'models/app_models.dart';
import 'services/yolo_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CountObjectApp());
}

class CountObjectApp extends StatelessWidget {
  const CountObjectApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Object Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const CategorySelectionScreen(),
    );
  }
}

// ۱. صفحه انتخاب نوع کالای شمارشی
class CategorySelectionScreen extends StatelessWidget {
  const CategorySelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('انتخاب نوع کالای شمارشی'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: appCategories.length,
          itemBuilder: (context, index) {
            final category = appCategories[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CounterHomeScreen(category: category),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.grid_view_rounded,
                      size: 48,
                      color: Colors.indigo,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      category.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ۲. صفحه اصلی پردازش و شمارش
class CounterHomeScreen extends StatefulWidget {
  final CountingCategory category;

  const CounterHomeScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<CounterHomeScreen> createState() => _CounterHomeScreenState();
}

class _CounterHomeScreenState extends State<CounterHomeScreen> {
  final YoloService _yoloService = YoloService();
  final ImagePicker _picker = ImagePicker();

  String? _imagePath;
  List<DetectedObject> _detectedObjects = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadModelForCategory();
  }

  Future<void> _loadModelForCategory() async {
    setState(() => _isLoading = true);
    await _yoloService.loadModel(
      widget.category.modelPath,
      widget.category.labelPath,
    );
    setState(() => _isLoading = false);
  }

  // گرفتن عکس یا انتخاب از گالری
  Future<void> _pickImage(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(source: source);
    if (photo == null) return;

    setState(() {
      _imagePath = photo.path;
      _isLoading = true;
      _detectedObjects.clear();
    });

    final results = await _yoloService.runInference(photo.path);

    setState(() {
      _detectedObjects = results;
      _isLoading = false;
    });
  }

  // افزودن دستی نقطه با لمس
  void _addPointManually(double relativeX, double relativeY) {
    setState(() {
      _detectedObjects.add(
        DetectedObject(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          label: 'Manual',
          confidence: 1.0,
          x: relativeX,
          y: relativeY,
        ),
      );
    });
  }

  // حذف نقطه با لمس مجدد
  void _removePointManually(DetectedObject object) {
    setState(() {
      _detectedObjects.removeWhere((item) => item.id == object.id);
    });
  }

  @override
  void dispose() {
    _yoloService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('شمارش: ${widget.category.title}'),
        centerTitle: true,
        actions: [
          if (_detectedObjects.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => setState(() => _detectedObjects.clear()),
            ),
        ],
      ),
      body: Column(
        children: [
          // نوار نمایش شمارش
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.indigo.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تعداد کل شناسایی شده:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade900,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_detectedObjects.length}',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ناحیه نمایش تصویر و CustomPaint
          Expanded(
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : _imagePath == null
                  ? const Text('برای شروع، عکس بگیرید یا عکسی انتخاب کنید')
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onTapUp: (details) {
                            double rx =
                                details.localPosition.dx / constraints.maxWidth;
                            double ry =
                                details.localPosition.dy /
                                constraints.maxHeight;

                            bool removed = false;
                            for (var obj in List.from(_detectedObjects)) {
                              double dx = (obj.x - rx) * constraints.maxWidth;
                              double dy = (obj.y - ry) * constraints.maxHeight;

                              // اگر کلیک به نقطه نزدیک بود، حذف کن
                              if ((dx * dx + dy * dy) < 0.002) {
                                _removePointManually(obj);
                                removed = true;
                                break;
                              }
                            }

                            if (!removed) {
                              _addPointManually(rx, ry);
                            }
                          },
                          child: CustomPaint(
                            foregroundPainter: ObjectPainter(_detectedObjects),
                            child: Image.file(
                              File(_imagePath!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),

      // دکمه‌های پایین صفحه
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('دوربین'),
            ),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('گالری'),
            ),
          ],
        ),
      ),
    );
  }
}

// ۳. رندرکننده مارکرها و شماره‌ها روی تصویر
class ObjectPainter extends CustomPainter {
  final List<DetectedObject> objects;

  ObjectPainter(this.objects);

  @override
  void paint(Canvas canvas, Size size) {
    final paintCircle = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    final paintText = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < objects.length; i++) {
      final obj = objects[i];
      final center = Offset(obj.x * size.width, obj.y * size.height);

      // رسم دایره
      canvas.drawCircle(center, 10, paintCircle);

      // رسم شماره داخل دایره
      paintText.text = TextSpan(
        text: '${i + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      );
      paintText.layout();
      paintText.paint(
        canvas,
        Offset(
          center.dx - (paintText.width / 2),
          center.dy - (paintText.height / 2),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
