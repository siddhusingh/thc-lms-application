import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../models/assessment_model.dart';
import '../data/assessment_repository.dart';

class AssessmentProvider extends ChangeNotifier {
  AssessmentProvider(this._repository);

  final AssessmentRepository _repository;

  final List<AssessmentModel> assessments = [];
  AssessmentAttemptModel? attempt;
  Map<String, dynamic>? result;
  bool loading = false;
  bool hasMore = true;
  int _page = 1;
  String? error;

  Future<void> load({bool refresh = false}) async {
    if (loading) return;
    if (refresh) {
      _page = 1;
      hasMore = true;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      final response = await _repository.fetchAssessments(page: _page);
      if (_page == 1) assessments.clear();
      assessments.addAll(response.items);
      hasMore = response.hasMore;
      _page = response.currentPage + 1;
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Unable to load assessments.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> start(String id) async {
    loading = true;
    error = null;
    result = null;
    notifyListeners();
    try {
      attempt = await _repository.startAssessment(id);
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'Unable to start assessment.';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> submit(Map<String, String> answers) async {
    final current = attempt;
    if (current == null) return false;
    loading = true;
    error = null;
    notifyListeners();
    try {
      result = await _repository.submitAssessment(current.attemptId, answers);
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'Unable to submit assessment.';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
