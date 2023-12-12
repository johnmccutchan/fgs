import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:fgs/golden_host.dart';

void serveBuildFile(String buildRoot, HttpRequest request) {
  final String normalizedPath = request.requestedUri.path == '/'
      ? 'index.html'
      : request.requestedUri.path;
  final String filePath = path.join(buildRoot, normalizedPath);
  print('serving ${filePath}');
  File file = File(filePath);
  if (!file.existsSync()) {
    request.response.statusCode = HttpStatus.notFound;
    request.response.write('Not found');
    request.response.close();
    return;
  }
  file.openRead().pipe(request.response).catchError((e) {
    print('failed to pipe file ${filePath} as HTTP response: $e');
  });
}

main() async {
  Directory current = Directory.current;
  Directory? projectRoot;
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
    return;
  }
  String buildRoot = path.join(projectRoot.path, 'build', 'web');
  var server = await HttpServer.bind(InternetAddress.loopbackIPv4, 9999);

  print('Golden server root=${projectRoot.path}');
  print('Golden server http=${server.address.host}:${server.port}');
  // TODO(johnmccutchan): Automatically invoke 'adb reverse tcp:9999 tcp:9999'.
  print('you may need to run adb reverse tcp:9999 tcp:9999');

  var goldenServer = GoldenServer(projectRoot.path);

  await for (var request in server) {
    if (request.method == 'GET') {
      if (request.requestedUri.path != '/serve_image') {
        serveBuildFile(buildRoot, request);
      } else {
        print('TODO serve image: ${request.requestedUri.path}');
      }
    } else if (request.method == 'POST') {
      final List<Uint8List> responses = await request.toList();
      if (responses.length != 1) {
        print('got malformed response: ${responses.length} should be 1');
        request.response.write("error");
        request.response.close();
        continue;
      }
      final Uint8List imageBytes = responses[0];
      final Map<String, String> params = Map<String, String>();
      request.headers.forEach((String name, List<String> values) {
        if (!name.startsWith('flutter-golden')) {
          // Ignore params we aren't interested in.
          return;
        }
        if (values.length != 1) {
          // We don't expect any values with length > 1.
          return;
        }
        params[name] = values[0];
      });
      if (params.isEmpty) {
        print('got malformed request -- missing params');
        request.response.write("error");
        request.response.close();
        continue;
      }
      print('params = $params');
      final GoldenRequest goldenRequest = GoldenRequest(params, imageBytes);
      final bool r = await goldenServer.processRequest(goldenRequest);
      request.response.write(r ? 'true' : 'false');
      request.response.close();
    } else {
      print('ignoring request with unknown HTTP method: ${request.method}');
    }
  }
}
