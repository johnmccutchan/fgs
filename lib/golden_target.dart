import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:flutter_test/flutter_test.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fgs/src/golden_shared.dart' as shared;

class HostGoldenFileComparator implements GoldenFileComparator {
  final Uri serverUri = Uri.parse("http://127.0.0.1:9999");
  final HttpClient client = HttpClient();

  @override
  Uri getTestUri(Uri key, int? version) {
    if (version == null) {
      return key;
    }
    final String keyString = key.toString();
    final String extension = path.extension(keyString);
    return Uri.parse('${keyString.split(extension).join()}.$version$extension');
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final bool matched =
        await postRequest(golden, imageBytes, shared.requestOperationCompare);
    return matched;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    await postRequest(golden, imageBytes, shared.requestOperationUpdate);
  }

  Future<bool> postRequest(
      Uri golden, Uint8List bytes, String requestOperation) async {
    final request = await client.postUrl(serverUri);
    // Parameters for the request.
    request.headers.add(shared.headerKeyImagePath, golden.toFilePath());
    final String model = await _modelName();
    final String os = await _os();
    final String osVersion = await _osVersion();
    request.headers.add(shared.headerKeyTargetModel, model);
    request.headers.add(shared.headerKeyTargetOS, os);
    request.headers.add(shared.headerKeyTargetOSVersion, osVersion);
    request.headers.add(shared.headerKeyOperation, requestOperation);

    // Body of response is the bytes of the image.
    request.add(bytes);
    final response = await request.close();
    final responseData = await response.transform(utf8.decoder).join();
    return responseData == 'true';
  }

  Future<String> _modelName() async {
    final DeviceInfoPlugin plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final AndroidDeviceInfo deviceInfo = await plugin.androidInfo;
      return deviceInfo.model;
    }
    throw UnimplementedError('_modelName');
  }

  Future<String> _osVersion() async {
    final DeviceInfoPlugin plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final AndroidDeviceInfo deviceInfo = await plugin.androidInfo;
      return '${deviceInfo.version.sdkInt}';
    }
    throw UnimplementedError('_osVersion');
  }

  Future<String> _os() async {
    if (Platform.isAndroid) {
      return 'android';
    }
    throw UnimplementedError('_os');
  }
}
