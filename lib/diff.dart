import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart';

// We only support RGBA uint8 image and pixel formats.
void _validateImageFormat(ImageData? data) {
  if (data == null) {
    throw UnsupportedError("Unknown image format.");
  }
  if (data.numChannels != 4) {
    throw UnsupportedError(
        "Expected 4 channels in image format was ${data.numChannels}");
  }
  if (data.format != Format.uint8) {
    throw UnsupportedError(
        "Expected each channel to be uint8 was ${data.format}");
  }
}

// We only support RGBA uint8 image and pixel formats.
void _validateColorFormat(Color? color) {
  if (color == null) {
    throw UnsupportedError("Unknown color format");
  }
  if (color.length != 4) {
    throw UnsupportedError(
        "Expected 4 channels in color was ${color.maxChannelValue}");
  }
  if (color.format != Format.uint8) {
    throw UnsupportedError(
        "Expected each channel to be uin8 was ${color.format}");
  }
}

// Orange gradient.
//
// These are non-premultiplied RGBA values.
final pixelDiffColorTable = [
  ColorUint8.fromList([0xfd, 0xd0, 0xa2, 0xff]),
  ColorUint8.fromList([0xfd, 0xae, 0x6b, 0xff]),
  ColorUint8.fromList([0xfd, 0x8d, 0x3c, 0xff]),
  ColorUint8.fromList([0xf1, 0x69, 0x13, 0xff]),
  ColorUint8.fromList([0xd9, 0x48, 0x01, 0xff]),
  ColorUint8.fromList([0xa6, 0x36, 0x03, 0xff]),
  ColorUint8.fromList([0x7f, 0x27, 0x04, 0xff])
];

// Blue gradient.
//
// These are non-premultiplied RGBA values.
final pixelAlphaDiffColorTable = [
  ColorUint8.fromList([0xc6, 0xdb, 0xef, 0xff]),
  ColorUint8.fromList([0x9e, 0xca, 0xe1, 0xff]),
  ColorUint8.fromList([0x6b, 0xae, 0xd6, 0xff]),
  ColorUint8.fromList([0x42, 0x92, 0xc6, 0xff]),
  ColorUint8.fromList([0x21, 0x71, 0xb5, 0xff]),
  ColorUint8.fromList([0x08, 0x51, 0x9c, 0xff]),
  ColorUint8.fromList([0x08, 0x30, 0x6b, 0xff])
];

// Returns an index into _pixelDiffColor or _pixelAlphaDiffColor based on
// the input value [n] ranging from 0..1024.
int colorTableIndex(int n) {
  var idx = (math.log(n.toDouble()) / math.log(3) + 0.5).ceil();
  if (idx < 1 || idx > 7) {
    throw UnsupportedError(
        "Invalid raw pixel difference wanted >= 1 && <= 1024 was ${n}");
  }
  return idx - 1;
}

final maxDiffColor = pixelDiffColorTable[colorTableIndex(1024)];
final matchColor = ColorUint8.rgba(0, 0, 0, 0);

// Returns the Pixel encoding the difference between [golden] and [test].
Color diffColor(Color golden, Color test) {
  _validateColorFormat(golden);
  _validateColorFormat(test);

  final rDiff = (golden.r - test.r).abs().toInt();
  final gDiff = (golden.g - test.g).abs().toInt();
  final bDiff = (golden.b - test.b).abs().toInt();
  final aDiff = (golden.a - test.a).abs().toInt();

  // If the color channels differ we mark with the diff color.
  if (rDiff != 0 || gDiff != 0 || bDiff != 0) {
    // We use the Manhattan metric for color difference.
    return pixelDiffColorTable[colorTableIndex(rDiff + gDiff + bDiff + aDiff)];
  }

  if (aDiff != 0) {
    return pixelAlphaDiffColorTable[colorTableIndex(aDiff)];
  }

  return matchColor;
}

class ImageDiffResult {
  final Image? golden;
  final Image? test;
  final Image diff;
  final double percentDifferent;

  ImageDiffResult(this.golden, this.test, this.diff, this.percentDifferent);
}

// Returns the difference between [golden] and [test].
ImageDiffResult diffImage(Image? golden, Image? test) {
  if (golden == null && test == null) {
    return ImageDiffResult(
        golden, test, Image(width: 0, height: 0, numChannels: 4), 0.0);
  }

  golden ??= Image(width: 0, height: 0, format: Format.uint8, numChannels: 4);
  test ??= Image(width: 0, height: 0, format: Format.uint8, numChannels: 4);

  _validateImageFormat(golden.data);
  _validateImageFormat(test.data);

  final int compareWidth = math.min(golden.width, test.width);
  final int compareHeight = math.min(golden.height, test.height);

  final int diffWidth = math.max(golden.width, test.width);
  final int diffHeight = math.max(golden.height, test.height);

  // Create an ARGB image of the correct dimensions.
  final Image diff =
      Image(width: diffWidth, height: diffHeight, numChannels: 4);

  final int totalPixels = diffWidth * diffHeight;
  int diffPixels = 0;

  // Compute the diff.
  for (int x = 0; x < diffWidth; x++) {
    for (int y = 0; y < diffHeight; y++) {
      if (x < compareWidth && y < compareHeight) {
        final pixelDiff = diffColor(golden.getPixel(x, y), test.getPixel(x, y));
        if (pixelDiff != matchColor) {
          diffPixels++;
        }
        diff.setPixel(x, y, pixelDiff);
      } else {
        diffPixels++;
        diff.setPixel(x, y, maxDiffColor);
      }
    }
  }
  final double diffPercent = totalPixels > 0
      ? (diffPixels.toDouble() * 100) / totalPixels.toDouble()
      : 0.0;
  return ImageDiffResult(golden, test, diff, diffPercent);
}
