import 'src/diff_tool/ui.dart';
import 'src/diff_tool/service/web.dart';

/// Runs the diff tool as a web app.
///
/// ## Example
///
/// ```shell
/// # Connect an Android device.
///
/// # Run the integration test on the device.
/// flutter drive --driver test_driver/test_driver.dart -t test_driver/test_app.dart
///
/// # Wait a few seconds for the UI to compile and open.
/// ```
void main() {
  const clientPort = String.fromEnvironment('fgs.serverPort');
  final serverUri = Uri(
    scheme: 'http',
    host: 'localhost',
    port: int.parse(clientPort),
  );

  runDiffTool(service: WebDiffToolService(serverUri));
}
