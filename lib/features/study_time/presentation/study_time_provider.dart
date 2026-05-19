import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../models/study_time_model.dart';
import '../data/study_time_repository.dart';

class StudyTimeProvider extends ChangeNotifier {
  StudyTimeProvider(this._repository);

  final StudyTimeRepository _repository;

  StudyTimeModel? data;
  bool loading = false;
  String? error;

  Future<void> load({bool refresh = false}) async {
    if (loading) return;
    if (!refresh && data != null) return;
    loading = data == null || refresh;
    error = null;
    notifyListeners();
    try {
      data = await _repository.fetchStudyTime();
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Unable to load study time.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
