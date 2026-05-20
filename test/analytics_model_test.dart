import 'package:flutter_test/flutter_test.dart';
import 'package:thc_lms_mobile/models/analytics_model.dart';

void main() {
  test('analytics parses nested student payload', () {
    final analytics = AnalyticsModel.fromJson({
      'status': true,
      'message': 'Analytics data.',
      'data': {
        'start_date': '2026-05-15',
        'end_date': '2026-05-20',
        'study_time': '0 Hrs. 55Min',
        'active_days': '6',
        'login_sessions': '42',
        'completed_courses': 0,
        'assessments': 3,
        'study_time_graph': [
          {'watch_date': '18 May', 'hours': '0.3'},
          {'watch_date': '19 May', 'hours': '0.37'},
        ],
        'time_spent_courses': [
          {
            'id': '2',
            'title': 'Where can I get some?',
            'total_seconds': '1935',
            'percentage': '58.1',
            'formatted_time': '0 hrs 32 mins',
          },
        ],
        'assessments_graph': [
          {
            'title': 'Pre Video Assess',
            'assessment_type': 'pre',
            'last_completed_at': '2026-05-17 23:23:32',
            'time_taken': '0 mins',
            'total_marks': '20',
            'obtained_marks': '4',
            'percentage': '20.00',
          },
        ],
        'login_sessions_graph': [
          {'login_date': '20 May 2026', 'total_logins': '3'},
        ],
      },
    });

    expect(analytics.startDate, '2026-05-15');
    expect(analytics.endDate, '2026-05-20');
    expect(analytics.studyTime, '0 Hrs. 55Min');
    expect(analytics.activeDays, 6);
    expect(analytics.loginSessions, 42);
    expect(analytics.completedCourses, 0);
    expect(analytics.assessments, 3);
    expect(analytics.hasChartData, isTrue);

    expect(analytics.studyTimeGraph.first.watchDate, '18 May');
    expect(analytics.studyTimeGraph.first.hours, 0.3);

    final course = analytics.timeSpentCourses.single;
    expect(course.id, '2');
    expect(course.displayTitle, 'Where can I get some?');
    expect(course.totalSeconds, 1935);
    expect(course.percentage, 58.1);
    expect(course.formattedTime, '0 hrs 32 mins');

    final assessment = analytics.assessmentsGraph.single;
    expect(assessment.displayTitle, 'Pre Video Assess');
    expect(assessment.displayAssessmentType, 'Pre');
    expect(assessment.lastCompletedAt, DateTime(2026, 5, 17, 23, 23, 32));
    expect(assessment.scoreLabel, '4/20');
    expect(assessment.percentage, 20);

    final login = analytics.loginSessionsGraph.single;
    expect(login.loginDate, '20 May 2026');
    expect(login.loginDateTime, DateTime(2026, 5, 20));
    expect(login.totalLogins, 3);
  });

  test('analytics uses graph fallback and safe defaults', () {
    final analytics = AnalyticsModel.fromJson({
      'data': {
        'active_days': 'bad-value',
        'graph': [
          {'watch_date': '15 May', 'hours': 'bad-value'},
        ],
        'time_spent_courses': [
          {'total_seconds': '120', 'formatted_time': ''},
        ],
        'login_sessions_graph': [
          {'login_date': 'not-a-date', 'total_logins': 'bad-value'},
        ],
      },
    });

    expect(analytics.studyTime, '0 Hrs. 0Min');
    expect(analytics.activeDays, 0);
    expect(analytics.studyTimeGraph.single.watchDate, '15 May');
    expect(analytics.studyTimeGraph.single.hours, 0);
    expect(analytics.timeSpentCourses.single.formattedTime, '0 hrs 2 mins');
    expect(analytics.loginSessionsGraph.single.loginDateTime, isNull);
    expect(analytics.loginSessionsGraph.single.totalLogins, 0);
  });
}
