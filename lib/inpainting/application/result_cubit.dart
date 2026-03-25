import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

sealed class ResultState {}
class ResultIdle extends ResultState {}
class ResultSaving extends ResultState {}
class ResultSaved extends ResultState {}
class ResultError extends ResultState {
  final String messageKey;
  ResultError(this.messageKey);
}

class ResultCubit extends Cubit<ResultState> {
  ResultCubit() : super(ResultIdle());

  Future<void> save(Uint8List bytes) async {
    emit(ResultSaving());
    final ok = await _ensurePermission();
    if (!ok) {
      emit(ResultError('permission_denied'));
      return;
    }

    try {
      final res = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: "Magic_${DateTime.now().millisecondsSinceEpoch}",
      );
      if (res != null && res['isSuccess'] == true) {
        emit(ResultSaved());
      } else {
        emit(ResultError('save_failed'));
      }
    } catch (_) {
      emit(ResultError('save_failed'));
    }
  }

  Future<void> shareBytes(Uint8List bytes) async {
    // مشاركة بدون حفظ
    await Share.shareXFiles([
      XFile.fromData(bytes, mimeType: 'image/png', name: 'result.png'),
    ]);
  }

  Future<bool> _ensurePermission() async {
    if (Platform.isAndroid) {
      final photos = await Permission.photos.request();
      final storage = await Permission.storage.request();
      return photos.isGranted || storage.isGranted;
    } else {
      final photos = await Permission.photos.request();
      return photos.isGranted;
    }
  }
}