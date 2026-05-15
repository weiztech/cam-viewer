import 'package:flutter/material.dart';
import '../models/host.dart';
import '../add_host_page.dart';

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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
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

class _HostTile extends StatelessWidget {
  const _HostTile({
    required this.host,
    required this.onEdit,
    required this.onDelete,
  });

  final Host host;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasCams = host.activeChannels.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    host.displayHost,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (host.username.isNotEmpty)
                    Text(
                      host.username,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Active-cameras badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: hasCams ? Colors.blueAccent : Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      hasCams ? '${host.activeChannels.length} cam' : 'No cams',
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
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 16,
              color: Colors.redAccent,
            ),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
