import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../models/user_model.dart';
import '../data/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider(this._repository);

  final ProfileRepository _repository;
  UserModel? profile;
  bool loading = false;
  bool uploadingImage = false;
  String? error;
  String? profileImageMessage;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      profile = await _repository.fetchProfile();
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Unable to load profile.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String mobile,
    required String aadhaarNumber,
    required String address,
    required String email,
    required String dateOfBirth,
    required String panNumber,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      profile = await _repository.updateProfile(
        name: name,
        mobile: mobile,
        aadhaarNumber: aadhaarNumber,
        address: address,
        email: email,
        dateOfBirth: dateOfBirth,
        panNumber: panNumber,
      );
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'Unable to update profile.';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadProfileImage(Uint8List bytes) async {
    uploadingImage = true;
    error = null;
    profileImageMessage = null;
    notifyListeners();
    try {
      final imageUrl = await _repository.uploadProfileImage(bytes);
      profile = (profile ?? await _repository.fetchProfile()).copyWith(
        avatarUrl: imageUrl,
      );
      profileImageMessage = 'Profile image updated.';
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } on FormatException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'Unable to upload profile image.';
      return false;
    } finally {
      uploadingImage = false;
      notifyListeners();
    }
  }
}
