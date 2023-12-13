import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart';
import 'package:path/path.dart' as path;
import 'package:fgs/src/golden_shared.dart' as shared;
import 'package:fgs/src/golden_comparator.dart';

class GoldenRequest {
  final Map<String, String> _params;
  final Uint8List imageBytes;
  GoldenRequest(this._params, this.imageBytes);

  String _getString(String key) {
    String? value = _params[key];
    if (value == null) {
      return '';
    }
    return value;
  }

  String get operation {
    return _getString(shared.headerKeyOperation);
  }

  String get goldenPath {
    return path.join(
        _getString(shared.headerKeyTargetOS),
        _getString(shared.headerKeyTargetOSVersion),
        _getString(shared.headerKeyTargetModel),
        _getString(shared.headerKeyImagePath));
  }

  @override
  String toString() {
    return 'GoldenRequest: op=$operation imageBytes#=${imageBytes.length}';
  }
}

class GoldenServer {
  final GoldenComparator _comparator = GoldenComparatorImpl();
  final Map<Uri, GoldenComparatorResult> _results = {};
  final String _rootDirectory;
  final Directory tempDirectory;

  GoldenServer(this._rootDirectory, this.tempDirectory);

  Uri _getGoldenFileUri(GoldenRequest request) {
    final String goldenPath = path.join(existingGoldenBasePath, request.goldenPath);
    return Uri.file(goldenPath);
  }

  String get existingGoldenBasePath {
    return path.join(_rootDirectory, 'integration_test',
        'flutter_goldens');
  }

  Future<bool> processRequest(GoldenRequest request) async {
    Uri goldenUri = _getGoldenFileUri(request);
    switch (request.operation) {
      case shared.requestOperationCompare:
        {
          final GoldenComparatorResult result =
              await _comparator.compare(request.imageBytes, goldenUri);
          _results[goldenUri] = result;
          {
            // Write out images so we can show a diff viewer.
            File(path.join(tempDirectory.path, request.goldenPath))
              ..createSync(recursive: true)
              ..writeAsBytesSync(request.imageBytes);
          }
          return result.matches;
        }
      case shared.requestOperationUpdate:
        {
          await _comparator.update(goldenUri, request.imageBytes);
          return true;
        }
      default:
        throw UnimplementedError(request.operation);
    }
  }
}
