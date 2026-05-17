import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thc_lms_mobile/features/courses/presentation/video_lesson_screen.dart';

void main() {
  testWidgets('face setup dialog blocks lesson start with clear actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FaceSetupRequiredDialog(
            title: 'Complete face setup',
            message:
                'Upload clear front, left, and right face images before watching course videos.',
            primaryLabel: 'Complete setup',
            secondaryLabel: 'Back to courses',
          ),
        ),
      ),
    );

    expect(find.text('Complete face setup'), findsOneWidget);
    expect(find.textContaining('front, left, and right'), findsOneWidget);
    expect(find.text('Complete setup'), findsOneWidget);
    expect(find.text('Back to courses'), findsOneWidget);
  });
}
