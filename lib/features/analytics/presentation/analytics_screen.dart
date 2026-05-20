import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../models/analytics_model.dart';
import 'analytics_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AnalyticsProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final data = provider.data;

    if (provider.loading && data == null) return const LoadingShimmer();

    if (provider.error != null && data == null) {
      return AppErrorView(
        message: provider.error!,
        onRetry: () => provider.load(refresh: true),
      );
    }

    final analytics = data ?? const AnalyticsModel();

    return RefreshIndicator(
      onRefresh: () => provider.load(refresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _AnalyticsHeader(
            startDate: provider.startDate,
            endDate: provider.endDate,
            loading: provider.loading,
            onPickRange: () => _pickDateRange(context, provider),
          ),
          const SizedBox(height: 14),
          _AnalyticsMetrics(data: analytics),
          const SizedBox(height: 14),
          if (!analytics.hasChartData)
            const SizedBox(
              height: 340,
              child: EmptyState(
                icon: Icons.analytics_outlined,
                title: 'No analytics yet',
                subtitle:
                    'Learning activity for the selected range will appear here.',
              ),
            )
          else ...[
            _StudyTimeChartCard(points: analytics.studyTimeGraph),
            const SizedBox(height: 14),
            _CourseTimePieCard(items: analytics.timeSpentCourses),
            const SizedBox(height: 14),
            _LoginSessionsChartCard(items: analytics.loginSessionsGraph),
            const SizedBox(height: 14),
            _AssessmentScoresCard(items: analytics.assessmentsGraph),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDateRange(
    BuildContext context,
    AnalyticsProvider provider,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      initialDateRange: DateTimeRange(
        start: provider.startDate,
        end: provider.endDate,
      ),
    );
    if (picked == null || !context.mounted) return;
    await provider.setDateRange(picked.start, picked.end);
  }
}

class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader({
    required this.startDate,
    required this.endDate,
    required this.loading,
    required this.onPickRange,
  });

  final DateTime startDate;
  final DateTime endDate;
  final bool loading;
  final VoidCallback onPickRange;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analytics',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Your learning activity and outcomes.',
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: loading ? null : onPickRange,
                icon: const Icon(Icons.date_range_rounded, size: 18),
                label: Text(
                  '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(42),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsMetrics extends StatelessWidget {
  const _AnalyticsMetrics({required this.data});

  final AnalyticsModel data;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricInfo(
        title: 'Study Time',
        value: data.studyTime,
        icon: Icons.timer_outlined,
        color: const Color(0xFF12CFA0),
      ),
      _MetricInfo(
        title: 'Active Days',
        value: '${data.activeDays}',
        icon: Icons.event_available_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      _MetricInfo(
        title: 'Login Sessions',
        value: '${data.loginSessions}',
        icon: Icons.login_rounded,
        color: const Color(0xFF4DB6E5),
      ),
      _MetricInfo(
        title: 'Assessments',
        value: '${data.assessments}',
        icon: Icons.quiz_outlined,
        color: const Color(0xFFFFAA0A),
      ),
      _MetricInfo(
        title: 'Completed Courses',
        value: '${data.completedCourses}',
        icon: Icons.workspace_premium_outlined,
        color: const Color(0xFF7C5CFF),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: constraints.maxWidth >= 640 ? 1.85 : 1.12,
          ),
          itemBuilder: (context, index) => _MetricCard(metrics[index]),
        );
      },
    );
  }
}

class _MetricInfo {
  const _MetricInfo({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.metric);

  final _MetricInfo metric;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: metric.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(metric.icon, color: metric.color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              metric.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              metric.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyTimeChartCard extends StatelessWidget {
  const _StudyTimeChartCard({required this.points});

  final List<AnalyticsStudyTimePoint> points;

  @override
  Widget build(BuildContext context) {
    final visiblePoints = points.isEmpty
        ? const [AnalyticsStudyTimePoint(watchDate: '', hours: 0)]
        : points;
    final maxValue = visiblePoints
        .map((point) => point.hours)
        .fold(0.0, math.max);
    final maxY = math.max(1.0, (maxValue * 1.25).ceilToDouble());
    final primary = Theme.of(context).colorScheme.primary;
    final gridColor = AppTheme.mutedText.withValues(alpha: 0.14);
    final labelStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText);

    return _ChartCard(
      title: 'Study Time Trend',
      subtitle: 'Daily watch time in hours',
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY <= 2 ? 0.5 : 1,
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
                      text: _formatHours(rod.toY),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                interval: maxY <= 2 ? 0.5 : 1,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      maxY <= 2
                          ? value.toStringAsFixed(1)
                          : value.toStringAsFixed(0),
                      style: labelStyle,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: visiblePoints.asMap().entries.map((entry) {
            return BarChartGroupData(
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
            );
          }).toList(),
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

  final List<AnalyticsCourseTime> items;

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
            const SizedBox(height: 4),
            Text(
              'Course share for the selected range',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
            ),
            const SizedBox(height: 16),
            if (visibleItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: EmptyState(
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'No course time',
                  subtitle: 'Course-wise study time will appear here.',
                ),
              )
            else ...[
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 42,
                    sectionsSpace: 2,
                    sections: visibleItems.asMap().entries.map((entry) {
                      final item = entry.value;
                      return PieChartSectionData(
                        value: item.percentage > 0
                            ? item.percentage
                            : item.totalSeconds.toDouble(),
                        title: '${item.percentage.toStringAsFixed(1)}%',
                        radius: 76,
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
                return _CourseLegendItem(
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

class _CourseLegendItem extends StatelessWidget {
  const _CourseLegendItem({required this.item, required this.color});

  final AnalyticsCourseTime item;
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
              item.displayTitle,
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

class _LoginSessionsChartCard extends StatelessWidget {
  const _LoginSessionsChartCard({required this.items});

  final List<AnalyticsLoginSession> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = [...items]
      ..sort((a, b) {
        final left = a.loginDateTime;
        final right = b.loginDateTime;
        if (left == null && right == null) return 0;
        if (left == null) return 1;
        if (right == null) return -1;
        return left.compareTo(right);
      });
    final chartItems = visibleItems.isEmpty
        ? const [AnalyticsLoginSession(loginDate: '', totalLogins: 0)]
        : visibleItems;
    final maxValue = chartItems
        .map((item) => item.totalLogins)
        .fold(0, math.max)
        .toDouble();
    final maxY = math.max(5.0, (maxValue * 1.2).ceilToDouble());
    final gridColor = AppTheme.mutedText.withValues(alpha: 0.14);
    final labelStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText);

    return _ChartCard(
      title: 'Login Sessions',
      subtitle: 'Daily app visits',
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: math.max(1, (maxY / 5).floor()).toDouble(),
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
                final item = chartItems[group.x];
                return BarTooltipItem(
                  '${_shortDate(item.loginDate)}\n',
                  Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: '${rod.toY.toInt()} logins',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                      index >= chartItems.length ||
                      value != index) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      _shortDate(chartItems[index].loginDate),
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
                interval: math.max(1, (maxY / 5).floor()).toDouble(),
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(value.toInt().toString(), style: labelStyle),
                  );
                },
              ),
            ),
          ),
          barGroups: chartItems.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.totalLogins.toDouble(),
                  width: 18,
                  color: const Color(0xFF4DB6E5),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AssessmentScoresCard extends StatelessWidget {
  const _AssessmentScoresCard({required this.items});

  final List<AnalyticsAssessmentScore> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.isEmpty
        ? const [
            AnalyticsAssessmentScore(
              title: 'Assessment',
              assessmentType: '',
              timeTaken: '0 mins',
            ),
          ]
        : items;
    final gridColor = AppTheme.mutedText.withValues(alpha: 0.14);
    final labelStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assessment Scores',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Latest completed assessment percentage',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 100,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
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
                        final item = visibleItems[group.x];
                        return BarTooltipItem(
                          '${item.displayTitle}\n',
                          Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${rod.toY.toStringAsFixed(0)}%  ${item.scoreLabel}',
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
                        reservedSize: 38,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 ||
                              index >= visibleItems.length ||
                              value != index) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text('#${index + 1}', style: labelStyle),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
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
                  barGroups: visibleItems.asMap().entries.map((entry) {
                    final item = entry.value;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: item.percentage,
                          width: 18,
                          color: _scoreColor(
                            item.percentage,
                            Theme.of(context).colorScheme.primary,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => _AssessmentScoreTile(item)),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double score, Color fallback) {
    if (score >= 80) return const Color(0xFF12CFA0);
    if (score < 50) return const Color(0xFFFF5A5F);
    return fallback;
  }
}

class _AssessmentScoreTile extends StatelessWidget {
  const _AssessmentScoreTile(this.item);

  final AnalyticsAssessmentScore item;

  @override
  Widget build(BuildContext context) {
    final color = item.percentage >= 80
        ? const Color(0xFF12CFA0)
        : item.percentage < 50
        ? const Color(0xFFFF5A5F)
        : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.assignment_turned_in_outlined, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.displayAssessmentType} - ${_formatDateTime(item.lastCompletedAt)} - ${item.timeTaken}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.percentage.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                item.scoreLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 240, child: child),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day} ${_monthName(date.month)} ${date.year}';
}

String _formatDateTime(DateTime? date) {
  if (date == null) return 'No date';
  return '${date.day} ${_monthName(date.month)}';
}

String _shortDate(String value) {
  final parts = value.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) return '${parts[0]} ${parts[1]}';
  return value;
}

String _monthName(int month) {
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
  return months[month - 1];
}

String _formatHours(double hours) {
  final totalMinutes = (hours * 60).round();
  if (totalMinutes < 60) return '$totalMinutes mins';
  final fullHours = totalMinutes ~/ 60;
  final remainingMinutes = totalMinutes % 60;
  if (remainingMinutes == 0) return '$fullHours hrs';
  return '$fullHours hrs $remainingMinutes mins';
}
