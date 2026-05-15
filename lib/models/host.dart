import 'dart:math';

class Host {
  const Host({
    required this.id,
    required this.rawInput,
    this.username = '',
    this.password = '',
    this.activeChannels = const [],
  });

  /// Unique identifier (random hex).
  final String id;

  /// Exactly what the user typed, e.g. "192.168.0.101:554/cam/realmonitor"
  /// or just "192.168.0.101" or "192.168.0.101:8554/live/ch1".
  final String rawInput;

  final String username;
  final String password;

  /// Channel numbers (1-18) that responded to RTSP DESCRIBE.
  final List<int> activeChannels;

  // ── Computed ──────────────────────────────────────────────────────────────

  /// Just the IP/hostname, lower-cased, no port, no path, no protocol.
  /// Used for duplicate-host detection.
  String get hostname {
    var s = rawInput.trim().toLowerCase();
    if (s.contains('://')) s = s.split('://').last;
    s = s.split('/').first; // drop path
    s = s.split(':').first; // drop port
    return s;
  }

  /// "host:port" (or just "host" if no port was given).  Used for display.
  String get displayHost {
    var s = rawInput.trim();
    if (s.contains('://')) s = s.split('://').last;
    return s.split('/').first; // keep port, drop path
  }

  // ── URL construction ─────────────────────────────────────────────────────

  /// Build a full-resolution RTSP URL for [channel] (subtype=0).
  ///
  /// Rules:
  /// 1. Strip any leading "rtsp://" the user may have typed.
  /// 2. If the input contains a "/" after the host:port part, treat it as a
  ///    full path and use it as-is.
  /// 3. If no path is present, append the default ":554/cam/realmonitor".
  /// 4. Prepend credentials if username is non-empty.
  /// 5. Append `?channel=<channel>&subtype=0`.
  String buildStreamUrl(int channel) {
    const subtype = 0;

    var input = rawInput.trim();
    // Strip explicit protocol prefix if user typed it
    if (input.toLowerCase().startsWith('rtsp://')) {
      input = input.substring(7);
    }

    final String hostPort;
    final String path;

    final slashIdx = input.indexOf('/');
    if (slashIdx != -1) {
      // User supplied a path, e.g. "192.168.0.101:8554/live/ch1"
      hostPort = input.substring(0, slashIdx);
      path = input.substring(slashIdx); // includes leading '/'
    } else {
      // No path: use defaults
      if (input.contains(':')) {
        hostPort = input; // already has port
      } else {
        hostPort = '$input:554'; // default RTSP port
      }
      path = '/cam/realmonitor';
    }

    final credPart = _credentialPrefix;
    return 'rtsp://$credPart$hostPort$path?channel=$channel&subtype=$subtype';
  }

  String get _credentialPrefix {
    if (username.isNotEmpty && password.isNotEmpty) {
      return '$username:$password@';
    }
    if (username.isNotEmpty) return '$username@';
    return '';
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  Host copyWith({
    String? rawInput,
    String? username,
    String? password,
    List<int>? activeChannels,
  }) => Host(
    id: id,
    rawInput: rawInput ?? this.rawInput,
    username: username ?? this.username,
    password: password ?? this.password,
    activeChannels: activeChannels ?? this.activeChannels,
  );

  /// Generate a random 16-byte hex string to use as a unique id.
  static String generateId() {
    final rng = Random.secure();
    return List.generate(
      16,
      (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
