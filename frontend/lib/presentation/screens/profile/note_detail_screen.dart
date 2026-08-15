import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/notes_provider.dart';

/// Full-page view of a single note: shows the attached image large, the full
/// body text, the recipe reference and a tappable link.
class NoteDetailScreen extends StatelessWidget {
  final NoteEntry note;
  const NoteDetailScreen({super.key, required this.note});

  Future<void> _openLink(BuildContext context) async {
    final uri = Uri.tryParse(note.link);
    if (uri == null || !uri.hasScheme) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Note')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.imagePath.isNotEmpty &&
                File(note.imagePath).existsSync()) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  File(note.imagePath),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 18),
            ],
            Text(
              note.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: note.bold ? FontWeight.w800 : FontWeight.w700,
                fontStyle: note.italic ? FontStyle.italic : null,
              ),
            ),
            if (note.body.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(note.body, style: theme.textTheme.bodyLarge),
            ],
            if (note.recipe.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Recipe',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.menu_book,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                      child:
                          Text(note.recipe, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ],
            if (note.link.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Link',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.link, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _openLink(context),
                      child: Text(
                        note.link,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
