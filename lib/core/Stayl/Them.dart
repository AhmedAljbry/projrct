import 'package:flutter/material.dart';

class AppUI {
  static const bg = Color(0xFF0B0F17);
  static const card = Color(0xFF121A2A);
  static const stroke = Color(0x1AFFFFFF);
  static const accent = Color(0xFF8B5CF6); // بنفسج عصري
  static const text = Color(0xFFF4F6FB);
  static const sub = Color(0xB3FFFFFF);

  static List<BoxShadow> softShadow = const [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];
}