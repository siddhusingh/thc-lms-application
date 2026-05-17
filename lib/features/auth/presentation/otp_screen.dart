import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_toast.dart';
import 'auth_provider.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({required this.email, super.key});

  final String email;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otp = TextEditingController();

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _otp,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.password_rounded),
                labelText: 'OTP',
              ),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Text(
                auth.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: auth.loading
                  ? null
                  : () async {
                      final ok = await auth.verifyOtp(
                        widget.email,
                        _otp.text.trim(),
                      );
                      if (!context.mounted) return;
                      if (!ok) {
                        showErrorToast(
                          context,
                          message: auth.error ?? 'Unable to verify OTP.',
                        );
                        return;
                      }
                      showSuccessToast(context, message: 'OTP verified.');
                      context.go('/login');
                    },
              child: auth.loading
                  ? const CircularProgressIndicator()
                  : const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
