import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../face_images/presentation/face_image_provider.dart';
import 'profile_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = context.read<ProfileProvider>();
    final submitted = await profile.changePassword(
      _currentPassword.text,
      _newPassword.text,
      _confirmPassword.text,
    );
    if (!mounted) return;

    if (!submitted) {
      showErrorToast(
        context,
        message: profile.error ?? 'Unable to submit password request.',
      );
      return;
    }

    showSuccessToast(
      context,
      message:
          'Password request submitted. Please wait for manager approval before signing in.',
    );
    context.read<FaceImageProvider>().clear();
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter current password';
    return null;
  }

  String? _validateNewPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Enter new password';
    if (password.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Confirm new password';
    if (password != _newPassword.text) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loading = context.watch<ProfileProvider>().loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Update password',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Your request will be sent for manager approval. You will be logged out after submission.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              _PasswordField(
                controller: _currentPassword,
                hintText: 'Current password',
                icon: Icons.lock_outline_rounded,
                obscureText: !_showCurrentPassword,
                textInputAction: TextInputAction.next,
                validator: _validateCurrentPassword,
                onToggleVisibility: () => setState(
                  () => _showCurrentPassword = !_showCurrentPassword,
                ),
                showPassword: _showCurrentPassword,
              ),
              const SizedBox(height: 14),
              _PasswordField(
                controller: _newPassword,
                hintText: 'New password',
                icon: Icons.password_rounded,
                obscureText: !_showNewPassword,
                textInputAction: TextInputAction.next,
                validator: _validateNewPassword,
                onToggleVisibility: () =>
                    setState(() => _showNewPassword = !_showNewPassword),
                showPassword: _showNewPassword,
              ),
              const SizedBox(height: 14),
              _PasswordField(
                controller: _confirmPassword,
                hintText: 'Confirm new password',
                icon: Icons.verified_user_outlined,
                obscureText: !_showConfirmPassword,
                textInputAction: TextInputAction.done,
                validator: _validateConfirmPassword,
                onFieldSubmitted: (_) => loading ? null : _submit(),
                onToggleVisibility: () => setState(
                  () => _showConfirmPassword = !_showConfirmPassword,
                ),
                showPassword: _showConfirmPassword,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.obscureText,
    required this.textInputAction,
    required this.validator,
    required this.onToggleVisibility,
    required this.showPassword,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputAction textInputAction;
  final String? Function(String?) validator;
  final VoidCallback onToggleVisibility;
  final bool showPassword;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppTheme.mutedText),
        suffixIcon: IconButton(
          tooltip: showPassword ? 'Hide password' : 'Show password',
          onPressed: onToggleVisibility,
          icon: Icon(
            showPassword
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: AppTheme.mutedText,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: _fieldBorder(),
        enabledBorder: _fieldBorder(),
        focusedBorder: _fieldBorder(
          color: Theme.of(context).colorScheme.primary,
          width: 1.4,
        ),
        errorBorder: _fieldBorder(color: AppTheme.danger),
        focusedErrorBorder: _fieldBorder(color: AppTheme.danger, width: 1.4),
      ),
    );
  }

  OutlineInputBorder _fieldBorder({Color? color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: color ?? AppTheme.mutedText.withValues(alpha: 0.26),
        width: width,
      ),
    );
  }
}
