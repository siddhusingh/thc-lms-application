import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../features/auth/presentation/auth_provider.dart';
import '../../../features/face_references/presentation/face_reference_provider.dart';
import '../../../models/face_image_state.dart';
import 'face_image_provider.dart';

class FaceImagesScreen extends StatefulWidget {
  const FaceImagesScreen({super.key});

  @override
  State<FaceImagesScreen> createState() => _FaceImagesScreenState();
}

class _FaceImagesScreenState extends State<FaceImagesScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<FaceImageProvider>().load(),
    );
  }

  Future<void> _pickImage(FaceImageSlot slot, ImageSource source) async {
    Navigator.of(context).pop();
    try {
      final picked = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 90,
        maxWidth: 1600,
      );
      if (picked == null || !mounted) return;

      final provider = context.read<FaceImageProvider>();
      final uploaded = await provider.upload(slot, File(picked.path));
      if (!mounted) return;

      if (uploaded) {
        final userId = context.read<AuthProvider>().user?.id;
        if (userId != null && userId.isNotEmpty) {
          context.read<FaceReferenceProvider>().prepare(userId, force: true);
        }
        showSuccessToast(
          context,
          message: '${slot.label} face image updated.',
        );
        return;
      }

      final error = provider.error;
      if (error != null) {
        showErrorToast(context, message: error);
      }
    } catch (_) {
      if (!mounted) return;
      showErrorToast(context, message: 'Unable to select image.');
    }
  }

  void _showImageSourcePicker(FaceImageSlot slot) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => _pickImage(slot, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => _pickImage(slot, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FaceImageProvider>();
    final images = provider.images;

    if (provider.loading && images == null) {
      return const LoadingShimmer();
    }
    if (provider.error != null && images == null) {
      return AppErrorView(
        message: provider.error!,
        onRetry: () => provider.load(refresh: true),
      );
    }

    final isComplete = images?.isComplete ?? false;
    final hasMissingImages = images?.hasMissingImages ?? true;

    return RefreshIndicator(
      onRefresh: () => provider.load(refresh: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(
            title: 'Face verification',
            onBack: () => context.pop(),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isComplete
                        ? Icons.verified_rounded
                        : Icons.pending_actions_rounded,
                    color: isComplete
                        ? Colors.green.shade700
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isComplete ? 'Face images complete' : 'Incomplete',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isComplete
                              ? 'All required verification images are uploaded.'
                              : 'All 3 images are required for verification.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasMissingImages) ...[
            const SizedBox(height: 12),
            Text(
              'Upload a clear front, left, and right face image before verification can be completed.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (provider.error != null && images != null) ...[
            const SizedBox(height: 12),
            Text(
              provider.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          const _RecommendedAnglesCard(),
          const SizedBox(height: 16),
          _UploadGrid(
            images: images,
            imageUrlFor: provider.imageUrlFor,
            isUploading: provider.isUploading,
            onPressed: _showImageSourcePicker,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 4),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }
}

class _RecommendedAnglesCard extends StatelessWidget {
  const _RecommendedAnglesCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recommended angles',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(
                  child: _RecommendedAngleTile(
                    label: 'Front',
                    assetPath: 'assets/face_guides/front.jpg',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _RecommendedAngleTile(
                    label: 'Left',
                    assetPath: 'assets/face_guides/left.jpg',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _RecommendedAngleTile(
                    label: 'Right',
                    assetPath: 'assets/face_guides/right.jpg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Upload clear, well-lit images with the full face visible. Blurry, low-resolution, or unclear images may cause verification issues.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedAngleTile extends StatelessWidget {
  const _RecommendedAngleTile({required this.label, required this.assetPath});

  final String label;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(assetPath, fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }
}

class _UploadGrid extends StatelessWidget {
  const _UploadGrid({
    required this.images,
    required this.imageUrlFor,
    required this.isUploading,
    required this.onPressed,
  });

  final FaceImageState? images;
  final String? Function(FaceImageSlot slot) imageUrlFor;
  final bool Function(FaceImageSlot slot) isUploading;
  final ValueChanged<FaceImageSlot> onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your uploads',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final slot in FaceImageSlot.values) ...[
              Expanded(
                child: _UploadTile(
                  slot: slot,
                  imageUrl: imageUrlFor(slot),
                  uploading: isUploading(slot),
                  onPressed: () => onPressed(slot),
                ),
              ),
              if (slot != FaceImageSlot.right) const SizedBox(width: 10),
            ],
          ],
        ),
      ],
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.slot,
    required this.imageUrl,
    required this.uploading,
    required this.onPressed,
  });

  final FaceImageSlot slot;
  final String? imageUrl;
  final bool uploading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null;

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: uploading ? null : onPressed,
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (_, _, _) => const _ImageLoadFailedSlot(),
                    )
                  else
                    const _EmptyImageSlot(),
                  if (uploading)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.48),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(9),
                        child: Icon(
                          hasImage
                              ? Icons.edit_rounded
                              : Icons.photo_camera_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          slot.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyImageSlot extends StatelessWidget {
  const _EmptyImageSlot();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: 34,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _ImageLoadFailedSlot extends StatelessWidget {
  const _ImageLoadFailedSlot();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.broken_image_outlined,
        size: 34,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
