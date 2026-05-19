import 'package:flutter_test/flutter_test.dart';
import 'package:thc_lms_mobile/models/dashboard_model.dart';

void main() {
  test('dashboard parses student metric payload fields', () {
    final dashboard = DashboardModel.fromJson({
      'learning_time': '23',
      'learning_time_unit': 'Minutes',
      'completed_course': 0,
      'in_progress_course': '2',
      'total_available_course': '4',
    });

    expect(dashboard.enrolledCourses, 4);
    expect(dashboard.inProgressCourses, 2);
    expect(dashboard.completedCourses, 0);
    expect(dashboard.watchTimeMinutes, 23);
    expect(dashboard.learningTimeUnit, 'Minutes');
  });

  test(
    'dashboard metrics keep safe defaults for missing or invalid values',
    () {
      final dashboard = DashboardModel.fromJson({
        'learning_time': 'not-a-number',
        'learning_time_unit': '',
        'in_progress_course': null,
      });

      expect(dashboard.enrolledCourses, 0);
      expect(dashboard.inProgressCourses, 0);
      expect(dashboard.completedCourses, 0);
      expect(dashboard.watchTimeMinutes, 0);
      expect(dashboard.learningTimeUnit, 'Minutes');
    },
  );

  test('dashboard accepts plural in-progress field alias', () {
    final dashboard = DashboardModel.fromJson({'in_progress_courses': '3'});

    expect(dashboard.inProgressCourses, 3);
  });

  test('dashboard parses course progress payload', () {
    final dashboard = DashboardModel.fromJson({
      'progress': [
        {
          'id': '2',
          'course_id': 'THC20260411122508',
          'course_name': 'Where can I get some?',
          'course_thumbnail': 'thumb.jpg',
          'progress_percentage': '40.00',
        },
      ],
    });

    final progress = dashboard.progress.single;
    expect(progress.id, '2');
    expect(progress.courseId, 'THC20260411122508');
    expect(progress.courseName, 'Where can I get some?');
    expect(progress.courseThumbnail, 'thumb.jpg');
    expect(progress.progressPercentage, 40);
  });

  test('dashboard progress keeps safe defaults for incomplete items', () {
    final dashboard = DashboardModel.fromJson({
      'progress': [
        {'progress_percentage': 'not-a-number'},
      ],
    });

    final progress = dashboard.progress.single;
    expect(progress.id, '');
    expect(progress.courseId, '');
    expect(progress.courseName, '');
    expect(progress.courseThumbnail, isNull);
    expect(progress.progressPercentage, 0);
  });

  test('dashboard parses weekly study hours and pads missing days', () {
    final dashboard = DashboardModel.fromJson({
      'weekly_graph': ['0.6', 1, '2.5'],
    });

    expect(dashboard.weeklyStudyHours, [0.6, 1, 2.5, 0, 0, 0, 0]);
  });

  test('dashboard weekly study hours keep safe defaults', () {
    final dashboard = DashboardModel.fromJson({
      'weekly_graph': ['bad-value', null],
    });

    expect(dashboard.weeklyStudyHours, [0, 0, 0, 0, 0, 0, 0]);
  });

  test('dashboard parses weekly login counts and pads missing days', () {
    final dashboard = DashboardModel.fromJson({
      'weekly_login': ['5', 2, '1'],
    });

    expect(dashboard.weeklyLoginCounts, [5, 2, 1, 0, 0, 0, 0]);
  });

  test('dashboard weekly login counts keep safe defaults', () {
    final dashboard = DashboardModel.fromJson({
      'weekly_login': ['bad-value', null],
    });

    expect(dashboard.weeklyLoginCounts, [0, 0, 0, 0, 0, 0, 0]);
  });

  test('dashboard parses course completion series by weekday labels', () {
    final dashboard = DashboardModel.fromJson({
      'com_percent': [
        {
          'name': 'Where can I get some?',
          'data': [
            {'x': 'Tue', 'y': '10'},
            {'x': 'Mon', 'y': 40},
            {'x': 'Sun', 'y': '5.5'},
          ],
        },
      ],
    });

    final completion = dashboard.courseCompletionSeries.single;
    expect(completion.name, 'Where can I get some?');
    expect(completion.values, [40, 10, 0, 0, 0, 0, 5.5]);
  });

  test('dashboard course completion series keep safe defaults', () {
    final dashboard = DashboardModel.fromJson({
      'com_percent': [
        {
          'data': [
            {'x': 'Mon', 'y': 'bad-value'},
            {'x': 'Unknown', 'y': 90},
          ],
        },
      ],
    });

    final completion = dashboard.courseCompletionSeries.single;
    expect(completion.name, '');
    expect(completion.values, [0, 0, 0, 0, 0, 0, 0]);
  });
}
