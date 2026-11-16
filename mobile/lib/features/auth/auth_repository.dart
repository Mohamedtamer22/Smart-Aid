import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/token_store.dart';

enum RegistrationType {
  citizen('CITIZEN'),
  volunteer('VOLUNTEER'),
  hospital('HOSPITAL');

  const RegistrationType(this.apiValue);
  final String apiValue;
}

class Session {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.displayName,
    required this.email,
    required this.roles,
  });
  final String accessToken;
  final String refreshToken;
  final String displayName;
  final String email;
  final List<String> roles;
  factory Session.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return Session(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      displayName: user['displayName'] as String,
      email: user['email'] as String,
      roles: (user['roles'] as List<dynamic>).cast<String>(),
    );
  }
  factory Session.fromCachedJson(
    String value, {
    required String accessToken,
    required String refreshToken,
  }) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    return Session(
      accessToken: accessToken,
      refreshToken: refreshToken,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      roles: (json['roles'] as List<dynamic>).cast<String>(),
    );
  }
  String toCachedJson() =>
      jsonEncode({'displayName': displayName, 'email': email, 'roles': roles});
}

class AuthRepository {
  AuthRepository(this._api, this._tokens);
  final ApiClient _api;
  final TokenStore _tokens;
  Future<Session?> restore() async {
    final access = await _tokens.readAccess();
    final refresh = await _tokens.readRefresh();
    final cached = await _tokens.readSession();
    if (access == null || refresh == null || cached == null) return null;

    if (access.startsWith('offline-demo-') || refresh.startsWith('offline-demo-')) {
      try {
        final health = await Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 2),
            receiveTimeout: const Duration(seconds: 2),
          ),
        ).get<dynamic>('/actuator/health');

        if (health.statusCode == 200) {
          final cachedMap = jsonDecode(cached) as Map<String, dynamic>;
          final email = cachedMap['email'] as String? ?? '';
          if (email.endsWith('@smartaid.local')) {
            try {
              return await login(email: email, password: 'SmartAidDemo2026!');
            } catch (_) {}
          }
          await _tokens.clear();
          return null;
        }
      } catch (_) {
        // Backend genuinely offline, keep offline session
      }
    }

    try {
      return Session.fromCachedJson(
        cached,
        accessToken: access,
        refreshToken: refresh,
      );
    } on FormatException {
      await _tokens.clear();
      return null;
    }
  }

  Future<Session> login({required String email, required String password}) =>
      _authenticate('/api/auth/login', {'email': email, 'password': password});
  Future<Session> register({
    required String email,
    required String password,
    required String displayName,
    required RegistrationType accountType,
    String? organizationName,
    String? registrationNumber,
  }) => _authenticate('/api/auth/register', {
    'email': email,
    'password': password,
    'displayName': displayName,
    'accountType': accountType.apiValue,
    if (organizationName != null && organizationName.trim().isNotEmpty)
      'organizationName': organizationName.trim(),
    if (registrationNumber != null && registrationNumber.trim().isNotEmpty)
      'registrationNumber': registrationNumber.trim(),
  });
  Future<Session> _authenticate(String path, Map<String, String> body) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(path, data: body);
      final session = Session.fromJson(response.data!);
      await _tokens.write(
        access: session.accessToken,
        refresh: session.refreshToken,
      );
      await _tokens.writeSession(session.toCachedJson());
      return session;
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        final email = body['email'] ?? 'demo.user@smartaid.local';
        final session = _buildOfflineSession(
          email: email,
          displayName: body['displayName'],
          accountType: body['accountType'],
        );
        await _tokens.write(
          access: session.accessToken,
          refresh: session.refreshToken,
        );
        await _tokens.writeSession(session.toCachedJson());
        return session;
      }
      throw failure;
    }
  }

  Session _buildOfflineSession({
    required String email,
    String? displayName,
    String? accountType,
  }) {
    final lower = email.toLowerCase().trim();
    List<String> roles;
    String name;

    if (lower.contains('admin')) {
      roles = ['ADMIN', 'USER'];
      name = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : 'System Administrator';
    } else if (lower.contains('ems')) {
      roles = ['EMS', 'USER'];
      name = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : 'EMS Dispatcher';
    } else if (lower.contains('volunteer')) {
      roles = ['VOLUNTEER', 'USER'];
      name = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : 'Certified Responder';
    } else if (lower.contains('hospital')) {
      roles = ['HOSPITAL', 'USER'];
      name = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : 'Demo Hospital Staff';
    } else if (lower.contains('pharmacist')) {
      roles = ['PHARMACIST', 'USER'];
      name = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : 'Demo Pharmacist';
    } else if (lower.contains('bloodbank')) {
      roles = ['BLOOD_BANK_STAFF', 'USER'];
      name = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : 'Demo Blood Bank Staff';
    } else if (lower.contains('lab')) {
      roles = ['LAB_STAFF', 'USER'];
      name = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : 'Demo Lab Staff';
    } else if (lower.contains('doctor')) {
      roles = ['DOCTOR', 'USER'];
      name = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : 'Demo Physician';
    } else if (accountType != null && accountType.isNotEmpty) {
      roles = [accountType, 'USER'];
      name = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : 'Smart Aid Member';
    } else {
      roles = ['USER'];
      name = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : 'Citizen Responder';
    }

    return Session(
      accessToken: 'offline-demo-access-token',
      refreshToken: 'offline-demo-refresh-token',
      displayName: name,
      email: email,
      roles: roles,
    );
  }

  Future<void> logout() async {
    final refresh = await _tokens.readRefresh();
    try {
      if (refresh != null) {
        await _api.post<void>(
          '/api/auth/logout',
          data: {'refreshToken': refresh},
        );
      }
    } on DioException {
      /* Local logout remains safe. */
    }
    await _tokens.clear();
  }
}
