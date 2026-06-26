import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum MicPermissionOutcome { granted, denied, permanentlyDenied }

/// Requests Android/iOS microphone permission before Zego voice publish.
Future<bool> ensureMicrophonePermission() async {
  final outcome = await requestMicrophonePermission();
  return outcome == MicPermissionOutcome.granted;
}

Future<MicPermissionOutcome> requestMicrophonePermission() async {
  var status = await Permission.microphone.status;
  if (status.isGranted) return MicPermissionOutcome.granted;

  status = await Permission.microphone.request();
  if (status.isGranted) return MicPermissionOutcome.granted;

  debugPrint('[Mic] permission denied: $status');
  if (status.isPermanentlyDenied || status.isRestricted) {
    return MicPermissionOutcome.permanentlyDenied;
  }
  return MicPermissionOutcome.denied;
}

String micPermissionMessage(MicPermissionOutcome outcome) {
  switch (outcome) {
    case MicPermissionOutcome.granted:
      return '';
    case MicPermissionOutcome.denied:
      return 'Allow microphone access to talk on voice calls.';
    case MicPermissionOutcome.permanentlyDenied:
      return 'Microphone is blocked. Open Settings → App → Permissions → Microphone → Allow.';
  }
}

Future<void> openMicrophoneSettings() => openAppSettings();

/// Prompt for microphone when the app opens — before the first call.
Future<void> prefetchMicrophonePermissionOnLaunch() async {
  final status = await Permission.microphone.status;
  if (status.isGranted) return;
  if (status.isPermanentlyDenied || status.isRestricted) {
    debugPrint('[Mic] launch prefetch skipped — enable microphone in Settings');
    return;
  }
  await Permission.microphone.request();
}
