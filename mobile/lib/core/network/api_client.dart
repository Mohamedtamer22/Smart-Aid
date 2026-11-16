import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../storage/token_store.dart';

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  ),
);
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.read(tokenStoreProvider)),
);

class ApiClient {
  ApiClient(this._tokens)
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 6),
          sendTimeout: const Duration(seconds: 5),
          headers: const {
            'Accept': 'application/json',
            'Connection': 'keep-alive',
          },
        ),
      ) {
    AppConfig.onBaseUrlChanged = (newUrl) {
      _dio.options.baseUrl = newUrl;
    };
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokens.readAccess();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          options.headers['X-Request-ID'] = DateTime.now()
              .microsecondsSinceEpoch
              .toString();
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode != 401 ||
              error.requestOptions.extra['retried'] == true ||
              error.requestOptions.path.startsWith('/api/auth/')) {
            return handler.next(error);
          }
          final refresh = await _tokens.readRefresh();
          if (refresh == null) return handler.next(error);
          try {
            final response =
                await Dio(
                  BaseOptions(baseUrl: AppConfig.apiBaseUrl),
                ).post<Map<String, dynamic>>(
                  '/api/auth/refresh',
                  data: {'refreshToken': refresh},
                );
            final data = response.data!;
            await _tokens.write(
              access: data['accessToken'] as String,
              refresh: data['refreshToken'] as String,
            );
            final retry = await _dio.fetch<dynamic>(
              error.requestOptions..extra['retried'] = true,
            );
            handler.resolve(retry);
          } on DioException {
            await _tokens.clear();
            handler.next(error);
          }
        },
      ),
    );
  }
  final TokenStore _tokens;
  final Dio _dio;
  Future<Response<T>> get<T>(String path) => _dio.get<T>(path);
  Future<Response<T>> post<T>(String path, {Object? data, Options? options}) =>
      _dio.post<T>(path, data: data, options: options);
  Future<Response<T>> put<T>(String path, {Object? data}) =>
      _dio.put<T>(path, data: data);
  Future<Response<T>> patch<T>(String path, {Object? data}) =>
      _dio.patch<T>(path, data: data);
  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);
}

class ApiFailure implements Exception {
  const ApiFailure(this.status, {this.message, this.isNetworkError = false});
  final int? status;
  final String? message;
  final bool isNetworkError;

  factory ApiFailure.fromDio(DioException error) {
    final isNetwork =
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown;
    String? serverMessage;
    if (error.response?.data is Map<String, dynamic>) {
      final map = error.response!.data as Map<String, dynamic>;
      serverMessage = map['message'] as String? ?? map['error'] as String?;
    }
    return ApiFailure(
      error.response?.statusCode,
      message: serverMessage ?? error.message,
      isNetworkError: isNetwork,
    );
  }
}
