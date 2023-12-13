# fgs

Flutter Golden Server

## Getting started

### Server

Start the server and forward the port from the device:

```$ dart run bin/golden_server```
```$ adb reverse tcp:9999 tcp:9999```

### Test

In your `integration/foo_test.dart` add the following:

```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  goldenFileComparator = HostGoldenFileComparator();
  ...
}
```

## Design Sketch

- Driver script acts as server
- Driver script writes test images to temporary directory
- Target communicates with driver script over vm:service protocol
- Diff tool is a Flutter app (desktop or browser based)
- Diff tool approves / skips image deltas.

### Old

Server process running on host machine has following features:
  - Modes:
    - Local: Receive test images from target device and determine if they match the goldens held on the host.
    - CI: Fetch test images from CI server.
  - Provide a UI for the developer to ACK/NACK the latest test images.
  - Write images into host filesystem after being ACKed.
  - Golden images are written under `integration_test/flutter_goldens/$OS/$OS_VERSION/$MODEL/$IMAGE_NAME`.

Server process running on CI machine has the following features:
  - Receive test images from target device and determine if they match the goldens held in the repository.
  - Collect images that have diffs.
  - Export these images on demand.

Target library has the following features:
   - Provides a new goldenFileComparator that talks to the server.

## TODO

- Make it possible to run diff app in the browser
  - driver protocol needs to manage file I/O on behalf of browser
- Diff app features:
  - Magnify tool
  - Periodic toggle between golden and test image
- Add a platform view test case
- Selector and tap support for Android Views
- How can we enable the same test to run inside of google3
  - Target code runs the same vm:service protocol but google3 driver talks with scuba
