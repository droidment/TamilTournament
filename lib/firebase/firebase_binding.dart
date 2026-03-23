import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'firebase_status.dart';

final class FirebaseBinding {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseBindingState.instance.value.value = FirebaseStatus.configured;
    if (kDebugMode) {
      debugPrint('Firebase initialized.');
    }
  }
}
