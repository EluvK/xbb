class TextSimilarityHasher {
  static int computeSimHash(String text) {
    if (text.isEmpty) return 0;

    List<String> features = [];
    for (int i = 0; i < text.length - 2; i++) {
      features.add(text.substring(i, i + 3));
    }
    if (features.isEmpty) features = text.split('');

    List<int> bitWeights = List.filled(64, 0);

    for (var feature in features) {
      int hash = _stringHash64(feature);

      for (int i = 0; i < 64; i++) {
        if (((hash >> i) & 1) == 1) {
          bitWeights[i]++;
        } else {
          bitWeights[i]--;
        }
      }
    }

    int fingerprint = 0;
    for (int i = 0; i < 64; i++) {
      if (bitWeights[i] > 0) {
        fingerprint |= (1 << i);
      }
    }
    return fingerprint;
  }

  static int getHammingDistance(int hash1, int hash2) {
    int xor = hash1 ^ hash2;
    int distance = 0;
    while (xor != 0) {
      xor &= (xor - 1);
      distance++;
    }
    return distance;
  }

  static int _stringHash64(String input) {
    var hash = 0xcbf29ce484222325; // FNV offset basis
    for (var i = 0; i < input.length; i++) {
      hash ^= input.codeUnitAt(i);
      hash *= 0x100000001b3; // FNV prime
    }
    return hash;
  }

  // import 'package:crypto/crypto.dart';
  // static int _stringHash64(String input) {
  //   // 使用 SHA-256 并取前 8 字节
  //   var bytes = sha256.convert(utf8.encode(input)).bytes;
  //   var result = 0;
  //   for (var i = 0; i < 8; i++) {
  //     result = (result << 8) | bytes[i];
  //   }
  //   return result;
  // }
}
