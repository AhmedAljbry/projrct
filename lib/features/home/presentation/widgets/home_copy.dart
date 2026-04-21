import 'package:flutter/material.dart';

bool isArabicLocale(BuildContext context) {
  return Localizations.localeOf(context).languageCode.toLowerCase().startsWith(
        'ar',
      );
}

String homeText(
  BuildContext context, {
  required String ar,
  required String en,
}) {
  return isArabicLocale(context) ? ar : en;
}
