import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fgs/golden_host.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:path/path.dart' as path;

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
      var process = await Process.start('flutter', <String>[
        'run',
        '-d',
        'macos',
        '-t',
        'lib/main_diff_tool.dart',
        '-a ${goldenServer.tempDirectory.absolute.path}',
        '-a ${path.absolute(goldenServer.existingGoldenBasePath)}',
      ]);
      await process.exitCode;

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
