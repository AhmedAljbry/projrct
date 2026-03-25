import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:gal/gal.dart';



// ==========================================
// الشاشة الرئيسية: لاختيار الصورة
// ==========================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlurEditorScreen(imageFile: File(image.path)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختيار صورة')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _pickImage(context),
          icon: const Icon(Icons.photo_library),
          label: const Text('اختر صورة من الاستوديو', style: TextStyle(fontSize: 18)),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
        ),
      ),
    );
  }
}

// ==========================================
// الدالة الخلفية (Isolate): للمعالجة الفعلية بدون تجميد الواجهة
// يجب أن تكون خارج الكلاسات (Top-level function)
// ==========================================
Future<Uint8List> _applyRealBlur(Map<String, dynamic> params) async {
  String imagePath = params['path'];
  double blurValue = params['blurValue'];

  // 1. قراءة الصورة
  final bytes = await File(imagePath).readAsBytes();
  img.Image? originalImage = img.decodeImage(bytes);

  if (originalImage == null) throw Exception('تعذر قراءة بيانات الصورة');

  // 2. تحسين الأداء (Optimization): تصغير الصورة إذا كانت ضخمة جداً
  // هذا يمنع انهيار التطبيق ويجعل المعالجة أسرع بـ 10 أضعاف
  img.Image imageToProcess = originalImage;
  if (originalImage.width > 1000) {
    imageToProcess = img.copyResize(originalImage, width: 1000);
  }

  // 3. تطبيق فلتر التغبيش الفعلي (نضرب القيمة في 2 لتتقارب مع التغبيش الشكلي)
  img.Image blurredImage = img.gaussianBlur(imageToProcess, radius: (blurValue * 2).toInt());

  // 4. إعادة تشفير الصورة إلى بايتات للحفظ
  return Uint8List.fromList(img.encodeJpg(blurredImage, quality: 95));
}

// ==========================================
// شاشة التعديل: المعاينة الفورية والحفظ
// ==========================================
class BlurEditorScreen extends StatefulWidget {
  final File imageFile;

  const BlurEditorScreen({super.key, required this.imageFile});

  @override
  State<BlurEditorScreen> createState() => _BlurEditorScreenState();
}

class _BlurEditorScreenState extends State<BlurEditorScreen> {
  double _blurValue = 0.0;
  bool _isProcessing = false;

  Future<void> _processAndSaveImage() async {
    if (_blurValue == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قم بزيادة التغبيش أولاً قبل الحفظ.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // إرسال البيانات للمعالجة في مسار خلفي (Isolate)
      final Uint8List processedBytes = await compute(_applyRealBlur, {
        'path': widget.imageFile.path,
        'blurValue': _blurValue,
      });

      // حفظ الصورة في استوديو الهاتف باستخدام مكتبة Gal
      final String fileName = 'blur_${DateTime.now().millisecondsSinceEpoch}';
      await Gal.putImageBytes(processedBytes, name: fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ الصورة بنجاح في الاستوديو!'),
            backgroundColor: Colors.green,
          ),
        );
        // العودة للشاشة الرئيسية بعد الحفظ بنجاح
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ حدث خطأ أثناء الحفظ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تغبيش الصورة'),
        actions: [
          _isProcessing
              ? const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.check, size: 30),
            onPressed: _processAndSaveImage,
            tooltip: 'حفظ الصورة',
          ),
        ],
      ),
      body: Column(
        children: [
          // مساحة عرض الصورة
          Expanded(
            child: ClipRect( // يمنع خروج تأثير التغبيش خارج إطار الصورة
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. الصورة الأصلية كخلفية
                  Image.file(widget.imageFile, fit: BoxFit.contain),

                  // 2. التغبيش الشكلي (UI Blur) المعتمد على كرت الشاشة لأداء فائق السرعة
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: _blurValue,
                        sigmaY: _blurValue,
                      ),
                      // لون شفاف كطبقة فوقية مطلوبة لعمل الـ BackdropFilter
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // منطقة التحكم (شريط التمرير)
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
                color: Colors.grey.shade900,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ]
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('قوة الضبابية', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${_blurValue.toInt()}'),
                  ],
                ),
                Slider(
                  value: _blurValue,
                  min: 0.0,
                  max: 20.0,
                  activeColor: Colors.blueAccent,
                  inactiveColor: Colors.grey.shade700,
                  onChanged: _isProcessing
                      ? null // تعطيل التعديل أثناء الحفظ
                      : (value) {
                    setState(() {
                      _blurValue = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}