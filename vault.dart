import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:open_filex/open_filex.dart';
import '../services/vault_service.dart';

// ───────────────────────── Lock screen ─────────────────────────

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});
  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _auth = LocalAuthentication();
  bool _loading = true, _setup = false, _bio = false;
  String _pin = '', _msg = '';
  String? _first;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _setup = !await VaultService.hasPin('real');
    _bio = await VaultService.bioEnabled;
    _msg = _setup ? 'Create a PIN (4-8 digits)' : 'Enter your PIN';
    if (mounted) setState(() => _loading = false);
    if (_bio && !_setup) _tryBio();
  }

  Future<void> _tryBio() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock your vault',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (ok && mounted) _openVault('vault');
    } catch (_) {}
  }

  void _openVault(String v) =>
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => VaultFiles(vault: v)));

  void _tap(String d) {
    if (_pin.length < 8) setState(() => _pin += d);
  }

  void _back() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (_pin.length < 4) {
      setState(() => _msg = 'PIN must be at least 4 digits');
      return;
    }
    final pin = _pin;
    if (_setup) {
      if (_first == null) {
        setState(() {
          _first = pin;
          _pin = '';
          _msg = 'Confirm your PIN';
        });
      } else if (_first == pin) {
        await VaultService.setPin('real', pin);
        _openVault('vault');
      } else {
        setState(() {
          _first = null;
          _pin = '';
          _msg = "PINs didn't match. Try again";
        });
      }
      return;
    }
    if (await VaultService.checkPin('real', pin)) {
      _openVault('vault');
    } else if (await VaultService.hasPin('fake') && await VaultService.checkPin('fake', pin)) {
      _openVault('decoy');
    } else {
      setState(() {
        _pin = '';
        _msg = 'Wrong PIN';
      });
    }
  }

  Widget _key(ColorScheme cs, String? label, VoidCallback? onTap, {IconData? icon}) => Padding(
        padding: const EdgeInsets.all(7),
        child: SizedBox(
          width: 74,
          height: 74,
          child: (label == null && icon == null) || onTap == null
              ? null
              : Material(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onTap,
                    child: Center(
                      child: icon != null
                          ? Icon(icon, size: 28)
                          : Text(label!, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Private Vault')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.primary.withValues(alpha: 0.25), cs.surface],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primary.withValues(alpha: 0.15)),
              child: Icon(Icons.lock_rounded, size: 44, color: cs.primary),
            ),
            const SizedBox(height: 16),
            Text(_msg, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 8; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: i < _pin.length ? cs.primary : cs.outlineVariant),
                ),
            ]),
            const Spacer(),
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
            ])
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (final d in row) _key(cs, d, () => _tap(d)),
              ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _key(cs, null, _bio && !_setup ? _tryBio : null, icon: Icons.fingerprint),
              _key(cs, '0', () => _tap('0')),
              _key(cs, null, _back, icon: Icons.backspace_outlined),
            ]),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(onPressed: _submit, child: Text(_setup ? 'Continue' : 'Unlock')),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── Vault contents ─────────────────────────

class VaultFiles extends StatefulWidget {
  final String vault; // 'vault' = real, 'decoy' = fake-PIN vault
  const VaultFiles({super.key, required this.vault});
  @override
  State<VaultFiles> createState() => _VaultFilesState();
}

class _VaultFilesState extends State<VaultFiles> with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  List<MapEntry<String, String>> _items = [];
  bool _busy = false, _skipLock = false;
  bool get _real => widget.vault == 'vault';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    VaultService.clearTemp();
    super.dispose();
  }

  // Auto-lock when the app goes to the background (except while picking/opening files).
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _skipLock = false;
    if (s == AppLifecycleState.paused && !_skipLock) {
      VaultService.clearTemp();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Future<void> _load() async {
    final d = await VaultService.dir(widget.vault);
    final idx = await VaultService.readIndex(d);
    if (mounted) setState(() => _items = idx.entries.toList().reversed.toList());
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _add() async {
    _skipLock = true;
    final r = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any);
    if (r == null) return;
    setState(() => _busy = true);
    try {
      for (final f in r.files) {
        if (f.path != null) await VaultService.addFile(widget.vault, f.path!, f.name);
      }
      await FilePicker.platform.clearTemporaryFiles();
    } catch (e) {
      _snack('Could not add file: $e');
    }
    if (mounted) setState(() => _busy = false);
    _load();
  }

  static const _img = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'];
  String _ext(String n) => n.contains('.') ? n.split('.').last.toLowerCase() : '';

  IconData _icon(String n) {
    final e = _ext(n);
    if (_img.contains(e)) return Icons.image_rounded;
    if (['mp4', 'mkv', 'mov', 'avi', 'webm'].contains(e)) return Icons.movie_rounded;
    if (e == 'pdf') return Icons.picture_as_pdf_rounded;
    if (['mp3', 'm4a', 'wav', 'aac', 'ogg'].contains(e)) return Icons.audiotrack_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Future<void> _open(String id, String name) async {
    setState(() => _busy = true);
    try {
      final path = await VaultService.decryptToTemp(widget.vault, id, name);
      if (!mounted) return;
      setState(() => _busy = false);
      if (_img.contains(_ext(name))) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => _ImageViewer(path: path, title: name)));
      } else {
        _skipLock = true;
        await OpenFilex.open(path);
      }
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      _snack('Could not open file');
    }
  }

  Future<void> _delete(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete file?'),
        content: Text(name),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await VaultService.deleteFile(widget.vault, id);
      _load();
    }
  }

  // ---- Vault settings (real vault only) ----

  Future<String?> _askPin(String title) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, obscureText: true, keyboardType: TextInputType.number, maxLength: 8, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('OK')),
        ],
      ),
    );
  }

  bool _validPin(String? p) => p != null && p.length >= 4 && RegExp(r'^\d+$').hasMatch(p);

  Future<bool> _bioCheck() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      return await _auth.authenticate(
        localizedReason: 'Confirm your fingerprint',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> _settings() async {
    var bioOn = await VaultService.bioEnabled;
    var fakeOn = await VaultService.hasPin('fake');
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Fingerprint unlock'),
              value: bioOn,
              onChanged: (v) async {
                if (v) {
                  _skipLock = true;
                  if (!await _bioCheck()) {
                    _snack('Fingerprint unavailable or not confirmed');
                    return;
                  }
                }
                await VaultService.setBio(v);
                set(() => bioOn = v);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pin_outlined),
              title: const Text('Change PIN'),
              onTap: () async {
                Navigator.pop(ctx);
                final p = await _askPin('New PIN (4-8 digits)');
                if (!_validPin(p)) return _snack('PIN must be 4-8 digits');
                await VaultService.setPin('real', p!);
                _snack('PIN changed');
              },
            ),
            ListTile(
              leading: const Icon(Icons.theater_comedy_outlined),
              title: Text(fakeOn ? 'Change fake PIN' : 'Set fake PIN'),
              subtitle: const Text('Opens an empty decoy vault'),
              onTap: () async {
                Navigator.pop(ctx);
                final p = await _askPin('Fake PIN (4-8 digits)');
                if (!_validPin(p)) return _snack('PIN must be 4-8 digits');
                if (await VaultService.checkPin('real', p!)) return _snack('Fake PIN must differ from your real PIN');
                await VaultService.setPin('fake', p);
                _snack('Fake PIN saved');
              },
            ),
            if (fakeOn)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove fake PIN'),
                onTap: () async {
                  await VaultService.removePin('fake');
                  set(() => fakeOn = false);
                },
              ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        actions: [
          IconButton(icon: const Icon(Icons.lock_outline), tooltip: 'Lock', onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
          if (_real) IconButton(icon: const Icon(Icons.tune_rounded), tooltip: 'Vault settings', onPressed: _settings),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Add files')),
      body: Column(children: [
        if (_busy) const LinearProgressIndicator(),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(colors: [cs.primary, cs.tertiary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Row(children: [
            const Icon(Icons.shield_rounded, color: Colors.white, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${_items.length} protected file${_items.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                Text('AES-256 encrypted', style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: _items.isEmpty
              ? Center(child: Text('No files yet. Tap Add files.', style: TextStyle(color: cs.onSurfaceVariant)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final it = _items[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        leading: CircleAvatar(backgroundColor: cs.primaryContainer, child: Icon(_icon(it.value), color: cs.onPrimaryContainer)),
                        title: Text(it.value, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => _open(it.key, it.value),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(it.key, it.value)),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class _ImageViewer extends StatelessWidget {
  final String path, title;
  const _ImageViewer({required this.path, required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)), iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(child: InteractiveViewer(child: Image.file(File(path)))),
      );
}
