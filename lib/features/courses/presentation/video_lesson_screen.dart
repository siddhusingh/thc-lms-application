import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../controllers/face_verification_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../features/auth/presentation/auth_provider.dart';
import '../../../features/face_references/presentation/face_reference_provider.dart';
import '../../../models/course_model.dart';
import '../../../models/course_player_model.dart';
import '../../../models/face_verification_result.dart';
import '../../../models/face_reference_status.dart';
import '../../../services/face_verification_service.dart';
import '../../../widgets/face_verification_widget.dart';
import 'course_provider.dart';
import 'video_verification_session.dart';

class VideoLessonScreen extends StatefulWidget {
  const VideoLessonScreen({required this.lesson, super.key});

  final LessonModel lesson;

  @override
  State<VideoLessonScreen> createState() => _VideoLessonScreenState();
}

class _VideoLessonScreenState extends State<VideoLessonScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  Timer? _syncTimer;
  Timer? _faceCheckTimer;
  FaceVerificationController? _faceVerificationController;
  final VideoVerificationSession _verificationSession =
      VideoVerificationSession();
  late LessonModel _lesson;
  bool _ready = false;
  bool _autoAdvancing = false;
  bool _faceCheckRunning = false;
  bool _verificationDialogVisible = false;
  bool _faceControllerReady = false;
  bool _lastKnownPlaying = false;
  bool _saveInFlight = false;
  bool _pendingForcedSave = false;
  bool _completionFlowRunning = false;
  bool _usingRestrictedControls = false;
  DateTime? _lastSaveAt;
  int? _lastSavedSecond;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lesson = widget.lesson;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initVideo());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_faceControllerReady) return;
    _faceControllerReady = true;
    _faceVerificationController = FaceVerificationController(
      FaceVerificationService(
        backendVerifier: (image, _) async {
          final matched = await context
              .read<FaceReferenceProvider>()
              .verifyLocal(image);
          return matched
              ? FaceVerificationResult.verified(
                  message: 'Face verified.',
                  similarity: 1,
                )
              : FaceVerificationResult.failed(
                  'Face does not match your registered images.',
                );
        },
      ),
    );
  }

  Future<void> _initVideo({
    bool preserveVerification = false,
    bool restartFromBeginning = false,
  }) async {
    _syncTimer?.cancel();
    stopPeriodicFaceCheck();
    unawaited(WakelockPlus.disable());
    _chewieController?.dispose();
    await _videoController?.dispose();
    if (!preserveVerification) {
      _verificationSession.resetForLesson();
    }
    _lastKnownPlaying = false;

    setState(() {
      _ready = false;
      _error = null;
    });

    try {
      final canOpenLesson = await _checkPreVideoAssessment();
      if (!canOpenLesson || !mounted) return;

      final faceSetupComplete = await _ensureFaceSetupComplete();
      if (!faceSetupComplete || !mounted) return;

      final progress = await _loadProgress();
      if (!mounted) return;

      final videoUrl = _lesson.videoUrl;
      if (videoUrl == null || videoUrl.isEmpty) {
        throw StateError('Missing video URL');
      }

      final videoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );
      _videoController = videoController;
      videoController.addListener(_handleVideoControllerChanged);
      await videoController.initialize();
      final resumeSeconds = restartFromBeginning
          ? 0
          : progress.exists
          ? progress.watchedSeconds
          : _lesson.progressSeconds;
      if (resumeSeconds > 0) {
        await videoController.seekTo(Duration(seconds: resumeSeconds));
      }
      _chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: false,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: _lesson.completed,
        draggableProgressBar: _lesson.completed,
        showOptions: _lesson.completed,
        customControls: _lesson.completed
            ? null
            : const _RestrictedVideoControls(),
      );
      _usingRestrictedControls = !_lesson.completed;
      _syncTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => unawaited(_saveProgress()),
      );
      if (mounted) {
        setState(() => _ready = true);
        if (preserveVerification && _verificationSession.canPlay) {
          resumeVideoAfterVerification();
        } else {
          await verifyBeforePlay();
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'Unable to play this lesson. Check your network and try again.',
      );
    }
  }

  Future<VideoProgressResponse> _loadProgress() async {
    final courseId = _courseId;
    if (courseId == null || _lesson.id.isEmpty) {
      return VideoProgressResponse.empty();
    }

    try {
      final progress = await context.read<CourseProvider>().fetchVideoProgress(
        courseId: courseId,
        videoId: _lesson.id,
      );
      if (mounted) {
        context.read<CourseProvider>().updateProgressFromFetch(
          _lesson.id,
          progress,
        );
        _lesson = _lesson.copyWith(
          completed: progress.isCompleted || _lesson.completed,
          progressSeconds: progress.watchedSeconds,
        );
      }
      return progress;
    } catch (_) {
      return VideoProgressResponse(
        watchedSeconds: _lesson.progressSeconds,
        isCompleted: _lesson.completed,
        exists: _lesson.progressSeconds > 0 || _lesson.completed,
      );
    }
  }

  Future<void> _saveProgress({
    bool force = false,
    bool showFeedback = false,
  }) async {
    final videoController = _videoController;
    final courseId = _courseId;
    if (courseId == null ||
        _lesson.id.isEmpty ||
        videoController == null ||
        !videoController.value.isInitialized) {
      return;
    }

    final position = videoController.value.position;
    final duration = videoController.value.duration > Duration.zero
        ? videoController.value.duration
        : Duration(seconds: _lesson.durationSeconds);
    final currentSecond = position.inSeconds;
    final now = DateTime.now();
    final savedRecently =
        _lastSaveAt != null &&
        now.difference(_lastSaveAt!) < const Duration(seconds: 10);
    if (_saveInFlight) {
      if (force) _pendingForcedSave = true;
      return;
    }
    if ((!force && !videoController.value.isPlaying) ||
        (!force && savedRecently) ||
        (!force && _lastSavedSecond == currentSecond)) {
      return;
    }

    _saveInFlight = true;
    if (mounted) {
      setState(() {
        _lesson = _lesson.copyWith(progressSeconds: currentSecond);
      });
    }
    try {
      final response = await context.read<CourseProvider>().saveVideoProgress(
        courseId: courseId,
        videoId: _lesson.id,
        position: position,
        duration: duration,
      );
      _lastSaveAt = now;
      _lastSavedSecond = currentSecond;
      if (!mounted) return;
      setState(() {
        _lesson = _lesson.copyWith(
          completed: response.isCompleted || _lesson.completed,
          progressSeconds: response.watchedSeconds > 0
              ? response.watchedSeconds
              : currentSecond,
        );
      });
      _refreshControlsIfLessonCompletionChanged();
      if (showFeedback) {
        showSuccessToast(context, message: 'Progress updated.');
      }
    } catch (_) {
      // Keep the local playback position and retry on the next save boundary.
      if (showFeedback && mounted) {
        showErrorToast(context, message: 'Unable to update progress.');
      }
    } finally {
      _saveInFlight = false;
      if (_pendingForcedSave) {
        _pendingForcedSave = false;
        unawaited(_saveProgress(force: true));
      }
    }
  }

  Future<bool> _checkPreVideoAssessment() async {
    final courseId = _courseId;
    if (courseId == null || _lesson.id.isEmpty) return true;
    try {
      final check = await context.read<CourseProvider>().checkVideoAssessment(
        courseId: courseId,
        videoId: _lesson.id,
        assessmentType: AssessmentType.pre,
      );
      if (!mounted || !check.hasIncompletePreVideoAssessment) return true;
      final assessmentId = check.preVideoAssessmentId;
      if (assessmentId == null || assessmentId.isEmpty) return true;
      _navigateToAssessment(assessmentId);
      return false;
    } catch (_) {
      return true;
    }
  }

  Future<bool> _checkPostVideoAssessment() async {
    final courseId = _courseId;
    if (courseId == null || _lesson.id.isEmpty) return false;
    try {
      final check = await context.read<CourseProvider>().checkVideoAssessment(
        courseId: courseId,
        videoId: _lesson.id,
        assessmentType: AssessmentType.post,
      );
      if (!mounted || !check.hasIncompletePostVideoAssessment) return false;
      final assessmentId = check.postVideoAssessmentId;
      if (assessmentId == null || assessmentId.isEmpty) return false;
      _navigateToAssessment(assessmentId);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _navigateToAssessment(String? assessmentId) {
    if (assessmentId != null && assessmentId.isNotEmpty) {
      final courseId = _courseId;
      final returnSuffix = courseId == null
          ? ''
          : '?return_to=${Uri.encodeComponent('/courses/$courseId')}';
      context.go(
        '/assessments/${Uri.encodeComponent(assessmentId)}$returnSuffix',
      );
    }
  }

  Future<void> verifyBeforePlay() async {
    final result = await _showFaceVerificationDialog(
      title: 'Verify to start video',
      message: 'Please verify your face before watching this lesson.',
      contextLabel: 'video_start',
    );
    if (!mounted) return;
    if (result?.isVerified == true) {
      resumeVideoAfterVerification();
    } else {
      pauseVideoForVerification(
        result?.message ?? 'Face verification is required to play this video.',
      );
    }
  }

  void startPeriodicFaceCheck() {
    _faceCheckTimer?.cancel();
    _faceCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final videoController = _videoController;
      if (videoController == null) return;
      if (_verificationSession.canRunPeriodicCheck(
        ready: _ready,
        playing: videoController.value.isPlaying,
        checkRunning: _faceCheckRunning,
      )) {
        unawaited(_runSilentFaceCheck());
      }
    });
  }

  void stopPeriodicFaceCheck() {
    _faceCheckTimer?.cancel();
    _faceCheckTimer = null;
  }

  Future<void> _runSilentFaceCheck() async {
    final controller = _faceVerificationController;
    final videoController = _videoController;
    if (controller == null ||
        videoController == null ||
        !videoController.value.isPlaying) {
      return;
    }

    _faceCheckRunning = true;
    try {
      final result = await controller.verify(context: 'video_periodic');
      if (!mounted || result.isVerified) return;
      pauseVideoForVerification(result.message);
    } finally {
      _faceCheckRunning = false;
    }
  }

  void pauseVideoForVerification(String message) {
    _verificationSession.requireReverification();
    stopPeriodicFaceCheck();
    _videoController?.pause();
    if (!_verificationDialogVisible) {
      unawaited(_showReverificationWarning(message));
    }
  }

  void resumeVideoAfterVerification() {
    _verificationSession.markVerified();
    _videoController?.play();
    if (_videoController?.value.isPlaying == true) {
      startPeriodicFaceCheck();
    }
  }

  Future<void> _showReverificationWarning(String message) async {
    _verificationDialogVisible = true;
    final result = await _showFaceVerificationDialog(
      title: 'Face verification needed',
      message: message,
      contextLabel: 'video_resume',
    );
    _verificationDialogVisible = false;
    if (!mounted) return;
    if (result?.isVerified == true) {
      resumeVideoAfterVerification();
    } else {
      pauseVideoForVerification(
        result?.message ?? 'Please verify again to continue watching.',
      );
    }
  }

  Future<FaceVerificationResult?> _showFaceVerificationDialog({
    required String title,
    required String message,
    required String contextLabel,
  }) {
    final controller = _faceVerificationController;
    if (controller == null) {
      return Future.value(
        FaceVerificationResult.failed('Face verification is not ready.'),
      );
    }

    return showDialog<FaceVerificationResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isLandscape =
            MediaQuery.orientationOf(dialogContext) == Orientation.landscape;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            Navigator.of(dialogContext).pop();
            if (mounted) context.go('/courses');
          },
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isLandscape ? 680 : 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: FaceVerificationWidget(
                    controller: controller,
                    contextLabel: contextLabel,
                    title: title,
                    message: message,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _ensureFaceSetupComplete() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      return false;
    }

    final faceReferences = context.read<FaceReferenceProvider>();
    while (mounted) {
      await faceReferences.prepare(userId);
      if (!mounted) return false;

      if (faceReferences.status.isReady) {
        return true;
      }

      if (faceReferences.status.phase == FaceReferencePhase.failed) {
        final action = await _showFaceSetupStatusDialog(
          title: 'Face setup unavailable',
          message:
              '${faceReferences.status.message} Please retry before starting this lesson.',
          primaryLabel: 'Retry',
          secondaryLabel: 'Back to courses',
        );
        if (!mounted) return false;
        if (action == _FaceSetupDialogAction.retry) {
          await faceReferences.retry();
          continue;
        }
        context.go('/courses');
        return false;
      }

      if (!faceReferences.status.isMissing) {
        await faceReferences.prepare(userId, force: true);
        continue;
      }

      _verificationSession.requireFaceSetup();
      final action = await _showFaceSetupStatusDialog(
        title: 'Complete face setup',
        message:
            faceReferences.status.message ??
            'Upload clear front, left, and right face images before watching course videos.',
        primaryLabel: 'Complete setup',
        secondaryLabel: 'Back to courses',
      );
      if (!mounted) return false;
      if (action == _FaceSetupDialogAction.completeSetup) {
        await context.push('/profile/face-images');
        await faceReferences.prepare(userId, force: true);
        continue;
      }
      context.go('/courses');
      return false;
    }
    return false;
  }

  Future<_FaceSetupDialogAction?> _showFaceSetupStatusDialog({
    required String title,
    required String message,
    required String primaryLabel,
    required String secondaryLabel,
  }) {
    return showDialog<_FaceSetupDialogAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FaceSetupRequiredDialog(
        title: title,
        message: message,
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
      ),
    );
  }

  void _handleVideoControllerChanged() {
    _handlePlaybackStateChanged();
    _handleVideoProgress();
  }

  void _handlePlaybackStateChanged() {
    final videoController = _videoController;
    if (videoController == null ||
        !videoController.value.isInitialized ||
        videoController.value.isPlaying == _lastKnownPlaying) {
      return;
    }

    _lastKnownPlaying = videoController.value.isPlaying;
    if (_lastKnownPlaying) {
      if (_verificationSession.canPlay) {
        unawaited(WakelockPlus.enable());
        startPeriodicFaceCheck();
      } else {
        pauseVideoForVerification(
          'Face verification is required to continue watching.',
        );
      }
    } else {
      unawaited(_saveProgress(force: true));
      unawaited(WakelockPlus.disable());
      stopPeriodicFaceCheck();
    }
  }

  void _handleVideoProgress() {
    final videoController = _videoController;
    if (_autoAdvancing ||
        _completionFlowRunning ||
        videoController == null ||
        !videoController.value.isInitialized) {
      return;
    }

    final duration = videoController.value.duration;
    final position = videoController.value.position;
    if (duration == Duration.zero) return;

    final remaining = duration - position;
    if (remaining > const Duration(milliseconds: 600)) return;

    unawaited(_completeCurrentLesson());
  }

  Future<void> _completeCurrentLesson() async {
    _completionFlowRunning = true;
    try {
      await _saveProgress(force: true);
      _markCurrentLessonCompletedLocally();
      final navigatedToAssessment = await _checkPostVideoAssessment();
      if (navigatedToAssessment || !mounted) return;
      final nextLesson = _nextVideoLesson();
      if (nextLesson == null) {
        await _checkPostCourseAssessmentIfCourseComplete();
        return;
      }
      await _advanceToNextLesson(nextLesson);
    } finally {
      _completionFlowRunning = false;
    }
  }

  Future<void> _advanceToNextLesson(LessonModel nextLesson) async {
    _autoAdvancing = true;
    try {
      if (!mounted) return;
      context.read<CourseProvider>().setCurrentVideoId(nextLesson.id);
      setState(() => _lesson = nextLesson);
      await _initVideo(preserveVerification: true);
    } finally {
      _autoAdvancing = false;
    }
  }

  LessonModel? _nextVideoLesson() {
    final course = context.read<CourseProvider>().selectedCourse;
    final lessons = _playlist(course)
        .where(
          (lesson) => lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty,
        )
        .toList();
    final currentIndex = lessons.indexWhere(_isCurrentLesson);
    if (currentIndex < 0 || currentIndex >= lessons.length - 1) return null;
    return lessons[currentIndex + 1];
  }

  Future<void> _selectLesson(LessonModel lesson) async {
    if (_isCurrentLesson(lesson)) return;
    if (lesson.videoUrl == null || lesson.videoUrl!.isEmpty) return;
    if (_isLessonLocked(lesson)) return;
    final preserveVerification = _canContinueWithoutReverification(lesson);
    await _saveProgress(force: true);
    if (!mounted) return;
    _autoAdvancing = false;
    stopPeriodicFaceCheck();
    context.read<CourseProvider>().setCurrentVideoId(lesson.id);
    setState(() => _lesson = lesson);
    await _initVideo(
      preserveVerification: preserveVerification,
      restartFromBeginning: lesson.completed,
    );
  }

  bool _isCurrentLesson(LessonModel lesson) {
    if (_lesson.id.isNotEmpty && lesson.id.isNotEmpty) {
      return _lesson.id == lesson.id;
    }
    return _lesson.videoUrl == lesson.videoUrl;
  }

  List<LessonModel> _playlist(CourseDetailModel? course) {
    final lessons = course?.modules.expand((module) => module.lessons).toList();
    if (lessons == null || lessons.isEmpty) return [_lesson];
    return lessons;
  }

  bool _isLessonLocked(LessonModel lesson) {
    final lessons = _playlist(context.read<CourseProvider>().selectedCourse);
    final index = lessons.indexWhere((item) => _sameLesson(item, lesson));
    return index > 0 && !lessons[index - 1].completed;
  }

  bool _canContinueWithoutReverification(LessonModel nextLesson) {
    if (!_verificationSession.canPlay || !_lesson.completed) return false;
    final lessons = _playlist(context.read<CourseProvider>().selectedCourse);
    final currentIndex = lessons.indexWhere(_isCurrentLesson);
    final nextIndex = lessons.indexWhere(
      (lesson) => _sameLesson(lesson, nextLesson),
    );
    return currentIndex >= 0 && nextIndex == currentIndex + 1;
  }

  bool _sameLesson(LessonModel first, LessonModel second) {
    if (first.id.isNotEmpty && second.id.isNotEmpty) {
      return first.id == second.id;
    }
    return first.videoUrl == second.videoUrl;
  }

  String? get _courseId {
    final courseId = context.read<CourseProvider>().selectedCourse?.id;
    if (courseId == null || courseId.isEmpty) return null;
    return courseId;
  }

  void _markCurrentLessonCompletedLocally() {
    final videoController = _videoController;
    final watchedSeconds = videoController?.value.position.inSeconds ?? 0;
    context.read<CourseProvider>().markLessonCompletedLocally(
      _lesson.id,
      watchedSeconds: watchedSeconds,
    );
    if (!mounted) return;
    setState(() {
      _lesson = _lesson.copyWith(
        completed: true,
        progressSeconds: watchedSeconds,
      );
    });
    _refreshControlsIfLessonCompletionChanged();
  }

  void _refreshControlsIfLessonCompletionChanged() {
    final videoController = _videoController;
    if (!_usingRestrictedControls ||
        !_lesson.completed ||
        videoController == null ||
        !videoController.value.isInitialized) {
      return;
    }

    final previousController = _chewieController;
    _chewieController = ChewieController(
      videoPlayerController: videoController,
      autoPlay: false,
      allowFullScreen: true,
      allowPlaybackSpeedChanging: true,
      draggableProgressBar: true,
      showOptions: true,
    );
    _usingRestrictedControls = false;
    previousController?.dispose();
    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> _checkPostCourseAssessmentIfCourseComplete() async {
    final courseId = _courseId;
    if (courseId == null || !_allVideoLessonsCompleted()) return false;
    try {
      final check = await context.read<CourseProvider>().checkCourseAssessment(
        courseId,
        AssessmentType.post,
      );
      if (!mounted || !check.hasIncompletePostCourseAssessment) return false;
      final assessmentId = check.postCourseAssessmentId;
      if (assessmentId == null || assessmentId.isEmpty) return false;
      _navigateToAssessment(assessmentId);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _allVideoLessonsCompleted() {
    final lessons = _playlist(
      context.read<CourseProvider>().selectedCourse,
    ).where((lesson) => lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty);
    return lessons.isNotEmpty && lessons.every((lesson) => lesson.completed);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(_saveProgress(force: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    stopPeriodicFaceCheck();
    unawaited(WakelockPlus.disable());
    if (_ready) unawaited(_saveProgress(force: true));
    _chewieController?.dispose();
    _videoController?.dispose();
    _faceVerificationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final course = provider.selectedCourse;
    final lessons = _playlist(course);
    final currentIndex = lessons.indexWhere(_isCurrentLesson);
    final displayIndex = currentIndex >= 0 ? currentIndex + 1 : 1;
    final total = lessons.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _VideoStage(
              ready: _ready,
              error: _error,
              chewieController: _chewieController,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/courses');
                }
              },
            ),
            Expanded(
              child: _PlaylistPanel(
                courseTitle: course?.title ?? _lesson.title,
                lesson: _lesson,
                lessons: lessons,
                currentNumber: displayIndex,
                total: total,
                onClose: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/courses');
                  }
                },
                onMarkComplete: _lesson.id.isEmpty
                    ? null
                    : () => unawaited(
                        _saveProgress(force: true, showFeedback: true),
                      ),
                onSelectLesson: (lesson) => unawaited(_selectLesson(lesson)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _FaceSetupDialogAction { completeSetup, retry, backToCourses }

class FaceSetupRequiredDialog extends StatelessWidget {
  const FaceSetupRequiredDialog({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
    super.key,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;

  @override
  Widget build(BuildContext context) {
    final isRetry = primaryLabel == 'Retry';
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_FaceSetupDialogAction.backToCourses),
            child: Text(secondaryLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              isRetry
                  ? _FaceSetupDialogAction.retry
                  : _FaceSetupDialogAction.completeSetup,
            ),
            child: Text(primaryLabel),
          ),
        ],
      ),
    );
  }
}

class _VideoStage extends StatelessWidget {
  const _VideoStage({
    required this.ready,
    required this.error,
    required this.chewieController,
    required this.onBack,
  });

  final bool ready;
  final String? error;
  final ChewieController? chewieController;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black,
              child: error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  : !ready
                  ? const Center(child: CircularProgressIndicator())
                  : Chewie(controller: chewieController!),
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: IconButton.filledTonal(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistPanel extends StatelessWidget {
  const _PlaylistPanel({
    required this.courseTitle,
    required this.lesson,
    required this.lessons,
    required this.currentNumber,
    required this.total,
    required this.onClose,
    required this.onMarkComplete,
    required this.onSelectLesson,
  });

  final String courseTitle;
  final LessonModel lesson;
  final List<LessonModel> lessons;
  final int currentNumber;
  final int total;
  final VoidCallback onClose;
  final VoidCallback? onMarkComplete;
  final ValueChanged<LessonModel> onSelectLesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border.all(color: AppTheme.mutedText.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${lesson.title} - $currentNumber / $total',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Replay',
                  onPressed: () => onSelectLesson(lesson),
                  icon: const Icon(Icons.replay_rounded),
                ),
                IconButton(
                  tooltip: 'Save progress',
                  onPressed: onMarkComplete,
                  icon: const Icon(Icons.cloud_upload_outlined),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'More',
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final item = lessons[index];
                final selected = item.id.isNotEmpty && lesson.id.isNotEmpty
                    ? item.id == lesson.id
                    : item.videoUrl == lesson.videoUrl;
                final locked = index > 0 && !lessons[index - 1].completed;
                return _PlaylistLessonTile(
                  lesson: item,
                  index: index,
                  selected: selected,
                  locked: locked,
                  onTap: locked ? null : () => onSelectLesson(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistLessonTile extends StatelessWidget {
  const _PlaylistLessonTile({
    required this.lesson,
    required this.index,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final LessonModel lesson;
  final int index;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.primary.withValues(alpha: 0.10) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: selected
                    ? Icon(
                        Icons.play_arrow_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : Text('${index + 1}', textAlign: TextAlign.center),
              ),
              const SizedBox(width: 8),
              _LessonThumbnail(
                durationSeconds: lesson.durationSeconds,
                thumbnailUrl: lesson.thumbnailUrl,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title.isEmpty ? 'Untitled lesson' : lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : AppTheme.textDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lesson.type.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (lesson.completed)
                Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                )
              else if (locked)
                const Icon(
                  Icons.lock_outline_rounded,
                  color: AppTheme.mutedText,
                )
              else
                IconButton(
                  tooltip: 'More',
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestrictedVideoControls extends StatefulWidget {
  const _RestrictedVideoControls();

  @override
  State<_RestrictedVideoControls> createState() =>
      _RestrictedVideoControlsState();
}

class _RestrictedVideoControlsState extends State<_RestrictedVideoControls> {
  ChewieController? _chewieController;
  VideoPlayerController? _videoController;
  Timer? _hidePlayPauseTimer;
  bool _showPlayPause = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextChewieController = ChewieController.of(context);
    if (nextChewieController == _chewieController) return;

    _videoController?.removeListener(_refresh);
    _chewieController = nextChewieController;
    _videoController = nextChewieController.videoPlayerController;
    _videoController?.addListener(_refresh);
  }

  @override
  void dispose() {
    _hidePlayPauseTimer?.cancel();
    _videoController?.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    final isPlaying = _videoController?.value.isPlaying == true;
    if (!isPlaying) {
      _hidePlayPauseTimer?.cancel();
      _hidePlayPauseTimer = null;
      _showPlayPause = true;
    } else if (_showPlayPause && _hidePlayPauseTimer == null) {
      _showControlsTemporarily();
      return;
    }
    setState(() {});
  }

  Future<void> _togglePlayback() async {
    final videoController = _videoController;
    if (videoController == null) return;
    if (videoController.value.isPlaying) {
      await videoController.pause();
      return;
    }
    await videoController.play();
    _showControlsTemporarily();
  }

  Future<void> _rewindTenSeconds() async {
    final videoController = _videoController;
    if (videoController == null) return;

    final currentPosition = videoController.value.position;
    final targetPosition = currentPosition - const Duration(seconds: 10);
    await videoController.seekTo(
      targetPosition < Duration.zero ? Duration.zero : targetPosition,
    );
    _showControlsTemporarily();
  }

  void _showControlsTemporarily() {
    _hidePlayPauseTimer?.cancel();
    if (mounted) {
      setState(() => _showPlayPause = true);
    }
    if (_videoController?.value.isPlaying != true) return;
    _hidePlayPauseTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _videoController?.value.isPlaying == true) {
        _hidePlayPauseTimer = null;
        setState(() => _showPlayPause = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chewieController = _chewieController;
    final videoController = _videoController;
    if (chewieController == null || videoController == null) {
      return const SizedBox.expand();
    }

    final value = videoController.value;
    final duration = value.duration;
    final progress = duration > Duration.zero
        ? value.position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _showControlsTemporarily,
            child: Center(
              child: AnimatedOpacity(
                opacity: _showPlayPause ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: !_showPlayPause,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Rewind 10 seconds',
                        onPressed: _rewindTenSeconds,
                        icon: const Icon(Icons.replay_10_rounded),
                      ),
                      const SizedBox(width: 16),
                      IconButton.filled(
                        tooltip: value.isPlaying ? 'Pause' : 'Play',
                        onPressed: _togglePlayback,
                        icon: Icon(
                          value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: LinearProgressIndicator(
            minHeight: 4,
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withValues(alpha: 0.28),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: IconButton(
            tooltip: chewieController.isFullScreen
                ? 'Exit full screen'
                : 'Full screen',
            onPressed: chewieController.toggleFullScreen,
            icon: Icon(
              chewieController.isFullScreen
                  ? Icons.fullscreen_exit_rounded
                  : Icons.fullscreen_rounded,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _LessonThumbnail extends StatelessWidget {
  const _LessonThumbnail({
    required this.durationSeconds,
    required this.thumbnailUrl,
  });

  final int durationSeconds;
  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 92,
            height: 52,
            child: thumbnailUrl == null || thumbnailUrl!.isEmpty
                ? _ThumbnailFallback()
                : CachedNetworkImage(
                    imageUrl: thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const _ThumbnailFallback(),
                    errorWidget: (context, url, error) =>
                        const _ThumbnailFallback(),
                  ),
          ),
          const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
          if (durationSeconds > 0)
            Positioned(
              right: 4,
              bottom: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  child: Text(
                    _formatDuration(durationSeconds),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: AppTheme.accent.withValues(alpha: 0.92));
  }
}
