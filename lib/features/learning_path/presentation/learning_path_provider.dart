import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../models/learning_path_model.dart';
import '../data/learning_path_repository.dart';

class LearningPathProvider extends ChangeNotifier {
  LearningPathProvider(this._repository);

  final LearningPathRepository _repository;

  LearningPathModel? data;
  bool loading = false;
  String? error;

  Future<void> load({bool refresh = false}) async {
    if (loading) return;
    if (!refresh && data != null) return;
    loading = data == null || refresh;
    error = null;
    notifyListeners();
    try {
      data = await _repository.fetchLearningPath();
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Unable to load learning path.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
