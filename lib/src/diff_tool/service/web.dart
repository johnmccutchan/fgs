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

  static GoldenFilePair _fromJson(_JsonMap<Object?> json) {
    return GoldenFilePair(
      json['canonicalPath'] as String,
      json['goldenPath'] as String,
      isNew: json['isNew'] as bool,
    );
  }

  @override
  Future<DiffToolBootstrap> list() async {
    final request = await html.HttpRequest.request(
      serverUri.toString(),
      method: 'GET',
    );

    // If the server returns an error, throw it.
    if (request.status != 200) {
      throw Exception(request.responseText);
    }

    final json = request.response as Map<String, Object?>;
    return DiffToolBootstrap(
      goldenPath: json['goldenPath'] as String,
      lastRunPath: json['lastRunPath'] as String,
      pairs: (json['pairs'] as _JsonList<_JsonMap>).map(_fromJson).toList(),
    );
  }

  @override
  Future<Image> load(String path) async {
    final request = await html.HttpRequest.request(
      serverUri.resolve(path).toString(),
      method: 'GET',
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
    final _JsonList<_JsonMap> json = pairs.map((pair) {
      return {
        'canonicalPath': pair.canonicalPath,
        'updatedPath': pair.updatedPath,
      };
    }).toList();

    final request = await html.HttpRequest.request(
      serverUri.toString(),
      method: 'POST',
      sendData: json,
    );

    // If the server returns an error, throw it.
    if (request.status != 200) {
      throw Exception(request.responseText);
    }
  }
}
