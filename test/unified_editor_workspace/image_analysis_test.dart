import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as im;
import 'package:untitled2/unified_editor_workspace/engine/image_analysis.dart';

void main() {
  test('analyzeScene returns bounded scores on tiny image', () {
    final img = im.Image(width: 32, height: 32);
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 32; x++) {
        img.setPixelRgb(x, y, 120, 130, 140);
      }
    }
    final a = analyzeScene(img);
    expect(a.confidence, inInclusiveRange(0.2, 1.0));
    expect(a.meanLuma, inInclusiveRange(0.0, 1.0));
    expect(a.skyScore, inInclusiveRange(0.0, 1.0));
  });
}
