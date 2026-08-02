import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/note_dialog.dart';

/// Full-screen "see all" view for checklist & notes with search support.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = ref.watch(notesProvider);
    final checklist = groups
        .cast<NoteGroup?>()
        .firstWhere((g) => g?.title == 'Checklist', orElse: () => null);

    final nonChecklist = groups.where((g) => g.title != 'Checklist').toList();
    final matching = _query.isEmpty
        ? nonChecklist
        : nonChecklist.where(_matchesQuery).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist / Notes'),
        actions: [
          IconButton(
            tooltip: 'Add detailed note',
            icon: const Icon(Icons.add),
            onPressed: () => showAddNoteDialog(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: _query.isEmpty
                  ? _buildAll(theme, checklist, nonChecklist)
                  : _buildSearchResults(theme, checklist, matching),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddNoteDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add detailed note'),
      ),
    );
  }

  bool _matchesQuery(NoteGroup group) {
    final q = _query.toLowerCase();
    if (group.title.toLowerCase().contains(q)) return true;
    return group.notes.any((n) =>
        n.title.toLowerCase().contains(q) ||
        n.body.toLowerCase().contains(q) ||
        n.recipe.toLowerCase().contains(q) ||
        n.link.toLowerCase().contains(q));
  }

  Widget _buildAll(
    ThemeData theme,
    NoteGroup? checklist,
    List<NoteGroup> groups,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        if (checklist != null) _buildChecklistSection(theme, checklist),
        if (checklist != null && checklist.notes.isNotEmpty)
          const SizedBox(height: 24),
        for (final group in groups) _buildGroupSection(theme, group),
        if (groups.isEmpty && (checklist?.notes.isEmpty ?? true))
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Column(
              children: [
                Icon(Icons.edit_note, size: 56, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No notes yet',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap + to add a checklist or a detailed note.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResults(
    ThemeData theme,
    NoteGroup? checklist,
    List<NoteGroup> matching,
  ) {
    if ((checklist?.notes.isNotEmpty ?? false) && _matchesQueryChecklist(checklist!)) {
      matching = [checklist, ...matching];
    }
    if (matching.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No matching notes', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: matching.map((g) => _buildGroupSection(theme, g)).toList(),
    );
  }

  bool _matchesQueryChecklist(NoteGroup group) {
    final q = _query.toLowerCase();
    return group.notes.any((n) => n.title.toLowerCase().contains(q));
  }

  Widget _buildChecklistSection(ThemeData theme, NoteGroup group) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_box_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Checklist',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  '${group.notes.where((n) => n.done).length}/${group.notes.length}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (group.notes.isEmpty)
              Text(
                'Add a simple checklist and tick items off.',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              )
            else
              for (final note in group.notes)
                Row(
                  children: [
                    Checkbox(
                      value: note.done,
                      onChanged: (_) => ref.read(notesProvider.notifier).toggle(group.id, note.id),
                    ),
                    Expanded(
                      child: Text(
                        note.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          decoration: note.done ? TextDecoration.lineThrough : null,
                          color: note.done ? Colors.grey : null,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => ref.read(notesProvider.notifier).remove(group.id, note.id),
                    ),
                  ],
                ),
            const SizedBox(height: 4),
            TextField(
              textInputAction: TextInputAction.done,
              onSubmitted: (v) {
                if (v.trim().isEmpty) return;
                ref.read(notesProvider.notifier).addChecklist(v.trim());
              },
              decoration: InputDecoration(
                hintText: 'Add checklist item...',
                isDense: true,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSection(ThemeData theme, NoteGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Text(
            group.title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        for (final note in group.notes)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.imagePath.isNotEmpty && File(note.imagePath).existsSync()) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(note.imagePath),
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: note.bold ? FontWeight.w800 : FontWeight.w600,
                          fontStyle: note.italic ? FontStyle.italic : null,
                        ),
                      ),
                      if (note.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(note.body,
                            style: theme.textTheme.bodySmall),
                      ],
                      if (note.recipe.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Recipe: ${note.recipe}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      if (note.link.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          note.link,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () =>
                      ref.read(notesProvider.notifier).remove(group.id, note.id),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
