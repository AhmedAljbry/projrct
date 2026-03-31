import 'package:untitled2/features/style_transfer/data/services/style_transfer_kernel.dart';

Future<Map<String, dynamic>> extractStyleWorker(
    Map<String, dynamic> payload) async {
  return const StyleTransferKernel().extractStyle(payload);
}

Future<Map<String, dynamic>> analyzeSceneWorker(
    Map<String, dynamic> payload) async {
  return const StyleTransferKernel().analyzeScene(payload);
}

Future<Map<String, dynamic>> applyStyleWorker(
    Map<String, dynamic> payload) async {
  return const StyleTransferKernel().applyStyle(payload);
}
