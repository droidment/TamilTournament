import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app.dart';
import '../firebase/firebase_binding.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await FirebaseBinding.initialize();
  runApp(const ProviderScope(child: TamilTournamentApp()));
}
