import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';

class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({required this.mode, super.key});

  final FaceMode mode;

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  final _picker = ImagePicker();
  File? _image;

  Future<void> _capture() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 90,
      maxWidth: 1280,
    );
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    final image = _image;
    if (image == null) return;
    final auth = context.read<AuthProvider>();
    final ok = widget.mode == FaceMode.register
        ? await auth.registerFace(image)
        : await auth.verifyFace(image, context: 'login');
    if (!mounted || !ok) return;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isRegister = widget.mode == FaceMode.register;
    return Scaffold(
      appBar: AppBar(
        title: Text(isRegister ? 'Face registration' : 'Face verification'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _image == null
                      ? const Center(
                          child: Icon(
                            Icons.face_retouching_natural_rounded,
                            size: 82,
                          ),
                        )
                      : Image.file(_image!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Use the front camera in clear light. The image is compressed locally and sent to the existing THC Learning verification API.',
                textAlign: TextAlign.center,
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  auth.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: auth.loading ? null : _capture,
                icon: const Icon(Icons.photo_camera_rounded),
                label: const Text('Capture'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _image == null || auth.loading ? null : _submit,
                child: auth.loading
                    ? const CircularProgressIndicator()
                    : Text(isRegister ? 'Register face' : 'Verify identity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum FaceMode { register, verify }
