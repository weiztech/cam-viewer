import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;

import '../models/host.dart';

/// RTSP channel discovery via a single unauthenticated DESCRIBE per channel.
///
/// Most DVRs respond to an unauthenticated DESCRIBE with:
///   401  — channel exists  (server is asking us to authenticate)
///   200  — channel exists  (no auth required)
///   404  — channel does not exist
///   503  — channel does not exist / unavailable
///
/// We never need to complete authentication for discovery — the 401 alone
/// tells us the channel is present.
class RtspService {
  static const int _maxChannels = 18;
  static const Duration _connectTimeout = Duration(seconds: 3);
  static const Duration _readTimeout = Duration(seconds: 4);
  static const int _batchSize = 4;

  // ── Public API ────────────────────────────────────────────────────────────

  static Future<List<int>> discoverChannels(
    Host host, {
    void Function(int checked, int total)? onProgress,
  }) async {
    debugPrint('[RTSP] ── Starting discovery for: ${host.displayHost} ──');

    final active = <int>[];
    int checked = 0;

    for (var start = 1; start <= _maxChannels; start += _batchSize) {
      final end = (start + _batchSize - 1).clamp(1, _maxChannels);
      final batch = List.generate(end - start + 1, (i) => start + i);

      final results = await Future.wait(
        batch.map((ch) async {
          final url = host.buildStreamUrl(ch, highRes: false);
          final isActive = await _probeChannel(url, channel: ch);
          onProgress?.call(++checked, _maxChannels);
          return isActive ? ch : null;
        }),
      );
      active.addAll(results.whereType<int>());
    }

    active.sort();
    debugPrint('[RTSP] ── Discovery done. Active channels: $active ──');
    return active;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  static Future<bool> _probeChannel(String url, {required int channel}) async {
    final uri = Uri.parse(url);
    final host = uri.host;
    final port = uri.hasPort && uri.port > 0 ? uri.port : 554;

    // Credentials must not appear in the request-URI.
    final cleanUrl = uri.replace(userInfo: '').toString();

    debugPrint('[RTSP] ch$channel → probing $host:$port');

    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: _connectTimeout);

      socket.write(
        'DESCRIBE $cleanUrl RTSP/1.0\r\n'
        'CSeq: 1\r\n'
        'Accept: application/sdp\r\n'
        '\r\n',
      );

      final buffer = StringBuffer();
      final completer = Completer<String?>();

      socket.listen(
        (data) {
          buffer.write(String.fromCharCodes(data.where((b) => b < 128)));
          if (buffer.toString().contains('\r\n\r\n') &&
              !completer.isCompleted) {
            completer.complete(buffer.toString());
            socket?.destroy();
          }
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(null);
          socket?.destroy();
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(null);
        },
        cancelOnError: true,
      );

      final response = await completer.future.timeout(
        _readTimeout,
        onTimeout: () {
          socket?.destroy();
          return null;
        },
      );

      if (response == null) {
        debugPrint('[RTSP] ch$channel → no response / timeout');
        return false;
      }

      final statusMatch = RegExp(r'RTSP/\S+\s+(\d+)').firstMatch(response);
      final status = int.tryParse(statusMatch?.group(1) ?? '') ?? 0;
      debugPrint('[RTSP] ch$channel ← ${response.split('\r\n').first}');

      // 200 = OK (no auth needed)  → channel exists
      // 401 = Unauthorized         → channel exists, auth required
      // Anything else (404, 503…)  → channel does not exist
      final active = status == 200 || status == 401;
      debugPrint('[RTSP] ch$channel → active=$active (status $status)');
      return active;
    } on SocketException catch (e) {
      debugPrint('[RTSP] ch$channel → socket error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[RTSP] ch$channel → error: $e');
      return false;
    } finally {
      socket?.destroy();
    }
  }
}
