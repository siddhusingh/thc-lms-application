import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../models/calendar_model.dart';
import 'calendar_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<CalendarProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final data = provider.data;

    if (provider.loading && data == null) return const LoadingShimmer();

    if (provider.error != null && data == null) {
      return AppErrorView(
        message: provider.error!,
        onRetry: () => provider.load(refresh: true),
      );
    }

    final hasEvents = provider.events.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () => provider.load(refresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const _CalendarHeader(),
          const SizedBox(height: 14),
          if (!hasEvents)
            const SizedBox(
              height: 420,
              child: EmptyState(
                icon: Icons.calendar_month_outlined,
                title: 'No calendar courses yet',
                subtitle: 'Scheduled and watching courses will appear here.',
              ),
            )
          else ...[
            _MonthCalendar(provider: provider),
            const SizedBox(height: 14),
            _SelectedDateEvents(provider: provider),
          ],
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: Colors.lightBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.lightBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calendar',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Scheduled and watching courses appear by date.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LegendChip(
                  color: Color(0xFF19C37D),
                  label: 'Watching Courses',
                ),
                _LegendChip(
                  color: Color(0xFFF45D64),
                  label: 'Scheduled Courses',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 9,
            width: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({required this.provider});

  final CalendarProvider provider;

  static const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final month = provider.focusedMonth;
    final dates = _calendarDates(month);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: provider.previousMonth,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    '${_months[month.month - 1]} ${month.year}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: provider.goToToday,
                  child: const Text('Today'),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: provider.nextMonth,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: _weekdays
                  .map(
                    (day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dates.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.86,
              ),
              itemBuilder: (context, index) {
                final date = dates[index];
                return _CalendarDayCell(
                  date: date,
                  focusedMonth: month,
                  selected: _sameDate(date, provider.selectedDate),
                  events: provider.eventsFor(date),
                  onTap: () => provider.selectDate(date),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<DateTime> _calendarDates(DateTime month) {
    final first = DateTime(month.year, month.month);
    final start = first.subtract(Duration(days: first.weekday % 7));
    return List.generate(42, (index) => start.add(Duration(days: index)));
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.focusedMonth,
    required this.selected,
    required this.events,
    required this.onTap,
  });

  final DateTime date;
  final DateTime focusedMonth;
  final bool selected;
  final List<CalendarCourseEvent> events;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inMonth = date.month == focusedMonth.month;
    final today = _sameDate(date, DateTime.now());
    final hasEvents = events.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: hasEvents || inMonth ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.14)
              : today
              ? colorScheme.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? Border.all(color: colorScheme.primary.withValues(alpha: 0.30))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: inMonth
                    ? selected
                          ? colorScheme.primary
                          : AppTheme.textDark
                    : AppTheme.mutedText.withValues(alpha: 0.46),
                fontWeight: today || selected
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _eventDots(events),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _eventDots(List<CalendarCourseEvent> events) {
    final visibleTypes = events.map((event) => event.type).toSet().take(2);
    return visibleTypes
        .map(
          (type) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            height: 6,
            width: 6,
            decoration: BoxDecoration(
              color: _eventColor(type),
              shape: BoxShape.circle,
            ),
          ),
        )
        .toList();
  }
}

class _SelectedDateEvents extends StatelessWidget {
  const _SelectedDateEvents({required this.provider});

  final CalendarProvider provider;

  @override
  Widget build(BuildContext context) {
    final events = provider.selectedDateEvents;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDateTitle(provider.selectedDate),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (events.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: EmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'No courses on this date',
                  subtitle: 'Select a highlighted date to view courses.',
                ),
              )
            else
              ...events.map(
                (event) => Padding(
                  padding: EdgeInsets.only(
                    bottom: event == events.last ? 0 : 12,
                  ),
                  child: _CalendarEventCard(event: event),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTitle(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({required this.event});

  final CalendarCourseEvent event;

  @override
  Widget build(BuildContext context) {
    final navigationCourseId = event.navigationCourseId;
    final canOpen = navigationCourseId.isNotEmpty;
    final eventColor = _eventColor(event.type);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: eventColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: eventColor.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EventThumbnail(url: event.thumbnailUrl, color: eventColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.courseName.isEmpty
                          ? 'Untitled course'
                          : event.courseName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _EventBadge(event: event),
                    const SizedBox(height: 8),
                    Text(
                      _timeRange(event),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${event.watchedVideos}/${event.totalVideos} videos watched',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: event.type == CalendarCourseEventType.watching
                ? ElevatedButton.icon(
                    onPressed: canOpen
                        ? () => _openCourse(context, navigationCourseId)
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Continue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: eventColor,
                      minimumSize: const Size.fromHeight(42),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: () => _showScheduledMessage(context),
                    icon: const Icon(Icons.lock_outline_rounded),
                    label: const Text('View Course'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: eventColor,
                      side: BorderSide(
                        color: eventColor.withValues(alpha: 0.42),
                      ),
                      minimumSize: const Size.fromHeight(42),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _openCourse(BuildContext context, String courseId) {
    context.go(
      '/courses/${Uri.encodeComponent(courseId)}'
      '?return_to=${Uri.encodeComponent('/calendar')}',
    );
  }

  void _showScheduledMessage(BuildContext context) {
    showInfoToast(
      context,
      message: 'Course available from ${_scheduledDateTime(event)}.',
    );
  }

  String _scheduledDateTime(CalendarCourseEvent event) {
    final start = event.startDate;
    if (start == null) return 'the scheduled date and time';
    return '${_formatDate(start)} at ${_formatTime(start)}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _timeRange(CalendarCourseEvent event) {
    final start = event.startDate;
    final end = event.endDate;
    if (start == null && end == null) return 'Time not available';
    if (end == null) return 'Starts ${_formatTime(start!)}';
    if (start == null) return 'Ends ${_formatTime(end)}';
    return '${_formatTime(start)} - ${_formatTime(end)}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _EventBadge extends StatelessWidget {
  const _EventBadge({required this.event});

  final CalendarCourseEvent event;

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(event.type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        event.type.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EventThumbnail extends StatelessWidget {
  const _EventThumbnail({required this.url, required this.color});

  final String? url;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 78,
        width: 104,
        child: url == null
            ? ColoredBox(
                color: color.withValues(alpha: 0.12),
                child: Icon(Icons.play_lesson_rounded, color: color),
              )
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => ColoredBox(
                  color: color.withValues(alpha: 0.12),
                  child: Icon(Icons.broken_image_outlined, color: color),
                ),
              ),
      ),
    );
  }
}

Color _eventColor(CalendarCourseEventType type) {
  return switch (type) {
    CalendarCourseEventType.watching => const Color(0xFF19C37D),
    CalendarCourseEventType.scheduled => const Color(0xFFF45D64),
  };
}

bool _sameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
