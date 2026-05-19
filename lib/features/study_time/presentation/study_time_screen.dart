import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../models/study_time_model.dart';
import 'study_time_provider.dart';

class StudyTimeScreen extends StatefulWidget {
  const StudyTimeScreen({super.key});

  @override
  State<StudyTimeScreen> createState() => _StudyTimeScreenState();
}

class _StudyTimeScreenState extends State<StudyTimeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<StudyTimeProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyTimeProvider>();
    final data = provider.data;

    if (provider.loading && data == null) return const LoadingShimmer();

    if (provider.error != null && data == null) {
      return AppErrorView(
        message: provider.error!,
        onRetry: () => provider.load(refresh: true),
      );
    }

    final studyTime = data ?? const StudyTimeModel();

    return RefreshIndicator(
      onRefresh: () => provider.load(refresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const _StudyTimeHeader(),
          const SizedBox(height: 14),
          _StudyTimeMetrics(data: studyTime),
          const SizedBox(height: 14),
          if (!studyTime.hasStudyTime)
            const SizedBox(
              height: 360,
              child: EmptyState(
                icon: Icons.timer_outlined,
                title: 'No study time yet',
                subtitle: 'Your course watch time will appear here.',
              ),
            )
          else ...[
            _CourseTimePieCard(items: studyTime.pieChart),
            const SizedBox(height: 14),
            _StudyTimeGraphCard(points: studyTime.graph),
          ],
        ],
      ),
    );
  }
}

class _StudyTimeHeader extends StatelessWidget {
  const _StudyTimeHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.timer_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Study Time',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Track how much time you spend learning.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyTimeMetrics extends StatelessWidget {
  const _StudyTimeMetrics({required this.data});

  final StudyTimeModel data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StudyMetricCard(
          title: 'Total Study Time',
          value: data.totalTime,
          icon: Icons.timer_outlined,
          color: const Color(0xFF12CFA0),
        ),
        const SizedBox(height: 12),
        _StudyMetricCard(
          title: 'Average Per Day',
          value: data.averageTime,
          icon: Icons.history_rounded,
          color: const Color(0xFFFF5A5F),
        ),
        const SizedBox(height: 12),
        _StudyMetricCard(
          title: 'Longest Study Session',
          value: data.longestSession,
          icon: Icons.star_border_rounded,
          color: const Color(0xFF7C5CFF),
        ),
      ],
    );
  }
}

class _StudyMetricContent extends StatelessWidget {
  const _StudyMetricContent({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.mutedText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StudyMetricCard extends StatelessWidget {
  const _StudyMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: _StudyMetricContent(
          title: title,
          value: value,
          icon: icon,
          color: color,
        ),
      ),
    );
  }
}

class _CourseTimePieCard extends StatelessWidget {
  const _CourseTimePieCard({required this.items});

  static const _colors = [
    Color(0xFF6766F6),
    Color(0xFFFFAA0A),
    Color(0xFF12CFA0),
    Color(0xFFFF5A5F),
    Color(0xFF4DB6E5),
    Color(0xFF7C5CFF),
  ];

  final List<StudyTimeCourseSlice> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items
        .where((item) => item.totalSeconds > 0 || item.percentage > 0)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Spent Per Course',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            if (visibleItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: EmptyState(
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'No course time yet',
                  subtitle: 'Course-wise study time will appear here.',
                ),
              )
            else ...[
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 0,
                    sectionsSpace: 2,
                    sections: visibleItems.asMap().entries.map((entry) {
                      final item = entry.value;
                      return PieChartSectionData(
                        value: item.percentage > 0
                            ? item.percentage
                            : item.totalSeconds.toDouble(),
                        title: item.percentage > 0
                            ? '${item.percentage.toStringAsFixed(1)}%'
                            : '',
                        radius: 84,
                        color: _colors[entry.key % _colors.length],
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ...visibleItems.asMap().entries.map((entry) {
                final item = entry.value;
                return _CourseTimeLegendItem(
                  item: item,
                  color: _colors[entry.key % _colors.length],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _CourseTimeLegendItem extends StatelessWidget {
  const _CourseTimeLegendItem({required this.item, required this.color});

  final StudyTimeCourseSlice item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.title.isEmpty ? 'Untitled course' : item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.formattedTime,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                '${item.percentage.toStringAsFixed(1)}%',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudyTimeGraphCard extends StatefulWidget {
  const _StudyTimeGraphCard({required this.points});

  final List<StudyTimeGraphPoint> points;

  @override
  State<_StudyTimeGraphCard> createState() => _StudyTimeGraphCardState();
}

class _StudyTimeGraphCardState extends State<_StudyTimeGraphCard> {
  late DateTimeRange _range;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _range = DateTimeRange(
      start: today.subtract(const Duration(days: 4)),
      end: today,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPoints = _pointsInRange(widget.points);
    final visiblePoints = selectedPoints.isEmpty
        ? const [StudyTimeGraphPoint(watchDate: '', hours: 0)]
        : selectedPoints;
    final maxValue = visiblePoints
        .map((point) => point.hours)
        .fold(0.0, math.max);
    final maxY = math.max(6.0, maxValue.ceilToDouble());
    final gridColor = AppTheme.mutedText.withValues(alpha: 0.14);
    final labelStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText);
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Study Time Graph',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Study time in hours',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: OutlinedButton.icon(
                    onPressed: _pickRange,
                    icon: const Icon(Icons.date_range_rounded, size: 18),
                    label: Text(
                      _rangeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: gridColor, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipColor: (_) => Colors.white,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final point = visiblePoints[group.x];
                        return BarTooltipItem(
                          '${point.watchDate.isEmpty ? 'Study time' : point.watchDate}\n',
                          Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            TextSpan(
                              text: 'Watch Time:  ${_formatHours(rod.toY)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 ||
                              index >= visiblePoints.length ||
                              value != index) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              visiblePoints[index].watchDate,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: labelStyle,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              value.toInt().toString(),
                              style: labelStyle,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: visiblePoints
                      .asMap()
                      .entries
                      .map(
                        (entry) => BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.hours,
                              width: 18,
                              color: primary,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<StudyTimeGraphPoint> _pointsInRange(List<StudyTimeGraphPoint> points) {
    return points.where((point) {
      final date = _parseGraphDate(point.watchDate);
      if (date == null) return false;
      return !date.isBefore(_range.start) && !date.isAfter(_range.end);
    }).toList();
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      initialDateRange: _range,
    );
    if (picked == null) return;
    setState(() {
      _range = DateTimeRange(
        start: DateUtils.dateOnly(picked.start),
        end: DateUtils.dateOnly(picked.end),
      );
    });
  }

  String get _rangeLabel {
    return '${_formatDate(_range.start)} - ${_formatDate(_range.end)}';
  }

  DateTime? _parseGraphDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed != null) return DateUtils.dateOnly(parsed);

    final parts = text.split(RegExp(r'\s+'));
    if (parts.length < 2) return null;

    final day = int.tryParse(parts.first);
    final month = _monthNumber(parts[1]);
    final year = parts.length >= 3 ? int.tryParse(parts[2]) : _range.end.year;
    if (day == null || month == null || year == null) return null;

    return DateUtils.dateOnly(DateTime(year, month, day));
  }

  int? _monthNumber(String value) {
    switch (value.toLowerCase()) {
      case 'jan':
      case 'january':
        return 1;
      case 'feb':
      case 'february':
        return 2;
      case 'mar':
      case 'march':
        return 3;
      case 'apr':
      case 'april':
        return 4;
      case 'may':
        return 5;
      case 'jun':
      case 'june':
        return 6;
      case 'jul':
      case 'july':
        return 7;
      case 'aug':
      case 'august':
        return 8;
      case 'sep':
      case 'sept':
      case 'september':
        return 9;
      case 'oct':
      case 'october':
        return 10;
      case 'nov':
      case 'november':
        return 11;
      case 'dec':
      case 'december':
        return 12;
    }
    return null;
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
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatHours(double hours) {
    final totalMinutes = (hours * 60).round();
    if (totalMinutes < 60) return '$totalMinutes Minutes';
    final fullHours = totalMinutes ~/ 60;
    final remainingMinutes = totalMinutes % 60;
    if (remainingMinutes == 0) {
      return '$fullHours ${fullHours == 1 ? 'Hour' : 'Hours'}';
    }
    return '$fullHours ${fullHours == 1 ? 'Hour' : 'Hours'} '
        '$remainingMinutes Minutes';
  }
}
