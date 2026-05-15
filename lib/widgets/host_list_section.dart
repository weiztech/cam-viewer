import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/host.dart';
import '../add_host_page.dart';
import 'keyboard_focus_ring_mixin.dart';

/// Renders the Add Host button + existing host list.
/// Handles navigation to [AddHostPage] internally; reports changes via callbacks.
class HostListSection extends StatelessWidget {
  const HostListSection({
    super.key,
    required this.hosts,
    required this.onHostAdded,
    required this.onHostEdited,
    required this.onHostDeleted,
  });

  final List<Host> hosts;
  final void Function(Host) onHostAdded;
  final void Function(int index, Host updated) onHostEdited;
  final void Function(int index) onHostDeleted;

  Future<void> _openAdd(BuildContext context) async {
    final result = await Navigator.push<Host>(
      context,
      MaterialPageRoute(builder: (_) => AddHostPage(existingHosts: hosts)),
    );
    if (result != null) onHostAdded(result);
  }

  Future<void> _openEdit(BuildContext context, int index) async {
    final result = await Navigator.push<Host>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddHostPage(initial: hosts[index], existingHosts: hosts),
      ),
    );
    if (result != null) onHostEdited(index, result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _openAdd(context),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Host'),
          style:
              ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ).copyWith(
                // White overlay when focused (visible on TV remote / keyboard)
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.focused)) {
                    return Colors.white.withOpacity(0.25);
                  }
                  return null;
                }),
                side: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.focused)) {
                    return const BorderSide(color: Colors.white, width: 2);
                  }
                  return BorderSide.none;
                }),
              ),
        ),
        if (hosts.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...hosts.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _HostTile(
                host: e.value,
                onEdit: () => _openEdit(context, e.key),
                onDelete: () => onHostDeleted(e.key),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Host tile ─────────────────────────────────────────────────────────────────

class _HostTile extends StatefulWidget {
  const _HostTile({
    required this.host,
    required this.onEdit,
    required this.onDelete,
  });

  final Host host;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_HostTile> createState() => _HostTileState();
}

class _HostTileState extends State<_HostTile> with KeyboardFocusRingMixin {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showRing = _focusNode.hasFocus && isKeyboardNavigation;
    final hasCams = widget.host.activeChannels.isNotEmpty;

    return Focus(
      focusNode: _focusNode,
      // D-pad Select / Enter → open edit
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onEdit();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onEdit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: const Color(0xFF252525),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: showRing ? Colors.white : Colors.white12,
              width: showRing ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.host.displayHost,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.host.username.isNotEmpty)
                        Text(
                          widget.host.username,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: hasCams
                              ? Colors.blueAccent
                              : Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          hasCams
                              ? '${widget.host.activeChannels.length} cam'
                              : 'No cams',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 16, color: Colors.white38),
                onPressed: widget.onEdit,
                focusColor: Colors.white.withOpacity(0.2),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Colors.redAccent,
                ),
                onPressed: widget.onDelete,
                focusColor: Colors.white.withOpacity(0.2),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
