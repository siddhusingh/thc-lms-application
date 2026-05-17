import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_provider.dart';
import 'face_reference_provider.dart';

class FaceReferencePreparationScreen extends StatefulWidget {
  const FaceReferencePreparationScreen({super.key});

  @override
  State<FaceReferencePreparationScreen> createState() =>
      _FaceReferencePreparationScreenState();
}

class _FaceReferencePreparationScreenState
    extends State<FaceReferencePreparationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null && userId.isNotEmpty) {
        context.read<FaceReferenceProvider>().prepare(userId, force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FaceReferenceProvider>();
    final status = provider.status;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.face_retouching_natural_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                'Preparing face verification',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                status.message ??
                    'Preparing secure local verification for course videos.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              if (status.isPreparing)
                const Center(child: CircularProgressIndicator())
              else if (!status.isReady)
                OutlinedButton.icon(
                  onPressed: provider.retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Continue to dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
