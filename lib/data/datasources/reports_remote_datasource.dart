import 'package:adota_pet/core/network/http_client.dart';
import 'package:adota_pet/data/models/dashboard_response_model.dart';

class ReportsRemoteDatasource {
  final HttpClient client;

  ReportsRemoteDatasource(this.client);

  Future<DashboardResponseModel> getDashboard({
    required int months,
    required int topLimit,
    required int staleDays,
  }) async {
    final response = await client.get(
      '/reports/dashboard',
      queryParameters: {
        'months': months,
        'topLimit': topLimit,
        'staleDays': staleDays,
      },
    );
    return DashboardResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
