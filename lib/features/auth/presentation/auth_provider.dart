import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../models/student_category_model.dart';
import '../../../models/user_model.dart';
import '../data/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository);

  final AuthRepository _repository;

  UserModel? user;
  List<StudentCategoryModel> categories = const [];
  bool loading = false;
  bool categoriesLoading = false;
  bool initialized = false;
  String? error;
  String? categoriesError;
  Map<String, String> fieldErrors = const {};

  bool get isAuthenticated => user != null;
  bool get hasFieldErrors => fieldErrors.isNotEmpty;
  String? get firstFieldError =>
      fieldErrors.isEmpty ? null : fieldErrors.values.first;

  Future<void> restoreSession() async {
    initialized = false;
    notifyListeners();
    try {
      if (await _repository.hasStoredSession()) {
        user = await _repository.currentUser();
      }
    } catch (_) {
      user = null;
    } finally {
      initialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(
    String email,
    String password, {
    bool rememberLogin = true,
  }) async {
    return _run(() async {
      user = await _repository.login(
        email: email,
        password: password,
        rememberLogin: rememberLogin,
      );
    });
  }

  Future<bool> register(Map<String, dynamic> payload) async {
    return _run(() async {
      user = await _repository.register(payload);
    });
  }

  Future<void> loadCategories({bool refresh = false}) async {
    if (categoriesLoading) return;
    if (!refresh && categories.isNotEmpty) return;
    categoriesLoading = true;
    categoriesError = null;
    notifyListeners();
    try {
      categories = await _repository.fetchStudentCategories();
    } on ApiException catch (exception) {
      categoriesError = exception.message;
    } catch (_) {
      categoriesError = 'Unable to load categories.';
    } finally {
      categoriesLoading = false;
      notifyListeners();
    }
  }

  Future<bool> forgotPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return _run(
      () => _repository.forgotPassword(
        email: email,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      ),
    );
  }

  Future<bool> verifyOtp(String email, String otp) async {
    return _run(() => _repository.verifyOtp(email: email, otp: otp));
  }

  Future<bool> registerFace(File image) async {
    return _run(() async {
      user = await _repository.registerFace(image);
    });
  }

  Future<bool> verifyFace(File image, {String? context}) async {
    return _run(() async {
      user = await _repository.verifyFace(image, context: context);
    });
  }

  Future<void> logout() async {
    loading = true;
    notifyListeners();
    await _repository.logout();
    user = null;
    loading = false;
    notifyListeners();
  }

  void updateUser(UserModel nextUser) {
    user = nextUser;
    notifyListeners();
  }

  String? fieldError(String field) => fieldErrors[field];

  void clearFieldError(String field) {
    if (!fieldErrors.containsKey(field)) return;
    final next = Map<String, String>.from(fieldErrors)..remove(field);
    fieldErrors = next;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    loading = true;
    error = null;
    fieldErrors = const {};
    notifyListeners();
    try {
      await action();
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      fieldErrors = _normalizeFieldErrors(exception.errors);
      return false;
    } catch (_) {
      error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Map<String, String> _normalizeFieldErrors(Map<String, dynamic>? errors) {
    if (errors == null || errors.isEmpty) return const {};
    final normalized = <String, String>{};
    for (final entry in errors.entries) {
      final message = _firstErrorMessage(entry.value);
      if (message != null && message.isNotEmpty) {
        normalized[entry.key] = message;
      }
    }
    return normalized;
  }

  String? _firstErrorMessage(Object? value) {
    if (value is List && value.isNotEmpty) {
      return value.first?.toString();
    }
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
