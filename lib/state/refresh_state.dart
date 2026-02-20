import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A global provider to trigger refreshes across dashboards.
/// Incrementing the state will notify listeners to refresh their data.
final dashboardRefreshProvider = StateProvider<int>((ref) => 0);
