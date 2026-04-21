import 'package:firebase_core/firebase_core.dart';

import 'package:untitled2/core/firebase/firebase_runtime_options.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap();

  Future<bool> initialize() async {
    if (Firebase.apps.isEmpty) {
      try {
        if (FirebaseRuntimeOptions.isConfigured) {
          await Firebase.initializeApp(
            options: FirebaseRuntimeOptions.currentPlatform,
          );
        } else {
          await Firebase.initializeApp();
        }
      } on UnsupportedError {
        return false;
      } on FirebaseException {
        // Fall back to "not configured" when native config files are absent.
        return false;
      }
    }
    return true;
  }
}
