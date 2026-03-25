import 'package:flutter/foundation.dart';

class SharedImageData {
  // متغيرات لمراقبة الصورة المشتركة بين الشاشتين
  static final ValueNotifier<String?> imagePath = ValueNotifier(null);
  static final ValueNotifier<Uint8List?> imageBytes = ValueNotifier(null);

  static void setImage(String path, Uint8List bytes) {
    imagePath.value = path;
    imageBytes.value = bytes;
  }
}