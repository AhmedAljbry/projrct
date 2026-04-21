import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker/talker.dart';

class LoginReminderLocalDataSource {
  LoginReminderLocalDataSource(
    this._preferences,
    this._talker,
  );

  static const String reminderTimestampKey =
      'auth.login_reminder.last_dismissed_at_ms';

  final SharedPreferences _preferences;
  final Talker _talker;

  DateTime? getLastReminderTimestamp() {
    final value = _preferences.getInt(reminderTimestampKey);
    if (value == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  Future<void> saveReminderTimestamp(DateTime timestamp) async {
    _talker.debug(
      'Persisting login reminder timestamp: ${timestamp.toIso8601String()}',
    );
    await _preferences.setInt(
      reminderTimestampKey,
      timestamp.millisecondsSinceEpoch,
    );
  }

  Future<void> clearReminderTimestamp() async {
    _talker.debug('Clearing login reminder timestamp');
    await _preferences.remove(reminderTimestampKey);
  }
}
