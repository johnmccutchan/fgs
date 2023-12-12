const String headerKeyTargetOS = 'flutter-golden-target-os';
const String headerKeyTargetOSVersion = 'flutter-golden-target-os-version';
const String headerKeyTargetModel = 'flutter-golden-target-model';
const String headerKeyImagePath = 'flutter-golden-image-path';
const String headerKeyOperation = 'flutter-golden-operation';

const String requestOperationUpdate = 'update';
const String requestOperationCompare = 'compare';

/**
 * - Write server UI that shows pending diffs (based on last run), allow for lazy 'apply'.
 * - Create diff images and surface them in UI
 */
