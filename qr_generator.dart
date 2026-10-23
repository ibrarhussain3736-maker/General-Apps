import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});
  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = _c.text.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('QR Generator')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        TextField(
          controller: _c,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Text, link, Wi-Fi, contact...'),
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 8, children: [
          ActionChip(label: const Text('Paste'), avatar: const Icon(Icons.paste, size: 18), onPressed: () async {
            final d = await Clipboard.getData('text/plain');
            if (d?.text != null) setState(() => _c.text = d!.text!);
          }),
          ActionChip(label: const Text('Clear'), avatar: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _c.clear())),
        ]),
        const SizedBox(height: 24),
        if (text.isNotEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: QrImageView(data: text, size: 250, backgroundColor: Colors.white),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(children: [
              Icon(Icons.qr_code_2_rounded, size: 80, color: cs.outlineVariant),
              const SizedBox(height: 12),
              Text('Type something to create a QR code', style: TextStyle(color: cs.onSurfaceVariant)),
            ]),
          ),
      ]),
    );
  }
}
