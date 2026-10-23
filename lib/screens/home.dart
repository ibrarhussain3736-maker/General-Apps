import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'notes.dart';
import 'password_generator.dart';
import 'qr_generator.dart';
import 'qr_scanner.dart';
import 'settings.dart';
import 'vault.dart';

class _Tool {
  final String title, subtitle;
  final IconData icon;
  final List<Color> colors;
  final Widget screen;
  const _Tool(this.title, this.subtitle, this.icon, this.colors, this.screen);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _q = '';

  static const _tools = <_Tool>[
    _Tool('Private Vault', 'Encrypted files', Icons.lock_rounded, [Color(0xFFFF7675), Color(0xFFE17055)], VaultScreen()),
    _Tool('Passwords', 'Strong generator', Icons.vpn_key_rounded, [Color(0xFF6C5CE7), Color(0xFFA29BFE)], PasswordScreen()),
    _Tool('QR Generator', 'Create codes', Icons.qr_code_2_rounded, [Color(0xFF00B894), Color(0xFF55EFC4)], QrGeneratorScreen()),
    _Tool('QR Scanner', 'Scan offline', Icons.qr_code_scanner_rounded, [Color(0xFF0984E3), Color(0xFF74B9FF)], QrScannerScreen()),
    _Tool('Notes', 'Quick notes', Icons.sticky_note_2_rounded, [Color(0xFFF39C12), Color(0xFFFDCB6E)], NotesScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = _tools.where((t) => t.title.toLowerCase().contains(_q.toLowerCase())).toList();
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [cs.primary.withValues(alpha: 0.22), cs.surface],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Toolbox', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                    Text('Everything offline, in one place', style: TextStyle(color: cs.onSurfaceVariant)),
                  ]),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.palette_rounded),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ]).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
              const SizedBox(height: 20),
              TextField(
                onChanged: (v) => setState(() => _q = v),
                decoration: const InputDecoration(hintText: 'Search tools', prefixIcon: Icon(Icons.search_rounded)),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: list.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (_, i) => _card(list[i]).animate().fadeIn(duration: 400.ms, delay: (70 * i).ms).slideY(begin: 0.15, end: 0),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _card(_Tool t) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => t.screen)),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(colors: t.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: t.colors.first.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(children: [
                Positioned(right: -16, bottom: -16, child: Icon(t.icon, size: 110, color: Colors.white.withValues(alpha: 0.18))),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(16)),
                      child: Icon(t.icon, color: Colors.white),
                    ),
                    const Spacer(),
                    Text(t.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(t.subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
}
