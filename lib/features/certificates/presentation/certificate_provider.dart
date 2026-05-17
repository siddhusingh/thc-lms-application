import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../models/certificate_model.dart';
import '../data/certificate_repository.dart';

class CertificateProvider extends ChangeNotifier {
  CertificateProvider(this._repository);

  final CertificateRepository _repository;
  final List<CertificateModel> certificates = [];
  bool loading = false;
  String? error;

  Future<void> load({bool refresh = false}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final response = await _repository.fetchCertificates();
      certificates
        ..clear()
        ..addAll(response.items);
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Unable to load certificates.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
