import 'package:flutter/material.dart';
import 'package:livocal/shared/ui/livocal_card.dart';
import 'package:livocal/shared/widgets/settings_row.dart';

/// Grouped card used by every settings sub-screen.
/// The hub (`settings_screen.dart`) already draws its rows inside one rounded
/// card per section, so sub-screens use this widget to stay visually
/// consistent instead of flat rows with full-width dividers.
class SettingsGroup extends StatelessWidget {
  final String? title;
  final List<Widget> rows;
  final EdgeInsetsGeometry margin;

  const SettingsGroup({
    super.key,
    this.title,
    required this.rows,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(
          Divider(
            height: 1,
            thickness: 0.6,
            indent: 66,
            color: Theme.of(context).dividerColor,
          ),
        );
      }
      children.add(rows[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) SettingsSectionHeader(title: title!.toUpperCase()),
        LivocalCard(
          margin: margin,
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// Turns a flat `ListView` of [SettingsRow]s, [SettingsSectionHeader]s and
/// [Divider]s into the same grouped cards the settings hub uses. Sub-screens
/// only need to swap `ListView` for this widget — their row code stays as is.
class SettingsGroupedList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;

  const SettingsGroupedList({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.only(top: 4, bottom: 28),
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];
    final rows = <Widget>[];
    String? title;

    void flush() {
      if (rows.isEmpty) {
        title = null;
        return;
      }
      sections.add(SettingsGroup(title: title, rows: List.of(rows)));
      rows.clear();
      title = null;
    }

    for (final child in children) {
      if (child is SettingsSectionHeader) {
        flush();
        title = child.title;
      } else if (child is Divider) {
        // Dividers are re-drawn by SettingsGroup inside each card.
        continue;
      } else {
        rows.add(child);
      }
    }
    flush();

    return ListView(
      padding: padding,
      physics: physics,
      children: sections,
    );
  }
}
