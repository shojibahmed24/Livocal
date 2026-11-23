import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/shared/utils/contact_grouping.dart';

class _Row {
  final String name;
  const _Row(this.name);
}

void main() {
  group('ContactGrouping.byInitial', () {
    test('groups alphabetically and keeps order', () {
      final groups = ContactGrouping.byInitial(
        const [_Row('Rose'), _Row('alice'), _Row('Bob'), _Row('ahmed')],
        nameOf: (row) => row.name,
      );

      expect(groups.keys.toList(), ['A', 'B', 'R']);
      expect(groups['A']!.map((r) => r.name).toList(), ['ahmed', 'alice']);
      expect(groups['B']!.single.name, 'Bob');
      expect(groups['R']!.single.name, 'Rose');
    });

    test('names with spaces are trimmed before grouping', () {
      final groups = ContactGrouping.byInitial(
        const [_Row('  Karim '), _Row('Kobita')],
        nameOf: (row) => row.name,
      );
      expect(groups.keys.toList(), ['K']);
      expect(groups['K']!.length, 2);
    });

    test('empty names land under the # bucket', () {
      final groups = ContactGrouping.byInitial(
        const [_Row(''), _Row('Zara')],
        nameOf: (row) => row.name,
      );
      expect(groups.keys.toList(), ['#', 'Z']);
    });

    test('empty input produces no groups', () {
      expect(
        ContactGrouping.byInitial(
          const <_Row>[],
          nameOf: (row) => row.name,
        ),
        isEmpty,
      );
    });
  });
}
