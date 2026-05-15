import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'models/host.dart';
import 'models/camera_slot.dart';
import 'services/host_storage.dart';
import 'widgets/camera_grid.dart';
import 'widgets/app_menu.dart';
import 'mobile_menu_page.dart';

const double kMobileBreakpoint = 600;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _layoutCount = 4;
  List<CameraSlot?> _displaySlots = [];
  List<Host> _hosts = [];
  bool _loaded = false;

  bool _menuVisible = true;
  DateTime? _lastEscPressTime;

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Flatten all hosts' activeChannels into an ordered list of CameraSlots.
  List<CameraSlot> get _activeSlots {
    final slots = <CameraSlot>[];
    for (final host in _hosts) {
      for (final ch in host.activeChannels) {
        slots.add(CameraSlot(host: host, channel: ch));
      }
    }
    return slots;
  }

  void _rebuildDisplaySlots() {
    final active = _activeSlots;
    _displaySlots = List.generate(
      _layoutCount,
      (i) => i < active.length ? active[i] : null,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadHosts();
  }

  Future<void> _loadHosts() async {
    try {
      debugPrint('[HostStorage] loading...');
      final hosts = await HostStorage.load();
      debugPrint('[HostStorage] loaded ${hosts.length} host(s)');
      if (!mounted) return;
      setState(() {
        _hosts = hosts;
        _loaded = true;
        _rebuildDisplaySlots();
      });
    } catch (e, st) {
      debugPrint('[HostStorage] load error: $e\n$st');
      if (!mounted) return;
      // Always unblock the UI even if storage fails.
      setState(() {
        _loaded = true;
        _rebuildDisplaySlots();
      });
    }
  }

  Future<void> _saveHosts() => HostStorage.save(_hosts);

  // ── Event handlers ────────────────────────────────────────────────────────

  void _onLayoutChanged(int count) {
    setState(() {
      _layoutCount = count;
      _rebuildDisplaySlots();
    });
  }

  void _onHostAdded(Host host) {
    setState(() {
      _hosts.add(host);
      _rebuildDisplaySlots();
    });
    _saveHosts();
  }

  void _onHostEdited(int index, Host updated) {
    setState(() {
      _hosts[index] = updated;
      _rebuildDisplaySlots();
    });
    _saveHosts();
  }

  void _onHostDeleted(int index) {
    setState(() {
      _hosts.removeAt(index);
      _rebuildDisplaySlots();
    });
    _saveHosts();
  }

  void _onCellTap(int index) {
    final slot = _displaySlots[index];
    if (slot == null) return;

    // Stop all grid streams before entering fullscreen so the DVR isn't
    // holding connections open in the background.
    final savedSlots = List<CameraSlot?>.from(_displaySlots);
    setState(() => _displaySlots = List.filled(_layoutCount, null));

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _CameraFullscreenPage(slot: slot),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) {
      // Restore streams when returning from fullscreen.
      if (mounted) setState(() => _displaySlots = savedSlots);
    });
  }

  /// Desktop only: single Esc toggles menu; double Esc within 2 s exits app.
  void _handleDesktopEsc() {
    final now = DateTime.now();
    if (_lastEscPressTime != null &&
        now.difference(_lastEscPressTime!) < const Duration(seconds: 2)) {
      _lastEscPressTime = null;
      ScaffoldMessenger.of(context).clearSnackBars();
      SystemNavigator.pop();
      return;
    }
    _lastEscPressTime = now;
    setState(() => _menuVisible = !_menuVisible);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Press Esc again to exit'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF141414),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < kMobileBreakpoint;

    final grid = CameraGrid(
      slots: _displaySlots,
      isMobile: isMobile,
      onCellTap: _onCellTap,
    );

    return isMobile ? _mobileScaffold(grid) : _desktopScaffold(grid);
  }

  // ── Mobile ────────────────────────────────────────────────────────────────

  Widget _mobileScaffold(CameraGrid grid) {
    return Scaffold(
      body: grid,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MobileMenuPage(
              layoutCount: _layoutCount,
              hosts: _hosts,
              onHostAdded: _onHostAdded,
              onHostEdited: _onHostEdited,
              onHostDeleted: _onHostDeleted,
              onLayoutChanged: _onLayoutChanged,
            ),
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1C),
        child: const Icon(Icons.settings, color: Colors.white),
      ),
    );
  }

  // ── Desktop ───────────────────────────────────────────────────────────────

  Widget _desktopScaffold(CameraGrid grid) {
    final menu = AppMenu(
      layoutCount: _layoutCount,
      hosts: _hosts,
      onHostAdded: _onHostAdded,
      onHostEdited: _onHostEdited,
      onHostDeleted: _onHostDeleted,
      onLayoutChanged: _onLayoutChanged,
    );

    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey != LogicalKeyboardKey.escape) {
            return KeyEventResult.ignored;
          }
          _handleDesktopEsc();
          return KeyEventResult.handled;
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: grid),
            if (_menuVisible) menu,
          ],
        ),
      ),
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

/// Full-screen camera view pushed as its own route.
/// Back button and Esc both pop it naturally.
class _CameraFullscreenPage extends StatefulWidget {
  const _CameraFullscreenPage({required this.slot});

  final CameraSlot slot;

  @override
  State<_CameraFullscreenPage> createState() => _CameraFullscreenPageState();
}

class _CameraFullscreenPageState extends State<_CameraFullscreenPage> {
  late final Player _player;
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _player.open(Media(widget.slot.fullResUrl));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.pop(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Video(
          controller: _controller,
          fill: Colors.black,
          controls: null,
        ),
      ),
    );
  }
}
