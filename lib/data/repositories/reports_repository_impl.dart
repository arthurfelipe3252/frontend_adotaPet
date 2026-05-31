import 'package:dio/dio.dart';

import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/data/datasources/_dio_error_helper.dart';
import 'package:adota_pet/data/datasources/reports_remote_datasource.dart';
import 'package:adota_pet/domain/entities/dashboard_data.dart';
import 'package:adota_pet/domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDatasource remote;

  ReportsRepositoryImpl(this.remote);

  @override
  Future<DashboardData> getDashboard({
    int months = 12,
    int topLimit = 5,
    int staleDays = 30,
  }) async {
    try {
      final model = await remote.getDashboard(
        months: months,
        topLimit: topLimit,
        staleDays: staleDays,
      );
      return model.toEntity();
    } on DioException catch (e) {
      throw failureFromDio(
        e,
        customByStatus: {
          401: 'Sua sessão expirou. Faça login novamente.',
          403: 'Apenas protetores e ONGs têm acesso ao painel.',
          404: 'Perfil de protetor/ONG não encontrado.',
        },
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw Failure('Não foi possível carregar o painel.');
    }
  }
}
