import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_to_cook/presentation/providers/ads_provider.dart';
import 'package:what_to_cook/presentation/providers/notes_provider.dart';
import 'package:what_to_cook/presentation/widgets/notes_card.dart';

class _FakeAdService extends AdService {
  @override
  Future<bool> showRewardedAd({
    required Function onRewarded,
    Function? onAdDismissed,
  }) async {
    return false;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('closing the add-note bottom sheet does not crash', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adServiceProvider.overrideWithValue(_FakeAdService()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NotesCard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add detailed note'));
    await tester.pumpAndSettle();
    expect(find.text('New note'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
  });
}
