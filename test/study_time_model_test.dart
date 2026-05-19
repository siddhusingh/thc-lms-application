import 'package:flutter_test/flutter_test.dart';
import 'package:thc_lms_mobile/models/study_time_model.dart';

void main() {
  test('study time parses nested API payload', () {
    final studyTime = StudyTimeModel.fromJson({
      'status': true,
      'message': 'Study time data.',
      'data': {
        'total_time': '0 hrs 55 mins',
        'average_time': '0 hrs 27 mins',
        'longest_session': '0 hrs 37 mins',
        'pie_chart': [
          {
            'id': '2',
            'title': 'Where can I get some?',
            'total_seconds': '1935',
            'percentage': '58.3',
            'formatted_time': '0 hrs 32 mins',
          },
          {
            'id': '4',
            'title': 'Essential Clinical Nursing Skills for Patient Care',
            'total_seconds': '1382',
            'percentage': '41.7',
            'formatted_time': '0 hrs 23 mins',
          },
        ],
        'graph': [
          {'watch_date': '01 May', 'hours': '0'},
          {'watch_date': '19 May', 'hours': '0.62'},
        ],
      },
    });

    expect(studyTime.totalTime, '0 hrs 55 mins');
    expect(studyTime.averageTime, '0 hrs 27 mins');
    expect(studyTime.longestSession, '0 hrs 37 mins');
    expect(studyTime.hasStudyTime, isTrue);
    expect(studyTime.pieChart.map((item) => item.id), ['2', '4']);

    final firstSlice = studyTime.pieChart.first;
    expect(firstSlice.title, 'Where can I get some?');
    expect(firstSlice.totalSeconds, 1935);
    expect(firstSlice.percentage, 58.3);
    expect(firstSlice.formattedTime, '0 hrs 32 mins');

    expect(studyTime.graph.first.watchDate, '01 May');
    expect(studyTime.graph.first.hours, 0);
    expect(studyTime.graph.last.watchDate, '19 May');
    expect(studyTime.graph.last.hours, 0.62);
  });

  test('study time keeps safe defaults for invalid and missing fields', () {
    final studyTime = StudyTimeModel.fromJson({
      'data': {
        'total_time': '',
        'pie_chart': [
          {
            'total_seconds': '120',
            'percentage': 'bad-value',
            'formatted_time': '',
          },
        ],
        'graph': [
          {'hours': 'bad-value'},
        ],
      },
    });

    expect(studyTime.totalTime, '0 hrs 0 mins');
    expect(studyTime.averageTime, '0 hrs 0 mins');
    expect(studyTime.longestSession, '0 hrs 0 mins');

    final slice = studyTime.pieChart.single;
    expect(slice.id, '');
    expect(slice.title, '');
    expect(slice.totalSeconds, 120);
    expect(slice.percentage, 0);
    expect(slice.formattedTime, '0 hrs 2 mins');

    final graphPoint = studyTime.graph.single;
    expect(graphPoint.watchDate, '');
    expect(graphPoint.hours, 0);
  });
}
