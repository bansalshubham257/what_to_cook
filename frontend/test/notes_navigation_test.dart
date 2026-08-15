import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_to_cook/presentation/providers/ads_provider.dart';
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

  testWidgets('tapping the notes card opens the notes screen', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: SingleChildScrollView(child: NotesCard()),
          ),
        ),
        GoRoute(
          path: '/notes',
          builder: (_, __) => const Scaffold(body: Text('NOTES_SCREEN')),
        ),
        GoRoute(
          path: '/note',
          builder: (_, __) => const Scaffold(body: Text('NOTE_DETAIL')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adServiceProvider.overrideWithValue(_FakeAdService()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NOTES_SCREEN'), findsNothing);
    await tester.tap(find.text('Checklist / Notes'));
    await tester.pumpAndSettle();
    expect(find.text('NOTES_SCREEN'), findsOneWidget);
  });
}
