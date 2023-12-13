/// Domain logic for reviewing and approving updates to golden files.
///
/// See [findGoldenPairs] to get started.
library;

import 'dart:io' as io;

import 'package:meta/meta.dart';

/// A pair of [canonical] and [updated] golden files.
///
/// ## Equality
///
/// Two [GoldenFilePair]s are equal if their [canonical] and [updated] files
/// are pointing to the same exact file paths.
@immutable
final class GoldenFilePair {
  /// The canonical golden file, i.e. the one that is checked in.
  final io.File canonical;

  /// The updated golden file, i.e. the one that is generated by a test run.
  final io.File updated;

  /// Creates a new [GoldenFilePair] from [canonical] and [updated].
  ///
  /// Throws an error if:
  /// - [canonical] and [updated] refer to the same exact file path
  GoldenFilePair.uncheckedAssumeExists(this.canonical, this.updated) {
    if (canonical.path == updated.path) {
      throw ArgumentError.value(
        canonical,
        'canonical',
        'must not be the same file as updated',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is GoldenFilePair &&
      other.canonical.path == canonical.path &&
      other.updated.path == updated.path;

  @override
  int get hashCode => Object.hash(canonical.path, updated.path);

  @override
  String toString() => 'GoldenFilePair($canonical, $updated)';
}

/// Finds all golden file pairs in [canonicalPath] and [updatedPath].
///
/// Throws an error if:
/// - [canonicalPath] or [updatedPath] do not exist
/// - [canonicalPath] or [updatedPath] are not directories
/// - [canonicalPath] does not have a corresponding file in [updatedPath]
///
/// For example, if you have a directory structure like this:
/// ```txt
/// /path
///   /to
///     /goldens
///       a.png
///       b.png
///
/// /tmp
///  /goldens
///    a.png
///    b.png
/// ```
///
/// Then you would call `findGoldenPairs` like this:
/// ```dart
/// final pairs = await findGoldenPairs(
///   '/path/to/goldens',
///   '/tmp/goldens',
/// );
/// ```
Future<List<GoldenFilePair>> findGoldenPairs(
  String canonicalPath,
  String updatedPath,
) async {
  // Ensure the paths exist and are directories.
  final canonicalDir = io.Directory(canonicalPath);
  if (!await canonicalDir.exists()) {
    throw ArgumentError.value(
      canonicalPath,
      'canonicalPath',
      'must exist',
    );
  }

  final updatedDir = io.Directory(updatedPath);
  if (!await updatedDir.exists()) {
    throw ArgumentError.value(
      updatedPath,
      'updatedPath',
      'must exist',
    );
  }

  // Load the golden file pairs.
  final pairs = <GoldenFilePair>[];
  await for (final canonical in canonicalDir.list(recursive: true)) {
    if (canonical is! io.File) {
      continue;
    }

    // Determine what the path to the updated file should be given.
    final expectedPath = canonical.path.replaceFirst(
      canonicalPath,
      updatedPath,
    );
    final updated = io.File(expectedPath);
    if (!await updated.exists()) {
      throw StateError(
        'Could not find updated golden file for canonical file: $canonical',
      );
    }

    pairs.add(GoldenFilePair.uncheckedAssumeExists(canonical, updated));
  }

  return pairs;
}
