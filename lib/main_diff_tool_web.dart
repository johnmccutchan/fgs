import 'src/diff_tool/ui.dart';
import 'src/diff_tool/service/web.dart';

void main() {
  const clientPort = String.fromEnvironment('fgs.serverPort');
  final serverUri = Uri(
    scheme: 'http',
    host: 'localhost',
    port: int.parse(clientPort),
  );

  runDiffTool(service: WebDiffToolService(serverUri));
}
