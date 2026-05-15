import '../models/host.dart';

/// Web stub for RtspService.
///
/// Browsers cannot open raw TCP connections, so RTSP discovery is not
/// possible on Flutter Web.  All calls immediately return an empty list.
class RtspService {
  /// Always returns [] on web — RTSP requires raw TCP which browsers block.
  static Future<List<int>> discoverChannels(
    Host host, {
    void Function(int checked, int total)? onProgress,
  }) async {
    // Signal all 18 "checked" instantly so any progress UI completes cleanly.
    for (var i = 1; i <= 18; i++) {
      onProgress?.call(i, 18);
    }
    return [];
  }
}
