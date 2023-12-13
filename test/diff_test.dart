import 'package:fgs/diff.dart';
import 'package:test/test.dart';
import 'package:image/image.dart';

void main() {
  group('color diff', () {
    test('matching colors', () {
      Color a = ColorUint8.rgba(255, 0, 0, 255);
      Color b = ColorUint8.rgba(255, 0, 0, 255);
      expect(diffColor(a, b), equals(matchColor));
    });
    test('max color diff', () {
      Color a = ColorUint8.rgba(255, 255, 255, 255);
      Color b = ColorUint8.rgba(0, 0, 0, 0);
      expect(diffColor(a, b), equals(maxDiffColor));
    });
    test('alpha diff', () {
      Color a = ColorUint8.rgba(255, 0, 0, 255);
      Color b = ColorUint8.rgba(255, 0, 0, 254);
      expect(diffColor(a, b), equals(pixelAlphaDiffColorTable[0]));
    });
  });
  group('image diff', () {
    test('correct size', () {
      Image a = Image(width: 1, height: 1, numChannels: 4);
      Image b = Image(width: 2, height: 2, numChannels: 4);
      Image r = diffImage(a, b).diff;
      expect(r.width, equals(2));
      expect(r.height, equals(2));
      r = diffImage(b, a).diff;
      expect(r.width, equals(2));
      expect(r.height, equals(2));
    });

    test('match', () {
      Image a = Image(width: 2, height: 2, numChannels: 4);
      Image b = Image(width: 2, height: 2, numChannels: 4);
      for (final pixel in a) {
        pixel.setRgba(255, 0, 0, 255);
      }
      for (final pixel in b) {
        pixel.setRgba(255, 0, 0, 255);
      }
      final diff = diffImage(a, b);
      expect(diff.percentDifferent, equals(0.0));
      for (final pixel in diff.diff) {
        expect(pixel, equals(matchColor));
      }
    });

    test('diff', () {
      Image a = Image(width: 2, height: 2, numChannels: 4);
      Image b = Image(width: 2, height: 2, numChannels: 4);
      for (final pixel in a) {
        pixel.setRgba(255, 0, 0, 255);
      }
      for (final pixel in b) {
        pixel.setRgba(0, 255, 0, 255);
      }
      final diff = diffImage(a, b);
      expect(diff.percentDifferent, equals(100.0));
      for (final pixel in diff.diff) {
        expect(pixelDiffColorTable, contains(pixel));
      }
    });
  });
}
