import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

sealed class ImagePickState {}
class ImagePickEmpty extends ImagePickState {}
class ImagePickLoading extends ImagePickState {}
class ImagePickReady extends ImagePickState {
  final Uint8List bytes;
  final ui.Image uiImage;
  ImagePickReady({required this.bytes, required this.uiImage});
}
class ImagePickError extends ImagePickState {
  final String message;
  ImagePickError(this.message);
}

class ImagePickCubit extends Cubit<ImagePickState> {
  final ImagePicker picker;
  ImagePickCubit({ImagePicker? picker})
      : picker = picker ?? ImagePicker(),
        super(ImagePickEmpty());

  Future<void> pickFromGallery() async => _pick(ImageSource.gallery);
  Future<void> pickFromCamera() async => _pick(ImageSource.camera);

  Future<void> _pick(ImageSource src) async {
    emit(ImagePickLoading());
    try {
      final x = await picker.pickImage(source: src, imageQuality: 95);
      if (x == null) {
        emit(ImagePickEmpty());
        return;
      }
      final bytes = await x.readAsBytes();
      final uiImage = await _decodeUiImage(bytes);
      emit(ImagePickReady(bytes: bytes, uiImage: uiImage));
    } catch (e) {
      emit(ImagePickError(e.toString()));
    }
  }



  Future<ui.Image> _decodeUiImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (img) => completer.complete(img));
    return completer.future;
  }
  void reset() => emit(ImagePickEmpty());
}