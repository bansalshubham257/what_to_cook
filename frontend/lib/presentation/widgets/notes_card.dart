import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notes_provider.dart';
import 'note_dialog.dart';

enum _NotesMode { checklist, notes }

class NotesCard extends ConsumerStatefulWidget {
  const NotesCard({super.key});

  @override
  ConsumerState<NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends ConsumerState<NotesCard> {
  final _controller = TextEditingController();
  _NotesMode _mode = _NotesMode.checklist;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addChecklist() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await ref.read(notesProvider.notifier).addChecklist(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = ref.watch(notesProvider);
    final checklistGroup = groups.cast<NoteGroup?>().firstWhere(
          (g) => g?.title == 'Checklist',
          orElse: () => null,
        );

    return GestureDetector(
      onTap: () => context.push('/notes'),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_note, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Checklist / Notes',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/notes'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SegmentedButton<_NotesMode>(
                segments: const [
                  ButtonSegment(
                    value: _NotesMode.checklist,
                    label: Text('Checklist'),
                    icon: Icon(Icons.check_box_outlined),
                  ),
                  ButtonSegment(
                    value: _NotesMode.notes,
                    label: Text('Notes'),
                    icon: Icon(Icons.notes_outlined),
                  ),
                ],
                selected: <_NotesMode>{_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              const SizedBox(height: 12),
              if (_mode == _NotesMode.checklist)
                _buildChecklist(theme, checklistGroup)
              else
                _buildNotes(context, theme,
                    groups.where((g) => g.title != 'Checklist').toList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklist(ThemeData theme, NoteGroup? group) {
    final checklist = group?.notes ?? [];
    return Column(
      children: [
        if (checklist.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Add a simple checklist and tick items off.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          )
        else
          for (final note in checklist)
            Row(
              children: [
                Checkbox(
                  value: note.done,
                  onChanged: group == null
                      ? null
                      : (_) => ref
                          .read(notesProvider.notifier)
                          .toggle(group.id, note.id),
                  visualDensity: VisualDensity.compact,
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
                if (group != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => ref
                        .read(notesProvider.notifier)
                        .remove(group.id, note.id),
                  ),
              ],
            ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _addChecklist(),
          decoration: InputDecoration(
            hintText: 'Add checklist item...',
            isDense: true,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _addChecklist,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotes(
    BuildContext context,
    ThemeData theme,
    List<NoteGroup> groups,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (groups.isEmpty)
          Text(
            'Create titled notes like Food, Recipes or Shopping Ideas, then add detailed notes inside.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          )
        else
          for (final group in groups) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: Text(
                group.title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            for (final note in group.notes)
              GestureDetector(
                onTap: () => context.push('/note', extra: note),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note.imagePath.isNotEmpty &&
                          File(note.imagePath).existsSync()) ...[
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
                                fontWeight: note.bold
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontStyle:
                                    note.italic ? FontStyle.italic : null,
                              ),
                            ),
                            if (note.body.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                note.body,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
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
                        onPressed: () => ref
                            .read(notesProvider.notifier)
                            .remove(group.id, note.id),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => showAddNoteDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add detailed note'),
          ),
        ),
      ],
    );
  }
}
