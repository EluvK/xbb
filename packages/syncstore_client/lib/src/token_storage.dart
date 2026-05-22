import 'dart:async';

import 'package:cryptography/cryptography.dart' show PublicKey;

/// Token storage abstraction.
///
/// Implementations:
/// - InMemoryTokenStorage (provided)
/// - FileTokenStorage / FlutterSecureStorage-based (implement yourself)
abstract class TokenStorage {
  Future<void> setAccessToken(String token, {DateTime? expiry});
  Future<String?> getAccessToken();
  Future<void> setRefreshToken(String token, {DateTime? expiry});
  Future<String?> getRefreshToken();
  void setUserId(String userId);
  String? getUserId();
  Future<void> setHpkePubKey(String pubKeyBase64);
  Future<PublicKey?> getHpkePubKey();
  Future<void> clear();
}
