import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../models/user_model.dart';
import '../data/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository);

  final AuthRepository _repository;

  UserModel? user;
  bool loading = false;
  bool initialized = false;
  String? error;

  bool get isAuthenticated => user != null;

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

  Future<bool> forgotPassword(String email) async {
    return _run(() => _repository.forgotPassword(email));
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

  Future<bool> _run(Future<void> Function() action) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
