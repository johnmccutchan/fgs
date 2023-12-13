import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:fgs/golden_approval.dart';
import 'package:image/image.dart';

import 'base.dart';

typedef _JsonList<T> = List<T>;
typedef _JsonMap<V> = Map<String, V>;

/// Web implementation of [DiffToolService] that uses `dart:html` APIs.
final class WebDiffToolService extends DiffToolService {
  final Uri serverUri;

  WebDiffToolService(this.serverUri);

  static GoldenFilePair _fromJson(Object? data) {
    final Map<String, Object?> typed = data as Map<String, Object?>;
    return GoldenFilePair.uncheckedAssumeExists(
      typed['canonicalPath'] as String,
      typed['goldenPath'] as String,
    );
  }

  @override
  Future<DiffToolBootstrap> list() async {
    final request = await html.HttpRequest.request(
      serverUri.resolve('list-images').toString(),
      method: 'GET',
    );

    // If the server returns an error, throw it.
    if (request.status != 200) {
      throw Exception(request.responseText);
    }

    final data = json.decode(request.response as String) as Map<String, Object?>;
    return DiffToolBootstrap(
      goldenPath: 'a',
      lastRunPath: 'b',
      pairs: (data['pairs'] as List<Object?>).map(_fromJson).toList(),
    );
  }

  @override
  Future<Image> load(String path) async {
    final request = await html.HttpRequest.request(
      serverUri.resolve('image').toString(),
      method: 'POST',
      sendData: path,
      responseType: 'arraybuffer',
    );

    // If the server returns an error, throw it.
    if (request.status != 200) {
      throw Exception(request.responseText);
    }

    final bytes = request.response as ByteBuffer;
    return decodeImage(bytes.asUint8List())!;
  }

  @override
  Future<void> approve(List<GoldenFilePair> pairs) async {
    // Make a POST request to the server with the list of pairs to approve.
    final List<Object?> data = pairs.map((pair) {
      return {
        'canonicalPath': pair.canonicalPath,
        'updatedPath': pair.updatedPath,
      };
    }).toList();

    final request = await html.HttpRequest.request(
      serverUri.resolve('approve').toString(),
      method: 'POST',
      sendData: json.encode(data),
    );

    // If the server returns an error, throw it.
    if (request.status != 200) {
      throw Exception(request.responseText);
    }
  }
}
