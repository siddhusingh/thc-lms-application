import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../models/course_model.dart';
import '../../../models/course_player_model.dart';
import '../data/course_repository.dart';

class CourseProvider extends ChangeNotifier {
  CourseProvider(this._repository);

  final CourseRepository _repository;

  final List<CourseModel> courses = [];
  CourseDetailModel? selectedCourse;
  String? currentVideoId;
  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  int _page = 1;
  String _search = '';
  String? error;

  Future<void> load({bool refresh = false, String? search}) async {
    if (loading || loadingMore) return;
    if (!refresh && search == null && courses.isNotEmpty) return;
    if (search != null) _search = search;
    if (refresh) {
      _page = 1;
      hasMore = true;
    }
    loading = refresh || courses.isEmpty;
    error = null;
    notifyListeners();
    try {
      final response = await _repository.fetchCourses(
        page: _page,
        search: _search,
      );
      if (_page == 1) courses.clear();
      _appendUniqueCourses(response.items);
      hasMore = response.hasMore;
      _page = response.currentPage + 1;
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Unable to load courses.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || loadingMore || loading) return;
    loadingMore = true;
    notifyListeners();
    try {
      final response = await _repository.fetchCourses(
        page: _page,
        search: _search,
      );
      _appendUniqueCourses(response.items);
      hasMore = response.hasMore;
      _page = response.currentPage + 1;
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadCourse(String id) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final course = await _repository.fetchCourse(id);
      final playlist = await _repository.fetchCoursePlaylist(id);
      currentVideoId = playlist.currentVideoId;
      selectedCourse = course.copyWith(
        modules: [
          CourseModuleModel(
            id: 'playlist',
            title: 'Lessons',
            lessons: playlist.videos
                .map((video) => video.toLessonModel())
                .toList(),
          ),
        ],
      );
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Unable to load course.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<CourseAssessmentCheckResponse> checkCourseAssessment(
    String courseId,
    AssessmentType assessmentType,
  ) {
    return _repository.checkCourseAssessment(courseId, assessmentType);
  }

  Future<VideoAssessmentCheckResponse> checkVideoAssessment({
    required String courseId,
    required String videoId,
    required AssessmentType assessmentType,
  }) {
    return _repository.checkVideoAssessment(
      courseId: courseId,
      videoId: videoId,
      assessmentType: assessmentType,
    );
  }

  Future<VideoProgressResponse> fetchVideoProgress({
    required String courseId,
    required String videoId,
  }) {
    return _repository.fetchVideoProgress(courseId: courseId, videoId: videoId);
  }

  Future<SaveVideoProgressResponse> saveVideoProgress({
    required String courseId,
    required String videoId,
    required Duration position,
    required Duration duration,
  }) async {
    final response = await _repository.saveVideoProgress(
      courseId: courseId,
      videoId: videoId,
      watchedSeconds: position.inSeconds,
      durationSeconds: duration.inSeconds,
    );
    _updateLessonProgress(
      videoId,
      watchedSeconds: response.watchedSeconds > 0
          ? response.watchedSeconds
          : position.inSeconds,
      completed: response.isCompleted,
    );
    return response;
  }

  void updateProgressFromFetch(String videoId, VideoProgressResponse progress) {
    _updateLessonProgress(
      videoId,
      watchedSeconds: progress.watchedSeconds,
      completed: progress.isCompleted,
    );
  }

  void markLessonCompletedLocally(
    String videoId, {
    required int watchedSeconds,
  }) {
    _updateLessonProgress(
      videoId,
      watchedSeconds: watchedSeconds,
      completed: true,
    );
  }

  void setCurrentVideoId(String videoId) {
    currentVideoId = videoId;
  }

  void _appendUniqueCourses(Iterable<CourseModel> items) {
    final existingIds = courses.map((course) => course.id).toSet();
    for (final course in items) {
      if (existingIds.add(course.id)) courses.add(course);
    }
  }

  void _updateLessonProgress(
    String videoId, {
    required int watchedSeconds,
    required bool completed,
  }) {
    final course = selectedCourse;
    if (course == null) return;

    var changed = false;
    final modules = course.modules.map((module) {
      final lessons = module.lessons.map((lesson) {
        if (lesson.id != videoId) return lesson;
        changed = true;
        return lesson.copyWith(
          completed: completed || lesson.completed,
          progressSeconds: watchedSeconds,
        );
      }).toList();
      return module.copyWith(lessons: lessons);
    }).toList();

    if (!changed) return;
    selectedCourse = course.copyWith(modules: modules);
    notifyListeners();
  }
}
