class CourseModel {
  const CourseModel({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.progress = 0,
    this.moduleCount = 0,
    this.lessonCount = 0,
    this.lastLessonId,
  });

  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final double progress;
  final int moduleCount;
  final int lessonCount;
  final String? lastLessonId;

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: '${json['id'] ?? json['_id'] ?? ''}',
      title: '${json['title'] ?? json['name'] ?? json['course_name'] ?? ''}',
      description: json['description']?.toString(),
      thumbnailUrl:
          json['thumbnail_url']?.toString() ??
          json['thumbnail']?.toString() ??
          json['image']?.toString(),
      progress: _toDouble(
        json['progress'] ??
            json['completion_percentage'] ??
            json['progress_percentage'],
      ),
      moduleCount: _toInt(json['module_count'] ?? json['modules_count']),
      lessonCount: _toInt(json['lesson_count'] ?? json['lessons_count']),
      lastLessonId: json['last_lesson_id']?.toString(),
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class CourseDetailModel extends CourseModel {
  const CourseDetailModel({
    required super.id,
    required super.title,
    super.description,
    super.thumbnailUrl,
    super.progress,
    super.moduleCount,
    super.lessonCount,
    super.lastLessonId,
    this.modules = const [],
  });

  final List<CourseModuleModel> modules;

  CourseDetailModel copyWith({List<CourseModuleModel>? modules}) {
    return CourseDetailModel(
      id: id,
      title: title,
      description: description,
      thumbnailUrl: thumbnailUrl,
      progress: progress,
      moduleCount: moduleCount,
      lessonCount: lessonCount,
      lastLessonId: lastLessonId,
      modules: modules ?? this.modules,
    );
  }

  factory CourseDetailModel.fromJson(Map<String, dynamic> json) {
    final base = CourseModel.fromJson(json);
    return CourseDetailModel(
      id: base.id,
      title: base.title,
      description: base.description,
      thumbnailUrl: base.thumbnailUrl,
      progress: base.progress,
      moduleCount: base.moduleCount,
      lessonCount: base.lessonCount,
      lastLessonId: base.lastLessonId,
      modules: ((json['modules'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CourseModuleModel.fromJson)
          .toList(),
    );
  }
}

class CourseModuleModel {
  const CourseModuleModel({
    required this.id,
    required this.title,
    this.lessons = const [],
  });

  final String id;
  final String title;
  final List<LessonModel> lessons;

  CourseModuleModel copyWith({List<LessonModel>? lessons}) {
    return CourseModuleModel(
      id: id,
      title: title,
      lessons: lessons ?? this.lessons,
    );
  }

  factory CourseModuleModel.fromJson(Map<String, dynamic> json) {
    return CourseModuleModel(
      id: '${json['id'] ?? json['_id'] ?? ''}',
      title: '${json['title'] ?? json['name'] ?? json['video_title'] ?? ''}',
      lessons: ((json['lessons'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(LessonModel.fromJson)
          .toList(),
    );
  }
}

class LessonModel {
  const LessonModel({
    required this.id,
    required this.title,
    this.type = 'video',
    this.videoUrl,
    this.thumbnailUrl,
    this.resourceUrl,
    this.durationSeconds = 0,
    this.completed = false,
    this.progressSeconds = 0,
  });

  final String id;
  final String title;
  final String type;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? resourceUrl;
  final int durationSeconds;
  final bool completed;
  final int progressSeconds;

  LessonModel copyWith({bool? completed, int? progressSeconds}) {
    return LessonModel(
      id: id,
      title: title,
      type: type,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      resourceUrl: resourceUrl,
      durationSeconds: durationSeconds,
      completed: completed ?? this.completed,
      progressSeconds: progressSeconds ?? this.progressSeconds,
    );
  }

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    final id =
        json['id'] ??
        json['_id'] ??
        json['lesson_id'] ??
        json['video_id'] ??
        json['course_video_id'] ??
        json['course_video'] ??
        json['playlist_id'];
    return LessonModel(
      id: id?.toString() ?? '',
      title:
          '${json['title'] ?? json['name'] ?? json['video_title'] ?? json['video_name'] ?? ''}',
      type: '${json['type'] ?? json['lesson_type'] ?? 'video'}',
      videoUrl:
          json['video_url']?.toString() ??
          json['hls_url']?.toString() ??
          json['s3_url']?.toString() ??
          json['video']?.toString() ??
          json['video_path']?.toString() ??
          json['file']?.toString(),
      thumbnailUrl:
          json['thumbnail_url']?.toString() ??
          json['thumbnail']?.toString() ??
          json['thumb_url']?.toString() ??
          json['poster_url']?.toString() ??
          json['poster']?.toString() ??
          json['image']?.toString(),
      resourceUrl:
          json['resource_url']?.toString() ?? json['file_url']?.toString(),
      durationSeconds: CourseModel._toInt(
        json['duration_seconds'] ?? json['duration'],
      ),
      completed: json['completed'] == true || json['is_completed'] == true,
      progressSeconds: CourseModel._toInt(
        json['watched_seconds'] ??
            json['watched_duration'] ??
            json['progress_seconds'] ??
            json['watch_position'],
      ),
    );
  }
}
