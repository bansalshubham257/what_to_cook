import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/recipe_videos_provider.dart';

/// Shows and edits the video links saved for a recipe. Links are stored on the
/// device per recipe; tapping a link opens it in the browser.
class RecipeVideoLinksSection extends ConsumerWidget {
  final String recipeId;
  const RecipeVideoLinksSection({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final videos = ref.watch(recipeVideosProvider)[recipeId] ?? const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Videos',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            TextButton.icon(
              onPressed: () => _showAddVideoDialog(context, ref),
              icon: const Icon(Icons.add_link, size: 18),
              label: const Text('Add link'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (videos.isEmpty)
          Text('No videos saved yet. Add a YouTube or recipe video link.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey))
        else
          ...List.generate(videos.length, (i) {
            final url = videos[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.play_circle_fill, color: Colors.red),
                title: Text(
                  _titleFor(url),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Remove link',
                  onPressed: () =>
                      ref.read(recipeVideosProvider.notifier).removeVideo(recipeId, i),
                ),
                onTap: () => _openLink(context, url),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _showAddVideoDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add video link'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Video URL',
            hintText: 'https://www.youtube.com/watch?v=...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (url == null || url.isEmpty || !context.mounted) return;
    if (!url.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid http(s) link'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await ref.read(recipeVideosProvider.notifier).addVideo(recipeId, url);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Video link saved'),
            backgroundColor: Colors.green,
          ),
        );
    }
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open link'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _titleFor(String url) {
    final uri = Uri.tryParse(url);
    final host = uri?.host ?? '';
    if (host.contains('youtube.com') || host.contains('youtu.be')) return 'YouTube video';
    if (host.isNotEmpty) return host.replaceFirst('www.', '');
    return 'Video link';
  }
}
