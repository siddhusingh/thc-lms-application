import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import 'assessment_provider.dart';

class AssessmentListScreen extends StatefulWidget {
  const AssessmentListScreen({super.key});

  @override
  State<AssessmentListScreen> createState() => _AssessmentListScreenState();
}

class _AssessmentListScreenState extends State<AssessmentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AssessmentProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    if (provider.loading && provider.assessments.isEmpty) {
      return const LoadingShimmer();
    }
    if (provider.error != null && provider.assessments.isEmpty) {
      return AppErrorView(
        message: provider.error!,
        onRetry: () => provider.load(refresh: true),
      );
    }
    if (provider.assessments.isEmpty) {
      return const EmptyState(
        title: 'No assessments',
        subtitle: 'Available tests will appear here.',
        icon: Icons.quiz_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: () => provider.load(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.assessments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = provider.assessments[index];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: const CircleAvatar(child: Icon(Icons.quiz_rounded)),
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${item.totalQuestions} questions • ${item.durationMinutes} min • Pass ${item.passPercentage.toStringAsFixed(0)}%',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/assessments/${item.id}'),
            ),
          );
        },
      ),
    );
  }
}
