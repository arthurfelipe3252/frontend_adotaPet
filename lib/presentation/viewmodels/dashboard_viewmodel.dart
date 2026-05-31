import 'package:flutter/foundation.dart';

import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/domain/entities/dashboard_data.dart';
import 'package:adota_pet/domain/repositories/reports_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final ReportsRepository repository;

  DashboardViewModel(this.repository);

  bool isLoading = false;
  String? error;
  DashboardData? data;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      data = await repository.getDashboard();
    } catch (e) {
      error = e is Failure ? e.message : 'Não foi possível carregar o painel.';
    }
    isLoading = false;
    notifyListeners();
  }
}
