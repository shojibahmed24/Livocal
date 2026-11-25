import 'package:livocal/shared/utils/text_safe.dart';

/// Alphabetical grouping shared by the contact picker and the contacts tab.
class ContactGrouping {
  ContactGrouping._();

  /// Sorts [items] by [nameOf] (case-insensitive) and groups them by the first
  /// character of the name. Empty names land under `#`.
  ///
  /// The returned map keeps insertion order, which is already alphabetical, so
  /// the UI can render sections without sorting again.
  static Map<String, List<T>> byInitial<T>(
    Iterable<T> items, {
    required String Function(T item) nameOf,
  }) {
    final sorted = items.toList()
      ..sort(
        (a, b) => nameOf(a)
            .trim()
            .toLowerCase()
            .compareTo(nameOf(b).trim().toLowerCase()),
      );

    final groups = <String, List<T>>{};
    for (final item in sorted) {
      final name = nameOf(item).trim();
      final initial = name.isEmpty ? '#' : firstRune(name).toUpperCase();
      groups.putIfAbsent(initial, () => <T>[]).add(item);
    }
    return groups;
  }
}
