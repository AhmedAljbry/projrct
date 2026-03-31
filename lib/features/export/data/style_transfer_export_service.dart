import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class StyleTransferExportService {
  const StyleTransferExportService();

  Future<void> saveToGallery(Uint8List bytes,
      {String name = 'viral_style_result.jpg'}) {
    return Gal.putImageBytes(bytes, name: name);
  }

  Future<void> share(Uint8List bytes,
      {String name = 'viral_style_result.jpg'}) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(<XFile>[XFile(file.path)],
        text: 'Made with AI Style Transfer Studio');
  }
}
