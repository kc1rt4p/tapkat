import 'package:tapkat/models/user.dart';
import 'package:tapkat/services/http/api_service.dart';

class UserRepository {
  final _apiService = ApiService();

  Future<UserModel?> getUser(String userId) async {
    final result = await _apiService.get(
      url: 'users/$userId',
    );

    if (result.data['status'] != 'SUCCESS') return null;

    return UserModel.fromJson(result.data['user']);
  }

  Future<bool> updateUser(UserModel user) async {
    final result = await _apiService.patch(
      url: 'users/${user.userid}',
      body: {
        'psk': "lcp9321p",
        ...user.toJson(),
      },
    );

    if (result.data['status'] != 'SUCCESS') return false;

    return true;
  }
}
