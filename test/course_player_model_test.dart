import 'package:flutter_test/flutter_test.dart';
import 'package:thc_lms_mobile/models/course_player_model.dart';

void main() {
  test('playlist preserves API order and parses numeric strings', () {
    final playlist = CoursePlaylistResponse.fromJson({
      'data': {
        'current_video_id': 'video-2',
        'videos': [
          {
            'video_id': 'video-1',
            'video_title': 'Intro',
            'duration_seconds': '30',
            'watched_seconds': '12',
            'thumbnail_url': 'https://example.test/thumb.jpg',
          },
          {
            'video_id': 'video-2',
            'video_title': 'Next',
            'duration_seconds': 45.8,
            'is_completed': 'true',
          },
        ],
      },
    });

    expect(playlist.currentVideoId, 'video-2');
    expect(playlist.videos.map((video) => video.id), ['video-1', 'video-2']);
    expect(playlist.videos.first.watchedSeconds, 12);
    expect(
      playlist.videos.first.thumbnailUrl,
      'https://example.test/thumb.jpg',
    );
    expect(playlist.videos.last.durationSeconds, 45);
    expect(playlist.videos.last.isCompleted, isTrue);
  });

  test('playlist reads nested current video and nested progress state', () {
    final playlist = CoursePlaylistResponse.fromJson({
      'data': {
        'course': {'current_video_id': 'video-2'},
        'videos': [
          {
            'video_id': 'video-2',
            'video_title': 'Resume here',
            'progress': {'watched_seconds': '61', 'is_completed': 'false'},
          },
        ],
      },
    });

    expect(playlist.currentVideoId, 'video-2');
    expect(playlist.videos.single.watchedSeconds, 61);
    expect(playlist.videos.single.isCompleted, isFalse);
  });

  test('playlist reads watched duration from API payload', () {
    final playlist = CoursePlaylistResponse.fromJson({
      'data': {
        'videos': [
          {'video_id': 'video-1', 'watched_duration': '74'},
        ],
      },
    });

    expect(playlist.videos.single.watchedSeconds, 74);
  });

  test('progress safely handles missing and string fields', () {
    final empty = VideoProgressResponse.fromJson({});
    final saved = VideoProgressResponse.fromJson({
      'data': {'watched_seconds': '91.4', 'is_completed': 1},
    });

    expect(empty.exists, isFalse);
    expect(empty.watchedSeconds, 0);
    expect(saved.exists, isTrue);
    expect(saved.watchedSeconds, 91);
    expect(saved.isCompleted, isTrue);
  });

  test('assessment checks read status fields without redirect URLs', () {
    final videoCheck = VideoAssessmentCheckResponse.fromJson({
      'data': {
        'pre_video_assessment_status': 'pending',
        'pre_video_assessment_id': 'pre-video-1',
        'post_video_assessment_status': 'completed',
      },
    });
    final courseCheck = CourseAssessmentCheckResponse.fromJson({
      'pre_course_assessment_completed': false,
      'pre_course_assessment_id': 'pre-course-1',
      'post_course_assessment_status': 'completed',
    });

    expect(videoCheck.hasIncompletePreVideoAssessment, isTrue);
    expect(videoCheck.preVideoAssessmentId, 'pre-video-1');
    expect(videoCheck.hasIncompletePostVideoAssessment, isFalse);
    expect(courseCheck.hasIncompletePreCourseAssessment, isTrue);
    expect(courseCheck.preCourseAssessmentId, 'pre-course-1');
    expect(courseCheck.hasIncompletePostCourseAssessment, isFalse);
  });

  test('assessment checks read generic typed response fields', () {
    final videoCheck = VideoAssessmentCheckResponse.fromJson({
      'data': {'assessment_status': 'pending', 'assessment_id': 'video-pre-1'},
    });
    final courseCheck = CourseAssessmentCheckResponse.fromJson({
      'assessment': {'status': 'completed', 'id': 'course-post-1'},
    });

    expect(videoCheck.hasIncompletePreVideoAssessment, isTrue);
    expect(videoCheck.preVideoAssessmentId, 'video-pre-1');
    expect(courseCheck.hasIncompletePostCourseAssessment, isFalse);
    expect(courseCheck.postCourseAssessmentId, 'course-post-1');
  });
}
