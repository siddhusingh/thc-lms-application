import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../models/course_model.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({required this.course, required this.onTap, super.key});

  final CourseModel course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 78,
                  width: 124,
                  child: course.thumbnailUrl == null
                      ? Icon(
                          Icons.play_lesson_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : CachedNetworkImage(
                          imageUrl: course.thumbnailUrl!,
                          fit: BoxFit.contain,
                          errorWidget: (_, _, _) => Icon(
                            Icons.broken_image_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: course.progress.clamp(0, 100) / 100,
                    ),
                    const SizedBox(height: 6),
                    Text('${course.progress.toStringAsFixed(0)}% complete'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
