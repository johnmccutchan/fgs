import 'dart:io' as io;

import 'package:fgs/golden_approval.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('GoldenFilePair fails if canonical and updated are the same file', () {
    const a = 'foo';
    const b = 'foo';
    expect(
      () => GoldenFilePair(a, b, isNew: false),
      throwsArgumentError,
    );
  });

  test('GoldenFilePair has equality/hashCode support', () {
    const a = 'foo';
    const b = 'bar';
    const c = 'baz';
    const d = 'qux';

    final pair1 = GoldenFilePair(a, b, isNew: false);
    final pair2 = GoldenFilePair(a, b, isNew: false);
    final pair3 = GoldenFilePair(c, d, isNew: false);

    expect(pair1, equals(pair2));
    expect(pair1.hashCode, equals(pair2.hashCode));

    expect(pair1, isNot(equals(pair3)));
    expect(pair1.hashCode, isNot(equals(pair3.hashCode)));
  });

  test('findGoldenPairs fails if canonicalPath does not exist', () {
    // Create a temporary directory that exists for 'updatedPath'.
    final updatedPath = io.Directory.systemTemp.createTempSync('updatedPath');
    addTearDown(() => updatedPath.deleteSync(recursive: true));

    // Ensure the canonical path does not exist.
    final canonicalPath = io.Directory.systemTemp.createTempSync(
      'canonicalPath',
    );
    canonicalPath.deleteSync(recursive: true);

    // Use a non-existent directory for 'canonicalPath'.
    expect(
      () => findGoldenPairs(
        canonicalPath.path,
        updatedPath.path,
      ),
      throwsArgumentError,
    );
  });

  test('findGoldenPairs fails if updatedPath does not exist', () {
    // Create a temporary directory that exists for 'canonicalPath'.
    final canonicalPath = io.Directory.systemTemp.createTempSync(
      'canonicalPath',
    );
    addTearDown(() => canonicalPath.deleteSync(recursive: true));

    // Ensure the updated path does not exist.
    final updatedPath = io.Directory.systemTemp.createTempSync('updatedPath');
    updatedPath.deleteSync(recursive: true);

    // Use a non-existent directory for 'updatedPath'.
    expect(
      () => findGoldenPairs(
        canonicalPath.path,
        updatedPath.path,
      ),
      throwsArgumentError,
    );
  });

  test('findGoldenPairs pairs files across 2 directories', () {
    // Create a temporary directory that exists for 'canonicalPath'.
    final canonicalPath = io.Directory.systemTemp.createTempSync(
      'canonicalPath',
    );
    addTearDown(() => canonicalPath.deleteSync(recursive: true));

    // Create a temporary directory that exists for 'updatedPath'.
    final updatedPath = io.Directory.systemTemp.createTempSync('updatedPath');
    addTearDown(() => updatedPath.deleteSync(recursive: true));

    // Create a file in 'canonicalPath' that exists in 'updatedPath'.
    io.File(p.join(canonicalPath.path, 'foo')).createSync();
    io.File(p.join(updatedPath.path, 'foo')).createSync();

    // Create a file in a nested directory as well.
    io.File(p.join(canonicalPath.path, 'bar', 'baz')).createSync(
      recursive: true,
    );
    io.File(p.join(updatedPath.path, 'bar', 'baz')).createSync(
      recursive: true,
    );

    // And create a file that only exists in 'updatedPath'.
    io.File(p.join(updatedPath.path, 'qux')).createSync();

    final pairs = findGoldenPairs(
      canonicalPath.path,
      updatedPath.path,
    );

    expect(
      pairs,
      completion(
        unorderedEquals([
          GoldenFilePair(
            p.join(canonicalPath.path, 'foo'),
            p.join(updatedPath.path, 'foo'),
            isNew: false,
          ),
          GoldenFilePair(
            p.join(canonicalPath.path, 'bar', 'baz'),
            p.join(updatedPath.path, 'bar', 'baz'),
            isNew: false,
          ),
          GoldenFilePair(
            p.join(canonicalPath.path, 'qux'),
            p.join(updatedPath.path, 'qux'),
            isNew: true,
          ),
        ]),
      ),
    );
  });
}
