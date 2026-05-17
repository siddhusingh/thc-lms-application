import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../controllers/face_verification_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../features/auth/presentation/auth_provider.dart';
import '../../../features/courses/presentation/course_provider.dart';
import '../../../features/face_references/presentation/face_reference_provider.dart';
import '../../../models/assessment_model.dart';
import '../../../models/face_reference_status.dart';
import '../../../models/face_verification_result.dart';
import '../../../services/face_verification_service.dart';
import '../../../widgets/face_verification_widget.dart';
import 'assessment_provider.dart';

class AssessmentAttemptScreen extends StatefulWidget {
  const AssessmentAttemptScreen({
    required this.assessmentId,
    this.returnTo,
    super.key,
  });

  final String assessmentId;
  final String? returnTo;

  @override
  State<AssessmentAttemptScreen> createState() =>
      _AssessmentAttemptScreenState();
}

class _AssessmentAttemptScreenState extends State<AssessmentAttemptScreen>
    with WidgetsBindingObserver {
  final Map<String, String> _answers = {};
  Timer? _timer;
  Timer? _faceCheckTimer;
  FaceVerificationController? _faceVerificationController;
  bool _hasStarted = false;
  bool _faceControllerReady = false;
  bool _faceVerified = false;
  bool _faceCheckRunning = false;
  bool _verificationDialogVisible = false;
  bool _appInForeground = true;
  int _elapsedSeconds = 0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  @override
  void didUpdateWidget(covariant AssessmentAttemptScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assessmentId == widget.assessmentId) return;
    _timer?.cancel();
    _stopPeriodicFaceCheck();
    _answers.clear();
    _hasStarted = false;
    _faceVerified = false;
    _elapsedSeconds = 0;
    _currentIndex = 0;
  }

  Future<void> _start() async {
    final provider = context.read<AssessmentProvider>();
    final ok = await provider.start(widget.assessmentId);
    if (!mounted || !ok) return;
    setState(() => _hasStarted = true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });

    final faceSetupComplete = await _ensureFaceSetupComplete();
    if (!mounted || !faceSetupComplete) return;
    await _verifyBeforeAssessment();
  }

  Future<void> _submit() async {
    final attempt = context.read<AssessmentProvider>().attempt;
    if (attempt == null) return;
    final unansweredCount = attempt.questions
        .where((question) => !_answers.containsKey(question.id))
        .length;
    if (unansweredCount > 0) {
      _showAnswerRequiredMessage(
        unansweredCount == 1
            ? 'Please answer the remaining question before submitting.'
            : 'Please answer all remaining questions before submitting.',
      );
      return;
    }

    final ok = await context.read<AssessmentProvider>().submit(
      widget.assessmentId,
      _answers,
    );
    if (!mounted) return;
    if (!ok) {
      showErrorToast(
        context,
        message:
            context.read<AssessmentProvider>().error ??
            'Unable to submit assessment.',
      );
      return;
    }
    final returnTo = widget.returnTo;
    if (returnTo != null && returnTo.isNotEmpty) {
      context.go(_withAssessmentCompletedFlag(returnTo));
      return;
    }
    final activeCourseId = context.read<CourseProvider>().selectedCourse?.id;
    if (activeCourseId != null && activeCourseId.isNotEmpty) {
      context.go('/courses/$activeCourseId?assessment_completed=true');
      return;
    }
    context.go('/assessments');
  }

  String _withAssessmentCompletedFlag(String path) {
    final uri = Uri.parse(path);
    return uri
        .replace(
          queryParameters: {
            ...uri.queryParameters,
            'assessment_completed': 'true',
          },
        )
        .toString();
  }

  Future<void> _selectAnswer(QuestionModel question, String answer) async {
    final previousAnswer = _answers[question.id];
    setState(() => _answers[question.id] = answer);

    final saved = await context.read<AssessmentProvider>().saveAnswer(
      questionId: question.id,
      answer: answer,
    );
    if (!mounted || saved) return;

    setState(() {
      if (previousAnswer == null) {
        _answers.remove(question.id);
      } else {
        _answers[question.id] = previousAnswer;
      }
    });
    final message = context.read<AssessmentProvider>().error;
    showErrorToast(context, message: message ?? 'Unable to save answer.');
  }

  void _goToPrevious() {
    if (_currentIndex == 0) return;
    setState(() => _currentIndex--);
  }

  Future<void> _goToNext(AssessmentAttemptModel attempt) async {
    final currentQuestion = attempt.questions[_currentIndex];
    if (!_answers.containsKey(currentQuestion.id)) {
      showErrorToast(context, message: 'Select an option to continue..');
      return;
    }

    if (_currentIndex < attempt.questions.length - 1) {
      setState(() => _currentIndex++);
      return;
    }
    if (attempt.isLast) return;

    final loaded = await context.read<AssessmentProvider>().loadNextQuestion(
      widget.assessmentId,
    );
    if (!mounted || !loaded) return;
    setState(() => _currentIndex++);
  }

  void _showAnswerRequiredMessage(String message) {
    showErrorToast(context, message: message);
  }

  Future<void> _verifyBeforeAssessment() async {
    final result = await _showFaceVerificationDialog(
      title: 'Verify to start assessment',
      message: 'Please verify your face before answering this assessment.',
      contextLabel: 'assessment_start',
    );
    if (!mounted) return;
    if (result?.isVerified == true) {
      _resumeAssessmentAfterVerification();
    } else {
      _pauseAssessmentForVerification(
        result?.message ?? 'Face verification is required to continue.',
      );
    }
  }

  void _startPeriodicFaceCheck() {
    _faceCheckTimer?.cancel();
    _faceCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_hasStarted &&
          _faceVerified &&
          _appInForeground &&
          !_faceCheckRunning) {
        unawaited(_runSilentFaceCheck());
      }
    });
  }

  void _stopPeriodicFaceCheck() {
    _faceCheckTimer?.cancel();
    _faceCheckTimer = null;
  }

  Future<void> _runSilentFaceCheck() async {
    final controller = _faceVerificationController;
    if (controller == null || !_faceVerified) return;

    _faceCheckRunning = true;
    try {
      final result = await controller.verify(context: 'assessment_periodic');
      if (!mounted || result.isVerified) return;
      _pauseAssessmentForVerification(result.message);
    } finally {
      _faceCheckRunning = false;
    }
  }

  void _pauseAssessmentForVerification(String message) {
    _faceVerified = false;
    _stopPeriodicFaceCheck();
    if (!_verificationDialogVisible) {
      unawaited(_showReverificationWarning(message));
    }
  }

  void _resumeAssessmentAfterVerification() {
    _faceVerified = true;
    _startPeriodicFaceCheck();
  }

  Future<void> _showReverificationWarning(String message) async {
    _verificationDialogVisible = true;
    final result = await _showFaceVerificationDialog(
      title: 'Face verification needed',
      message: message,
      contextLabel: 'assessment_resume',
    );
    _verificationDialogVisible = false;
    if (!mounted) return;
    if (result?.isVerified == true) {
      _resumeAssessmentAfterVerification();
    } else {
      _pauseAssessmentForVerification(
        result?.message ?? 'Please verify again to continue.',
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
    if (userId == null || userId.isEmpty) return false;

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
              '${faceReferences.status.message} Please retry before starting this assessment.',
          primaryLabel: 'Retry',
          secondaryLabel: 'Back to courses',
        );
        if (!mounted) return false;
        if (action == _AssessmentFaceSetupAction.retry) {
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

      final action = await _showFaceSetupStatusDialog(
        title: 'Complete face setup',
        message:
            faceReferences.status.message ??
            'Upload clear front, left, and right face images before taking assessments.',
        primaryLabel: 'Complete setup',
        secondaryLabel: 'Back to courses',
      );
      if (!mounted) return false;
      if (action == _AssessmentFaceSetupAction.completeSetup) {
        await context.push('/profile/face-images');
        await faceReferences.prepare(userId, force: true);
        continue;
      }
      context.go('/courses');
      return false;
    }
    return false;
  }

  Future<_AssessmentFaceSetupAction?> _showFaceSetupStatusDialog({
    required String title,
    required String message,
    required String primaryLabel,
    required String secondaryLabel,
  }) {
    return showDialog<_AssessmentFaceSetupAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AssessmentFaceSetupRequiredDialog(
        title: title,
        message: message,
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
      ),
    );
  }

  void _handleBack() {
    context.go('/courses');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _stopPeriodicFaceCheck();
    _faceVerificationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    final attempt = provider.attempt;

    if (!_hasStarted) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _handleBack();
        },
        child: _AssessmentStartScreen(
          loading: provider.loading,
          error: provider.error,
          isCourseGate: widget.returnTo != null && widget.returnTo!.isNotEmpty,
          onStart: _start,
        ),
      );
    }

    if (provider.loading && attempt == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (attempt == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(provider.error ?? 'Unable to start assessment.'),
          ),
        ),
      );
    }

    if (attempt.questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No questions are available.')),
      );
    }

    final loadedQuestionCount = attempt.questions.length;
    final questionCount = attempt.totalQuestions > 0
        ? attempt.totalQuestions
        : loadedQuestionCount;
    final safeIndex = _currentIndex.clamp(0, loadedQuestionCount - 1);
    final question = attempt.questions[safeIndex];
    final atLastLoadedQuestion = safeIndex >= loadedQuestionCount - 1;
    final answeredCount = _answers.length;
    final answeredProgress = questionCount == 0
        ? 0.0
        : answeredCount / questionCount;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              children: [
              _AssessmentHeader(elapsedSeconds: _elapsedSeconds),
              const SizedBox(height: 24),
              _AssessmentProgress(
                answeredCount: answeredCount,
                questionCount: questionCount,
                progress: answeredProgress,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${safeIndex + 1} of $questionCount',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.question,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.separated(
                        itemCount: question.options.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final option = question.options[index];
                          final selected = _answers[question.id] == option.id;
                          return _AnswerOptionTile(
                            label: _optionLabel(index),
                            option: option,
                            selected: selected,
                            onTap: () => _selectAnswer(question, option.id),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: safeIndex == 0 ? null : _goToPrevious,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accent,
                        side: BorderSide(
                          color: safeIndex == 0
                              ? AppTheme.mutedText.withValues(alpha: 0.20)
                              : AppTheme.accent.withValues(alpha: 0.55),
                        ),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Prev'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          provider.loading ||
                              (attempt.isLast && atLastLoadedQuestion)
                          ? null
                          : () => _goToNext(attempt),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: provider.loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Next'),
                    ),
                  ),
                ],
              ),
              if (attempt.isLast && atLastLoadedQuestion) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: provider.loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: provider.loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit'),
                  ),
                ),
              ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _optionLabel(int index) {
    return String.fromCharCode(65 + index);
  }
}

class _AssessmentStartScreen extends StatelessWidget {
  const _AssessmentStartScreen({
    required this.loading,
    required this.error,
    required this.isCourseGate,
    required this.onStart,
  });

  final bool loading;
  final String? error;
  final bool isCourseGate;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final bodyText = isCourseGate
        ? 'Complete this assessment to unlock the lesson. Once started, '
              'please finish it without leaving the app.'
        : 'Please review the instructions before you begin. Once started, '
              'complete the assessment in one sitting.';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Complete Your Assessment.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    bodyText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.mutedText,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '(Do not refresh, reload, or close the app during the '
                    'assessment.)',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (error != null && error!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppTheme.danger),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: loading ? null : onStart,
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Yes! Start Now.'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssessmentHeader extends StatelessWidget {
  const _AssessmentHeader({required this.elapsedSeconds});

  final int elapsedSeconds;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time taken',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppTheme.mutedText),
            ),
            Text(
              _formatDuration(elapsedSeconds),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final remainingSeconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$hours : $minutes : $remainingSeconds';
  }
}

class _AssessmentProgress extends StatelessWidget {
  const _AssessmentProgress({
    required this.answeredCount,
    required this.questionCount,
    required this.progress,
  });

  final int answeredCount;
  final int questionCount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 9,
              strokeCap: StrokeCap.round,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Text(
            '$answeredCount/$questionCount',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _AnswerOptionTile extends StatelessWidget {
  const _AnswerOptionTile({
    required this.label,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final AnswerOptionModel option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: selected ? primary.withValues(alpha: 0.10) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected
              ? primary
              : AppTheme.mutedText.withValues(alpha: 0.24),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  '$label.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: selected ? primary : AppTheme.mutedText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  option.text,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AssessmentFaceSetupAction { completeSetup, retry, backToCourses }

class _AssessmentFaceSetupRequiredDialog extends StatelessWidget {
  const _AssessmentFaceSetupRequiredDialog({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
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
            onPressed: () => Navigator.of(
              context,
            ).pop(_AssessmentFaceSetupAction.backToCourses),
            child: Text(secondaryLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              isRetry
                  ? _AssessmentFaceSetupAction.retry
                  : _AssessmentFaceSetupAction.completeSetup,
            ),
            child: Text(primaryLabel),
          ),
        ],
      ),
    );
  }
}
