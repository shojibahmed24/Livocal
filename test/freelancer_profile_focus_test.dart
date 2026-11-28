import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:livocal/features/freelancer/models/freelancer_profile.dart';
import 'package:livocal/features/freelancer/widgets/profile_pro_fields.dart';

/// Regression: autosave used to pass a `ValueKey(updatedAt)` to
/// `ProfileProFields`, so every save recreated the fields and the keyboard
/// closed. The profile screen now rebuilds the widget in place; this test
/// proves the fields keep focus and text across those rebuilds.
void main() {
  testWidgets('pro fields keep focus and text across parent rebuilds',
      (tester) async {
    final profile = FreelancerProfile(
      ownerUid: 'uid-1',
      slug: 'shojib',
      username: 'shojib',
      displayName: 'Shojib',
      updatedAt: DateTime(2026, 1, 1),
    );
    late StateSetter rebuildHost;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              StatefulBuilder(
                builder: (context, setState) {
                  rebuildHost = setState;
                  return ProfileProFields(
                    profile: profile,
                    t: (key) => key,
                    mutate: (change) => setState(() => change(profile)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    final github = find.byKey(const ValueKey('profilePro-githubUrl'));
    await tester.ensureVisible(github);
    await tester.tap(github);
    await tester.pump();
    await tester.enterText(github, 'github.com/shojib');
    await tester.pump(const Duration(milliseconds: 600));

    // Simulates the autosave rebuild that runs after the 450 ms debounce.
    rebuildHost(() {});
    await tester.pump();

    final editable = tester.widget<EditableText>(
      find.descendant(of: github, matching: find.byType(EditableText)),
    );
    expect(editable.focusNode.hasFocus, isTrue);
    expect(editable.controller.text, 'github.com/shojib');
    expect(profile.githubUrl, 'github.com/shojib');
  });
}
