import '../models/auth_session.dart';
import '../services/api_service.dart';

class AuthRepository {
  AuthRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService.shared;

  final ApiService _apiService;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      'login',
      data: {'email': email, 'password': password},
    );
    final data = response is Map && response['data'] is Map
        ? response['data'] as Map
        : response;
    if (data is! Map ||
        data['token'] is! String ||
        data['owner'] is! Map) {
      throw const FormatException(
        'Invalid login response: expected token and owner.',
      );
    }
    final owner = data['owner'] as Map;
    final session = AuthSession(
      token: data['token'] as String,
      owner: AuthOwner(
        id: owner['id'].toString(),
        name: owner['name']?.toString() ?? '',
      ),
    );
    _apiService.setAuthToken(session.token);
    return session;
  }

  void logout() => _apiService.clearAuthToken();
}
