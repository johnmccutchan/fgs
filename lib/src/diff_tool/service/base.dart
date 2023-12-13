import 'package:fgs/golden_approval.dart';
import 'package:image/image.dart';

/// Configuration for how the initialize the diff tool.
final class DiffToolBootstrap {
  /// Where the golden files are located.
  ///
  /// On an initial run of a newly authored test, this directory may be blank
  /// or contain only a few golden files. On subsequent runs, this directory
  /// will contain all the golden files within [lastRunPath].
  final String goldenPath;

  /// Where the last run's golden files are located.
  final String lastRunPath;

  /// The pairs of golden files found in [goldenPath] and [lastRunPath].
  ///
  /// See [GoldenFilePair] for more information.
  final List<GoldenFilePair> pairs;

  /// Initializes the diff tool with path and pair information.
  DiffToolBootstrap({
    required this.goldenPath,
    required this.lastRunPath,
    required this.pairs,
  });
}

/// Service API for the diff tool.
///
/// As a desktop app, the tool is able to load and make changes to files
/// synchronously. However, the APIs are still asynchronous to allow for a
/// server-side implementation with a web UI.
abstract base class DiffToolService {
  /// Loads the golden file pairs from [goldenPath] and [lastRunPath].
  Future<DiffToolBootstrap> list();

  /// Loads the image at [path].
  ///
  /// It is an error o load a non-image file, or a file that lives outside of
  /// [DiffToolBootstrap.goldenPath] or [DiffToolBootstrap.lastRunPath].
  Future<Image> load(String path);

  /// Approves the golden file pairs in [pairs].
  ///
  /// In practice, this copies the updated golden file to the canonical golden
  /// file, making changes to the golden files on disk.
  Future<void> approve(List<GoldenFilePair> pairs);
}
