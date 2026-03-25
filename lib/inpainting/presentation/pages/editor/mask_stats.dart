class MaskStats {
  final int w, h;
  final int total;
  final int nonZero;
  final double nonZeroPct;
  final int minV, maxV;
  final double mean;
  final int bboxMinX, bboxMinY, bboxMaxX, bboxMaxY;
  final bool hasBBox;
  final Map<String, int> buckets;

  const MaskStats({
    required this.w,
    required this.h,
    required this.total,
    required this.nonZero,
    required this.nonZeroPct,
    required this.minV,
    required this.maxV,
    required this.mean,
    required this.bboxMinX,
    required this.bboxMinY,
    required this.bboxMaxX,
    required this.bboxMaxY,
    required this.hasBBox,
    required this.buckets,
  });

  @override
  String toString() {
    if (!hasBBox) {
      return 'w=$w h=$h nonZero=$nonZero (${nonZeroPct.toStringAsFixed(2)}%) '
          'min=$minV max=$maxV mean=${mean.toStringAsFixed(2)} bbox=NONE buckets=$buckets';
    }
    return 'w=$w h=$h nonZero=$nonZero (${nonZeroPct.toStringAsFixed(2)}%) '
        'min=$minV max=$maxV mean=${mean.toStringAsFixed(2)} '
        'bbox=[$bboxMinX,$bboxMinY]-[$bboxMaxX,$bboxMaxY] buckets=$buckets';
  }
}