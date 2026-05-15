import 'package:flutter/material.dart';
import 'models/host.dart';
import 'widgets/app_menu.dart' show kLayoutOptions;
import 'widgets/host_list_section.dart';

class MobileMenuPage extends StatefulWidget {
  const MobileMenuPage({
    super.key,
    required this.layoutCount,
    required this.hosts,
    required this.onHostAdded,
    required this.onHostEdited,
    required this.onHostDeleted,
    required this.onLayoutChanged,
  });

  final int layoutCount;
  final List<Host> hosts;
  final void Function(Host) onHostAdded;
  final void Function(int index, Host updated) onHostEdited;
  final void Function(int index) onHostDeleted;
  final ValueChanged<int> onLayoutChanged;

  @override
  State<MobileMenuPage> createState() => _MobileMenuPageState();
}

class _MobileMenuPageState extends State<MobileMenuPage> {
  late int _currentLayout;
  late List<Host> _localHosts;

  @override
  void initState() {
    super.initState();
    _currentLayout = widget.layoutCount;
    _localHosts = List.of(widget.hosts);
  }

  void _onHostAdded(Host host) {
    setState(() => _localHosts.add(host));
    widget.onHostAdded(host);
  }

  void _onHostEdited(int index, Host updated) {
    setState(() => _localHosts[index] = updated);
    widget.onHostEdited(index, updated);
  }

  void _onHostDeleted(int index) {
    setState(() => _localHosts.removeAt(index));
    widget.onHostDeleted(index);
  }

  void _changeLayout(int count) {
    setState(() => _currentLayout = count);
    widget.onLayoutChanged(count);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        foregroundColor: Colors.white,
        title: const Text('Menu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('HOSTS'),
            const SizedBox(height: 10),
            HostListSection(
              hosts: _localHosts,
              onHostAdded: _onHostAdded,
              onHostEdited: _onHostEdited,
              onHostDeleted: _onHostDeleted,
            ),
            const SizedBox(height: 28),
            _label('VIEW LAYOUT'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kLayoutOptions.map((count) {
                final selected = count == _currentLayout;
                return GestureDetector(
                  onTap: () => _changeLayout(count),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.blueAccent
                          : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white38,
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.4,
    ),
  );
}
