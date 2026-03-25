import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:untitled2/vv/blemish_operation.dart';
import 'package:untitled2/vv/history_service.dart';


/// Schema version for forward-compatibility checks.
const _kSessionSchemaVersion = 1;

/// Serialized edit session containing all blemish operations.
class BlemishSession {
  final String sessionId;
  final String sourceImagePath;
  final DateTime createdAt;
  final DateTime lastModifiedAt;
  final int schemaVersion;
  final List<BlemishOperation> operations;

  const BlemishSession({
    required this.sessionId,
    required this.sourceImagePath,
    required this.createdAt,
    required this.lastModifiedAt,
    required this.operations,
    this.schemaVersion = _kSessionSchemaVersion,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'sessionId': sessionId,
        'sourceImagePath': sourceImagePath,
        'createdAt': createdAt.toIso8601String(),
        'lastModifiedAt': lastModifiedAt.toIso8601String(),
        'operations': operations.map((o) => o.toJson()).toList(),
      };

  factory BlemishSession.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'] as int? ?? 1;
    if (version > _kSessionSchemaVersion) {
      throw UnsupportedError(
          'Session schema v$version is newer than supported v$_kSessionSchemaVersion.');
    }
    return BlemishSession(
      sessionId: json['sessionId'] as String,
      sourceImagePath: json['sourceImagePath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModifiedAt: DateTime.parse(json['lastModifiedAt'] as String),
      operations: (json['operations'] as List)
          .map((o) => BlemishOperation.fromJson(o as Map<String, dynamic>))
          .toList(),
      schemaVersion: version,
    );
  }
}

/// Handles saving and loading [BlemishSession] to/from disk.
class BlemishSessionSerializer {
  /// Serialize session to a JSON string.
  String serialize(BlemishSession session) {
    return const JsonEncoder.withIndent('  ').convert(session.toJson());
  }

  /// Deserialize session from a JSON string.
  BlemishSession deserialize(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return BlemishSession.fromJson(json);
  }

  /// Save session to [filePath].
  Future<void> saveToFile(BlemishSession session, String filePath) async {
    final file = File(filePath);
    await file.writeAsString(serialize(session));
    debugPrint('[BlemishSessionSerializer] Session saved to $filePath');
  }

  /// Load session from [filePath]. Returns null if file does not exist.
  Future<BlemishSession?> loadFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    try {
      final jsonString = await file.readAsString();
      return deserialize(jsonString);
    } catch (e) {
      debugPrint('[BlemishSessionSerializer] Failed to load session: $e');
      return null;
    }
  }

  /// Create a new session for a given source image.
  BlemishSession createSession({
    required String sourceImagePath,
    List<BlemishOperation> operations = const [],
  }) {
    return BlemishSession(
      sessionId: _generateId(),
      sourceImagePath: sourceImagePath,
      createdAt: DateTime.now(),
      lastModifiedAt: DateTime.now(),
      operations: operations,
    );
  }

  /// Update session with latest operations from [HistoryService].
  BlemishSession updateSession(BlemishSession existing, HistoryService history) {
    return BlemishSession(
      sessionId: existing.sessionId,
      sourceImagePath: existing.sourceImagePath,
      createdAt: existing.createdAt,
      lastModifiedAt: DateTime.now(),
      operations: history.operations,
    );
  }

  String _generateId() =>
      'session_${DateTime.now().millisecondsSinceEpoch}_${Object.hash(DateTime.now(), this)}';
}
