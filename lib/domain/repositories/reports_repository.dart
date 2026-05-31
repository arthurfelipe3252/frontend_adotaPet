import 'package:adota_pet/domain/entities/dashboard_data.dart';

abstract class ReportsRepository {
  /// Carrega o payload agregado do dashboard do protetor/ONG autenticado.
  ///
  /// [months] janela dos gráficos de timeline (1-60), [topLimit] quantidade de
  /// pets mais solicitados (1-50), [staleDays] threshold de dias sem
  /// solicitação para a lista de pets parados (1-365).
  ///
  /// Lança `Failure` em erro de rede/permissão.
  Future<DashboardData> getDashboard({
    int months,
    int topLimit,
    int staleDays,
  });
}
