part of 'editor_page.dart';


extension _EditorPageMaskQA on _EditorPageState {
  // =========================================================
  // PUBLIC ENTRY: Deep QA for current drawing + final mask
  // =========================================================
  Future<void> _testMaskRendering() async {
    final drawState = context.read<DrawingCubit>().state;
    if (drawState.strokes.isEmpty) {
      _toast(context, 'ارسم على الهدف أولاً', isError: true);
      return;
    }

    final pickState = context.read<ImagePickCubit>().state;
    if (pickState is! ImagePickReady) {
      _toast(context, 'الصورة غير جاهزة', isError: true);
      return;
    }

    _updateEditorUi(() => _isPreparing = true);

    try {
      final srcImage = pickState.uiImage;

      // 1) Stroke-space analysis
      final strokeStats = _analyzeStrokeSpace(
        strokes: drawState.strokes,
        imageWidth: srcImage.width,
        imageHeight: srcImage.height,
      );

      // 2) RAW mask
      final rawMask = await _renderBinaryMask(srcImage, drawState);
      final rawStats = await _analyzeMaskBytes(rawMask, label: 'RAW');

      // 3) FINAL mask
      final finalMask = await prepareMaskForLama(rawMask);
      final finalStats = await _analyzeMaskBytes(finalMask, label: 'FINAL');

      // 4) Diff
      final diffStats = await _compareMasks(rawMask, finalMask);

      // 5) Geometry
      final geometryDiagnosis = _diagnoseStrokeToMaskGeometry(
        strokeStats: strokeStats,
        rawStats: rawStats,
      );

      // 6) Overlays
      final overlayRaw = await _buildOverlayPng(srcImage, rawMask);
      final overlayFinal = await _buildOverlayPng(srcImage, finalMask);
      final diffOverlay = await _buildDiffOverlay(rawMask, finalMask);

      // 7) Polarity
      final rawPolarity = await _analyzeBinaryPolarity(rawMask);
      final finalPolarity = await _analyzeBinaryPolarity(finalMask);

      // 8) Inverted final for diagnostics only
      final invertedFinalMask = await _invertMaskPng(finalMask);
      final invertedFinalStats = await _analyzeMaskBytes(
        invertedFinalMask,
        label: 'FINAL_INVERTED',
      );
      final invertedOverlay = await _buildOverlayPng(srcImage, invertedFinalMask);
      final invertedPolarity = await _analyzeBinaryPolarity(invertedFinalMask);

      // 9) Final diagnosis
      final diagnosis = _diagnoseMaskPipeline(
        imageWidth: srcImage.width,
        imageHeight: srcImage.height,
        strokeStats: strokeStats,
        rawStats: rawStats,
        finalStats: finalStats,
        diffStats: diffStats,
      );

      final serverRiskNormal = _diagnoseServerEmptyMaskRisk(
        finalStats: finalStats,
        polarity: finalPolarity,
        maskBytesLength: finalMask.length,
      );

      final serverRiskInverted = _diagnoseServerEmptyMaskRisk(
        finalStats: invertedFinalStats,
        polarity: invertedPolarity,
        maskBytesLength: invertedFinalMask.length,
      );

      debugPrint('================ MASK QA REPORT ================');
      debugPrint('🟡 STROKES : ${strokeStats.pretty()}');
      debugPrint('🔵 RAW     : ${rawStats.pretty()}');
      debugPrint('🔵 RAW POL : ${rawPolarity.pretty()}');
      debugPrint('🟢 FINAL   : ${finalStats.pretty()}');
      debugPrint('🟢 FIN POL : ${finalPolarity.pretty()}');
      debugPrint('🟣 DIFF    : ${diffStats.pretty()}');
      debugPrint('🧭 GEOM    : $geometryDiagnosis');
      debugPrint('🚨 DIAGNOSIS:\n$diagnosis');
      debugPrint('🛰 SERVER RISK (NORMAL): $serverRiskNormal');
      debugPrint('🛰 SERVER RISK (INVERT): $serverRiskInverted');
      debugPrint('================================================');

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.bug_report_rounded, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mask QA - Deep Diagnostic',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _qaSectionTitle('1) Stroke Analysis'),
                  _qaLine('STROKES', strokeStats.pretty()),

                  SizedBox(height: 10),
                  _qaSectionTitle('2) Geometry Diagnosis'),
                  _qaLine('GEOMETRY', geometryDiagnosis),

                  SizedBox(height: 14),
                  _qaSectionTitle('3) RAW Mask'),
                  _qaLine('RAW', rawStats.pretty()),
                  _qaLine('RAW POLARITY', rawPolarity.pretty()),
                  SizedBox(height: 8),
                  _qaImageBox(
                    label: 'RAW MASK',
                    borderColor: Colors.blueAccent,
                    child: Image.memory(rawMask, fit: BoxFit.contain),
                  ),
                  SizedBox(height: 8),
                  _qaImageBox(
                    label: 'RAW OVERLAY',
                    borderColor: Colors.blueGrey,
                    child: Image.memory(overlayRaw, fit: BoxFit.contain),
                  ),

                  SizedBox(height: 14),
                  _qaSectionTitle('4) FINAL Mask (الذي يذهب للسيرفر)'),
                  _qaLine('FINAL', finalStats.pretty()),
                  _qaLine('FINAL POLARITY', finalPolarity.pretty()),
                  _qaLine('SERVER RISK (NORMAL)', serverRiskNormal),
                  SizedBox(height: 8),
                  _qaImageBox(
                    label: 'FINAL MASK',
                    borderColor: Colors.greenAccent,
                    child: Image.memory(finalMask, fit: BoxFit.contain),
                  ),
                  SizedBox(height: 8),
                  _qaImageBox(
                    label: 'FINAL OVERLAY',
                    borderColor: Colors.purpleAccent,
                    child: Image.memory(overlayFinal, fit: BoxFit.contain),
                  ),

                  SizedBox(height: 14),
                  _qaSectionTitle('5) FINAL INVERTED (تشخيص فقط)'),
                  _qaLine('FINAL INVERTED', invertedFinalStats.pretty()),
                  _qaLine('INVERTED POLARITY', invertedPolarity.pretty()),
                  _qaLine('SERVER RISK (INVERTED)', serverRiskInverted),
                  SizedBox(height: 8),
                  _qaImageBox(
                    label: 'FINAL INVERTED MASK',
                    borderColor: Colors.orangeAccent,
                    child: Image.memory(invertedFinalMask, fit: BoxFit.contain),
                  ),
                  SizedBox(height: 8),
                  _qaImageBox(
                    label: 'FINAL INVERTED OVERLAY',
                    borderColor: Colors.deepOrangeAccent,
                    child: Image.memory(invertedOverlay, fit: BoxFit.contain),
                  ),

                  SizedBox(height: 14),
                  _qaSectionTitle('6) RAW vs FINAL Difference'),
                  _qaLine('DIFF', diffStats.pretty()),
                  SizedBox(height: 8),
                  _qaImageBox(
                    label: 'DIFF OVERLAY (أبيض = تغيّر)',
                    borderColor: Colors.amber,
                    child: Image.memory(diffOverlay, fit: BoxFit.contain),
                  ),

                  SizedBox(height: 14),
                  _qaSectionTitle('7) Diagnosis'),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      diagnosis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'إغلاق',
                style: TextStyle(color: Color(0xFF2EE59D)),
              ),
            ),
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('❌ [MASK QA] error: $e');
      debugPrint('$st');
      _toast(context, 'Mask QA فشل: $e', isError: true);
    } finally {
      if (mounted) {
        _updateEditorUi(() => _isPreparing = false);
      }
    }
  }
  Future<void> _submitWithQaExample() async {
    final pickState = context.read<ImagePickCubit>().state;
    if (pickState is! ImagePickReady) {
      _toast(context, 'الصورة غير جاهزة', isError: true);
      return;
    }

    final drawState = context.read<DrawingCubit>().state;
    if (drawState.strokes.isEmpty) {
      _toast(context, 'لا يوجد mask مرسوم', isError: true);
      return;
    }

    try {
      // 1) ابنِ raw + final
      final rawMask = await _renderBinaryMask(pickState.uiImage, drawState);
      final finalMask = await prepareMaskForLama(rawMask);

      // 2) هنا حط نفس image bytes التي سترسلها فعلياً
      // مثال فقط: استبدل هذا بالمصدر الحقيقي للصورة المرسلة
      final imageByteData = await pickState.uiImage.toByteData(format: ui.ImageByteFormat.png);
      final imageBytesToUpload = imageByteData!.buffer.asUint8List();

      // 3) نفس bytes الماسك التي سترسلها فعلياً
      final maskBytesToUpload = finalMask;

      // 4) شغل preflight QA
      final report = await _runFullPreflightQa(
        srcImage: pickState.uiImage,
        imageBytesToUpload: imageBytesToUpload,
        maskBytesToUpload: maskBytesToUpload,
        imageFieldName: 'image',   // عدّلها إذا اسمك مختلف
        maskFieldName: 'mask',     // عدّلها إذا اسمك مختلف
        imageFilename: 'image.png',
        maskFilename: 'mask.png',
        imageContentType: 'image/png',
        maskContentType: 'image/png',
        url: 'YOUR_SUBMIT_JOB_URL',
      );

      debugPrint('PREUPLOAD REPORT => ${report.pretty()}');

      // 5) قارِن final mask مع uploaded mask
      await _debugCompareFinalVsUpload(
        finalMaskBytes: finalMask,
        uploadedMaskBytes: maskBytesToUpload,
      );

      // 6) بعد هذا أرسل الطلب الحقيقي
      // submit-job...
    } catch (e, st) {
      debugPrint('❌ submitWithQaExample error: $e');
      debugPrint('$st');
      _toast(context, 'فشل preflight QA: $e', isError: true);
    }
  }
  // =========================================================
  // PUBLIC ENTRY: Upload Preflight QA
  // شغّلها على نفس bytes التي سترسلها فعلياً
  // =========================================================
  Future<UploadPreflightReport> _runFullPreflightQa({
    required ui.Image srcImage,
    required Uint8List imageBytesToUpload,
    required Uint8List maskBytesToUpload,
    String imageFieldName = 'image',
    String maskFieldName = 'mask',
    String imageFilename = 'image.png',
    String maskFilename = 'mask.png',
    String imageContentType = 'image/png',
    String maskContentType = 'image/png',
    String? url,
  }) async {
    final maskStats = await _analyzeMaskBytes(maskBytesToUpload, label: 'UPLOAD_MASK');
    final polarity = await _analyzeBinaryPolarity(maskBytesToUpload);

    final report = UploadPreflightReport(
      imageHash: _shortHash(imageBytesToUpload),
      maskHash: _shortHash(maskBytesToUpload),
      imageBytes: imageBytesToUpload.length,
      maskBytes: maskBytesToUpload.length,
      maskStats: maskStats,
      polarity: polarity,
      imageFieldName: imageFieldName,
      maskFieldName: maskFieldName,
      imageFilename: imageFilename,
      maskFilename: maskFilename,
      imageContentType: imageContentType,
      maskContentType: maskContentType,
      expectedImageWidth: srcImage.width,
      expectedImageHeight: srcImage.height,
      url: url,
    );

    final serverRisk = _diagnoseServerEmptyMaskRisk(
      finalStats: maskStats,
      polarity: polarity,
      maskBytesLength: maskBytesToUpload.length,
    );

    debugPrint('================ PREUPLOAD QA =====================');
    debugPrint(report.pretty());
    debugPrint('serverEmptyMaskRisk: $serverRisk');
    debugPrint('expectedImageSize  : ${srcImage.width} x ${srcImage.height}');
    debugPrint('===================================================');

    return report;
  }

  // =========================================================
  // UI
  // =========================================================
  Widget _qaSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.orangeAccent,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _qaImageBox({
    required String label,
    required Color borderColor,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        SizedBox(height: 6),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2),
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: child,
        ),
      ],
    );
  }

  // =========================================================
  // Stroke-space QA
  // =========================================================
  StrokeSpaceStats _analyzeStrokeSpace({
    required List<dynamic> strokes,
    required int imageWidth,
    required int imageHeight,
  }) {
    int pointsCount = 0;
    int strokesCount = strokes.length;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    int outsideCount = 0;
    int singlePointStrokes = 0;

    for (final s in strokes) {
      final pts = (s.pts as List);
      if (pts.length == 1) singlePointStrokes++;

      for (final p in pts) {
        pointsCount++;

        final dx = p.dx as double;
        final dy = p.dy as double;

        minX = math.min(minX, dx);
        minY = math.min(minY, dy);
        maxX = math.max(maxX, dx);
        maxY = math.max(maxY, dy);

        if (dx < 0 || dy < 0 || dx >= imageWidth || dy >= imageHeight) {
          outsideCount++;
        }
      }
    }

    if (pointsCount == 0) {
      return StrokeSpaceStats.empty(imageWidth, imageHeight);
    }

    return StrokeSpaceStats(
      imageW: imageWidth,
      imageH: imageHeight,
      strokesCount: strokesCount,
      pointsCount: pointsCount,
      singlePointStrokes: singlePointStrokes,
      outsideCount: outsideCount,
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
    );
  }

  // =========================================================
  // Core pixel reading
  // =========================================================
  int _maskValueFromRgba(Uint8List rgba, int idx) {
    final r = rgba[idx];
    final g = rgba[idx + 1];
    final b = rgba[idx + 2];
    final a = rgba[idx + 3];

    if (a == 0) return 0;
    if (r == g && g == b) return r;

    final lum = (0.299 * r + 0.587 * g + 0.114 * b).round();
    return lum.clamp(0, 255);
  }

  // =========================================================
  // Analyze mask bytes
  // =========================================================
  Future<MaskStats> _analyzeMaskBytes(Uint8List maskPngBytes, {String label = ''}) async {
    final codec = await ui.instantiateImageCodec(maskPngBytes);
    final frame = await codec.getNextFrame();
    final img = frame.image;

    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgba = bd!.buffer.asUint8List();

    final w = img.width;
    final h = img.height;
    final total = w * h;

    int minV = 255;
    int maxV = 0;
    int sum = 0;
    int nonZero = 0;
    int full255 = 0;
    int soft = 0;

    int minX = 1 << 30;
    int minY = 1 << 30;
    int maxX = -1;
    int maxY = -1;

    int alphaNonOpaque = 0;
    int weirdColored = 0;

    final buckets = <String, int>{
      '0': 0,
      '1-50': 0,
      '51-100': 0,
      '101-150': 0,
      '151-200': 0,
      '201-254': 0,
      '255': 0,
    };

    int p = 0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final r = rgba[p];
        final g = rgba[p + 1];
        final b = rgba[p + 2];
        final a = rgba[p + 3];
        final v = _maskValueFromRgba(rgba, p);
        p += 4;

        if (a != 255) alphaNonOpaque++;
        if (!(r == g && g == b)) weirdColored++;

        minV = math.min(minV, v);
        maxV = math.max(maxV, v);
        sum += v;

        if (v == 0) {
          buckets['0'] = buckets['0']! + 1;
        } else if (v == 255) {
          buckets['255'] = buckets['255']! + 1;
          full255++;
        } else if (v <= 50) {
          buckets['1-50'] = buckets['1-50']! + 1;
          soft++;
        } else if (v <= 100) {
          buckets['51-100'] = buckets['51-100']! + 1;
          soft++;
        } else if (v <= 150) {
          buckets['101-150'] = buckets['101-150']! + 1;
          soft++;
        } else if (v <= 200) {
          buckets['151-200'] = buckets['151-200']! + 1;
          soft++;
        } else {
          buckets['201-254'] = buckets['201-254']! + 1;
          soft++;
        }

        if (v > 0) {
          nonZero++;
          minX = math.min(minX, x);
          minY = math.min(minY, y);
          maxX = math.max(maxX, x);
          maxY = math.max(maxY, y);
        }
      }
    }

    final hasBBox = nonZero > 0 && maxX >= 0 && maxY >= 0;
    final mean = total == 0 ? 0.0 : sum / total;
    final nonZeroPct = total == 0 ? 0.0 : (nonZero / total) * 100.0;
    final full255Pct = total == 0 ? 0.0 : (full255 / total) * 100.0;
    final softPct = total == 0 ? 0.0 : (soft / total) * 100.0;
    final alphaNonOpaquePct = total == 0 ? 0.0 : (alphaNonOpaque / total) * 100.0;
    final weirdColoredPct = total == 0 ? 0.0 : (weirdColored / total) * 100.0;

    return MaskStats(
      label: label,
      w: w,
      h: h,
      total: total,
      nonZero: nonZero,
      nonZeroPct: nonZeroPct,
      minV: minV,
      maxV: maxV,
      mean: mean,
      bboxMinX: hasBBox ? minX : 0,
      bboxMinY: hasBBox ? minY : 0,
      bboxMaxX: hasBBox ? maxX : 0,
      bboxMaxY: hasBBox ? maxY : 0,
      hasBBox: hasBBox,
      buckets: buckets,
      full255: full255,
      full255Pct: full255Pct,
      soft: soft,
      softPct: softPct,
      alphaNonOpaque: alphaNonOpaque,
      alphaNonOpaquePct: alphaNonOpaquePct,
      weirdColored: weirdColored,
      weirdColoredPct: weirdColoredPct,
    );
  }

  // =========================================================
  // Binary polarity
  // =========================================================
  Future<BinaryPolarityStats> _analyzeBinaryPolarity(Uint8List maskPngBytes) async {
    final codec = await ui.instantiateImageCodec(maskPngBytes);
    final frame = await codec.getNextFrame();
    final img = frame.image;

    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgba = bd!.buffer.asUint8List();

    final total = img.width * img.height;
    int white = 0;
    int black = 0;

    for (int i = 0; i < rgba.length; i += 4) {
      final v = _maskValueFromRgba(rgba, i);
      if (v >= 250) {
        white++;
      } else if (v <= 5) {
        black++;
      }
    }

    return BinaryPolarityStats(
      whitePixels: white,
      blackPixels: black,
      whitePct: total == 0 ? 0 : (white / total) * 100.0,
      blackPct: total == 0 ? 0 : (black / total) * 100.0,
    );
  }

  // =========================================================
  // Compare masks
  // =========================================================
  Future<MaskDiffStats> _compareMasks(Uint8List aPng, Uint8List bPng) async {
    final aCodec = await ui.instantiateImageCodec(aPng);
    final bCodec = await ui.instantiateImageCodec(bPng);

    final aFrame = await aCodec.getNextFrame();
    final bFrame = await bCodec.getNextFrame();

    final aImg = aFrame.image;
    final bImg = bFrame.image;

    if (aImg.width != bImg.width || aImg.height != bImg.height) {
      return MaskDiffStats(
        sameSize: false,
        widthA: aImg.width,
        heightA: aImg.height,
        widthB: bImg.width,
        heightB: bImg.height,
        changedPixels: -1,
        changedPct: -1,
        meanAbsDiff: -1,
        binaryAgreementPct: -1,
      );
    }

    final aBd = await aImg.toByteData(format: ui.ImageByteFormat.rawRgba);
    final bBd = await bImg.toByteData(format: ui.ImageByteFormat.rawRgba);

    final aRgba = aBd!.buffer.asUint8List();
    final bRgba = bBd!.buffer.asUint8List();

    final total = aImg.width * aImg.height;

    int changed = 0;
    int absDiffSum = 0;
    int binaryAgree = 0;

    for (int i = 0; i < aRgba.length; i += 4) {
      final va = _maskValueFromRgba(aRgba, i);
      final vb = _maskValueFromRgba(bRgba, i);

      if (va != vb) changed++;
      absDiffSum += (va - vb).abs();

      final ba = va > 0 ? 1 : 0;
      final bb = vb > 0 ? 1 : 0;
      if (ba == bb) binaryAgree++;
    }

    return MaskDiffStats(
      sameSize: true,
      widthA: aImg.width,
      heightA: aImg.height,
      widthB: bImg.width,
      heightB: bImg.height,
      changedPixels: changed,
      changedPct: total == 0 ? 0 : (changed / total) * 100.0,
      meanAbsDiff: total == 0 ? 0 : absDiffSum / total,
      binaryAgreementPct: total == 0 ? 0 : (binaryAgree / total) * 100.0,
    );
  }

  // =========================================================
  // Hash helpers
  // =========================================================
  String _sha256OfBytes(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  String _shortHash(Uint8List bytes) {
    final h = _sha256OfBytes(bytes);
    return h.substring(0, 12);
  }

  // =========================================================
  // Geometry diagnosis
  // =========================================================
  String _diagnoseStrokeToMaskGeometry({
    required StrokeSpaceStats strokeStats,
    required MaskStats rawStats,
  }) {
    if (strokeStats.pointsCount == 0 || !rawStats.hasBBox) {
      return 'لا توجد بيانات كافية للمقارنة الهندسية.';
    }

    final strokeW = (strokeStats.maxX - strokeStats.minX).abs();
    final strokeH = (strokeStats.maxY - strokeStats.minY).abs();

    final maskW = (rawStats.bboxMaxX - rawStats.bboxMinX).abs().toDouble();
    final maskH = (rawStats.bboxMaxY - rawStats.bboxMinY).abs().toDouble();

    final strokeCx = (strokeStats.minX + strokeStats.maxX) / 2.0;
    final strokeCy = (strokeStats.minY + strokeStats.maxY) / 2.0;
    final maskCx = (rawStats.bboxMinX + rawStats.bboxMaxX) / 2.0;
    final maskCy = (rawStats.bboxMinY + rawStats.bboxMaxY) / 2.0;

    final expandX = strokeW <= 0 ? 999.0 : maskW / strokeW;
    final expandY = strokeH <= 0 ? 999.0 : maskH / strokeH;
    final shiftX = (maskCx - strokeCx).abs();
    final shiftY = (maskCy - strokeCy).abs();

    final issues = <String>[];

    if (expandX > 1.6) {
      issues.add('الماسك متوسع أفقيًا أكثر من المتوقع: x${expandX.toStringAsFixed(2)}');
    }
    if (expandY > 1.6) {
      issues.add('الماسك متوسع عموديًا أكثر من المتوقع: x${expandY.toStringAsFixed(2)}');
    }
    if (shiftX > 20 || shiftY > 20) {
      issues.add(
        'مركز الماسك منحرف عن مركز الرسم: dx=${shiftX.toStringAsFixed(1)}, dy=${shiftY.toStringAsFixed(1)}',
      );
    }
    if (rawStats.bboxMinY == 0 && strokeStats.minY > 20) {
      issues.add('الماسك لمس الحافة العليا رغم أن الرسم لا يبدأ من الأعلى.');
    }
    if (rawStats.nonZeroPct > 20 && strokeStats.pointsCount < 300) {
      issues.add('نسبة تغطية الماسك كبيرة جدًا مقارنة بعدد النقاط.');
    }

    if (issues.isEmpty) return 'Geometry OK';
    return issues.join(' | ');
  }

  // =========================================================
  // Main pipeline diagnosis
  // =========================================================
  String _diagnoseMaskPipeline({
    required int imageWidth,
    required int imageHeight,
    required StrokeSpaceStats strokeStats,
    required MaskStats rawStats,
    required MaskStats finalStats,
    required MaskDiffStats diffStats,
  }) {
    final issues = <String>[];
    final fixes = <String>[];

    if (strokeStats.pointsCount == 0) {
      issues.add('لا توجد points داخل الـ strokes.');
      fixes.add('تأكد أن الرسام يسجل النقاط فعليًا أثناء السحب.');
    }

    if (strokeStats.outsideCount > 0) {
      issues.add('بعض نقاط الرسم خارج حدود الصورة الأصلية.');
      fixes.add('المشكلة غالبًا في mapping من widget-space إلى image-space.');
    }

    if (rawStats.w != imageWidth || rawStats.h != imageHeight) {
      issues.add('RAW mask ليس بنفس أبعاد الصورة الأصلية.');
      fixes.add('يجب أن يتم render على canvas بحجم image.width × image.height بالضبط.');
    }

    if (finalStats.w != imageWidth || finalStats.h != imageHeight) {
      issues.add('FINAL mask ليس بنفس أبعاد الصورة الأصلية.');
      fixes.add('هناك resize أو crop أو transform داخل prepareMaskForLama.');
    }

    if (rawStats.nonZero == 0) {
      issues.add('RAW mask فارغ بالكامل رغم وجود رسم.');
      fixes.add('الخلل قبل السيرفر: في الـ painter أو طريقة render أو الإحداثيات.');
    }

    if (rawStats.nonZero > 0 && finalStats.nonZero == 0) {
      issues.add('RAW سليم لكن FINAL أصبح فارغ.');
      fixes.add('الخلل داخل prepareMaskForLama: threshold / invert / alpha / resize.');
    }

    if (rawStats.softPct > 0.5) {
      issues.add('RAW يحتوي درجات رمادية كثيرة، وليس binary صريح.');
      fixes.add('اجعل الماسك 0 أو 255 فقط قبل الإرسال إلى LaMa.');
    }

    if (finalStats.softPct > 0.5) {
      issues.add('FINAL ما زال soft mask وليس binary صارم.');
      fixes.add('أضف threshold واضح مثل: v >= 128 ? 255 : 0.');
    }

    if (finalStats.alphaNonOpaquePct > 0.5) {
      issues.add('FINAL يحتوي alpha غير opaque بشكل ملحوظ.');
      fixes.add('حوّل الماسك النهائي إلى grayscale opaque بالكامل.');
    }

    if (diffStats.sameSize && diffStats.changedPct > 20) {
      issues.add('هناك تغيّر كبير بين RAW و FINAL.');
      fixes.add('prepareMaskForLama يغيّر الماسك بقوة؛ افحص invert/blur/threshold/resize.');
    }

    final strokeW = (strokeStats.maxX - strokeStats.minX).abs();
    final strokeH = (strokeStats.maxY - strokeStats.minY).abs();

    if (rawStats.hasBBox && strokeStats.pointsCount > 0) {
      final rawW = (rawStats.bboxMaxX - rawStats.bboxMinX).abs().toDouble();
      final rawH = (rawStats.bboxMaxY - rawStats.bboxMinY).abs().toDouble();

      final expandX = strokeW <= 0 ? 999.0 : rawW / strokeW;
      final expandY = strokeH <= 0 ? 999.0 : rawH / strokeH;

      if (expandX > 1.6 || expandY > 1.6) {
        issues.add('RAW mask أكبر من حدود الرسم بشكل غير منطقي.');
        fixes.add('افحص _renderBinaryMask: هل يتم fill/path close/transform غير صحيح؟');
      }

      final strokeCx = (strokeStats.minX + strokeStats.maxX) / 2.0;
      final strokeCy = (strokeStats.minY + strokeStats.maxY) / 2.0;
      final rawCx = (rawStats.bboxMinX + rawStats.bboxMaxX) / 2.0;
      final rawCy = (rawStats.bboxMinY + rawStats.bboxMaxY) / 2.0;

      final dx = (strokeCx - rawCx).abs();
      final dy = (strokeCy - rawCy).abs();

      if (dx > 20 || dy > 20) {
        issues.add('مركز RAW mask منحرف عن مركز الرسم.');
        fixes.add('يوجد offset/scale/translation داخل render pipeline.');
      }

      if (rawStats.bboxMinY == 0 && strokeStats.minY > 20) {
        issues.add('RAW mask يلامس أعلى الصورة رغم أن الرسم لا يبدأ من الأعلى.');
        fixes.add('غالبًا يوجد shape inflation أو path fill أو render transform خاطئ.');
      }
    }

    if (rawStats.hasBBox && finalStats.hasBBox) {
      final rawCx = (rawStats.bboxMinX + rawStats.bboxMaxX) / 2.0;
      final rawCy = (rawStats.bboxMinY + rawStats.bboxMaxY) / 2.0;
      final finCx = (finalStats.bboxMinX + finalStats.bboxMaxX) / 2.0;
      final finCy = (finalStats.bboxMinY + finalStats.bboxMaxY) / 2.0;

      final dx = (rawCx - finCx).abs();
      final dy = (rawCy - finCy).abs();

      if (dx > 8 || dy > 8) {
        issues.add('مركز الماسك تحرّك بين RAW و FINAL.');
        fixes.add('هناك shift أو crop أو padding غير صحيح أثناء المعالجة.');
      }
    }

    if (rawStats.nonZeroPct > 85 || finalStats.nonZeroPct > 85) {
      issues.add('الماسك يغطي معظم الصورة؛ هذا غير منطقي عادة.');
      fixes.add('غالبًا عندك invert أو fill كامل أو blend خاطئ.');
    }

    if (rawStats.nonZeroPct < 0.01 && strokeStats.pointsCount > 10) {
      issues.add('الرسم موجود لكن coverage شبه صفر.');
      fixes.add('غالبًا سماكة الفرشاة لا تُطبّق فعليًا أو الرسم في scale مختلف.');
    }

    if (issues.isEmpty) {
      return '''
✅ لم يتم رصد خلل قاتل واضح داخل Flutter.
إذا كانت النتيجة من السيرفر تقول "القناع فارغ"، فالأقرب:
1) الماسك الذي يُرسل ليس هو نفس FINAL
2) اسم field خطأ
3) polarity مقلوبة
4) السيرفر يقرأ قناة مختلفة أو alpha
''';
    }

    final b = StringBuffer();
    b.writeln('تم اكتشاف مشاكل محتملة:');
    for (int i = 0; i < issues.length; i++) {
      b.writeln('${i + 1}) ${issues[i]}');
    }
    b.writeln('\nالإجراءات المقترحة:');
    for (int i = 0; i < fixes.length; i++) {
      b.writeln('${i + 1}) ${fixes[i]}');
    }
    return b.toString();
  }

  // =========================================================
  // Server risk diagnosis
  // =========================================================
  String _diagnoseServerEmptyMaskRisk({
    required MaskStats finalStats,
    required BinaryPolarityStats polarity,
    required int maskBytesLength,
  }) {
    final issues = <String>[];

    if (maskBytesLength <= 100) {
      issues.add('الماسك صغير جدًا بالحجم، قد يكون الملف غير صحيح أو فارغ.');
    }

    if (finalStats.nonZero == 0) {
      issues.add('الماسك النهائي فارغ فعليًا.');
    }

    if (finalStats.full255 == 0) {
      issues.add('لا توجد منطقة بيضاء صريحة، وإذا كان السيرفر يعتمد الأبيض فلن يجد شيئًا.');
    }

    if (polarity.whitePixels == 0) {
      issues.add('لا توجد بكسلات بيضاء تقريبًا؛ السيرفر قد يعتبر القناع فارغًا.');
    }

    if (polarity.blackPixels == 0) {
      issues.add('لا توجد بكسلات سوداء تقريبًا؛ إذا كان السيرفر يعتمد الأسود كمنطقة فسيعتبر القناع فارغًا.');
    }

    if (finalStats.alphaNonOpaque > 0) {
      issues.add('الماسك يحتوي alpha غير ثابت؛ بعض السيرفرات تقرأه كقناع فارغ.');
    }

    if (issues.isEmpty) {
      return 'لا يظهر خطر محلي واضح. إذا استمر السيرفر بقول "القناع فارغ"، فالأغلب أن المشكلة في polarity أو اسم الحقل أو الملف المرسل ليس هو نفسه الملف المحلَّل.';
    }

    return issues.join(' | ');
  }

  // =========================================================
  // Invert mask for diagnostics
  // =========================================================
  Future<Uint8List> _invertMaskPng(Uint8List maskPngBytes) async {
    final codec = await ui.instantiateImageCodec(maskPngBytes);
    final frame = await codec.getNextFrame();
    final img = frame.image;

    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgba = bd!.buffer.asUint8List();

    final out = Uint8List(rgba.length);

    for (int i = 0; i < rgba.length; i += 4) {
      final v = _maskValueFromRgba(rgba, i);
      final inv = 255 - v;
      out[i] = inv;
      out[i + 1] = inv;
      out[i + 2] = inv;
      out[i + 3] = 255;
    }

    return _rgbaToPng(out, img.width, img.height);
  }

  // =========================================================
  // Overlay
  // =========================================================
  Future<Uint8List> _buildOverlayPng(ui.Image image, Uint8List maskPngBytes) async {
    final codec = await ui.instantiateImageCodec(maskPngBytes);
    final frame = await codec.getNextFrame();
    final maskImg = frame.image;

    final w = image.width;
    final h = image.height;

    final maskBd = await maskImg.toByteData(format: ui.ImageByteFormat.rawRgba);
    final maskRgba = maskBd!.buffer.asUint8List();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    );

    canvas.drawImage(image, Offset.zero, Paint());

    final srcRect = Rect.fromLTWH(
      0,
      0,
      maskImg.width.toDouble(),
      maskImg.height.toDouble(),
    );
    final dstRect = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());

    canvas.drawImageRect(maskImg, srcRect, dstRect, Paint());

    // Tint فوق المناطق البيضاء فقط تقريباً
    final rgbaResized = await _renderMaskAsRedOverlay(
      maskRgba: maskRgba,
      srcW: maskImg.width,
      srcH: maskImg.height,
      dstW: w,
      dstH: h,
    );

    final overlayImg = await _decodeRgbaToImage(rgbaResized, w, h);
    canvas.drawImage(overlayImg, Offset.zero, Paint());

    final pic = recorder.endRecording();
    final out = await pic.toImage(w, h);
    final bd = await out.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  Future<Uint8List> _renderMaskAsRedOverlay({
    required Uint8List maskRgba,
    required int srcW,
    required int srcH,
    required int dstW,
    required int dstH,
  }) async {
    final out = Uint8List(dstW * dstH * 4);

    for (int y = 0; y < dstH; y++) {
      for (int x = 0; x < dstW; x++) {
        final sx = ((x / dstW) * srcW).floor().clamp(0, srcW - 1);
        final sy = ((y / dstH) * srcH).floor().clamp(0, srcH - 1);

        final si = (sy * srcW + sx) * 4;
        final di = (y * dstW + x) * 4;

        final v = _maskValueFromRgba(maskRgba, si);
        if (v > 0) {
          out[di] = 255;
          out[di + 1] = 0;
          out[di + 2] = 0;
          out[di + 3] = math.min(180, (v * 0.7).round());
        } else {
          out[di] = 0;
          out[di + 1] = 0;
          out[di + 2] = 0;
          out[di + 3] = 0;
        }
      }
    }

    return out;
  }

  // =========================================================
  // Diff overlay
  // =========================================================
  Future<Uint8List> _buildDiffOverlay(Uint8List aPng, Uint8List bPng) async {
    final aCodec = await ui.instantiateImageCodec(aPng);
    final bCodec = await ui.instantiateImageCodec(bPng);

    final aFrame = await aCodec.getNextFrame();
    final bFrame = await bCodec.getNextFrame();

    final aImg = aFrame.image;
    final bImg = bFrame.image;

    final w = math.min(aImg.width, bImg.width);
    final h = math.min(aImg.height, bImg.height);

    final aBd = await aImg.toByteData(format: ui.ImageByteFormat.rawRgba);
    final bBd = await bImg.toByteData(format: ui.ImageByteFormat.rawRgba);

    final aRgba = aBd!.buffer.asUint8List();
    final bRgba = bBd!.buffer.asUint8List();

    final out = Uint8List(w * h * 4);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final i = (y * w + x) * 4;
        final va = _maskValueFromRgba(aRgba, i);
        final vb = _maskValueFromRgba(bRgba, i);
        final diff = (va - vb).abs();

        out[i] = diff;
        out[i + 1] = diff;
        out[i + 2] = diff;
        out[i + 3] = 255;
      }
    }

    return _rgbaToPng(out, w, h);
  }

  // =========================================================
  // RGBA helpers
  // =========================================================
  Future<ui.Image> _decodeRgbaToImage(Uint8List rgba, int w, int h) {
    final c = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      w,
      h,
      ui.PixelFormat.rgba8888,
          (img) => c.complete(img),
    );
    return c.future;
  }

  Future<Uint8List> _rgbaToPng(Uint8List rgba, int w, int h) async {
    final img = await _decodeRgbaToImage(rgba, w, h);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  // =========================================================
  // Optional helper: compare final vs upload bytes
  // =========================================================
  Future<void> _debugCompareFinalVsUpload({
    required Uint8List finalMaskBytes,
    required Uint8List uploadedMaskBytes,
  }) async {
    final finalHash = _shortHash(finalMaskBytes);
    final uploadHash = _shortHash(uploadedMaskBytes);

    debugPrint('================ HASH CHECK ======================');
    debugPrint('FINAL MASK   : bytes=${finalMaskBytes.length} sha=$finalHash');
    debugPrint('UPLOADED MASK: bytes=${uploadedMaskBytes.length} sha=$uploadHash');
    debugPrint('MATCH        : ${finalHash == uploadHash}');
    debugPrint('==================================================');
  }
}

// =========================================================
// MODELS
// =========================================================
class StrokeSpaceStats {
  final int imageW;
  final int imageH;
  final int strokesCount;
  final int pointsCount;
  final int singlePointStrokes;
  final int outsideCount;
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  StrokeSpaceStats({
    required this.imageW,
    required this.imageH,
    required this.strokesCount,
    required this.pointsCount,
    required this.singlePointStrokes,
    required this.outsideCount,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  factory StrokeSpaceStats.empty(int w, int h) {
    return StrokeSpaceStats(
      imageW: w,
      imageH: h,
      strokesCount: 0,
      pointsCount: 0,
      singlePointStrokes: 0,
      outsideCount: 0,
      minX: 0,
      minY: 0,
      maxX: 0,
      maxY: 0,
    );
  }

  String pretty() {
    return 'img=$imageW x $imageH | strokes=$strokesCount | pts=$pointsCount | singlePoint=$singlePointStrokes | outside=$outsideCount | bbox=(${minX.toStringAsFixed(1)}, ${minY.toStringAsFixed(1)})→(${maxX.toStringAsFixed(1)}, ${maxY.toStringAsFixed(1)})';
  }
}

class MaskStats {
  final String label;
  final int w;
  final int h;
  final int total;
  final int nonZero;
  final double nonZeroPct;
  final int minV;
  final int maxV;
  final double mean;
  final int bboxMinX;
  final int bboxMinY;
  final int bboxMaxX;
  final int bboxMaxY;
  final bool hasBBox;
  final Map<String, int> buckets;

  final int full255;
  final double full255Pct;
  final int soft;
  final double softPct;
  final int alphaNonOpaque;
  final double alphaNonOpaquePct;
  final int weirdColored;
  final double weirdColoredPct;

  MaskStats({
    required this.label,
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
    required this.full255,
    required this.full255Pct,
    required this.soft,
    required this.softPct,
    required this.alphaNonOpaque,
    required this.alphaNonOpaquePct,
    required this.weirdColored,
    required this.weirdColoredPct,
  });

  String pretty() {
    final bboxText = hasBBox
        ? 'bbox=($bboxMinX,$bboxMinY)→($bboxMaxX,$bboxMaxY)'
        : 'bbox=none';

    return '$label | $w x $h | nonZero=$nonZero (${nonZeroPct.toStringAsFixed(3)}%) | min=$minV max=$maxV mean=${mean.toStringAsFixed(2)} | full255=$full255 (${full255Pct.toStringAsFixed(3)}%) | soft=$soft (${softPct.toStringAsFixed(3)}%) | alpha!=255=$alphaNonOpaque (${alphaNonOpaquePct.toStringAsFixed(3)}%) | weirdRGB=$weirdColored (${weirdColoredPct.toStringAsFixed(3)}%) | $bboxText | buckets=$buckets';
  }
}

class MaskDiffStats {
  final bool sameSize;
  final int widthA;
  final int heightA;
  final int widthB;
  final int heightB;
  final int changedPixels;
  final double changedPct;
  final double meanAbsDiff;
  final double binaryAgreementPct;

  MaskDiffStats({
    required this.sameSize,
    required this.widthA,
    required this.heightA,
    required this.widthB,
    required this.heightB,
    required this.changedPixels,
    required this.changedPct,
    required this.meanAbsDiff,
    required this.binaryAgreementPct,
  });

  String pretty() {
    if (!sameSize) {
      return 'SIZE MISMATCH | A=$widthA x $heightA | B=$widthB x $heightB';
    }
    return 'sameSize=true | changed=$changedPixels (${changedPct.toStringAsFixed(3)}%) | meanAbsDiff=${meanAbsDiff.toStringAsFixed(3)} | binaryAgreement=${binaryAgreementPct.toStringAsFixed(3)}%';
  }
}

class BinaryPolarityStats {
  final int whitePixels;
  final int blackPixels;
  final double whitePct;
  final double blackPct;

  BinaryPolarityStats({
    required this.whitePixels,
    required this.blackPixels,
    required this.whitePct,
    required this.blackPct,
  });

  String pretty() {
    return 'white=$whitePixels (${whitePct.toStringAsFixed(3)}%) | black=$blackPixels (${blackPct.toStringAsFixed(3)}%)';
  }
}

class UploadPreflightReport {
  final String imageHash;
  final String maskHash;
  final int imageBytes;
  final int maskBytes;
  final MaskStats maskStats;
  final BinaryPolarityStats polarity;

  final String imageFieldName;
  final String maskFieldName;
  final String imageFilename;
  final String maskFilename;
  final String imageContentType;
  final String maskContentType;
  final int expectedImageWidth;
  final int expectedImageHeight;
  final String? url;

  UploadPreflightReport({
    required this.imageHash,
    required this.maskHash,
    required this.imageBytes,
    required this.maskBytes,
    required this.maskStats,
    required this.polarity,
    required this.imageFieldName,
    required this.maskFieldName,
    required this.imageFilename,
    required this.maskFilename,
    required this.imageContentType,
    required this.maskContentType,
    required this.expectedImageWidth,
    required this.expectedImageHeight,
    this.url,
  });

  String pretty() {
    return 'url=${url ?? "-"} | imageBytes=$imageBytes imageHash=$imageHash field=$imageFieldName file=$imageFilename type=$imageContentType | maskBytes=$maskBytes maskHash=$maskHash field=$maskFieldName file=$maskFilename type=$maskContentType | expectedImage=$expectedImageWidth x $expectedImageHeight | maskStats=[${maskStats.pretty()}] | polarity=[${polarity.pretty()}]';
  }
}
