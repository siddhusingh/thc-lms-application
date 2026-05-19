import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../models/assessment_model.dart';
import 'assessment_provider.dart';

class AssessmentResultsScreen extends StatefulWidget {
  const AssessmentResultsScreen({super.key});

  @override
  State<AssessmentResultsScreen> createState() =>
      _AssessmentResultsScreenState();
}

class _AssessmentResultsScreenState extends State<AssessmentResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AssessmentProvider>().loadResults(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    final results = provider.resultHistory;

    if (provider.resultsLoading && results.isEmpty) {
      return const LoadingShimmer();
    }

    if (provider.resultsError != null && results.isEmpty) {
      return AppErrorView(
        message: provider.resultsError!,
        onRetry: () => provider.loadResults(refresh: true),
      );
    }

    if (results.isEmpty) {
      return const EmptyState(
        title: 'No results yet',
        subtitle: 'Completed assessment results will appear here.',
        icon: Icons.analytics_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadResults(refresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _ResultsSummary(results: results),
          const SizedBox(height: 14),
          _ScoreTimelineCard(results: results),
          const SizedBox(height: 14),
          Text(
            'Result History',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...results.reversed.map((result) => _ResultHistoryCard(result)),
        ],
      ),
    );
  }
}

class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({required this.results});

  final List<AssessmentResultHistoryModel> results;

  @override
  Widget build(BuildContext context) {
    final totalAttempts = results.length;
    final averageScore =
        results.map((item) => item.percentage).fold(0.0, (a, b) => a + b) /
        totalAttempts;
    final bestScore = results
        .map((item) => item.percentage)
        .fold(0.0, math.max);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Average',
            value: '${averageScore.toStringAsFixed(0)}%',
            icon: Icons.show_chart_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Best',
            value: '${bestScore.toStringAsFixed(0)}%',
            icon: Icons.emoji_events_outlined,
            color: const Color(0xFF12CFA0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Attempts',
            value: '$totalAttempts',
            icon: Icons.assignment_turned_in_outlined,
            color: const Color(0xFFFFAA0A),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 108,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.mutedText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreTimelineCard extends StatelessWidget {
  const _ScoreTimelineCard({required this.results});

  final List<AssessmentResultHistoryModel> results;

  @override
  Widget build(BuildContext context) {
    final spots = results
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.percentage))
        .toList();
    final primary = Theme.of(context).colorScheme.primary;
    final gridColor = AppTheme.mutedText.withValues(alpha: 0.14);
    final labelStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText);
    final labelInterval = math.max(1, (results.length / 6).ceil()).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score Timeline',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Assessment score percentage',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: math.max(0, results.length - 1).toDouble(),
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
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          final result = results[index];
                          return LineTooltipItem(
                            '${result.displayTitle}\n',
                            Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    '${_formatDate(result.lastCompletedAt)}  '
                                    '${result.percentage.toStringAsFixed(0)}%  '
                                    '${result.scoreLabel}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textDark,
                                      fontWeight: FontWeight.w800,
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
                        reservedSize: 36,
                        interval: labelInterval,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 ||
                              index >= results.length ||
                              value != index ||
                              (index != results.length - 1 &&
                                  index % labelInterval.toInt() != 0)) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              _formatDate(results[index].lastCompletedAt),
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
                        interval: 20,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          if (value % 20 != 0) return const SizedBox.shrink();
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
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: _scoreColor(spot.y, primary),
                            strokeWidth: 0,
                          );
                        },
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

  Color _scoreColor(double score, Color fallback) {
    if (score >= 80) return const Color(0xFF12CFA0);
    if (score < 50) return const Color(0xFFFF5A5F);
    return fallback;
  }
}

class _ResultHistoryCard extends StatelessWidget {
  const _ResultHistoryCard(this.result);

  final AssessmentResultHistoryModel result;

  @override
  Widget build(BuildContext context) {
    final scoreColor = result.percentage >= 80
        ? const Color(0xFF12CFA0)
        : result.percentage < 50
        ? const Color(0xFFFF5A5F)
        : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.analytics_outlined, color: scoreColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.displayCourseTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                    ),
                    if (result.videoTitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        result.videoTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _ResultChip(result.displayAssessmentType),
                        _ResultChip(_formatDate(result.lastCompletedAt)),
                        _ResultChip(result.timeTaken),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${result.percentage.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scoreColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.scoreLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w700,
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
}

class _ResultChip extends StatelessWidget {
  const _ResultChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.mutedText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return 'No date';
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
  return '${value.day} ${months[value.month - 1]}';
}
