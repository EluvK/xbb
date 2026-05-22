/// NOTE:
///
/// Given the fact that dart/flutter ecosystem lacks a complete HPKE implementation as of now,
/// This file contains a partial implementation of HPKE (Hybrid Public Key Encryption)
/// according to RFC 9180. **But** it is NOT a complete implementation of the standard.
///
/// Only the necessary parts to support the SyncStore client's use case are implemented here.
/// which is "Base Mode" HPKE with X25519 KEM, HKDF-SHA256 KDF, and AES-256-GCM AEAD.
/// and only serves the once-pre-requested encryption/decryption(the nonce sequence is always 0).
///
/// Take no responsibility for any security issues arising from incomplete or incorrect implementation.
/// So please use with caution and at your own risk.
/// Read the RFC 9180 for more details: https://www.rfc-editor.org/rfc/rfc9180.html

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';

Uint8List concat(List<Uint8List> parts) {
  final length = parts.fold(0, (a, b) => a + b.length);
  final out = Uint8List(length);
  var offset = 0;
  for (final p in parts) {
    out.setRange(offset, offset + p.length, p);
    offset += p.length;
  }
  return out;
}

Uint8List xorBytes(Uint8List a, Uint8List b) {
  if (a.length != b.length) {
    throw ArgumentError('xorBytes length mismatch: ${a.length} vs ${b.length}');
  }
  final out = Uint8List(a.length);
  for (var i = 0; i < a.length; i++) {
    out[i] = a[i] ^ b[i];
  }
  return out;
}

Uint8List encodeSeqForNonce(int seq, int nonceLength) {
  final out = Uint8List(nonceLength);
  final b = ByteData(8);
  b.setUint64(0, seq, Endian.big);
  out.setRange(nonceLength - 8, nonceLength, b.buffer.asUint8List());
  return out;
}

final Uint8List suiteId = Uint8List.fromList([
  ...utf8.encode("HPKE"),
  0x00, 0x20, // KEM ID: 32 (X25519)
  0x00, 0x01, // KDF ID: 1  (HKDF-SHA256)
  0x00, 0x02, // AEAD ID: 2 (AES-256-GCM)
]);
final Uint8List kemSuiteId = Uint8List.fromList([
  ...utf8.encode("KEM"),
  0x00, 0x20, // KEM ID: 32 (X25519)
]);

Uint8List publicKeyBytes(PublicKey pk) {
  if (pk is SimplePublicKey) {
    return Uint8List.fromList(pk.bytes);
  }
  throw ArgumentError('Unsupported PublicKey type: ${pk.runtimeType}');
}

class HpkeKdf {
  static final _hmac = Hmac.sha256();
  static const int _hashLength = 32; // SHA256 length

  /// RFC 9180 §4.3 labeledExtract
  static Future<Uint8List> labeledExtract(Uint8List? salt, String label, Uint8List ikm, Uint8List suiteId) async {
    final labeledIkm = concat([utf8.encode("HPKE-v1"), suiteId, utf8.encode(label), ikm]);
    final effectiveSalt = salt ?? Uint8List(_hashLength);
    final mac = await _hmac.calculateMac(labeledIkm, secretKey: SecretKey(effectiveSalt));
    return Uint8List.fromList(mac.bytes);
  }

  /// RFC 9180 §4.3 labeledExpand
  static Future<Uint8List> labeledExpand(
    Uint8List prk,
    String label,
    Uint8List info,
    int length,
    Uint8List suiteId,
  ) async {
    final lenBuf = ByteData(2)..setUint16(0, length, Endian.big);
    final labeledInfo = concat([
      lenBuf.buffer.asUint8List(),
      utf8.encode("HPKE-v1"),
      suiteId,
      utf8.encode(label),
      info,
    ]);
    return _manualExpand(prk, labeledInfo, length);
  }

  static Future<Uint8List> _manualExpand(Uint8List prk, Uint8List info, int length) async {
    final n = (length / _hashLength).ceil();
    var okm = <int>[];
    var t = Uint8List(0);

    for (var i = 1; i <= n; i++) {
      final input = concat([
        t,
        info,
        Uint8List.fromList([i]),
      ]);
      final mac = await _hmac.calculateMac(input, secretKey: SecretKey(prk));
      t = Uint8List.fromList(mac.bytes);
      okm.addAll(t);
    }
    return Uint8List.fromList(okm.sublist(0, length));
  }
}

class X25519Kem {
  static final _dh = X25519();

  Future<SimpleKeyPair> newKeyPair() async {
    return await _dh.newKeyPair();
  }

  static Future<(Uint8List enc, Uint8List sharedSecret)> encap(PublicKey recipientPub) async {
    final kpE = await _dh.newKeyPair();
    final pkE = await kpE.extractPublicKey();
    final pkEBytes = Uint8List.fromList(pkE.bytes);
    final pkRBytes = Uint8List.fromList((recipientPub as SimplePublicKey).bytes);

    final sharedKey = await _dh.sharedSecretKey(keyPair: kpE, remotePublicKey: recipientPub);
    final zz = Uint8List.fromList(await sharedKey.extractBytes());
    final kemContext = concat([pkEBytes, pkRBytes]);

    // RFC 9180 Section 4.1: ExtractAndExpand
    final prk = await HpkeKdf.labeledExtract(null, "eae_prk", zz, kemSuiteId);
    final sharedSecret = await HpkeKdf.labeledExpand(prk, "shared_secret", kemContext, 32, kemSuiteId); // SHA256 length

    return (pkEBytes, sharedSecret);
  }

  static Future<Uint8List> decap(Uint8List enc, KeyPair recipientKeyPair, PublicKey recipientPub) async {
    final pkE = SimplePublicKey(enc, type: KeyPairType.x25519);

    final sharedKey = await _dh.sharedSecretKey(keyPair: recipientKeyPair, remotePublicKey: pkE);
    final zz = Uint8List.fromList(await sharedKey.extractBytes());
    final pkRBytes = Uint8List.fromList((recipientPub as SimplePublicKey).bytes);
    final kemContext = concat([enc, pkRBytes]);

    final prk = await HpkeKdf.labeledExtract(null, "eae_prk", zz, kemSuiteId);
    final sharedSecret = await HpkeKdf.labeledExpand(prk, "shared_secret", kemContext, 32, kemSuiteId);

    return sharedSecret;
  }
}

class HpkeKeyScheduleResult {
  final Uint8List key;
  final Uint8List baseNonce;
  HpkeKeyScheduleResult(this.key, this.baseNonce);
}

Future<HpkeKeyScheduleResult> keySchedule({required Uint8List sharedSecret, required Uint8List info}) async {
  final emptyBytes = Uint8List(0);
  final pskIdHash = await HpkeKdf.labeledExtract(null, "psk_id_hash", emptyBytes, suiteId);
  final infoHash = await HpkeKdf.labeledExtract(null, "info_hash", info, suiteId);

  final keyScheduleContext = concat([
    Uint8List.fromList([0x00]), // Mode: base
    pskIdHash,
    infoHash,
  ]);

  final secret = await HpkeKdf.labeledExtract(sharedSecret, "secret", emptyBytes, suiteId);
  final key = await HpkeKdf.labeledExpand(secret, "key", keyScheduleContext, 32, suiteId);
  final nonce = await HpkeKdf.labeledExpand(secret, "base_nonce", keyScheduleContext, 12, suiteId);

  return HpkeKeyScheduleResult(key, nonce);
}

class HpkeContext {
  final Uint8List key;
  final Uint8List baseNonce;
  int seq = 0;

  HpkeContext(this.key, this.baseNonce);

  Uint8List computeNonce() {
    final seqBytes = encodeSeqForNonce(seq, baseNonce.length);
    return xorBytes(baseNonce, seqBytes);
  }
}

class HpkeBase {
  final _aead = AesGcm.with256bits();
  static final _info = Uint8List.fromList("syncstore hpke v1".codeUnits);

  Future<(Uint8List enc, Uint8List ciphertext)> seal({
    required Uint8List plaintext,
    required PublicKey recipientPub,
    // required Uint8List info,
    required Uint8List aad,
  }) async {
    final (enc, sharedSecret) = await X25519Kem.encap(recipientPub);
    final ks = await keySchedule(sharedSecret: sharedSecret, info: _info);
    final ctx = HpkeContext(ks.key, ks.baseNonce);
    final nonce = ctx.computeNonce();

    final box = await _aead.encrypt(plaintext, secretKey: SecretKey(ks.key), nonce: nonce, aad: aad);
    return (enc, Uint8List.fromList([...box.cipherText, ...box.mac.bytes]));
  }

  Future<Uint8List> open({
    required Uint8List enc,
    required Uint8List ciphertext,
    required KeyPair recipientKeyPair,
    required PublicKey recipientPub,
    // required Uint8List info,
    required Uint8List aad,
  }) async {
    final sharedSecret = await X25519Kem.decap(enc, recipientKeyPair, recipientPub);
    final ks = await keySchedule(sharedSecret: sharedSecret, info: _info);
    final ctx = HpkeContext(ks.key, ks.baseNonce);
    final nonce = ctx.computeNonce();

    final ct = ciphertext.sublist(0, ciphertext.length - 16);
    final tag = ciphertext.sublist(ciphertext.length - 16);

    final secretBox = SecretBox(ct, nonce: nonce, mac: Mac(tag));
    final plaintext = await _aead.decrypt(secretBox, secretKey: SecretKey(ks.key), aad: aad);

    return Uint8List.fromList(plaintext);
  }
}

PublicKey decodePublicKey(String base64Key) {
  final bytes = base64Decode(base64Key);
  return SimplePublicKey(bytes, type: KeyPairType.x25519);
}

class HpkeInterceptor extends Interceptor {
  final HpkeBase _hpke = HpkeBase();
  final PublicKey serverPublicKey;

  HpkeInterceptor(this.serverPublicKey);

  // store/share the session key pair for each request
  final _keyState = Expando<KeyPair>();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['secureHpke'] != true) {
      print("HpkeInterceptor/onRequest: skipping encryption for ${options.method} ${options.path}");
      return handler.next(options);
    }
    print("HpkeInterceptor/onRequest: encrypting request for ${options.method} ${options.path}");

    options.extra['__raw_data'] ??= options.data;

    try {
      // 1. generate a session unique key pair for this request
      // put the public key into header, keep the private key for response decryption
      // the server will use this public key to encrypt the response
      final sessionKeyPair = await X25519().newKeyPair();
      final sessionPublicKey = await sessionKeyPair.extractPublicKey();
      _keyState[options] = sessionKeyPair; // 暂存私钥

      // 2. encrypt the request body
      final aad = utf8.encode('/api' + Uri.parse(options.path).path);
      final payload = options.data is List<int> ? options.data : utf8.encode(jsonEncode(options.data));

      final result = await _hpke.seal(plaintext: payload, recipientPub: serverPublicKey, aad: aad);
      print("HpkeInterceptor/onRequest: request encrypted done: length ${result.$2.length} bytes");

      // 3. set headers according to Rust logic
      options.headers['X-Enc'] = base64Encode(result.$1); // encapsulated public key
      options.headers['X-Session-PubKey'] = base64Encode(sessionPublicKey.bytes);
      options.data = result.$2;
      options.headers['Content-Type'] = 'application/octet-stream';
      handler.next(options);
    } catch (e) {
      print("HpkeInterceptor/onRequest: encryption error: $e");
      handler.reject(DioException(requestOptions: options, error: "Encryption failed: $e"));
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (response.requestOptions.extra['secureHpke'] != true) {
      print("HpkeInterceptor/onResponse: skipping decryption for ${response.requestOptions.path}");
      return handler.next(response);
    }
    print("HpkeInterceptor/onResponse: decrypting response[${response.statusCode}]:${response.requestOptions.path}");

    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! <= 299) {
      final KeyPair? sessionKeyPair = _keyState[response.requestOptions];
      final String? encKeyB64 = response.headers.value('X-Enc');
      final aad = utf8.encode('/api' + Uri.parse(response.requestOptions.path).path);
      if (sessionKeyPair != null && encKeyB64 != null && response.data != null) {
        try {
          final sessionPublicKey = await sessionKeyPair.extractPublicKey();
          final encKey = SimplePublicKey(base64Decode(encKeyB64), type: KeyPairType.x25519);
          final ciphertext = response.data;

          Uint8List decrypted = await _hpke.open(
            enc: Uint8List.fromList(encKey.bytes),
            ciphertext: ciphertext,
            recipientKeyPair: sessionKeyPair,
            recipientPub: sessionPublicKey,
            aad: aad,
          );

          response.data = jsonDecode(utf8.decode(decrypted));
          response.requestOptions.headers['Content-Type'] = 'application/json';
        } catch (e) {
          print("HpkeInterceptor/onResponse: decryption error: $e");
          return handler.reject(DioException(requestOptions: response.requestOptions, error: "Decryption failed: $e"));
        }
      }
    }
    handler.next(response);
  }
}
