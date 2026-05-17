import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/camera_slot.dart';
import 'keyboard_focus_ring_mixin.dart';

/// Low-latency MPV properties shared by every player (grid + fullscreen).
/// Does NOT mute audio — callers that want silence add `'audio': 'no'`.
const kRtspLowLatencyProps = {
  // ── Transport ────────────────────────────────────────────────────────────
  // UDP: no TCP retransmit stalls, no head-of-line blocking.
  // reorder_queue_size=0: drop the RTP jitter buffer entirely – a late UDP
  // packet is useless for live view, so just discard it immediately.
  //
  // NOTE: setProperty replaces demuxer-lavf-o entirely.
  'demuxer-lavf-o': 'rtsp_transport=udp,reorder_queue_size=0,fflags=+nobuffer',
  'demuxer-lavf-analyzeduration': '0', // probe stream for 0.1 s, not 5 s
  // ── Cache / read-ahead ──────────────────────────────────────────────────
  // demuxer-max-bytes is intentionally omitted here — it is set (along with
  // demuxer-max-back-bytes) via PlayerConfiguration(bufferSize: 512 KB).
  'cache': 'no', // no ring-buffer, always at live edge
  'demuxer-readahead-secs': '0', // don't pre-read ahead of current PTS
  // ── Decoder ─────────────────────────────────────────────────────────────
  'vd-lavc-o': 'flags=+low_delay', // no B-frame reorder + no thread pipeline
  // ── Presentation ────────────────────────────────────────────────────────
  //'video-sync': 'desync', // render frame the moment it is decoded
  //'framedrop': 'vo', // drop at display if decoder ever lags
};

int _columnsFor(int count) {
  switch (count) {
    case 4:
      return 2;
    case 6:
      return 3;
    case 8:
      return 4;
    case 16:
      return 4;
    case 18:
      return 6;
    default:
      return 2;
  }
}

class CameraGrid extends StatelessWidget {
  const CameraGrid({
    super.key,
    required this.slots,
    required this.isMobile,
    this.onCellTap,
  });

  /// One entry per grid cell; null means the cell is empty.
  final List<CameraSlot?> slots;
  final bool isMobile;

  /// Called with the grid index when a cell is tapped.
  final void Function(int index)? onCellTap;

  int get _layoutCount => slots.length;

  @override
  Widget build(BuildContext context) {
    return isMobile ? _buildMobile() : _buildDesktop();
  }

  // Mobile: 1 column, each camera fills the full screen width at 16:9, scrollable
  Widget _buildMobile() {
    return ColoredBox(
      color: const Color(0xFF0D0D0D),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: slots.length,
        itemBuilder: (context, index) {
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: _CameraCell(
              slot: slots[index],
              position: index + 1,
              onTap: onCellTap != null ? () => onCellTap!(index) : null,
            ),
          );
        },
      ),
    );
  }

  // Desktop: fills all available space, no scroll
  Widget _buildDesktop() {
    final cols = _columnsFor(_layoutCount);
    final rows = (_layoutCount / cols).ceil();
    const gap = 4.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = (constraints.maxWidth - (cols - 1) * gap) / cols;
        final cellH = (constraints.maxHeight - (rows - 1) * gap) / rows;
        return ColoredBox(
          color: const Color(0xFF0D0D0D),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
              childAspectRatio: cellW / cellH,
            ),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              return _CameraCell(
                slot: slots[index],
                position: index + 1,
                onTap: onCellTap != null ? () => onCellTap!(index) : null,
              );
            },
          ),
        );
      },
    );
  }
}

// ── Camera cell ───────────────────────────────────────────────────────────────

class _CameraCell extends StatefulWidget {
  const _CameraCell({required this.slot, required this.position, this.onTap});

  final CameraSlot? slot;
  final int position;
  final VoidCallback? onTap;

  @override
  State<_CameraCell> createState() => _CameraCellState();
}

class _CameraCellState extends State<_CameraCell> with KeyboardFocusRingMixin {
  Player? _player;
  VideoController? _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
    _startStream(widget.slot?.fullResUrl);
  }

  @override
  void didUpdateWidget(_CameraCell old) {
    super.didUpdateWidget(old);
    final oldUrl = old.slot?.fullResUrl;
    final newUrl = widget.slot?.fullResUrl;
    if (oldUrl != newUrl) {
      _disposePlayer();
      _startStream(newUrl);
      setState(() {});
    }
  }

  // Grid cells mute audio to eliminate A/V sync stall; fullscreen keeps it.
  static const _kLowLatencyProps = {...kRtspLowLatencyProps, 'audio': 'no'};

  Future<void> _startStream(String? url) async {
    if (url == null) return;
    _player = Player(
      configuration: const PlayerConfiguration(bufferSize: 524288),
    );
    _controller = VideoController(_player!);
    final native = _player!.platform as NativePlayer;
    for (final e in _kLowLatencyProps.entries) {
      await native.setProperty(e.key, e.value);
    }
    if (mounted) _player!.open(Media(url));
  }

  void _disposePlayer() {
    _player?.dispose();
    _player = null;
    _controller = null;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      // autofocus: widget.position == 1,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onTap?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border.all(color: Colors.grey.shade800, width: 1),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_controller != null)
                Video(
                  controller: _controller!,
                  fill: Colors.black,
                  controls: null,
                )
              else
                const Center(
                  child: Icon(
                    Icons.videocam_outlined,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
              // Semi-transparent overlay for labels
              Positioned(
                top: 4,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  color: Colors.black45,
                  child: Text(
                    widget.slot?.label ?? 'EMPTY',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 6,
                child: Text(
                  '#${widget.position}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
