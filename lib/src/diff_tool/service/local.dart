import 'dart:io' as io;

import 'package:fgs/golden_approval.dart';
import 'package:image/image.dart';

import 'base.dart';

/// Local implementation of [DiffToolService] that uses `dart:io` APIs.
final class LocalDiffToolService extends DiffToolService {
  /// See [DiffToolBootstrap.goldenPath].
  final String goldenPath;

  /// See [DiffToolBootstrap.lastRunPath].
  final String lastRunPath;

  LocalDiffToolService({
    required this.goldenPath,
    required this.lastRunPath,
  });

  @override
  Future<DiffToolBootstrap> list() async {
    return DiffToolBootstrap(
      goldenPath: goldenPath,
      lastRunPath: lastRunPath,
      pairs: await findGoldenPairs(goldenPath, lastRunPath),
    );
  }

  @override
  Future<Image> load(String path) async {
    return decodeImage(io.File(path).readAsBytesSync())!;
  }

  @override
  Future<void> approve(List<GoldenFilePair> pairs) async {
    // Approving means copying the updated golden file to the canonical golden.
    await Future.wait(pairs.map((pair) async {
      await io.File(pair.updatedPath).copy(pair.canonicalPath);
    }));
  }
}
