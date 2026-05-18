import 'package:flutter/material.dart';
import 'models/host.dart';

class AddHostPage extends StatefulWidget {
  const AddHostPage({super.key, this.initial, this.existingHosts = const []});

  final Host? initial;
  final List<Host> existingHosts;

  @override
  State<AddHostPage> createState() => _AddHostPageState();
}

class _AddHostPageState extends State<AddHostPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _hostCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;

  late final Set<int> _selectedChannels;
  late String _resolution;
  bool _obscurePass = true;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _hostCtrl = TextEditingController(text: widget.initial?.rawInput ?? '');
    _userCtrl = TextEditingController(text: widget.initial?.username ?? '');
    _passCtrl = TextEditingController(text: widget.initial?.password ?? '');
    _selectedChannels = widget.initial?.activeChannels.toSet() ?? {};
    _resolution = widget.initial?.resolution ?? 'SD';
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final rawInput = _hostCtrl.text.trim();
    final hostname = _extractHostname(rawInput);

    for (final h in widget.existingHosts) {
      if (h.id == widget.initial?.id) continue;
      if (h.hostname == hostname) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Host already exists: $hostname')),
        );
        return;
      }
    }

    Navigator.pop(
      context,
      Host(
        id: widget.initial?.id ?? Host.generateId(),
        rawInput: rawInput,
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
        activeChannels: _selectedChannels.toList()..sort(),
        resolution: _resolution,
      ),
    );
  }

  static String _extractHostname(String raw) {
    var s = raw.trim().toLowerCase();
    if (s.contains('://')) s = s.split('://').last;
    s = s.split('/').first;
    s = s.split(':').first;
    return s;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        foregroundColor: Colors.white,
        title: Text(_isEdit ? 'Edit Host' : 'Add Host'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('HOST'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _hostCtrl,
                style: const TextStyle(color: Colors.white70),
                decoration: _inputDeco('e.g. 192.168.1.100:554'),
                autocorrect: false,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Host is required' : null,
              ),
              const SizedBox(height: 20),
              _label('USERNAME'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _userCtrl,
                style: const TextStyle(color: Colors.white70),
                decoration: _inputDeco('optional'),
                autocorrect: false,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              _label('PASSWORD'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passCtrl,
                style: const TextStyle(color: Colors.white70),
                obscureText: _obscurePass,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                decoration: _inputDeco('optional').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white38,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                autocorrect: false,
              ),
              const SizedBox(height: 28),
              _label('RESOLUTION'),
              const SizedBox(height: 10),
              _resPicker(),
              const SizedBox(height: 28),
              _label('CHANNELS'),
              const SizedBox(height: 10),
              _channelPicker(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_isEdit ? 'Update Host' : 'Save Host'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _resPicker() {
    return Row(
      children: ['SD', 'HD'].map((res) {
        final on = _resolution == res;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => setState(() => _resolution = res),
            borderRadius: BorderRadius.circular(4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: on ? Colors.blueAccent : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: on ? Colors.blueAccent : Colors.white24,
                ),
              ),
              child: Text(
                res,
                style: TextStyle(
                  color: on ? Colors.white : Colors.white38,
                  fontWeight: on ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _channelPicker() {
    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: List.generate(18, (i) {
        final ch = i + 1;
        final on = _selectedChannels.contains(ch);
        return InkWell(
          onTap: () => setState(
            () => on ? _selectedChannels.remove(ch) : _selectedChannels.add(ch),
          ),
          borderRadius: BorderRadius.circular(4),
          focusColor: Colors.white.withOpacity(0.3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: on ? Colors.blueAccent : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: on ? Colors.blueAccent : Colors.white24,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$ch',
              style: TextStyle(
                color: on ? Colors.white : Colors.white38,
                fontSize: 13,
                fontWeight: on ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white24),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white24),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blueAccent),
    ),
    errorBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.redAccent),
    ),
    errorStyle: const TextStyle(color: Colors.redAccent),
  );

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
