import '../../../core/api/api_client.dart';

class PersonalIncomeApi {
  final ApiClient _api;
  PersonalIncomeApi(this._api);

  Future<Map<String, dynamic>> incomeByMonth({int months = 6}) {
    return _api.getJson('/personal-workspace/income-by-month', query: {'months': months});
  }
}
