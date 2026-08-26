class TypeHelper {
  static String formatTypeLabel(String rawType) {
    final trimmed = rawType.trim();
    if (trimmed.isEmpty) return 'Other';

    final lower = trimmed.toLowerCase();
    if (lower == 'lightnovel' || lower == 'light novel' || lower == 'ln') {
      return 'Light Novel';
    }
    if (lower == 'manga') return 'Manga';
    if (lower == 'comic' || lower == 'comics') return 'Comic';
    if (lower == 'book' || lower == 'books') return 'Book';

    return trimmed.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  static String normalizeKey(String type) {
    final trimmed = type.trim();
    final lower = trimmed.toLowerCase();
    if (lower == 'light novel' || lower == 'lightnovel' || lower == 'ln') {
      return 'lightNovel';
    }
    if (lower == 'manga') return 'manga';
    if (lower == 'comic' || lower == 'comics') return 'comic';
    if (lower == 'book' || lower == 'books') return 'book';
    return trimmed;
  }

  static List<String> getAllAvailableTypes(Iterable<String> existingTypes) {
    final types = <String>{};
    for (final t in existingTypes) {
      if (t.trim().isNotEmpty) {
        types.add(formatTypeLabel(t));
      }
    }
    return types.toList()..sort();
  }
}
