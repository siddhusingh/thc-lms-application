import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../face_images/presentation/face_image_provider.dart';
import 'auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final faceImages = context.read<FaceImageProvider>()..clear();
    final ok = await auth.login(
      _email.text.trim(),
      _password.text,
      rememberLogin: _remember,
    );
    if (!mounted) return;
    if (!ok) {
      showErrorToast(context, message: auth.error ?? 'Unable to login.');
      return;
    }
    showSuccessToast(context, message: 'Login successful.');
    await faceImages.load(refresh: true, ownerKey: _faceImageOwner(auth));
    if (!mounted) return;
    if (faceImages.images?.isComplete == true) {
      context.go('/face/preparing');
    } else {
      context.go('/face-images/setup');
    }
  }

  String _faceImageOwner(AuthProvider auth) {
    final user = auth.user;
    if (user == null) return '';
    return user.id.isNotEmpty ? user.id : user.email;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 42, 24, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _LoginLogo(),
                const SizedBox(height: 18),
                Text(
                  'Sign in to continue learning',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                const _LabelText(label: 'Email', required: true),
                const SizedBox(height: 8),
                _LoginTextField(
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
                const _LabelText(label: 'Password', required: true),
                const SizedBox(height: 8),
                _LoginTextField(
                  controller: _password,
                  hintText: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  errorText: auth.fieldError('password'),
                  onChanged: (_) => auth.clearFieldError('password'),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: AppTheme.mutedText,
                    ),
                  ),
                  onFieldSubmitted: (_) => auth.loading ? null : _submit(),
                  validator: (value) => value == null || value.length < 6
                      ? 'Enter password'
                      : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Checkbox(
                      value: _remember,
                      onChanged: (value) =>
                          setState(() => _remember = value ?? true),
                    ),
                    Text(
                      'Remember login',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/forgot-password'),
                      child: const Text('Forgot?'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
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
                      : const Text('Login'),
                ),
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Create student account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginLogo extends StatelessWidget {
  const _LoginLogo();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
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

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
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
        errorText: errorText,
      ),
      onChanged: onChanged,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
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
