import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/ads_provider.dart';
import '../providers/notes_provider.dart';

/// Opens the "add detailed note" bottom sheet and saves via [notesProvider].
/// Shared by [NotesCard] and the full Notes screen.
Future<void> showAddNoteDialog(BuildContext context, WidgetRef ref) async {
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
                    final adService = ref.read(adServiceProvider);
                    final bool adShown = await adService.showRewardedAd(
                      onRewarded: () {},
                      onAdDismissed: () async {
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
                    );
                    if (!adShown && ctx.mounted) {
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
                    }
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
                    onImage: () async {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 82,
                      );
                      if (picked == null) return;
                      final dir = await getApplicationDocumentsDirectory();
                      final ext = picked.path.split('.').last;
                      final target = File(
                        '${dir.path}/note-${DateTime.now().microsecondsSinceEpoch}.$ext',
                      );
                      await File(picked.path).copy(target.path);
                      setDialogState(() => imagePath = target.path);
                    },
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
  required VoidCallback onImage,
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
      ActionChip(
        avatar: const Icon(Icons.image_outlined, size: 18),
        label: const Text('Image'),
        onPressed: onImage,
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
