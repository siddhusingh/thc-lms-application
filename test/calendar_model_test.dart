import 'package:flutter_test/flutter_test.dart';
import 'package:thc_lms_mobile/models/calendar_model.dart';

void main() {
  test('calendar parses nested watching courses payload', () {
    final calendar = CalendarModel.fromJson({
      'status': true,
      'message': 'Calendar data.',
      'data': {
        'scheduled_courses': [],
        'watching_courses': [
          {
            'id': '2',
            'course_id': 'THC20260411122508',
            'thumbnail': '6225f2ec001a190d048b2a860a41a2de.jpg',
            'course_name': 'Where can I get some?',
            'start_date': '2026-05-18 12:44:54',
            'end_date': '2026-05-19 00:25:30',
            'total_videos': '3',
            'watched_videos': '2',
            'thumbnail_url':
                'https://srmcare.in/uploads/courses/6225f2ec001a190d048b2a860a41a2de.jpg',
          },
          {
            'id': '4',
            'course_id': 'THC20260502153456',
            'thumbnail': '96076ef2d798f22c34ea61010a6a3a0e.jpg',
            'course_name': 'Essential Clinical Nursing Skills for Patient Care',
            'start_date': '2026-05-19 00:13:09',
            'end_date': '2026-05-19 00:50:00',
            'total_videos': '4',
            'watched_videos': '3',
            'thumbnail_url':
                'https://srmcare.in/uploads/courses/96076ef2d798f22c34ea61010a6a3a0e.jpg',
          },
        ],
      },
    });

    expect(calendar.scheduledCourses, isEmpty);
    expect(calendar.watchingCourses, hasLength(2));
    expect(calendar.events.map((event) => event.courseId), [
      'THC20260411122508',
      'THC20260502153456',
    ]);

    final first = calendar.watchingCourses.first;
    expect(first.id, '2');
    expect(first.navigationCourseId, '2');
    expect(first.courseName, 'Where can I get some?');
    expect(first.type, CalendarCourseEventType.watching);
    expect(first.startDate, DateTime(2026, 5, 18, 12, 44, 54));
    expect(first.endDate, DateTime(2026, 5, 19, 0, 25, 30));
    expect(first.totalVideos, 3);
    expect(first.watchedVideos, 2);
    expect(
      first.thumbnailUrl,
      'https://srmcare.in/uploads/courses/6225f2ec001a190d048b2a860a41a2de.jpg',
    );
    expect(first.occursOn(DateTime(2026, 5, 18)), isTrue);
    expect(first.occursOn(DateTime(2026, 5, 19)), isFalse);
  });

  test('calendar parses scheduled courses and falls back safely', () {
    final calendar = CalendarModel.fromJson({
      'scheduled_courses': [
        {
          'id': '5',
          'course_id': 'THC20260519225324',
          'course_name': 'Infection Prevention & Control (IPC)',
          'status': 'Scheduled',
          'scheduled_at': '2026-05-30 10:00:00',
          'thumbnail': '0d140bdd3a1d523d207dc07552fb18bf.jpg',
          'thumbnail_url':
              'https://srmcare.in/uploads/courses/0d140bdd3a1d523d207dc07552fb18bf.jpg',
        },
        {
          'course_id': 'THC-SCHEDULED',
          'course_name': '',
          'thumbnail': 'scheduled.jpg',
          'start_date': 'not-a-date',
          'total_videos': 'bad-value',
          'watched_videos': null,
        },
      ],
    });

    final scheduled = calendar.scheduledCourses.first;
    expect(scheduled.id, '5');
    expect(scheduled.courseId, 'THC20260519225324');
    expect(scheduled.navigationCourseId, '5');
    expect(scheduled.courseName, 'Infection Prevention & Control (IPC)');
    expect(scheduled.type, CalendarCourseEventType.scheduled);
    expect(scheduled.startDate, DateTime(2026, 5, 30, 10));
    expect(
      scheduled.thumbnailUrl,
      'https://srmcare.in/uploads/courses/0d140bdd3a1d523d207dc07552fb18bf.jpg',
    );
    expect(scheduled.occursOn(DateTime(2026, 5, 30)), isTrue);

    final event = calendar.scheduledCourses.last;
    expect(event.id, '');
    expect(event.courseId, 'THC-SCHEDULED');
    expect(event.navigationCourseId, 'THC-SCHEDULED');
    expect(event.courseName, '');
    expect(event.type, CalendarCourseEventType.scheduled);
    expect(event.thumbnailUrl, 'scheduled.jpg');
    expect(event.startDate, isNull);
    expect(event.endDate, isNull);
    expect(event.totalVideos, 0);
    expect(event.watchedVideos, 0);
    expect(event.occursOn(DateTime(2026, 5, 19)), isFalse);
  });
}
