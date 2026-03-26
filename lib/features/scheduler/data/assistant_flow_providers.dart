import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tournaments/data/tournament_providers.dart';
import 'assistant_flow_service.dart';

final assistantFlowServiceProvider = Provider<AssistantFlowService>((ref) {
  return AssistantFlowService(ref.watch(firebaseFirestoreProvider));
});
