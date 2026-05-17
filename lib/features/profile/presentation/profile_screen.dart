import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_provider.dart';
import 'profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ProfileProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile ?? auth.user;
    return RefreshIndicator(
      onRefresh: () => context.read<ProfileProvider>().load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  _ProfileAvatar(
                    name: profile?.name,
                    imageUrl: profile?.avatarUrl,
                    uploading: provider.uploadingImage,
                    onPressed: _showImageSourcePicker,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.name ?? 'Student',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(profile?.email ?? ''),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: const Text('Personal details'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/profile/personal-details'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.face_retouching_natural_rounded),
                  title: const Text('Face verification'),
                  subtitle: const Text('Manage front, left, and right images'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/profile/face-images'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: const Text('Change password'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => const _ChangePasswordDialog(),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Logout'),
                  onTap: () async {
                    await auth.logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showImageSourcePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickCropAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickCropAndUpload(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCropAndUpload(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 95,
        maxWidth: 1600,
      );
      if (picked == null || !mounted) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 95,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop profile image',
            lockAspectRatio: true,
            initAspectRatio: CropAspectRatioPreset.square,
          ),
          IOSUiSettings(
            title: 'Crop profile image',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 420, height: 420),
            initialAspectRatio: 1,
            cropBoxMovable: true,
            cropBoxResizable: false,
            viewwMode: WebViewMode.mode_1,
          ),
        ],
      );
      if (cropped == null || !mounted) return;

      final processedBytes = await _prepareProfileImage(
        await cropped.readAsBytes(),
      );
      if (!mounted) return;

      final provider = context.read<ProfileProvider>();
      final uploaded = await provider.uploadProfileImage(processedBytes);
      if (!mounted) return;

      final message = uploaded
          ? provider.profileImageMessage ?? 'Profile image updated.'
          : provider.error ?? 'Unable to upload profile image.';
      if (uploaded && provider.profile != null) {
        context.read<AuthProvider>().updateUser(provider.profile!);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on FormatException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to process profile image: $error')),
      );
    }
  }

  Future<Uint8List> _prepareProfileImage(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Please choose a valid image file.');
    }

    final resized = img.copyResize(
      decoded,
      width: 200,
      height: 200,
      interpolation: img.Interpolation.average,
    );
    if (resized.width != 200 || resized.height != 200) {
      throw const FormatException('Unable to resize profile image.');
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: 88));
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.name,
    required this.imageUrl,
    required this.uploading,
    required this.onPressed,
  });

  final String? name;
  final String? imageUrl;
  final bool uploading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl?.isNotEmpty == true;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 34,
          backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
          child: hasImage
              ? null
              : Text((name?.isNotEmpty == true ? name![0] : 'S').toUpperCase()),
        ),
        if (uploading)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Material(
            color: Theme.of(context).colorScheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: uploading ? null : onPressed,
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(
                  Icons.photo_camera_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    return AlertDialog(
      title: const Text('Change password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _current,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _next,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          if (provider.error != null) ...[
            const SizedBox(height: 10),
            Text(
              provider.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: provider.loading
              ? null
              : () async {
                  final ok = await provider.changePassword(
                    _current.text,
                    _next.text,
                  );
                  if (context.mounted && ok) Navigator.pop(context);
                },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
