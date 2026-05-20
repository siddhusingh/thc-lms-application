import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../face_images/presentation/face_image_provider.dart';
import 'auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String? _selectedCategoryId;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      await auth.loadCategories();
      if (!mounted || _selectedCategoryId != null || auth.categories.isEmpty) {
        return;
      }
      setState(() => _selectedCategoryId = auth.categories.first.id);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    context.read<FaceImageProvider>().clear();
    final ok = await context.read<AuthProvider>().register({
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text,
      if (_selectedCategoryId?.isNotEmpty == true)
        'categories': _selectedCategoryId,
    });
    if (!mounted) return;
    if (!ok) {
      showErrorToast(
        context,
        message:
            context.read<AuthProvider>().firstFieldError ??
            context.read<AuthProvider>().error ??
            'Unable to register.',
      );
      return;
    }
    showSuccessToast(context, message: 'Registration successful.');
    await context.read<FaceImageProvider>().load(
      refresh: true,
      ownerKey: _faceImageOwner(context.read<AuthProvider>()),
    );
    if (!mounted) return;
    context.go('/face-images/setup');
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
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RegisterHeader(onBack: () => context.go('/login')),
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'Create student account',
                  subtitle: 'Enter your details to start learning.',
                ),
                const SizedBox(height: 20),
                _LabelText(label: 'Name', required: true),
                const SizedBox(height: 8),
                _RegisterTextField(
                  controller: _name,
                  hintText: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  errorText: auth.fieldError('name'),
                  onChanged: (_) => auth.clearFieldError('name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter full name'
                      : null,
                ),
                const SizedBox(height: 16),
                _LabelText(label: 'Email', required: true),
                const SizedBox(height: 8),
                _RegisterTextField(
                  controller: _email,
                  hintText: 'Email address',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  errorText: auth.fieldError('email'),
                  onChanged: (_) => auth.clearFieldError('email'),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Enter valid email'
                      : null,
                ),
                const SizedBox(height: 16),
                _LabelText(label: 'Mobile'),
                const SizedBox(height: 8),
                _RegisterTextField(
                  controller: _phone,
                  hintText: 'Mobile number',
                  icon: Icons.call_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  errorText:
                      auth.fieldError('mobile') ?? auth.fieldError('phone'),
                  onChanged: (_) {
                    auth.clearFieldError('mobile');
                    auth.clearFieldError('phone');
                  },
                ),
                const SizedBox(height: 16),
                _LabelText(label: 'Password'),
                const SizedBox(height: 8),
                _RegisterTextField(
                  controller: _password,
                  hintText: 'Enter password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  errorText: auth.fieldError('password'),
                  onChanged: (_) => auth.clearFieldError('password'),
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
                _LabelText(label: 'Categories'),
                const SizedBox(height: 8),
                _CategoryField(
                  selectedCategoryId: _selectedCategoryId,
                  errorText:
                      auth.fieldError('categories') ??
                      auth.fieldError('category_id'),
                  onChanged: (value) =>
                      setState(() => _selectedCategoryId = value),
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
                      : const Text('Register'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Login'),
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
    if (password.isEmpty) return 'Enter password';
    if (password.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader({required this.onBack});

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

class _RegisterTextField extends StatelessWidget {
  const _RegisterTextField({
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

class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.selectedCategoryId,
    required this.errorText,
    required this.onChanged,
  });

  final String? selectedCategoryId;
  final String? errorText;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final categories = auth.categories;
    final selectedValue =
        categories.any((category) => category.id == selectedCategoryId)
        ? selectedCategoryId
        : null;

    if (auth.categoriesError != null && categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.mutedText.withValues(alpha: 0.22)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.category_outlined, color: AppTheme.mutedText),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                auth.categoriesError!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: auth.categoriesLoading
                  ? null
                  : () => auth.loadCategories(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      items: categories
          .map(
            (category) => DropdownMenuItem(
              value: category.id,
              child: Text(category.displayName),
            ),
          )
          .toList(),
      onChanged: auth.categoriesLoading || categories.isEmpty
          ? null
          : (value) {
              auth.clearFieldError('categories');
              auth.clearFieldError('category_id');
              onChanged(value);
            },
      validator: (value) =>
          categories.isNotEmpty && (value == null || value.isEmpty)
          ? 'Select category'
          : null,
      icon: auth.categoriesLoading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: _fieldDecoration(
        hintText: auth.categoriesLoading
            ? 'Loading categories'
            : categories.isEmpty
            ? 'No categories available'
            : 'Select category',
        icon: Icons.category_outlined,
        errorText: errorText,
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(14),
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
