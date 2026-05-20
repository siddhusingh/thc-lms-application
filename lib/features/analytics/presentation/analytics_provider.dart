import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../models/analytics_model.dart';
import '../data/analytics_repository.dart';

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider(this._repository) {
    final today = _dateOnly(DateTime.now());
    startDate = today.subtract(const Duration(days: 5));
    endDate = today;
  }

  final AnalyticsRepository _repository;

  late DateTime startDate;
  late DateTime endDate;
  AnalyticsModel? data;
  bool loading = false;
  String? error;

  Future<void> load({bool refresh = false}) async {
    if (loading) return;
    if (!refresh && data != null) return;
    loading = data == null || refresh;
    error = null;
    notifyListeners();
    try {
      data = await _repository.fetchAnalytics(
        startDate: startDate,
        endDate: endDate,
      );
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Unable to load analytics.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> setDateRange(DateTime start, DateTime end) async {
    startDate = _dateOnly(start);
    endDate = _dateOnly(end);
    await load(refresh: true);
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
