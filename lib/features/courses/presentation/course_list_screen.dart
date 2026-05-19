import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import 'course_card.dart';
import 'course_provider.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final _controller = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<CourseProvider>().load(),
    );
    _controller.addListener(() {
      if (_controller.position.pixels >
          _controller.position.maxScrollExtent - 300) {
        context.read<CourseProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    if (provider.loading && provider.courses.isEmpty) {
      return const LoadingShimmer();
    }
    if (provider.error != null && provider.courses.isEmpty) {
      return AppErrorView(
        message: provider.error!,
        onRetry: () => provider.load(refresh: true),
      );
    }
    return RefreshIndicator(
      onRefresh: () => provider.load(refresh: true),
      child: ListView.separated(
        controller: _controller,
        padding: const EdgeInsets.all(16),
        itemCount: provider.courses.isEmpty ? 2 : provider.courses.length + 2,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search courses',
              ),
              onSubmitted: (value) =>
                  provider.load(refresh: true, search: value.trim()),
            );
          }
          if (provider.courses.isEmpty) {
            return const SizedBox(
              height: 420,
              child: EmptyState(
                title: 'No courses',
                subtitle: 'Your enrolled courses will appear here.',
              ),
            );
          }
          final itemIndex = index - 1;
          if (itemIndex >= provider.courses.length) {
            return provider.loadingMore
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink();
          }
          final course = provider.courses[itemIndex];
          return CourseCard(
            course: course,
            onTap: () => context.go(
              '/courses/${course.id}?return_to=${Uri.encodeComponent('/courses')}',
            ),
          );
        },
      ),
    );
  }
}
