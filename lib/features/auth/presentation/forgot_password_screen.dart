import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import 'auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.forgotPassword(
      email: _email.text.trim(),
      newPassword: _password.text,
      confirmPassword: _confirmPassword.text,
    );
    if (!mounted) return;
    if (!ok) {
      showErrorToast(
        context,
        message: auth.firstFieldError ?? auth.error ?? 'Unable to send request.',
      );
      return;
    }
    showSuccessToast(context, message: 'Password reset request sent.');
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ForgotPasswordHeader(onBack: () => context.go('/login')),
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'Forgot password',
                  subtitle: 'Enter your email and choose a new password.',
                ),
                const SizedBox(height: 20),
                const _LabelText(label: 'Email', required: true),
                const SizedBox(height: 8),
                _ResetTextField(
                  controller: _email,
                  hintText: 'Email address',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  errorText: auth.fieldError('email'),
                  onChanged: (_) => auth.clearFieldError('email'),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 16),
                const _LabelText(label: 'New password', required: true),
                const SizedBox(height: 8),
                _ResetTextField(
                  controller: _password,
                  hintText: 'New password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  errorText:
                      auth.fieldError('new_password') ??
                      auth.fieldError('password'),
                  onChanged: (_) {
                    auth.clearFieldError('new_password');
                    auth.clearFieldError('password');
                  },
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: AppTheme.mutedText,
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                const _LabelText(label: 'Confirm password', required: true),
                const SizedBox(height: 8),
                _ResetTextField(
                  controller: _confirmPassword,
                  hintText: 'Confirm password',
                  icon: Icons.lock_reset_rounded,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  errorText: auth.fieldError('confirm_password'),
                  onChanged: (_) => auth.clearFieldError('confirm_password'),
                  suffixIcon: IconButton(
                    tooltip: _obscureConfirmPassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () => setState(
                      () =>
                          _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: AppTheme.mutedText,
                    ),
                  ),
                  validator: _validateConfirmPassword,
                  onFieldSubmitted: (_) => auth.loading ? null : _submit(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: auth.loading
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit request'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Back to login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Enter new password';
    if (password.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final confirmPassword = value ?? '';
    if (confirmPassword.isEmpty) return 'Confirm new password';
    if (confirmPassword != _password.text) return 'Passwords do not match';
    return null;
  }
}

class _ForgotPasswordHeader extends StatelessWidget {
  const _ForgotPasswordHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to login',
        ),
        const Spacer(),
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.35),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              'assets/branding/thc-logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.accent,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LabelText extends StatelessWidget {
  const _LabelText({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppTheme.accent,
          fontWeight: FontWeight.w700,
        ),
        children: [
          if (required)
            TextSpan(
              text: ' *',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}

class _ResetTextField extends StatelessWidget {
  const _ResetTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.errorText,
    this.onChanged,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      decoration: _fieldDecoration(
        hintText: hintText,
        icon: icon,
        suffixIcon: suffixIcon,
        errorText: _shortError(errorText),
      ),
      onChanged: onChanged,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  String? _shortError(String? message) {
    if (message == null) return null;
    if (message.toLowerCase().contains('password must contain')) {
      return 'Password must be at least 8 characters.';
    }
    return message;
  }
}

InputDecoration _fieldDecoration({
  required String hintText,
  required IconData icon,
  Widget? suffixIcon,
  String? errorText,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: AppTheme.mutedText.withValues(alpha: 0.26)),
  );

  return InputDecoration(
    hintText: hintText,
    prefixIcon: Icon(icon, color: AppTheme.mutedText),
    suffixIcon: suffixIcon,
    errorText: errorText,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: AppTheme.primary, width: 1.4),
    ),
    errorBorder: border.copyWith(
      borderSide: const BorderSide(color: AppTheme.danger),
    ),
    focusedErrorBorder: border.copyWith(
      borderSide: const BorderSide(color: AppTheme.danger, width: 1.4),
    ),
  );
}
