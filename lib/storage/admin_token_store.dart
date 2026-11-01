import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredAdminToken {
  const StoredAdminToken({
    required this.accessToken,
    required this.expiresAtUtc,
  });
  final String accessToken;
  final DateTime expiresAtUtc;
}

abstract interface class AdminTokenStore {
  Future<StoredAdminToken?> read();
  Future<void> write(StoredAdminToken token);
  Future<void> clear();
}

class SecureAdminTokenStore implements AdminTokenStore {
  SecureAdminTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'bridge_pdx_admin_access_token';
  static const _expirationKey = 'bridge_pdx_admin_token_expiration';
  final FlutterSecureStorage _storage;

  @override
  Future<StoredAdminToken?> read() async {
    final values = await Future.wait([
      _storage.read(key: _tokenKey),
      _storage.read(key: _expirationKey),
    ]);
    final token = values[0];
    final expiration = values[1] == null ? null : DateTime.tryParse(values[1]!);
    if (token == null || expiration == null) {
      if (token != null || values[1] != null) await clear();
      return null;
    }
    return StoredAdminToken(accessToken: token, expiresAtUtc: expiration);
  }

  @override
  Future<void> write(StoredAdminToken token) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token.accessToken),
      _storage.write(
        key: _expirationKey,
        value: token.expiresAtUtc.toUtc().toIso8601String(),
      ),
    ]);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _expirationKey),
    ]);
  }
}
