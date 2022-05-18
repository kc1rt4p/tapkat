import 'package:tapkat/models/localization.dart';
import 'package:tapkat/services/http/api_service.dart';

class ReferenceRepository {
  final _apiService = ApiService();

  Future<List<LocalizationModel>> getLocalizations() async {
    final response = await _apiService.get(
      url: 'reference/localization',
    );

    if (response.data['status'] != 'SUCCESS') return [];

    return (response.data['localization data'] as List<dynamic>)
        .map((item) => LocalizationModel.fromJson(item))
        .toList();
  }
}
