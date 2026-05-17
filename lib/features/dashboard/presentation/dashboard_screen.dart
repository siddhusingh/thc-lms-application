import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/metric_card.dart';
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
            'Hi, ${dashboard?.studentName ?? auth.user?.name ?? 'Student'}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Continue your training from where you left off',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              MetricCard(
                title: 'Courses',
                value: '${dashboard?.enrolledCourses ?? 0}',
                icon: Icons.menu_book_rounded,
                color: AppTheme.primary,
              ),
              MetricCard(
                title: 'Completed',
                value: '${dashboard?.completedCourses ?? 0}',
                icon: Icons.verified_rounded,
                color: AppTheme.accent,
              ),
              MetricCard(
                title: 'Certificates',
                value: '${dashboard?.certificates ?? 0}',
                icon: Icons.workspace_premium_rounded,
                color: AppTheme.warning,
              ),
              MetricCard(
                title: 'Watch time',
                value: '${dashboard?.watchTimeMinutes ?? 0}m',
                icon: Icons.play_circle_rounded,
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
                          '/courses/${dashboard.continueLearning!.id}',
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
          _ListPanel(
            title: 'Upcoming assessments',
            items: dashboard?.upcomingAssessments ?? const [],
            emptyText: 'No upcoming assessments',
          ),
          const SizedBox(height: 16),
          _ListPanel(
            title: 'Recent activities',
            items: dashboard?.recentActivities ?? const [],
            emptyText: 'No recent activity',
          ),
        ],
      ),
    );
  }
}

class _ListPanel extends StatelessWidget {
  const _ListPanel({
    required this.title,
    required this.items,
    required this.emptyText,
  });

  final String title;
  final List<String> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text(emptyText)
            else
              ...items
                  .take(5)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 7,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
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
}
