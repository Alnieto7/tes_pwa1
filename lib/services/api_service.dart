import 'package:dio/dio.dart';

const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({String? baseUrl, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _normalizeBaseUrl(baseUrl ?? apiBaseUrl),
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );

  static final ApiService shared = ApiService();

  final Dio _dio;

  static String _normalizeBaseUrl(String value) {
    if (value.isEmpty) return value;
    return value.endsWith('/') ? value : '$value/';
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return (await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      )).data;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<dynamic> post(String path, {Object? data}) async {
    try {
      return (await _dio.post<dynamic>(path, data: data)).data;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<dynamic> put(String path, {Object? data}) async {
    try {
      return (await _dio.put<dynamic>(path, data: data)).data;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<dynamic> patch(String path, {Object? data}) async {
    try {
      return (await _dio.patch<dynamic>(path, data: data)).data;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<dynamic> delete(String path, {Object? data}) async {
    try {
      return (await _dio.delete<dynamic>(path, data: data)).data;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  ApiException _toApiException(DioException error) {
    final statusCode = error.response?.statusCode;
    if (error.response == null) {
      return ApiException('Unable to connect to server.');
    }
    final responseData = error.response?.data;
    final serverMessage =
        responseData is Map ? responseData['message']?.toString() : null;
    return ApiException(
      serverMessage?.isNotEmpty == true
          ? serverMessage!
          : 'Request failed${statusCode == null ? '' : ' ($statusCode)'}.',
      statusCode: statusCode,
    );
  }
}
