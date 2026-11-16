import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  TokenStore(this._storage);
  final FlutterSecureStorage _storage;
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _sessionKey = 'session_metadata';

  String? _cachedAccess;
  String? _cachedRefresh;
  String? _cachedSession;

  Future<String?> readAccess() async {
    if (_cachedAccess != null) return _cachedAccess;
    _cachedAccess = await _storage.read(key: _accessKey);
    return _cachedAccess;
  }

  Future<String?> readRefresh() async {
    if (_cachedRefresh != null) return _cachedRefresh;
    _cachedRefresh = await _storage.read(key: _refreshKey);
    return _cachedRefresh;
  }

  Future<void> write({required String access, required String refresh}) async {
    _cachedAccess = access;
    _cachedRefresh = refresh;
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<String?> readSession() async {
    if (_cachedSession != null) return _cachedSession;
    _cachedSession = await _storage.read(key: _sessionKey);
    return _cachedSession;
  }

  Future<void> writeSession(String session) async {
    _cachedSession = session;
    await _storage.write(key: _sessionKey, value: session);
  }

  Future<void> clear() async {
    _cachedAccess = null;
    _cachedRefresh = null;
    _cachedSession = null;
    await _storage.deleteAll();
  }
}
