import 'dart:async';
import 'dart:convert';
import 'package:cryptography/cryptography.dart' show PublicKey, KeyPairType, SimplePublicKey;

import 'token_storage.dart';

class InMemoryTokenStorage implements TokenStorage {
  String? _userId;
  String? _access;
  String? _refresh;
  DateTime? _accessExpiry;
  DateTime? _refreshExpiry;
  PublicKey? _hpkePubKey;

  @override
  Future<String?> getAccessToken() async {
    if (_access == null) return null;
    if (_accessExpiry != null && DateTime.now().isAfter(_accessExpiry!)) {
      return null;
    }
    return _access;
  }

  @override
  Future<String?> getRefreshToken() async {
    if (_refresh == null) return null;
    if (_refreshExpiry != null && DateTime.now().isAfter(_refreshExpiry!)) {
      return null;
    }
    return _refresh;
  }

  @override
  String? getUserId() {
    return _userId;
  }

  @override
  void setUserId(String userId) {
    _userId = userId;
  }

  @override
  Future<void> setAccessToken(String token, {DateTime? expiry}) async {
    _access = token;
    _accessExpiry = expiry;
  }

  @override
  Future<void> setRefreshToken(String token, {DateTime? expiry}) async {
    _refresh = token;
    _refreshExpiry = expiry;
  }

  @override
  Future<void> setHpkePubKey(String pubKeyBase64) async {
    final bytes = base64Decode(pubKeyBase64);
    _hpkePubKey = SimplePublicKey(bytes, type: KeyPairType.x25519);
  }

  @override
  Future<PublicKey?> getHpkePubKey() {
    return Future.value(_hpkePubKey);
  }

  @override
  Future<void> clear() async {
    _userId = null;
    _access = null;
    _refresh = null;
    _accessExpiry = null;
    _refreshExpiry = null;
  }
}
