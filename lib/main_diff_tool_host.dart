import 'dart:io' as io;

import 'src/diff_tool/ui.dart';
import 'src/diff_tool/service/local.dart';

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
