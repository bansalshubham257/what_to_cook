import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoteEntry {
  final String id;
  final String title;
  final String body;
  final String link;
  final String recipe;
  final String imagePath;
  final bool bold;
  final bool italic;
  final bool done;

  const NoteEntry({
    required this.id,
    required this.title,
    this.body = '',
    this.link = '',
    this.recipe = '',
    this.imagePath = '',
    this.bold = false,
    this.italic = false,
    this.done = false,
  });

  factory NoteEntry.fromJson(Map<String, dynamic> json) => NoteEntry(
        id: json['id']?.toString() ?? '',
        title: (json['title'] ?? json['text'] ?? '').toString(),
        body: json['body']?.toString() ?? '',
        link: json['link']?.toString() ?? '',
        recipe: json['recipe']?.toString() ?? '',
        imagePath: json['image_path']?.toString() ?? '',
        bold: json['bold'] == true,
        italic: json['italic'] == true,
        done: json['done'] == true,
      );

  NoteEntry copyWith({bool? done}) => NoteEntry(
        id: id,
        title: title,
        body: body,
        link: link,
        recipe: recipe,
        imagePath: imagePath,
        bold: bold,
        italic: italic,
        done: done ?? this.done,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'link': link,
        'recipe': recipe,
        'image_path': imagePath,
        'bold': bold,
        'italic': italic,
        'done': done,
      };
}

class NoteGroup {
  final String id;
  final String title;
  final List<NoteEntry> notes;

  const NoteGroup({required this.id, required this.title, this.notes = const []});

  factory NoteGroup.fromJson(Map<String, dynamic> json) => NoteGroup(
        id: json['id']?.toString() ?? '',
        title: (json['title'] ?? 'Notes').toString(),
        notes: json['notes'] is List
            ? (json['notes'] as List)
                .map((e) => NoteEntry.fromJson((e as Map).cast<String, dynamic>()))
                .toList()
            : const [],
      );

  NoteGroup copyWith({List<NoteEntry>? notes}) => NoteGroup(
        id: id,
        title: title,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes.map((n) => n.toJson()).toList(),
      };
}

class NotesNotifier extends Notifier<List<NoteGroup>> {
  static const _prefsKey = 'home_notes_v2';
  static const _legacyPrefsKey = 'home_notes_v1';

  @override
  List<NoteGroup> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        state = decoded
            .map((e) => NoteGroup.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
        return;
      }

      final legacyRaw = prefs.getString(_legacyPrefsKey);
      if (legacyRaw == null) return;
      final legacy = jsonDecode(legacyRaw) as List<dynamic>;
      final notes = legacy
          .map((e) => NoteEntry.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      state = [NoteGroup(id: _id(), title: 'Quick Notes', notes: notes)];
      await _persist();
    } catch (_) {}
  }

  Future<void> addChecklist(String text) async {
    await addNote(groupTitle: 'Checklist', title: text);
  }

  Future<void> addNote({
    required String groupTitle,
    required String title,
    String body = '',
    String link = '',
    String recipe = '',
    String imagePath = '',
    bool bold = false,
    bool italic = false,
  }) async {
    final cleanGroup = groupTitle.trim().isEmpty ? 'Notes' : groupTitle.trim();
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;
    final groups = List<NoteGroup>.from(state);
    var index = groups.indexWhere((g) => g.title.toLowerCase() == cleanGroup.toLowerCase());
    if (index == -1) {
      groups.add(NoteGroup(id: _id(), title: cleanGroup));
      index = groups.length - 1;
    }
    final group = groups[index];
    groups[index] = group.copyWith(notes: [
      ...group.notes,
      NoteEntry(
        id: _id(),
        title: cleanTitle,
        body: body.trim(),
        link: link.trim(),
        recipe: recipe.trim(),
        imagePath: imagePath.trim(),
        bold: bold,
        italic: italic,
      ),
    ]);
    state = groups;
    await _persist();
  }

  Future<void> toggle(String groupId, String noteId) async {
    state = state.map((group) {
      if (group.id != groupId) return group;
      return group.copyWith(notes: group.notes.map((n) => n.id == noteId ? n.copyWith(done: !n.done) : n).toList());
    }).toList();
    await _persist();
  }

  Future<void> remove(String groupId, String noteId) async {
    state = state
        .map((group) => group.id == groupId
            ? group.copyWith(notes: group.notes.where((n) => n.id != noteId).toList())
            : group)
        .where((group) => group.notes.isNotEmpty || group.title == 'Checklist')
        .toList();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(state.map((g) => g.toJson()).toList()));
    } catch (_) {}
  }

  static String _id() => DateTime.now().microsecondsSinceEpoch.toString();
}

final notesProvider = NotifierProvider<NotesNotifier, List<NoteGroup>>(NotesNotifier.new);
