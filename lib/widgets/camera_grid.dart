import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/camera_slot.dart';

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

  // Mobile: always 2 columns, 16:9 cells, scrollable
  Widget _buildMobile() {
    return ColoredBox(
      color: const Color(0xFF0D0D0D),
      child: GridView.builder(
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 16 / 9,
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

class _CameraCellState extends State<_CameraCell> {
  Player? _player;
  VideoController? _controller;

  @override
  void initState() {
    super.initState();
    _startStream(widget.slot?.streamUrl);
  }

  @override
  void didUpdateWidget(_CameraCell old) {
    super.didUpdateWidget(old);
    final oldUrl = old.slot?.streamUrl;
    final newUrl = widget.slot?.streamUrl;
    if (oldUrl != newUrl) {
      _disposePlayer();
      _startStream(newUrl);
      setState(() {});
    }
  }

  void _startStream(String? url) {
    if (url == null) return;
    _player = Player();
    _controller = VideoController(_player!);
    _player!.open(Media(url));
  }

  void _disposePlayer() {
    _player?.dispose();
    _player = null;
    _controller = null;
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
    );
  }
}
