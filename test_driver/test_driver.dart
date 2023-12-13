import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fgs/golden_host.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:path/path.dart' as path;

const List<int> kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x06, 0x62, 0x4B,
  0x47, 0x44, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0xA0, 0xBD, 0xA7, 0x93, 0x00,
  0x00, 0x00, 0x09, 0x70, 0x48, 0x59, 0x73, 0x00, 0x00, 0x0B, 0x13, 0x00, 0x00,
  0x0B, 0x13, 0x01, 0x00, 0x9A, 0x9C, 0x18, 0x00, 0x00, 0x00, 0x07, 0x74, 0x49,
  0x4D, 0x45, 0x07, 0xE6, 0x03, 0x10, 0x17, 0x07, 0x1D, 0x2E, 0x5E, 0x30, 0x9B,
  0x00, 0x00, 0x00, 0x0B, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0x60, 0x00,
  0x02, 0x00, 0x00, 0x05, 0x00, 0x01, 0xE2, 0x26, 0x05, 0x9B, 0x00, 0x00, 0x00,
  0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

GoldenServer setupGoldenServer() {
  Directory current = Directory.current;
  Directory? projectRoot;
  final Directory tempDirectory = Directory.systemTemp.createTempSync('golden_comparisons');

  while (current.path != current.parent.path) {
    File pubspec = File(path.join(current.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      projectRoot = current;
      break;
    }
    current = current.parent;
  }
  if (projectRoot == null) {
    print('Could not find pubspec.yaml in ${Directory.current.path}');
    exit(1);
  }
  return GoldenServer(projectRoot.path, tempDirectory);
}

final GoldenServer goldenServer = setupGoldenServer();

void main() async {
  final FlutterDriver driver = await FlutterDriver.connect();
  List<StreamSubscription> subscriptions = <StreamSubscription>[];

  subscriptions.add(driver.serviceClient.onExtensionEvent.listen((event) async {
    if (event.extensionKind == 'fgs.golden') {
      final Map<String, Object?> extensionData = event.extensionData!.data;
      final Uint8List imageBytes = base64.decode(extensionData['bytes']! as String);
      final Map<String, String> params = (extensionData['golden_params']! as Map<Object?, Object?>).cast<String, String>();
      final GoldenRequest goldenRequest = GoldenRequest(params, imageBytes);
      final bool result = await goldenServer.processRequest(goldenRequest);

      driver.serviceClient.callServiceExtension('ext.fgs.screenshot', args: {
        'parameters': json.encode({
          'id': extensionData['id'] as int,
          'result': result,
        }),
      }, isolateId: event.isolate!.id);
    }

    if (event.extensionKind == 'fgs.done') {
      // Once all tests are finished, we can pop open a browser/flutter app
      // and show the diffs. This exit call can block on the acceptance.
      final HttpServer server = await HttpServer.bind(InternetAddress.loopbackIPv4, 9999);
      server.listen((HttpRequest request) async {
        // Return the set of all golden keys.
        if (request.method == 'GET' && request.uri.path == '/list-images') {
          request.response.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
          request.response.write(json.encode(<String, Object?>{
            'pairs': [
              for (var key in goldenServer.getAllKeys())
                <String, Object?>{
                  'canonicalPath': path.join(goldenServer.existingGoldenBasePath, key),
                  'goldenPath': path.join(goldenServer.tempDirectory.path, key),
                },
            ],
          }));
        } else if (request.method == 'POST' && request.uri.path == '/image') {
          final File file = File(await request.map(utf8.decoder.convert).join());
          request.response.headers.set(HttpHeaders.contentTypeHeader, 'image/png');
          request.response.add(file.existsSync() ? await file.readAsBytes() : kTransparentImage);
        }
        await request.response.close();
      });

      var process = await Process.start('flutter', <String>[
        'run',
        '-d',
        'chrome',
        '-t',
        'lib/main_diff_tool_web.dart',
        '--web-browser-flag=--disable-web-security',
        '--dart-define=fgs.serverPort=${server.port}'
      ]);
      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(print);
      process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(print);

      // Shutdown.
      await process.exitCode;
      await server.close();
      goldenServer.tempDirectory.deleteSync(recursive: true);
      for (var subscription in subscriptions) {
        await subscription.cancel();
      }
      await driver.close();
    }
  }));

  // TODO: this might be flaky, change code so that we don't unpause app isolate
  // until this setup is complete. Possible by adding hook to FlutterDriver
  // connect.
  await Future.wait([
    driver.serviceClient.streamListen('Extension'),
  ]);
}
