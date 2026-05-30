import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/metric_card.dart';
import '../../../models/dashboard_model.dart';
import '../../auth/presentation/auth_provider.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DashboardProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final auth = context.watch<AuthProvider>();
    final dashboard = provider.dashboard;
    final dashboardName = dashboard?.studentName.trim();
    final authName = auth.user?.name.trim();
    final studentName = authName?.isNotEmpty == true
        ? authName!
        : dashboardName?.isNotEmpty == true && dashboardName != 'Student'
        ? dashboardName!
        : 'Student';
    final learningTimeUnit = _shortLearningTimeUnit(
      dashboard?.learningTimeUnit,
    );

    if (provider.loading && dashboard == null) return const LoadingShimmer();
    if (provider.error != null && dashboard == null) {
      return AppErrorView(
        message: provider.error!,
        onRetry: () => provider.load(refresh: true),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.load(refresh: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${_greetingFor(DateTime.now())}, $studentName',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Continue your training from where you left off',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _MetricGrid(
            cards: [
              MetricCard(
                title: 'Courses available',
                value: '${dashboard?.enrolledCourses ?? 0}',
                icon: Icons.menu_book_rounded,
                color: AppTheme.primary,
              ),
              MetricCard(
                title: 'In progress courses',
                value: '${dashboard?.inProgressCourses ?? 0}',
                icon: Icons.hourglass_bottom_rounded,
                color: AppTheme.warning,
              ),
              MetricCard(
                title: 'Completed courses',
                value: '${dashboard?.completedCourses ?? 0}',
                icon: Icons.verified_rounded,
                color: AppTheme.accent,
              ),
              MetricCard(
                title: 'Total learning time',
                value: '${dashboard?.watchTimeMinutes ?? 0} $learningTimeUnit',
                icon: Icons.schedule_rounded,
                color: AppTheme.danger,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (dashboard?.continueLearning != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue learning',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      dashboard!.continueLearning!.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value:
                          dashboard.continueLearning!.progress.clamp(0, 100) /
                          100,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        onPressed: () => context.go(
                          '/courses/${dashboard.continueLearning!.id}'
                          '?return_to=${Uri.encodeComponent('/dashboard')}',
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Resume'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          _CourseProgressPanel(items: dashboard?.progress ?? const []),
          const SizedBox(height: 16),
          _WeeklyStudyTimePanel(
            studyHours:
                dashboard?.weeklyStudyHours ?? const [0, 0, 0, 0, 0, 0, 0],
          ),
          const SizedBox(height: 16),
          _ActivityByDayPanel(
            loginCounts:
                dashboard?.weeklyLoginCounts ?? const [0, 0, 0, 0, 0, 0, 0],
          ),
          const SizedBox(height: 16),
          _CourseCompletionPanel(
            series: dashboard?.courseCompletionSeries ?? const [],
          ),
        ],
      ),
    );
  }

  String _greetingFor(DateTime now) {
    if (now.hour < 12) return 'Good Morning';
    if (now.hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _shortLearningTimeUnit(String? unit) {
    switch (unit?.trim().toLowerCase()) {
      case 'hour':
      case 'hours':
      case 'hr':
      case 'hrs':
        return 'Hrs.';
      case 'minute':
      case 'minutes':
      case 'min':
      case 'mins':
      default:
        return 'Min.';
    }
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(
      1.0,
      1.35,
    ).toDouble();
    final cardHeight = 112 + ((textScale - 1) * 44);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 330 ? 1 : 2;

        return GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

class _CourseCompletionPanel extends StatelessWidget {
  const _CourseCompletionPanel({required this.series});

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _colors = [
    Color(0xFF2196F3),
    Color(0xFF12CFA0),
    Color(0xFFFFA726),
    Color(0xFFFF5263),
    Color(0xFF7D78D9),
    Color(0xFF26A69A),
  ];

  final List<DashboardCourseCompletionSeries> series;

  @override
  Widget build(BuildContext context) {
    final visibleSeries = series
        .where((item) => item.name.trim().isNotEmpty)
        .toList();
    final gridColor = AppTheme.mutedText.withValues(alpha: 0.14);
    final labelStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course Completion %',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (visibleSeries.isEmpty)
              const Text('No course completion data yet')
            else ...[
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    maxY: 100,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: gridColor, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipColor: (_) => Colors.white,
                        getTooltipItems: (spots) {
                          return spots.map((spot) {
                            final chartSeries = visibleSeries[spot.barIndex];
                            return LineTooltipItem(
                              '${chartSeries.name}\n',
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '${_days[spot.x.toInt()]}:  ${spot.y.toStringAsFixed(0)}%',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            );
                          }).toList();
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
                          reservedSize: 28,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 ||
                                index >= _days.length ||
                                value != index) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(_days[index], style: labelStyle),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          reservedSize: 34,
                          getTitlesWidget: (value, meta) {
                            if (value % 20 != 0) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                value.toInt().toString(),
                                softWrap: false,
                                style: labelStyle,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: visibleSeries.asMap().entries.map((entry) {
                      final color = _colors[entry.key % _colors.length];
                      final values = List<double>.generate(
                        7,
                        (index) => index < entry.value.values.length
                            ? entry.value.values[index].clamp(0, 100).toDouble()
                            : 0,
                        growable: false,
                      );
                      return LineChartBarData(
                        spots: values
                            .asMap()
                            .entries
                            .map(
                              (spot) => FlSpot(
                                spot.key.toDouble(),
                                spot.value.toDouble(),
                              ),
                            )
                            .toList(),
                        isCurved: true,
                        preventCurveOverShooting: true,
                        color: color,
                        barWidth: 2,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                            radius: 4,
                            color: color,
                            strokeWidth: 0,
                          ),
                        ),
                        belowBarData: BarAreaData(show: false),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 10,
                children: visibleSeries.asMap().entries.map((entry) {
                  final color = _colors[entry.key % _colors.length];
                  return _CompletionLegendItem(
                    label: entry.value.name,
                    color: color,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompletionLegendItem extends StatelessWidget {
  const _CompletionLegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 145),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityByDayPanel extends StatelessWidget {
  const _ActivityByDayPanel({required this.loginCounts});

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final List<int> loginCounts;

  @override
  Widget build(BuildContext context) {
    final values = List<int>.generate(
      7,
      (index) => index < loginCounts.length ? loginCounts[index] : 0,
      growable: false,
    );
    final maxValue = values.fold<int>(0, math.max);
    final maxY = math.max(5, maxValue).toDouble();
    final barColor = const Color(0xFF7D78D9);
    final gridColor = AppTheme.mutedText.withValues(alpha: 0.14);
    final labelStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity by Day',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Login sessions',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
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
                        return BarTooltipItem(
                          '${_days[group.x]}\n',
                          Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            TextSpan(
                              text: 'Login Sessions:  ${rod.toY.toInt()}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.w700,
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
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= _days.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(_days[index], style: labelStyle),
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
                          if (value % 1 != 0) {
                            return const SizedBox.shrink();
                          }
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
                  barGroups: values
                      .asMap()
                      .entries
                      .map(
                        (entry) => BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              width: 18,
                              color: barColor,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
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
}

class _WeeklyStudyTimePanel extends StatelessWidget {
  const _WeeklyStudyTimePanel({required this.studyHours});

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final List<double> studyHours;

  @override
  Widget build(BuildContext context) {
    final values = List<double>.generate(
      7,
      (index) => index < studyHours.length ? studyHours[index] : 0,
      growable: false,
    );
    final maxValue = values.fold<double>(0, math.max);
    final maxY = math.max(6, maxValue.ceil()).toDouble();
    final spots = values
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();
    final primary = Theme.of(context).colorScheme.primary;
    final gridColor = AppTheme.mutedText.withValues(alpha: 0.14);
    final labelStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Study Time',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Study time in hours',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: gridColor, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipColor: (_) => Colors.white,
                      getTooltipItems: (spots) {
                        return spots
                            .map(
                              (spot) => LineTooltipItem(
                                '${_days[spot.x.toInt()]}\n',
                                Theme.of(context).textTheme.bodySmall!.copyWith(
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        'Study Time:  ${_formatStudyTime(spot.y)}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textDark,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            )
                            .toList();
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
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 ||
                              index >= _days.length ||
                              value != index) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(_days[index], style: labelStyle),
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
                          if (value % 1 != 0) {
                            return const SizedBox.shrink();
                          }
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
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: primary,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                          radius: 3.5,
                          color: primary,
                          strokeWidth: 0,
                        ),
                      ),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatStudyTime(double hours) {
    final totalMinutes = (hours * 60).round();
    if (totalMinutes < 60) {
      return '$totalMinutes Minutes';
    }

    final fullHours = totalMinutes ~/ 60;
    final remainingMinutes = totalMinutes % 60;
    if (remainingMinutes == 0) {
      return '$fullHours ${fullHours == 1 ? 'Hour' : 'Hours'}';
    }
    return '$fullHours ${fullHours == 1 ? 'Hour' : 'Hours'} '
        '$remainingMinutes Minutes';
  }
}

class _CourseProgressPanel extends StatelessWidget {
  const _CourseProgressPanel({required this.items});

  final List<DashboardCourseProgress> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course progress',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('No course progress yet')
            else
              ...items.asMap().entries.map(
                (entry) => _CourseProgressRow(
                  item: entry.value,
                  showDivider: entry.key != items.length - 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CourseProgressRow extends StatelessWidget {
  const _CourseProgressRow({required this.item, required this.showDivider});

  final DashboardCourseProgress item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final progress = item.progressPercentage.clamp(0, 100).toDouble();
    final navigationCourseId = item.navigationCourseId;
    final thumbnailUrl = item.courseThumbnail;
    final canShowThumbnail =
        thumbnailUrl != null &&
        (thumbnailUrl.startsWith('http://') ||
            thumbnailUrl.startsWith('https://'));

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: canShowThumbnail
                    ? Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _thumbnailFallback(context),
                      )
                    : _thumbnailFallback(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.courseName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(
                        width: 38,
                        child: Text(
                          '${progress.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            value: progress / 100,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: navigationCourseId.isEmpty
                  ? null
                  : () => context.go(
                      '/courses/${Uri.encodeComponent(navigationCourseId)}'
                      '?return_to=${Uri.encodeComponent('/dashboard')}',
                    ),
              child: const Text('Continue'),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _thumbnailFallback(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
      child: Icon(
        Icons.play_lesson_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
