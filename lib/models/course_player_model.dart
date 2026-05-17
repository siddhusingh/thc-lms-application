import 'course_model.dart';

enum AssessmentType {
  pre('pre'),
  post('post');

  const AssessmentType(this.apiValue);

  final String apiValue;
}

class CoursePlaylistResponse {
  const CoursePlaylistResponse({required this.videos, this.currentVideoId});

  final List<PlaylistVideoItem> videos;
  final String? currentVideoId;

  factory CoursePlaylistResponse.fromJson(Map<String, dynamic> json) {
    final payload = _payload(json);
    final course = payload['course'];
    final currentVideo = payload['current_video'];
    final rawVideos =
        payload['videos'] ??
        payload['playlist'] ??
        payload['items'] ??
        payload['lessons'];

    return CoursePlaylistResponse(
      videos: rawVideos is List
          ? rawVideos
                .whereType<Map<String, dynamic>>()
                .map(PlaylistVideoItem.fromJson)
                .toList()
          : const [],
      currentVideoId: _nullableString(
        payload['current_video_id'] ??
            payload['currentVideoId'] ??
            payload['current_lesson_id'] ??
            (course is Map<String, dynamic>
                ? course['current_video_id'] ?? course['current_lesson_id']
                : null) ??
            (currentVideo is Map<String, dynamic>
                ? currentVideo['id'] ??
                      currentVideo['_id'] ??
                      currentVideo['video_id']
                : currentVideo),
      ),
    );
  }
}

class PlaylistVideoItem {
  const PlaylistVideoItem({
    required this.id,
    required this.title,
    required this.type,
    this.videoUrl,
    this.thumbnailUrl,
    this.resourceUrl,
    this.durationSeconds = 0,
    this.isCompleted = false,
    this.watchedSeconds = 0,
  });

  final String id;
  final String title;
  final String type;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? resourceUrl;
  final int durationSeconds;
  final bool isCompleted;
  final int watchedSeconds;

  factory PlaylistVideoItem.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'];
    final progressPayload = progress is Map<String, dynamic>
        ? progress
        : const <String, dynamic>{};
    return PlaylistVideoItem(
      id: _string(
        json['id'] ??
            json['_id'] ??
            json['lesson_id'] ??
            json['video_id'] ??
            json['course_video_id'] ??
            json['course_video'] ??
            json['playlist_id'],
      ),
      title: _string(
        json['title'] ??
            json['name'] ??
            json['video_title'] ??
            json['video_name'],
      ),
      type: _string(json['type'] ?? json['lesson_type'], fallback: 'video'),
      videoUrl: _nullableString(
        json['video_url'] ??
            json['hls_url'] ??
            json['s3_url'] ??
            json['video'] ??
            json['video_path'] ??
            json['file'],
      ),
      thumbnailUrl: _nullableString(
        json['thumbnail_url'] ??
            json['thumbnail'] ??
            json['thumb_url'] ??
            json['poster_url'] ??
            json['poster'] ??
            json['image'],
      ),
      resourceUrl: _nullableString(json['resource_url'] ?? json['file_url']),
      durationSeconds: _toInt(json['duration_seconds'] ?? json['duration']),
      isCompleted: _toBool(
        json['completed'] ??
            json['is_completed'] ??
            json['completion_status'] ??
            progressPayload['completed'] ??
            progressPayload['is_completed'],
      ),
      watchedSeconds: _toInt(
        json['watched_seconds'] ??
            json['watched_duration'] ??
            json['progress_seconds'] ??
            json['watch_position'] ??
            progressPayload['watched_seconds'] ??
            progressPayload['watched_duration'] ??
            progressPayload['progress_seconds'] ??
            progressPayload['watch_position'],
      ),
    );
  }

  LessonModel toLessonModel() {
    return LessonModel(
      id: id,
      title: title,
      type: type,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      resourceUrl: resourceUrl,
      durationSeconds: durationSeconds,
      completed: isCompleted,
      progressSeconds: watchedSeconds,
    );
  }
}

class VideoProgressResponse {
  const VideoProgressResponse({
    required this.watchedSeconds,
    required this.isCompleted,
    required this.exists,
  });

  final int watchedSeconds;
  final bool isCompleted;
  final bool exists;

  factory VideoProgressResponse.fromJson(Map<String, dynamic> json) {
    final payload = _payload(json);
    final watchedSeconds = _toInt(
      payload['watched_seconds'] ??
          payload['progress_seconds'] ??
          payload['watch_position'],
    );
    final isCompleted = _toBool(
      payload['is_completed'] ?? payload['completed'],
    );
    final explicitExists =
        payload['exists'] ??
        payload['has_progress'] ??
        payload['progress_exists'];

    return VideoProgressResponse(
      watchedSeconds: watchedSeconds,
      isCompleted: isCompleted,
      exists: explicitExists == null
          ? payload.isNotEmpty
          : _toBool(explicitExists),
    );
  }

  factory VideoProgressResponse.empty() {
    return const VideoProgressResponse(
      watchedSeconds: 0,
      isCompleted: false,
      exists: false,
    );
  }
}

class SaveVideoProgressResponse {
  const SaveVideoProgressResponse({
    required this.watchedSeconds,
    required this.isCompleted,
  });

  final int watchedSeconds;
  final bool isCompleted;

  factory SaveVideoProgressResponse.fromJson(Map<String, dynamic> json) {
    final payload = _payload(json);
    return SaveVideoProgressResponse(
      watchedSeconds: _toInt(
        payload['watched_seconds'] ??
            payload['progress_seconds'] ??
            payload['watch_position'],
      ),
      isCompleted: _toBool(payload['is_completed'] ?? payload['completed']),
    );
  }
}

class VideoAssessmentCheckResponse {
  const VideoAssessmentCheckResponse({
    required this.hasIncompletePreVideoAssessment,
    required this.hasIncompletePostVideoAssessment,
    this.preVideoAssessmentId,
    this.postVideoAssessmentId,
  });

  final bool hasIncompletePreVideoAssessment;
  final bool hasIncompletePostVideoAssessment;
  final String? preVideoAssessmentId;
  final String? postVideoAssessmentId;

  factory VideoAssessmentCheckResponse.fromJson(Map<String, dynamic> json) {
    final payload = _payload(json);
    return VideoAssessmentCheckResponse(
      hasIncompletePreVideoAssessment: _isIncompleteAssessment(
        payload,
        prefix: 'pre_video',
        fallbackPrefixes: const ['pre'],
      ),
      hasIncompletePostVideoAssessment: _isIncompleteAssessment(
        payload,
        prefix: 'post_video',
        fallbackPrefixes: const ['post'],
      ),
      preVideoAssessmentId: _assessmentId(
        payload,
        prefix: 'pre_video',
        fallbackPrefixes: const ['pre'],
      ),
      postVideoAssessmentId: _assessmentId(
        payload,
        prefix: 'post_video',
        fallbackPrefixes: const ['post'],
      ),
    );
  }
}

class CourseAssessmentCheckResponse {
  const CourseAssessmentCheckResponse({
    required this.hasIncompletePreCourseAssessment,
    required this.hasIncompletePostCourseAssessment,
    this.preCourseAssessmentId,
    this.postCourseAssessmentId,
  });

  final bool hasIncompletePreCourseAssessment;
  final bool hasIncompletePostCourseAssessment;
  final String? preCourseAssessmentId;
  final String? postCourseAssessmentId;

  factory CourseAssessmentCheckResponse.fromJson(Map<String, dynamic> json) {
    final payload = _payload(json);
    return CourseAssessmentCheckResponse(
      hasIncompletePreCourseAssessment: _isIncompleteAssessment(
        payload,
        prefix: 'pre_course',
        fallbackPrefixes: const ['pre'],
      ),
      hasIncompletePostCourseAssessment: _isIncompleteAssessment(
        payload,
        prefix: 'post_course',
        fallbackPrefixes: const ['post'],
      ),
      preCourseAssessmentId: _assessmentId(
        payload,
        prefix: 'pre_course',
        fallbackPrefixes: const ['pre'],
      ),
      postCourseAssessmentId: _assessmentId(
        payload,
        prefix: 'post_course',
        fallbackPrefixes: const ['post'],
      ),
    );
  }
}

Map<String, dynamic> _payload(Map<String, dynamic> json) {
  final data = json['data'];
  return data is Map<String, dynamic> ? data : json;
}

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _toInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ??
      double.tryParse(value?.toString() ?? '')?.toInt() ??
      0;
}

bool _toBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' ||
      normalized == '1' ||
      normalized == 'yes' ||
      normalized == 'completed' ||
      normalized == 'complete' ||
      normalized == 'passed';
}

bool _isIncompleteAssessment(
  Map<String, dynamic> payload, {
  required String prefix,
  required List<String> fallbackPrefixes,
}) {
  for (final candidate in [prefix, ...fallbackPrefixes]) {
    final direct =
        payload['has_incomplete_${candidate}_assessment'] ??
        payload['incomplete_${candidate}_assessment'] ??
        payload['${candidate}_assessment_incomplete'] ??
        payload['${candidate}_incomplete'];
    if (direct != null) return _toBool(direct);

    final completed =
        payload['${candidate}_assessment_completed'] ??
        payload['${candidate}_completed'];
    if (completed != null) return !_toBool(completed);

    final status =
        payload['${candidate}_assessment_status'] ??
        payload['${candidate}_status'];
    final statusIncomplete = _statusIndicatesIncomplete(status);
    if (statusIncomplete != null) return statusIncomplete;

    final nested = payload['${candidate}_assessment'];
    if (nested is Map<String, dynamic>) {
      final nestedCompleted = nested['is_completed'] ?? nested['completed'];
      if (nestedCompleted != null) return !_toBool(nestedCompleted);
      final nestedStatus = _statusIndicatesIncomplete(nested['status']);
      if (nestedStatus != null) return nestedStatus;
      final required = nested['required'] ?? nested['is_required'];
      if (required != null) return _toBool(required);
    }
  }

  final genericDirect =
      payload['has_incomplete_assessment'] ??
      payload['incomplete_assessment'] ??
      payload['assessment_incomplete'];
  if (genericDirect != null) return _toBool(genericDirect);

  final genericCompleted =
      payload['assessment_completed'] ??
      payload['is_completed'] ??
      payload['completed'];
  if (genericCompleted != null) return !_toBool(genericCompleted);

  final genericStatus = _statusIndicatesIncomplete(
    payload['assessment_status'] ?? payload['status'],
  );
  if (genericStatus != null) return genericStatus;

  final genericNested = payload['assessment'];
  if (genericNested is Map<String, dynamic>) {
    final nestedCompleted =
        genericNested['is_completed'] ?? genericNested['completed'];
    if (nestedCompleted != null) return !_toBool(nestedCompleted);
    final nestedStatus = _statusIndicatesIncomplete(genericNested['status']);
    if (nestedStatus != null) return nestedStatus;
    final required = genericNested['required'] ?? genericNested['is_required'];
    if (required != null) return _toBool(required);
  }

  return false;
}

bool? _statusIndicatesIncomplete(Object? value) {
  final status = value?.toString().trim().toLowerCase();
  if (status == null || status.isEmpty) return null;
  if (status == 'completed' ||
      status == 'complete' ||
      status == 'passed' ||
      status == 'done') {
    return false;
  }
  if (status == 'incomplete' ||
      status == 'pending' ||
      status == 'required' ||
      status == 'not_started' ||
      status == 'not started' ||
      status == 'failed') {
    return true;
  }
  return null;
}

String? _assessmentId(
  Map<String, dynamic> payload, {
  required String prefix,
  required List<String> fallbackPrefixes,
}) {
  for (final candidate in [prefix, ...fallbackPrefixes]) {
    final direct = _nullableString(
      payload['${candidate}_assessment_id'] ??
          payload['${candidate}_id'] ??
          payload['assessment_id'],
    );
    if (direct != null) return direct;

    final nested = payload['${candidate}_assessment'];
    if (nested is Map<String, dynamic>) {
      final nestedId = _nullableString(
        nested['id'] ?? nested['_id'] ?? nested['assessment_id'],
      );
      if (nestedId != null) return nestedId;
    }
  }
  final genericNested = payload['assessment'];
  if (genericNested is Map<String, dynamic>) {
    final nestedId = _nullableString(
      genericNested['id'] ??
          genericNested['_id'] ??
          genericNested['assessment_id'],
    );
    if (nestedId != null) return nestedId;
  }
  return _nullableString(payload['assessment_id']);
}
