import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../models/assessment_model.dart';
import '../data/assessment_repository.dart';

class AssessmentProvider extends ChangeNotifier {
  AssessmentProvider(this._repository);

  final AssessmentRepository _repository;

  final List<AssessmentModel> assessments = [];
  final List<AssessmentResultHistoryModel> resultHistory = [];
  AssessmentAttemptModel? attempt;
  Map<String, dynamic>? result;
  bool loading = false;
  bool resultsLoading = false;
  bool hasMore = true;
  int _page = 1;
  String? error;
  String? resultsError;

  Future<void> load({bool refresh = false}) async {
    if (loading) return;
    if (!refresh && assessments.isNotEmpty) return;
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
      for (final item in response.items) {
        if (!_hasAssessment(item)) {
          assessments.add(item);
        }
      }
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

  bool _hasAssessment(AssessmentModel item) {
    return assessments.any((loaded) {
      if (item.id.isNotEmpty && loaded.id == item.id) return true;
      return loaded.title == item.title &&
          loaded.courseTitle == item.courseTitle &&
          loaded.videoTitle == item.videoTitle &&
          loaded.assessmentType == item.assessmentType &&
          loaded.lastCompletedAt == item.lastCompletedAt;
    });
  }

  Future<void> loadResults({bool refresh = false}) async {
    if (resultsLoading) return;
    if (!refresh && resultHistory.isNotEmpty) return;
    resultsLoading = true;
    resultsError = null;
    notifyListeners();
    try {
      final results = await _repository.fetchAssessmentResults();
      resultHistory
        ..clear()
        ..addAll(results);
    } on ApiException catch (exception) {
      resultsError = exception.message;
    } catch (_) {
      resultsError = 'Unable to load assessment results.';
    } finally {
      resultsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> start(String id) async {
    loading = true;
    error = null;
    result = null;
    attempt = null;
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

  Future<bool> submit(String assessmentId, Map<String, String> answers) async {
    final current = attempt;
    if (current == null) return false;
    loading = true;
    error = null;
    notifyListeners();
    try {
      result = await _repository.submitAssessment(
        assessmentId,
        current.attemptId,
        answers,
      );
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

  Future<bool> saveAnswer({
    required String questionId,
    required String answer,
  }) async {
    final current = attempt;
    if (current == null || current.attemptId.isEmpty) return false;
    error = null;
    notifyListeners();
    try {
      await _repository.saveAssessmentAnswer(
        attemptId: current.attemptId,
        questionId: questionId,
        answer: answer,
      );
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'Unable to save answer.';
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> loadNextQuestion(String assessmentId) async {
    final current = attempt;
    final nextQuestionId = current?.nextQuestionId;
    if (current == null ||
        nextQuestionId == null ||
        nextQuestionId.isEmpty ||
        current.isLast) {
      return false;
    }

    loading = true;
    error = null;
    notifyListeners();
    try {
      final nextPage = await _repository.fetchAssessmentQuestion(
        assessmentId,
        attemptId: current.attemptId,
        questionId: nextQuestionId,
      );
      final nextQuestions = nextPage.questions
          .where(
            (question) => current.questions.every(
              (loadedQuestion) => loadedQuestion.id != question.id,
            ),
          )
          .toList();
      attempt = current.copyWith(
        questions: [...current.questions, ...nextQuestions],
        totalQuestions: nextPage.totalQuestions > 0
            ? nextPage.totalQuestions
            : current.totalQuestions,
        currentNumber: nextPage.currentNumber,
        nextQuestionId: nextPage.nextQuestionId,
        isLast: nextPage.isLast,
      );
      return nextQuestions.isNotEmpty;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'Unable to load next question.';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
