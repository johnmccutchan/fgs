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

### Code changes

- Better image diffing algorithm (see https://github.com/google/skia-buildbot/blob/main/golden/go/diff/diff.go)

- Frontend server support:
  - Ability to fetch set of images from CI server.
  - UI to display and inspect image diffs.

- Backend server support:
  - Some sort of session key (git repository, branch, commit\_hash) so that the frontend server can fetch their specific set of images.
  - Export test images that have diffs.

### Workflow changes

This is mostly victory lap stuff.

- We currently stop running tests on the first golden image fail, would be better to run all of them and deal with the diffs as a batch.
- flutter tool should spawn the backend and frontend servers
  - block test command from exiting until user requests it.
