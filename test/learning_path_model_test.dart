import 'package:flutter_test/flutter_test.dart';
import 'package:thc_lms_mobile/models/learning_path_model.dart';

void main() {
  test('learning path parses nested summary and courses payload', () {
    final learningPath = LearningPathModel.fromJson({
      'status': true,
      'message': 'Learning path data.',
      'data': {
        'summary': {
          'total_courses': 4,
          'progress_percentage': 0,
          'watched_time': '55.3 Minutes',
        },
        'courses': [
          {
            'id': 4,
            'course_id': 'THC20260502153456',
            'course_name': 'Essential Clinical Nursing Skills for Patient Care',
            'course_thumbnail': '96076ef2d798f22c34ea61010a6a3a0e.jpg',
            'status': 'Published',
            'progress_percentage': 60,
            'total_seconds': 1382,
            'total_watch_time': '23.03 Minutes',
            'course_thumbnail_url':
                'https://srmcare.in/uploads/courses/96076ef2d798f22c34ea61010a6a3a0e.jpg',
            'is_completed': false,
            'action': 'watch_continue',
          },
          {
            'id': 2,
            'course_id': 'THC20260411122508',
            'course_name': 'Where can I get some?',
            'course_thumbnail': '6225f2ec001a190d048b2a860a41a2de.jpg',
            'status': 'Published',
            'progress_percentage': '40.00',
            'total_seconds': '1935',
            'total_watch_time': '32.25 Minutes',
            'course_thumbnail_url':
                'https://srmcare.in/uploads/courses/6225f2ec001a190d048b2a860a41a2de.jpg',
            'is_completed': 'false',
            'action': 'watch_continue',
          },
        ],
      },
    });

    expect(learningPath.summary.totalCourses, 4);
    expect(learningPath.summary.progressPercentage, 0);
    expect(learningPath.summary.watchedTime, '55.3 Minutes');
    expect(learningPath.courses.map((course) => course.courseId), [
      'THC20260502153456',
      'THC20260411122508',
    ]);

    final first = learningPath.courses.first;
    expect(first.id, '4');
    expect(
      first.courseName,
      'Essential Clinical Nursing Skills for Patient Care',
    );
    expect(
      first.thumbnailUrl,
      'https://srmcare.in/uploads/courses/96076ef2d798f22c34ea61010a6a3a0e.jpg',
    );
    expect(first.progressPercentage, 60);
    expect(first.totalSeconds, 1382);
    expect(first.totalWatchTime, '23.03 Minutes');
    expect(first.isCompleted, isFalse);
    expect(first.action, 'watch_continue');
    expect(first.navigationCourseId, '4');
  });

  test(
    'learning path navigation prefers numeric id used by course detail API',
    () {
      final course = LearningPathCourse.fromJson({
        'id': 7,
        'course_id': 'THC20260502153456',
        'course_name': 'Essential Clinical Nursing Skills',
      });

      expect(course.navigationCourseId, '7');
    },
  );

  test('learning path uses safe defaults for missing and invalid values', () {
    final learningPath = LearningPathModel.fromJson({
      'summary': {
        'total_courses': 'bad-value',
        'progress_percentage': null,
        'watched_time': '',
      },
      'courses': [
        {
          'progress_percentage': 'bad-value',
          'total_seconds': null,
          'is_completed': 1,
        },
      ],
    });

    expect(learningPath.summary.totalCourses, 0);
    expect(learningPath.summary.progressPercentage, 0);
    expect(learningPath.summary.watchedTime, '0 Minutes');

    final course = learningPath.courses.single;
    expect(course.id, '');
    expect(course.courseId, '');
    expect(course.courseName, '');
    expect(course.thumbnailUrl, isNull);
    expect(course.status, '');
    expect(course.progressPercentage, 0);
    expect(course.totalSeconds, 0);
    expect(course.totalWatchTime, '0');
    expect(course.isCompleted, isTrue);
    expect(course.action, '');
  });
}
