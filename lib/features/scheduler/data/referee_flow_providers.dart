import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tournaments/data/tournament_providers.dart';
import 'referee_flow_service.dart';

final refereeFlowServiceProvider = Provider<RefereeFlowService>((ref) {
  return RefereeFlowService(ref.watch(firebaseFirestoreProvider));
});
