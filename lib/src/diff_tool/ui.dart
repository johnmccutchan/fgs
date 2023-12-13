import 'package:fgs/diff.dart';
import 'package:fgs/golden_approval.dart';
import 'package:fgs/src/diff_tool/service/base.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Runs the UI for the diff tool.
///
/// This method is expected to be called from a `main()` method.
///
/// For example, on a desktop (host):
/// ```dart
/// void main(List<String> arguments) async {
///   await runDiffTool(
///     service: LocalDiffToolService(
///       goldenPath: arguments[0],
///       lastRunPath: arguments[1],
///     ),
///   );
/// }
/// ```
///
/// On the web (or possibly, just a remote host in general):
/// ```dart
/// void main() async {
///   // Get the server URI from query paramters, environment variables, etc.
///   final serverUri = getServerUriFromSomewhere();
///   await runDiffTool(
///     service: WebDiffToolService(serverUri),
///   );
/// }
/// ```
void runDiffTool({
  required DiffToolService service,
}) {
  runApp(_DiffToolList(service: service));
}

/// The UI-side of [GoldenFilePair], which includes decoded and diffed images.
@immutable
final class GoldenDiffPair {
  /// The canonical golden file.
  final GoldenFilePair pair;

  /// The decoded image of [pair.canonicalPath].
  ///
  /// If [pair.isNew], then this is `null`.
  final img.Image? canonicalImage;

  /// The decoded image of [pair.updatedPath].
  final img.Image updatedImage;

  /// The diff between [canonicalImage] and [updatedImage].
  final img.Image diffedImage;

  /// The diff score between [canonicalImage] and [updatedImage].
  final double diffScore;

  /// Creates a new [GoldenDiffPair] from the provided images.
  ///
  /// See [loadWith] for a way to populate these images from a [service].
  const GoldenDiffPair({
    required this.pair,
    required this.canonicalImage,
    required this.updatedImage,
    required this.diffedImage,
    required this.diffScore,
  });

  /// Loads the golden file pair with [service] and computes the diff.
  static Future<GoldenDiffPair> loadWith(
    GoldenFilePair pair,
    DiffToolService service,
  ) async {
    // Load both the canonical and updated images.
    final [canonicalImage, updatedImage] = await Future.wait([
      pair.isNew ? Future.value() : service.load(pair.canonicalPath),
      service.load(pair.updatedPath),
    ]);

    // If it was new, then the canonical image is null.
    if (pair.isNew) {
      return GoldenDiffPair(
        pair: pair,
        canonicalImage: null,
        updatedImage: updatedImage,
        diffedImage: updatedImage,
        diffScore: 100,
      );
    }

    // Compute the diff.
    final diffResult = diffImage(canonicalImage, updatedImage);
    return GoldenDiffPair(
      pair: pair,
      canonicalImage: canonicalImage,
      updatedImage: updatedImage,
      diffedImage: diffResult.diff,
      diffScore: diffResult.percentDifferent,
    );
  }

  @override
  String toString() => 'GoldenDiffPair($pair | $diffScore)';
}

final class _DiffToolList extends StatefulWidget {
  final DiffToolService service;

  const _DiffToolList({
    required this.service,
  });

  @override
  State<_DiffToolList> createState() => _DiffToolListState();
}

final class _DiffToolListState extends State<_DiffToolList> {
  /// The golden files and their images/diffs.
  ///
  /// If this is `null`, then the app is still loading.
  late Future<List<GoldenDiffPair>> _pairs;
  final Set<GoldenFilePair> _approved = {};

  late int _loadedPairs;
  Duration? _loadAndDiffTime;

  @override
  void initState() {
    super.initState();
    loadState();
  }

  void loadState() {
    final stopwatch = Stopwatch()..start();
    _pairs = widget.service.list().then((bootstrap) {
      return Future.wait(bootstrap.pairs.map((pair) {
        return GoldenDiffPair.loadWith(pair, widget.service);
      })).then((pairs) {
        setState(() {
          _loadedPairs = pairs.length;
          _loadAndDiffTime = stopwatch.elapsed;
        });
        return pairs;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Golden Diff Tool',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Golden Diff Tool'),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reload'),
                onPressed: loadState,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.commit),
                label: const Text('Commit'),
                onPressed: () {
                  widget.service.approve(_approved.toList());
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _loadAndDiffTime != null
                ? Text(
                    'Loaded and diffed $_loadedPairs golden files in '
                    '${_loadAndDiffTime!.inMilliseconds}ms',
                  )
                : const Text('Loading...'),
          ),
        ),
        body: FutureBuilder<List<GoldenDiffPair>>(
          future: _pairs,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(snapshot.error.toString() +
                    (snapshot.stackTrace?.toString() ?? '')),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final pairs = snapshot.data!;
            return ListView.separated(
              itemCount: pairs.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final pair = pairs[index];
                return ListTile(
                  title: Text(pair.pair.canonicalPath),
                  leading: Image.memory(
                    img.encodePng(pair.diffedImage),
                    width: 100,
                    height: 100,
                  ),
                  subtitle: pair.pair.isNew
                      ? const Text('Newly Added')
                      : Text(pair.diffScore.toStringAsFixed(2)),
                  trailing: _approved.contains(pair.pair)
                      ? const Icon(Icons.check)
                      : const Icon(Icons.question_mark),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return _DiffDecisionView(
                            pair: pair,
                            onToggleApproval: () {
                              setState(() {
                                if (!_approved.add(pair.pair)) {
                                  _approved.remove(pair.pair);
                                }
                              });
                            },
                            wasApproved: _approved.contains(pair.pair),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

final class _DiffDecisionView extends StatelessWidget {
  final GoldenDiffPair pair;
  final void Function() onToggleApproval;
  final bool wasApproved;

  const _DiffDecisionView({
    required this.pair,
    required this.onToggleApproval,
    required this.wasApproved,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pair.pair.canonicalPath),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: wasApproved
                  ? const Icon(Icons.close)
                  : const Icon(Icons.check),
              label: wasApproved ? const Text('Reject') : const Text('Approve'),
              onPressed: () {
                onToggleApproval();
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
      // Show a table with 3 columns:
      // Canonical | Diff  | Updated
      // <img>     | <img> | <img>
      body: Table(
        children: [
          TableRow(
            children: [
              const ListTile(
                title: Text('Canonical'),
                subtitle: Text('Checked into source control'),
              ),
              ListTile(
                title: const Text('Diffed'),
                subtitle: Text('${pair.diffScore.toStringAsFixed(2)}%'),
              ),
              const ListTile(
                title: Text('Updated'),
                subtitle: Text('Generated by the last test run'),
              ),
            ],
          ),
          TableRow(
            children: [
              pair.canonicalImage != null
                  ? _DiffImage(image: pair.canonicalImage!)
                  : SizedBox(
                      width: pair.updatedImage.width.toDouble(),
                      height: pair.updatedImage.height.toDouble() / 2,
                      child: const Center(
                        child: Text(
                          'Newly Added',
                        ),
                      ),
                    ),
              _DiffImage(image: pair.diffedImage),
              _DiffImage(image: pair.updatedImage),
            ],
          ),
        ],
      ),
    );
  }
}

final class _DiffImage extends StatelessWidget {
  final img.Image image;

  const _DiffImage({
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    // A vertical column with the header and the image.
    // The image is centered vertically but the header is always at the top.
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.memory(
        img.encodePng(image),
        fit: BoxFit.contain,
      ),
    );
  }
}
