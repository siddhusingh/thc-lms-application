import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../models/course_model.dart';
import '../../../models/course_player_model.dart';
import 'course_provider.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({required this.courseId, super.key});

  final String courseId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _openedPlayer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareCourse());
  }

  @override
  void didUpdateWidget(covariant CourseDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courseId != widget.courseId) {
      _openedPlayer = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepareCourse());
    }
  }

  Future<void> _prepareCourse() async {
    final provider = context.read<CourseProvider>();
    try {
      final check = await provider.checkCourseAssessment(
        widget.courseId,
        AssessmentType.pre,
      );
      if (!mounted) return;
      if (_navigateForIncompletePreCourseAssessment(check)) return;
    } catch (_) {
      // Assessment failures should not block access to the course player.
    }
    if (!mounted) return;
    await provider.loadCourse(widget.courseId);
  }

  bool _navigateForIncompletePreCourseAssessment(
    CourseAssessmentCheckResponse check,
  ) {
    if (!check.hasIncompletePreCourseAssessment) return false;
    final assessmentId = check.preCourseAssessmentId;
    if (assessmentId != null && assessmentId.isNotEmpty) {
      context.go('/assessments/${Uri.encodeComponent(assessmentId)}');
    } else {
      context.go('/assessments');
    }
    return true;
  }

  void _openPlayer(LessonModel lesson) {
    final id = lesson.id.trim();
    final path = id.isEmpty
        ? '/lessons'
        : '/lessons/${Uri.encodeComponent(id)}';
    context.go(path, extra: lesson);
  }

  LessonModel? _firstVideoLesson(CourseDetailModel course) {
    for (final module in course.modules) {
      for (final lesson in module.lessons) {
        final videoUrl = lesson.videoUrl;
        if (videoUrl != null &&
            videoUrl.isNotEmpty &&
            !lesson.completed &&
            lesson.progressSeconds > 0) {
          return lesson;
        }
      }
    }

    final currentVideoId = context.read<CourseProvider>().currentVideoId;
    if (currentVideoId != null && currentVideoId.isNotEmpty) {
      for (final module in course.modules) {
        for (final lesson in module.lessons) {
          if (lesson.id == currentVideoId &&
              lesson.videoUrl != null &&
              lesson.videoUrl!.isNotEmpty) {
            return lesson;
          }
        }
      }
    }

    for (final module in course.modules) {
      for (final lesson in module.lessons) {
        final videoUrl = lesson.videoUrl;
        if (videoUrl != null && videoUrl.isNotEmpty && !lesson.completed) {
          return lesson;
        }
      }
    }

    for (final module in course.modules) {
      for (final lesson in module.lessons) {
        final videoUrl = lesson.videoUrl;
        if (videoUrl != null && videoUrl.isNotEmpty) return lesson;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final course = provider.selectedCourse;
    final courseReady = course != null && course.id == widget.courseId;

    if (provider.error != null && !courseReady) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course')),
        body: AppErrorView(
          message: provider.error!,
          onRetry: () => provider.loadCourse(widget.courseId),
        ),
      );
    }

    if (provider.loading || !courseReady) {
      return const Scaffold(body: LoadingShimmer());
    }

    final lesson = _firstVideoLesson(course);
    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(title: Text(course.title)),
        body: AppErrorView(
          message: 'No video lessons are available for this course.',
          onRetry: () => provider.loadCourse(widget.courseId),
        ),
      );
    }

    if (!_openedPlayer) {
      _openedPlayer = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPlayer(lesson));
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
