import 'host.dart';

/// Represents a single camera channel on a host.
/// Used as the data unit for grid cells and fullscreen view.
class CameraSlot {
  const CameraSlot({required this.host, required this.channel});

  final Host host;

  /// Channel number (1-18).
  final int channel;

  /// Full-resolution stream URL (subtype=0).
  String get fullResUrl => host.buildStreamUrl(channel);

  /// Short human-readable label, e.g. "192.168.0.101 Ch3".
  String get label => '${host.displayHost} Ch$channel';
}
