import 'package:flutter/material.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Appearance')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Theme', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ValueListenableBuilder<int>(
            valueListenable: AppTheme.mode,
            builder: (_, m, __) => SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Auto')),
                ButtonSegment(value: 1, label: Text('Light')),
                ButtonSegment(value: 2, label: Text('Dark')),
                ButtonSegment(value: 3, label: Text('AMOLED')),
              ],
              selected: {m},
              onSelectionChanged: (s) => AppTheme.setMode(s.first),
            ),
          ),
          const SizedBox(height: 28),
          Text('Accent color', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ValueListenableBuilder<Color>(
            valueListenable: AppTheme.accent,
            builder: (_, cur, __) => Wrap(spacing: 14, runSpacing: 14, children: [
              for (final c in AppTheme.accents)
                GestureDetector(
                  onTap: () => AppTheme.setAccent(c),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: c,
                    child: cur.toARGB32() == c.toARGB32() ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                ),
            ]),
          ),
        ]),
      );
}
