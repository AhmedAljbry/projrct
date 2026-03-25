import 'dart:io';
import 'package:untitled2/vv/blemish_session_serializer.dart';


/// Abstract contract for persisting blemish editing sessions.
abstract class BlemishSessionRepository {
  Future<BlemishSession?> loadSession(String sessionId);
  Future<void> saveSession(BlemishSession session);
  Future<void> deleteSession(String sessionId);
  Future<List<String>> listSessionIds();
}

/// File-system-based implementation of [BlemishSessionRepository].
/// Stores each session as a JSON file in [baseDirectory].
class FileBlemishSessionRepository implements BlemishSessionRepository {
  final String baseDirectory;
  final BlemishSessionSerializer _serializer;

  FileBlemishSessionRepository({
    required this.baseDirectory,
    BlemishSessionSerializer? serializer,
  }) : _serializer = serializer ?? BlemishSessionSerializer();

  String _sessionPath(String sessionId) =>
      '$baseDirectory/$sessionId.blemish.json';

  @override
  Future<BlemishSession?> loadSession(String sessionId) async {
    return _serializer.loadFromFile(_sessionPath(sessionId));
  }

  @override
  Future<void> saveSession(BlemishSession session) async {
    await Directory(baseDirectory).create(recursive: true);
    await _serializer.saveToFile(session, _sessionPath(session.sessionId));
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final file = File(_sessionPath(sessionId));
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<List<String>> listSessionIds() async {
    final dir = Directory(baseDirectory);
    if (!await dir.exists()) return [];
    final files = await dir
        .list()
        .where((f) => f.path.endsWith('.blemish.json'))
        .map((f) => File(f.path).uri.pathSegments.last.replaceAll('.blemish.json', ''))
        .toList();
    return files.cast<String>();
  }
}
