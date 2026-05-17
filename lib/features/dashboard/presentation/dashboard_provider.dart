import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../models/dashboard_model.dart';
import '../data/dashboard_repository.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._repository);

  final DashboardRepository _repository;

  DashboardModel? dashboard;
  bool loading = false;
  String? error;

  Future<void> load({bool refresh = false}) async {
    if (loading) return;
    loading = dashboard == null || refresh;
    error = null;
    notifyListeners();
    try {
      dashboard = await _repository.fetchDashboard();
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Unable to load dashboard.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
