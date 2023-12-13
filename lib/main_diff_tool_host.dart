import 'dart:io' as io;

import 'src/diff_tool/ui.dart';
import 'src/diff_tool/service/local.dart';

/// Runs the diff tool as a desktop app.
///
/// ## Example
///
/// ```shell
/// flutter run -d macos -t lib/main_diff_tool_host.dart -a "test/fixtures/goldens" -a "test/fixtures/goldens_example_run"
/// ```
///
/// Note this has not been tested on Windows or Linux.
void main(List<String> args) {
  if (args.length != 2) {
    io.stderr.writeln('Usage: diff_tool <path-to-goldens> <path-to-last-run>');
    io.exit(1);
  }

  // TODO: Assert paths exist.
  final goldenPath = args[0].trim();
  final lastRunPath = args[1].trim();

  runDiffTool(
    service: LocalDiffToolService(
      goldenPath: goldenPath,
      lastRunPath: lastRunPath,
    ),
  );
}
