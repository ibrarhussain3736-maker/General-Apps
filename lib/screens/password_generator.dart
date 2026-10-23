import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});
  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  double _len = 16;
  bool _up = true, _low = true, _dig = true, _sym = true;
  String _pw = '';
  final _r = Random.secure();

  List<String> get _sets => [
        if (_low) 'abcdefghijkmnopqrstuvwxyz',
        if (_up) 'ABCDEFGHJKLMNPQRSTUVWXYZ',
        if (_dig) '23456789',
        if (_sym) '!@#\$%^&*()-_=+?',
      ];

  @override
  void initState() {
    super.initState();
    _gen();
  }

  void _gen() {
    final sets = _sets;
    final pool = sets.join();
    final n = _len.round();
    final chars = <String>[for (final s in sets) s[_r.nextInt(s.length)]];
    while (chars.length < n) {
      chars.add(pool[_r.nextInt(pool.length)]);
    }
    chars.shuffle(_r);
    setState(() => _pw = chars.join());
  }

  void _toggle(bool cur, bool v, void Function(bool) set) {
    if (!v && _sets.length == 1) return; // keep at least one set
    set(v);
    _gen();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bits = _len * (log(_sets.join().length) / ln2);
    final (label, color) = bits < 45
        ? ('Weak', Colors.redAccent)
        : bits < 65
            ? ('Fair', Colors.orange)
            : bits < 90
                ? ('Good', Colors.lightGreen)
                : ('Excellent', Colors.green);
    return Scaffold(
      appBar: AppBar(title: const Text('Password Generator')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(colors: [cs.primary, cs.tertiary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Column(children: [
            SelectableText(
              _pw,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: cs.primary),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _pw));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy'),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(onPressed: _gen, icon: const Icon(Icons.refresh_rounded)),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Text('Strength: $label', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          const Spacer(),
          Text('${bits.round()} bits', style: TextStyle(color: cs.onSurfaceVariant)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: (bits / 110).clamp(0.05, 1.0), minHeight: 10, color: color, backgroundColor: cs.surfaceContainerHighest),
        ),
        const SizedBox(height: 24),
        Text('Length: ${_len.round()}', style: Theme.of(context).textTheme.titleMedium),
        Slider(value: _len, min: 8, max: 64, divisions: 56, onChanged: (v) => setState(() => _len = v), onChangeEnd: (_) => _gen()),
        SwitchListTile(title: const Text('Lowercase (a-z)'), value: _low, onChanged: (v) => _toggle(_low, v, (x) => _low = x)),
        SwitchListTile(title: const Text('Uppercase (A-Z)'), value: _up, onChanged: (v) => _toggle(_up, v, (x) => _up = x)),
        SwitchListTile(title: const Text('Numbers (2-9)'), value: _dig, onChanged: (v) => _toggle(_dig, v, (x) => _dig = x)),
        SwitchListTile(title: const Text('Symbols (!@#...)'), value: _sym, onChanged: (v) => _toggle(_sym, v, (x) => _sym = x)),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Look-alike characters (l, I, O, 0, 1) are left out.', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        ),
      ]),
    );
  }
}
