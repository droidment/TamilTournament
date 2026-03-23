import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'router/app_router.dart';

final class TamilTournamentApp extends StatelessWidget {
  const TamilTournamentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tamil Tournament',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: AppRouter.router,
    );
  }
}
