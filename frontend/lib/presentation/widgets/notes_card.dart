import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notes_provider.dart';

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
                Icon(Icons.edit_note, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Checklist / Notes',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
              _buildNotes(context, theme, groups.where((g) => g.title != 'Checklist').toList()),
          ],
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
                      : (_) => ref.read(notesProvider.notifier).toggle(group.id, note.id),
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
                    onPressed: () => ref.read(notesProvider.notifier).remove(group.id, note.id),
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
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            for (final note in group.notes)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
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
                              fontWeight:
                                  note.bold ? FontWeight.w800 : FontWeight.w600,
                              fontStyle: note.italic ? FontStyle.italic : null,
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
                      onPressed: () =>
                          ref.read(notesProvider.notifier).remove(group.id, note.id),
                    ),
                  ],
                ),
              ),
          ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _showNoteDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add detailed note'),
          ),
        ),
      ],
    );
  }

  Future<void> _showNoteDialog(BuildContext context) async {
    final groupController = TextEditingController();
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final linkController = TextEditingController();
    final recipeController = TextEditingController();
    var bold = false;
    var italic = false;
    String imagePath = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                  const Expanded(
                    child: Text(
                      'New note',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await ref.read(notesProvider.notifier).addNote(
                            groupTitle: groupController.text,
                            title: titleController.text,
                            body: bodyController.text,
                            link: linkController.text,
                            recipe: recipeController.text,
                            imagePath: imagePath,
                            bold: bold,
                            italic: italic,
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    TextField(
                      controller: groupController,
                      decoration: const InputDecoration(
                        labelText: 'Note list title',
                        hintText: 'Food',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.sentences,
                      style:
                          const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 10),
                    _formatToolbar(
                      bold: bold,
                      italic: italic,
                      onBold: () {
                        _wrapSelection(bodyController, '**', '**');
                        setDialogState(() => bold = !bold);
                      },
                      onItalic: () {
                        _wrapSelection(bodyController, '_', '_');
                        setDialogState(() => italic = !italic);
                      },
                      onBullet: () => _insertAtSelection(bodyController, '\n- '),
                    ),
                    const SizedBox(height: 10),
                    if (imagePath.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            File(imagePath),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    TextField(
                      controller: bodyController,
                      minLines: 8,
                      maxLines: 16,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Write freely',
                        hintText:
                            'Select text and use Bold/Italic, add bullets, links, images and recipe details.',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: linkController,
                      decoration:
                          const InputDecoration(labelText: 'Link', hintText: 'https://...'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: recipeController,
                      minLines: 3,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Recipe / food details',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    groupController.dispose();
    titleController.dispose();
    bodyController.dispose();
    linkController.dispose();
    recipeController.dispose();
  }

  Widget _formatToolbar({
    required bool bold,
    required bool italic,
    required VoidCallback onBold,
    required VoidCallback onItalic,
    required VoidCallback onBullet,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(label: const Text('B'), selected: bold, onSelected: (_) => onBold()),
        FilterChip(label: const Text('Italic'), selected: italic, onSelected: (_) => onItalic()),
        ActionChip(
          avatar: const Icon(Icons.format_list_bulleted, size: 18),
          label: const Text('Bullet'),
          onPressed: onBullet,
        ),
      ],
    );
  }

  void _wrapSelection(
    TextEditingController controller,
    String before,
    String after,
  ) {
    final selection = controller.selection;
    if (!selection.isValid || selection.isCollapsed) {
      _insertAtSelection(controller, before + after);
      final cursor = controller.selection.baseOffset - after.length;
      controller.selection = TextSelection.collapsed(
        offset: cursor.clamp(0, controller.text.length),
      );
      return;
    }
    final text = controller.text;
    final selected = text.substring(selection.start, selection.end);
    controller.text = text.replaceRange(
      selection.start,
      selection.end,
      '$before$selected$after',
    );
    controller.selection = TextSelection(
      baseOffset: selection.start + before.length,
      extentOffset: selection.end + before.length,
    );
  }

  void _insertAtSelection(TextEditingController controller, String value) {
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : controller.text.length;
    final end = selection.isValid ? selection.end : controller.text.length;
    controller.text = controller.text.replaceRange(start, end, value);
    controller.selection = TextSelection.collapsed(offset: start + value.length);
  }
}