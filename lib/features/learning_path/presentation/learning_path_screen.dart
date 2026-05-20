import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../models/learning_path_model.dart';
import 'learning_path_provider.dart';

const _upcomingCourseColor = Color(0xFFF45D64);

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<LearningPathProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LearningPathProvider>();
    final data = provider.data;

    if (provider.loading && data == null) return const LoadingShimmer();

    if (provider.error != null && data == null) {
      return AppErrorView(
        message: provider.error!,
        onRetry: () => provider.load(refresh: true),
      );
    }

    final courses = data?.courses ?? const <LearningPathCourse>[];

    return RefreshIndicator(
      onRefresh: () => provider.load(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: courses.isEmpty ? 2 : courses.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _LearningPathSummaryCard(
              summary: data?.summary ?? const LearningPathSummary(),
            );
          }
          if (courses.isEmpty) {
            return const SizedBox(
              height: 380,
              child: EmptyState(
                icon: Icons.route_outlined,
                title: 'No learning path',
                subtitle: 'Your learning path courses will appear here.',
              ),
            );
          }

          final itemIndex = index - 1;
          final course = courses[itemIndex];
          return _TimelineCourseItem(
            course: course,
            isFirst: itemIndex == 0,
            isLast: itemIndex == courses.length - 1,
          );
        },
      ),
    );
  }
}

class _LearningPathSummaryCard extends StatelessWidget {
  const _LearningPathSummaryCard({required this.summary});

  final LearningPathSummary summary;

  @override
  Widget build(BuildContext context) {
    final progress = summary.progressPercentage.clamp(0, 100);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learning Path',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    icon: Icons.menu_book_outlined,
                    label: 'Courses',
                    value: '${summary.totalCourses}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryMetric(
                    icon: Icons.trending_up_rounded,
                    label: 'Progress',
                    value: '${progress.toStringAsFixed(0)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SummaryMetric(
              icon: Icons.hourglass_bottom_rounded,
              label: 'Duration',
              value: summary.watchedTime,
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress / 100,
                backgroundColor: AppTheme.mutedText.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineCourseItem extends StatelessWidget {
  const _TimelineCourseItem({
    required this.course,
    required this.isFirst,
    required this.isLast,
  });

  final LearningPathCourse course;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 38,
            child: _TimelineMarker(isFirst: isFirst, isLast: isLast),
          ),
          const SizedBox(width: 8),
          Expanded(child: _LearningPathCourseCard(course: course)),
        ],
      ),
    );
  }
}

class _TimelineMarker extends StatelessWidget {
  const _TimelineMarker({required this.isFirst, required this.isLast});

  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: isFirst ? 26 : 0,
          bottom: isLast ? 26 : 0,
          child: Container(
            width: 2,
            color: AppTheme.mutedText.withValues(alpha: 0.18),
          ),
        ),
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.32),
            ),
          ),
          child: Icon(
            Icons.schedule_rounded,
            size: 19,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _LearningPathCourseCard extends StatelessWidget {
  const _LearningPathCourseCard({required this.course});

  final LearningPathCourse course;

  @override
  Widget build(BuildContext context) {
    final courseId = course.navigationCourseId;
    final isUpcoming = course.isScheduled;
    final canOpen = courseId.isNotEmpty && !isUpcoming;
    return Card(
      child: InkWell(
        onTap: isUpcoming || canOpen
            ? () => _handleCourseTap(context, courseId, isUpcoming)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CourseThumbnail(url: course.thumbnailUrl),
                  const SizedBox(width: 12),
                  Expanded(child: _CourseText(course: course)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: course.progressPercentage.clamp(0, 100) / 100,
                  backgroundColor: AppTheme.mutedText.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _CourseMeta(
                      icon: Icons.timer_outlined,
                      label: _durationText(course),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: isUpcoming || canOpen
                        ? () => _handleCourseTap(context, courseId, isUpcoming)
                        : null,
                    icon: Icon(
                      isUpcoming
                          ? Icons.lock_outline_rounded
                          : Icons.play_circle_outline_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isUpcoming ? 'Up Coming' : _actionLabel(course),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUpcoming ? _upcomingCourseColor : null,
                      foregroundColor: isUpcoming ? Colors.white : null,
                      disabledBackgroundColor: AppTheme.mutedText.withValues(
                        alpha: 0.16,
                      ),
                      disabledForegroundColor: AppTheme.mutedText,
                      minimumSize: const Size(0, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCourseTap(
    BuildContext context,
    String courseId,
    bool isUpcoming,
  ) {
    if (isUpcoming) {
      showInfoToast(
        context,
        message: 'This course is scheduled and will be available soon.',
      );
      return;
    }
    _openCourseVideo(context, courseId);
  }

  void _openCourseVideo(BuildContext context, String courseId) {
    context.go(
      '/courses/${Uri.encodeComponent(courseId)}'
      '?return_to=${Uri.encodeComponent('/learning-path')}',
    );
  }

  String _actionLabel(LearningPathCourse course) {
    if (course.isCompleted) return 'Review Course';
    if (course.action == 'watch_continue') return 'Watch Continue';
    if (course.progressPercentage <= 0) return 'Start Course';
    return 'Watch Continue';
  }

  String _durationText(LearningPathCourse course) {
    if (course.totalWatchTime.isNotEmpty && course.totalWatchTime != '0') {
      return course.totalWatchTime;
    }
    if (course.totalSeconds <= 0) return '0 Minutes';
    final minutes = course.totalSeconds / 60;
    return '${minutes.toStringAsFixed(minutes >= 10 ? 0 : 1)} Minutes';
  }
}

class _CourseThumbnail extends StatelessWidget {
  const _CourseThumbnail({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 78,
        width: 124,
        child: url == null
            ? Icon(Icons.play_lesson_rounded, color: colorScheme.primary)
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.contain,
                errorWidget: (_, _, _) => Icon(
                  Icons.broken_image_outlined,
                  color: colorScheme.primary,
                ),
              ),
      ),
    );
  }
}

class _CourseText extends StatelessWidget {
  const _CourseText({required this.course});

  final LearningPathCourse course;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.courseName.isEmpty ? 'Untitled course' : course.courseName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _CourseMeta(
              icon: Icons.trending_up_rounded,
              label:
                  '${course.progressPercentage.clamp(0, 100).toStringAsFixed(0)}%',
            ),
            if (course.status.isNotEmpty)
              _StatusBadge(
                label: course.isCompleted ? 'Completed' : course.status,
                isUpcoming: course.isScheduled,
              ),
          ],
        ),
      ],
    );
  }
}

class _CourseMeta extends StatelessWidget {
  const _CourseMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.mutedText),
        const SizedBox(width: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.isUpcoming});

  final String label;
  final bool isUpcoming;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isUpcoming ? _upcomingCourseColor : colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isUpcoming ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
