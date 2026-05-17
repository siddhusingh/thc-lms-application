import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../controllers/face_verification_controller.dart';
import '../models/face_verification_result.dart';

class FaceVerificationWidget extends StatefulWidget {
  const FaceVerificationWidget({
    required this.controller,
    required this.contextLabel,
    required this.title,
    required this.message,
    super.key,
  });

  final FaceVerificationController controller;
  final String contextLabel;
  final String title;
  final String message;

  @override
  State<FaceVerificationWidget> createState() => _FaceVerificationWidgetState();
}

class _FaceVerificationWidgetState extends State<FaceVerificationWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.initializeCamera(),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<FaceVerificationResult> verify() {
    return widget.controller.verify(context: widget.contextLabel);
  }

  @override
  Widget build(BuildContext context) {
    final cameraController = widget.controller.cameraController;
    final result = widget.controller.lastResult;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    if (isLandscape) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 320,
            child: _buildPreview(
              context,
              cameraController,
              isLandscape: true,
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 280,
            child: _buildContent(context, result, isLandscape: true),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildPreview(context, cameraController, isLandscape: false),
        _buildFooter(context, result),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    FaceVerificationResult? result, {
    required bool isLandscape,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        SizedBox(height: isLandscape ? 20 : 12),
        _buildFooter(context, result),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(widget.message),
      ],
    );
  }

  Widget _buildPreview(
    BuildContext context,
    CameraController? cameraController, {
    required bool isLandscape,
  }) {
    final previewAspectRatio =
        cameraController?.value.isInitialized == true
        ? isLandscape
              ? cameraController!.value.aspectRatio
              : 1 / cameraController!.value.aspectRatio
        : isLandscape
        ? 4 / 3
        : 3 / 4;

    return AspectRatio(
      aspectRatio: isLandscape ? 4 / 3 : 6 / 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: cameraController?.value.isInitialized == true
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: previewAspectRatio,
                    height: 1,
                    child: CameraPreview(cameraController!),
                  ),
                )
              : const Center(
                  child: Icon(Icons.face_retouching_natural_rounded, size: 72),
                ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, FaceVerificationResult? result) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (result != null && !result.isVerified) ...[
          const SizedBox(height: 12),
          Text(
            result.message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed:
              widget.controller.initializing || widget.controller.verifying
              ? null
              : () async {
                  final result = await verify();
                  if (!context.mounted || !result.isVerified) return;
                  Navigator.of(context).pop(result);
                },
          icon: widget.controller.verifying
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.verified_user_rounded),
          label: Text(
            widget.controller.verifying ? 'Verifying...' : 'Verify face',
          ),
        ),
      ],
    );
  }
}
