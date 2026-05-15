import 'package:flutter/material.dart';
import '../models/host.dart';
import 'host_list_section.dart';

const List<int> kLayoutOptions = [4, 6, 8, 16, 18];

class AppMenu extends StatelessWidget {
  const AppMenu({
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
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: const Color(0xFF1C1C1C),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('MENU'),
            const SizedBox(height: 12),
            HostListSection(
              hosts: hosts,
              onHostAdded: onHostAdded,
              onHostEdited: onHostEdited,
              onHostDeleted: onHostDeleted,
            ),
            const SizedBox(height: 24),
            _label('VIEW LAYOUT'),
            const SizedBox(height: 8),
            _layoutChips(),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white38,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    ),
  );

  Widget _layoutChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: kLayoutOptions.map((count) {
        final selected = count == layoutCount;
        return InkWell(
          onTap: () => onLayoutChanged(count),
          borderRadius: BorderRadius.circular(6),
          focusColor: Colors.white.withOpacity(0.3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: selected ? Colors.blueAccent : Colors.grey.shade800,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
