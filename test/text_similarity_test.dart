import 'package:test/test.dart';
import 'package:xbb/utils/text_similarity.dart';

void main() {
  group('TextSimilarityHasher', () {
    test('empty string returns 0', () {
      expect(TextSimilarityHasher.computeSimHash(''), equals(0));
    });

    test('same text yields same hash', () {
      final h1 = TextSimilarityHasher.computeSimHash('hello world');
      final h2 = TextSimilarityHasher.computeSimHash('hello world');
      print(h1);
      expect(h1, equals(h2));
    });

    test('small change produces non-zero hamming distance', () {
      final a = TextSimilarityHasher.computeSimHash('hello world');
      final b = TextSimilarityHasher.computeSimHash('hello worlt');
      print('Hash a: $a');
      print('Hash b: $b');
      final d = TextSimilarityHasher.getHammingDistance(a, b);
      expect(d, greaterThan(0));
      expect(d, lessThanOrEqualTo(64));
    });

    test('distance is symmetric and zero for identical', () {
      final x = TextSimilarityHasher.computeSimHash('abc');
      expect(TextSimilarityHasher.getHammingDistance(x, x), equals(0));
      final y = TextSimilarityHasher.computeSimHash('abcd');
      expect(TextSimilarityHasher.getHammingDistance(x, y), equals(TextSimilarityHasher.getHammingDistance(y, x)));
    });

    test('short strings produce non-zero hash', () {
      expect(TextSimilarityHasher.computeSimHash('a'), isNot(equals(0)));
      expect(TextSimilarityHasher.computeSimHash('ab'), isNot(equals(0)));
    });

    test('long text and insert in center', () {
      const start = '''
          Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor.
          Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. 
          Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. 
      ''';
      const modify = '''
          Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor.
          Aenean massa. Maecenas tempus, tellus eget condimentum, nascetur ridiculus mus. 
          Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. 
      ''';
      const someElse = '''
          Different content entirely to test the hash function's sensitivity to changes in text.
          This should yield a significantly different SimHash value compared to the original text.
      ''';
      final hashStart = TextSimilarityHasher.computeSimHash(start);
      final hashModify = TextSimilarityHasher.computeSimHash(modify);
      print('Hash Start: $hashStart');
      print('Hash Modify: $hashModify');
      final distance = TextSimilarityHasher.getHammingDistance(hashStart, hashModify);
      print('Hamming Distance: $distance');
      expect(distance, greaterThan(0));

      final hashElse = TextSimilarityHasher.computeSimHash(someElse);
      print('Hash SomeElse: $hashElse');
      final distanceElse = TextSimilarityHasher.getHammingDistance(hashStart, hashElse);
      print('Hamming Distance to SomeElse: $distanceElse');
    });
  });
}
