/// Platform-aware RTSP service.
///
/// On Android/iOS/desktop (dart:io available) → uses real TCP DESCRIBE probes.
/// On web                                     → always returns [] (RTSP is not
///   reachable from a browser; use a native build for camera discovery).
library;

export 'rtsp_service_io.dart' if (dart.library.html) 'rtsp_service_web.dart';
