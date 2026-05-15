import 'package:flutter/material.dart';

/// Adds keyboard-only focus ring visibility to a [State].
///
/// The focus ring is shown only when the user is navigating via keyboard or
/// D-pad remote ([FocusHighlightMode.traditional]). On touch or mouse input
/// ([FocusHighlightMode.touch]) the ring is hidden — so autofocused widgets
/// don't show a border on launch when no remote/keyboard is being used.
///
/// Usage:
///   class _MyState extends State<MyWidget> with KeyboardFocusRingMixin { ... }
///
/// Then in build:
///   final showRing = _focusNode.hasFocus && isKeyboardNavigation;
mixin KeyboardFocusRingMixin<T extends StatefulWidget> on State<T> {
  void _onHighlightModeChanged(FocusHighlightMode _) {
    if (mounted) setState(() {});
  }

  /// True when the user's last input was a keyboard or D-pad remote.
  bool get isKeyboardNavigation =>
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightModeChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightModeChanged);
    super.dispose();
  }
}
