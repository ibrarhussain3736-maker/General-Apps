import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<String> _notes = [];
  SharedPreferences? _p;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) => setState(() {
          _p = p;
          _notes = p.getStringList('notes') ?? [];
        }));
  }

  void _save() => _p?.setStringList('notes', _notes);

  Future<void> _edit([int? i]) async {
    final c = TextEditingController(text: i == null ? '' : _notes[i]);
    final res = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(i == null ? 'New note' : 'Edit note'),
        content: TextField(controller: c, maxLines: 6, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (res == null || res.isEmpty) return;
    setState(() => i == null ? _notes.insert(0, res) : _notes[i] = res);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = [cs.primaryContainer, cs.secondaryContainer, cs.tertiaryContainer];
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('New note')),
      body: _notes.isEmpty
          ? Center(child: Text('No notes yet', style: TextStyle(color: cs.onSurfaceVariant)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: _notes.length,
              itemBuilder: (_, i) => Dismissible(
                key: ValueKey('$i${_notes[i]}'),
                onDismissed: (_) {
                  setState(() => _notes.removeAt(i));
                  _save();
                },
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(22)),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: colors[i % 3], borderRadius: BorderRadius.circular(22)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    title: Text(_notes[i], maxLines: 4, overflow: TextOverflow.ellipsis),
                    onTap: () => _edit(i),
                  ),
                ),
              ),
            ),
    );
  }
}
