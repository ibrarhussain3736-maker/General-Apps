import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});
  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _ctrl = MobileScannerController();
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture cap) async {
    if (_busy || cap.barcodes.isEmpty) return;
    final v = cap.barcodes.first.rawValue;
    if (v == null) return;
    _busy = true;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Scanned result', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SelectableText(v),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: v));
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Scan again'))),
            ]),
          ]),
        ),
      ),
    );
    _busy = false;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('QR Scanner'),
          actions: [IconButton(icon: const Icon(Icons.flash_on_rounded), onPressed: () => _ctrl.toggleTorch())],
        ),
        body: Stack(fit: StackFit.expand, children: [
          MobileScanner(controller: _ctrl, onDetect: _onDetect),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(28)),
              ),
            ),
          ),
        ]),
      );
}
