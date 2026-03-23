import 'package:flutter/foundation.dart';

enum FirebaseStatus { notConfigured, configured }

final class FirebaseBindingState {
  FirebaseBindingState._();

  static final FirebaseBindingState instance = FirebaseBindingState._();

  final ValueNotifier<FirebaseStatus> value = ValueNotifier(
    FirebaseStatus.notConfigured,
  );
}
