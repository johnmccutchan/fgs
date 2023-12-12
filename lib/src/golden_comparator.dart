import 'dart:typed_data';
import 'dart:io';
import 'package:image/image.dart';

abstract class GoldenComparatorResult {
  bool get matches;
  Image? get goldenImage;
  Image? get testImage;
  Image? get diffImage;
  double get diffPercent;
}

abstract class GoldenComparator {
  // Compares the pixels of decoded png imageBytes against the golden file identified by golden.
  Future<GoldenComparatorResult> compare(Uint8List imageBytes, Uri golden);
  // Updates the golden file identified by golden with imageBytes.
  Future<void> update(Uri golden, Uint8List imageBytes);
}

class GoldenComparatorResultImpl implements GoldenComparatorResult {
  final Uri _golden;
  Image? _goldenImage;
  Image? _testImage;
  Image? _diffImage;
  double _diffPercent = 0.0;
  String _explanation = 'matches';

  GoldenComparatorResultImpl(this._golden);

  @override
  bool get matches {
    return _diffPercent == 0.0;
  }

  // The golden image.
  @override
  Image? get goldenImage {
    return _goldenImage;
  }

  // The test image.
  @override
  Image? get testImage {
    return _testImage;
  }

  // The difference between golden and test.
  @override
  Image? get diffImage {
    return _diffImage;
  }

  @override
  double get diffPercent {
    return _diffPercent;
  }

  @override
  String toString() {
    return 'Golden "${_golden.toFilePath()}" $_explanation';
  }
}

// Compares test and golden images.
Future<GoldenComparatorResult> compareImages(
    Uri goldenUri, Image? testImage, Image? goldenImage) async {
  final GoldenComparatorResultImpl result =
      GoldenComparatorResultImpl(goldenUri);

  result._testImage = testImage;
  result._goldenImage = goldenImage;

  if (testImage == null) {
    result._diffPercent = 100.0;
    result._explanation = 'test image could not be decoded';
    return result;
  }

  if (goldenImage == null) {
    result._diffPercent = 100.0;
    result._explanation = 'golden image does not exist';
    return result;
  }

  if (testImage.width != goldenImage.width ||
      testImage.height != goldenImage.height) {
    result._diffPercent = 100.0;
    result._explanation =
        'golden image size (${goldenImage.width}x${goldenImage.height}) does not match test image size (${testImage.width}x${testImage.height})';
    return result;
  }

  Image diffImage =
      Image(width: testImage.width, height: testImage.height, numChannels: 4);
  int differentPixelCount = 0;
  for (int x = 0; x < testImage.width; x++) {
    for (int y = 0; y < testImage.height; y++) {
      var testPixel = testImage.getPixel(x, y);
      var goldenPixel = goldenImage.getPixel(x, y);
      final int pixelDiff = (testPixel.r - goldenPixel.r).abs().ceil() +
          (testPixel.g - goldenPixel.g).abs().ceil() +
          (testPixel.b - goldenPixel.b).abs().ceil() +
          (testPixel.a - goldenPixel.a).abs().ceil();
      if (pixelDiff != 0) {
        differentPixelCount++;
        // TODO(johnmccutchan): Populate diff image in a better way.
        diffImage.setPixelRgba(x, y, 255, 0, 0, 255);
      }
    }
  }
  print('diff $differentPixelCount');
  if (differentPixelCount > 0) {
    result._diffImage = diffImage;
    result._diffPercent =
        (differentPixelCount / (diffImage.width * diffImage.height)) * 100.0;
    result._explanation =
        'golden image and test image do not match (${result._diffPercent.toStringAsFixed(2)})';
    return result;
  }
  return result;
}

class GoldenComparatorImpl implements GoldenComparator {
  @override
  Future<GoldenComparatorResult> compare(
      Uint8List imageBytes, Uri golden) async {
    Image? goldenImage;
    try {
      final File goldenFile = File.fromUri(golden);
      goldenImage = await decodeImageFile(goldenFile.path);
    } on FileSystemException catch (_) {
      // Ignore.
    }
    final Image? testImage = decodeImage(imageBytes);
    return compareImages(golden, testImage, goldenImage);
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final File goldenFile = File.fromUri(golden);
    await goldenFile.parent.create(recursive: true);
    await goldenFile.writeAsBytes(imageBytes, flush: true);
    print('${goldenFile.path} was updated.');
  }
}
