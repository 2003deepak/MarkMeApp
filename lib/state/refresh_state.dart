import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardRefreshProvider = StateProvider<int>((ref) => 0);

//trigger refresh helper
void triggerDashboardRefresh(Ref ref) {
  ref.read(dashboardRefreshProvider.notifier).state++;
}