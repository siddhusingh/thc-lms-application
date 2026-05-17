import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_provider.dart';
import 'profile_provider.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _aadhaar = TextEditingController();
  final _address = TextEditingController();
  final _email = TextEditingController();
  final _dateOfBirth = TextEditingController();
  final _pan = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProfileProvider>();
      if (provider.profile == null) {
        provider.load();
      } else {
        _syncControllers();
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _aadhaar.dispose();
    _address.dispose();
    _email.dispose();
    _dateOfBirth.dispose();
    _pan.dispose();
    super.dispose();
  }

  void _syncControllers() {
    final profile =
        context.read<ProfileProvider>().profile ??
        context.read<AuthProvider>().user;
    if (profile == null || _initialized) return;

    _name.text = profile.name;
    _mobile.text = profile.phone ?? '';
    _aadhaar.text = profile.aadhaarNumber ?? '';
    _address.text = profile.address ?? '';
    _email.text = profile.email;
    _dateOfBirth.text = profile.dateOfBirth ?? '';
    _pan.text = profile.panNumber ?? '';
    _initialized = true;
  }

  Future<void> _pickDate() async {
    final current = DateTime.tryParse(_dateOfBirth.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    _dateOfBirth.text =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profileProvider = context.read<ProfileProvider>();
    final saved = await profileProvider.updateProfile(
      name: _name.text.trim(),
      mobile: _mobile.text.trim(),
      aadhaarNumber: _aadhaar.text.trim(),
      address: _address.text.trim(),
      email: _email.text.trim(),
      dateOfBirth: _dateOfBirth.text.trim(),
      panNumber: _pan.text.trim(),
    );
    if (!mounted) return;

    final profile = profileProvider.profile;
    if (saved && profile != null) {
      context.read<AuthProvider>().updateUser(profile);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profile =
        profileProvider.profile ?? context.watch<AuthProvider>().user;
    if (!_initialized && profile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(_syncControllers);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Personal details')),
      body: SafeArea(
        child: profile == null && profileProvider.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person_outline_rounded),
                            label: _RequiredLabel('Name'),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                            label: _RequiredLabel('Email'),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _mobile,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.phone_outlined),
                            label: _RequiredLabel('Mobile Number'),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _dateOfBirth,
                          readOnly: true,
                          onTap: _pickDate,
                          validator: _required,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.cake_outlined),
                            label: _RequiredLabel('Date Of Birth'),
                            suffixIcon: Icon(Icons.calendar_month_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _pan,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.credit_card_outlined),
                            labelText: 'PAN Number',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _aadhaar,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.badge_outlined),
                            label: _RequiredLabel('Adhaar Number'),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _address,
                          minLines: 3,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.home_outlined),
                            labelText: 'Address',
                            alignLabelWithHint: true,
                          ),
                        ),
                        if (profileProvider.error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            profileProvider.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: profileProvider.loading ? null : _save,
                          child: profileProvider.loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Update profile'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _RequiredLabel extends StatelessWidget {
  const _RequiredLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          TextSpan(text: text),
          TextSpan(
            text: ' *',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );
  }
}
