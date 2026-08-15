import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/constants/category_catalog.dart';
import 'l10n/generated/app_localizations.dart';
import 'presentation/providers/ads_provider.dart';
import 'presentation/providers/meal_history_provider.dart';
import 'presentation/providers/notes_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/kitchen/kitchen_screen.dart';
import 'presentation/screens/suggestions/suggestions_screen.dart';
import 'presentation/screens/explore/explore_screen.dart';
import 'presentation/screens/explore/explore_special_screen.dart';
import 'presentation/screens/discover/favorites_screen.dart';
import 'presentation/screens/discover/category_detail_screen.dart';
import 'presentation/screens/discover/dish_detail_screen.dart';
import 'presentation/screens/insights/insights_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/profile/meal_history_screen.dart';
import 'presentation/screens/profile/notes_screen.dart';
import 'presentation/screens/profile/note_detail_screen.dart';
import 'presentation/screens/planner/meal_plan_screen.dart';
import 'presentation/screens/recipe/recipe_detail_screen.dart';
import 'presentation/screens/shopping_list/shopping_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, __) => const HomeScreen())
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/kitchen', builder: (_, __) => const KitchenScreen())
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/suggestions',
                  builder: (_, __) => const SuggestionsScreen())
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/insights', builder: (_, __) => const InsightsScreen())
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/profile', builder: (_, __) => const ProfileScreen())
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/recipe/:id',
        builder: (_, state) =>
            RecipeDetailScreen(recipeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/favorites',
        builder: (_, __) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/explore',
        builder: (_, __) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/explore-special',
        builder: (_, __) => const ExploreSpecialScreen(),
      ),
      GoRoute(
        path: '/category/:slug',
        builder: (_, state) => CategoryDetailScreen(
          slug: state.pathParameters['slug']!,
          label: state.uri.queryParameters['label'],
          cuisine: state.uri.queryParameters['cuisine'],
          meal: state.uri.queryParameters['meal'],
          filters: state.uri.queryParameters['filters'],
        ),
      ),
      GoRoute(
        path: '/meal-plan',
        builder: (_, __) => const MealPlanScreen(),
      ),
      GoRoute(
        path: '/meal-history',
        builder: (_, __) => const MealHistoryScreen(),
      ),
      GoRoute(
        path: '/dish',
        builder: (_, state) {
          final extra = state.extra as (CategoryDish, String);
          return DishDetailScreen(dish: extra.$1, categorySlug: extra.$2);
        },
      ),
      GoRoute(
        path: '/shopping-list',
        builder: (_, __) => const ShoppingListScreen(),
      ),
      GoRoute(
        path: '/notes',
        builder: (_, __) => const NotesScreen(),
      ),
      GoRoute(
        path: '/note',
        builder: (_, state) => NoteDetailScreen(note: state.extra as NoteEntry),
      ),
    ],
  );
});

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  static const _tabCount = 5;
  static const _insightsIndex = 3;

  void _maybeRefreshInsights(int index) {
    if (index == _insightsIndex) {
      ref.read(insightsRefreshProvider.notifier).bump();
    }
  }

  /// Swipes between bottom tabs while keeping the IndexedStack state intact.
  /// A fast horizontal fling (or slow drag past half the screen) switches tabs.
  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final current = widget.navigationShell.currentIndex;
    if (velocity < -250 && current < _tabCount - 1) {
      widget.navigationShell.goBranch(current + 1);
      _maybeRefreshInsights(current + 1);
    } else if (velocity > 250 && current > 0) {
      widget.navigationShell.goBranch(current - 1);
      _maybeRefreshInsights(current - 1);
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // No-op: presence here lets the gesture win over inner horizontal
    // scrollables once the drag is strongly horizontal.
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: _BottomNavWithBanner(
          navigationShell: widget.navigationShell,
          onDestinationSelected: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
            _maybeRefreshInsights(index);
          },
        ),
      ),
    );
  }
}

/// Separate widget to manage banner ad lifecycle independently
class _BottomNavWithBanner extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onDestinationSelected;
  const _BottomNavWithBanner({
    required this.navigationShell,
    required this.onDestinationSelected,
  });

  @override
  ConsumerState<_BottomNavWithBanner> createState() =>
      _BottomNavWithBannerState();
}

class _BottomNavWithBannerState extends ConsumerState<_BottomNavWithBanner> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    if (_isDisposed) return;

    _bannerAd?.dispose();
    _bannerAd = ref.read(adServiceProvider).createBannerAd(
      onLoaded: () {
        if (!mounted || _isDisposed) {
          return;
        }
        setState(() => _isBannerLoaded = true);
      },
      onFailed: (error) {
        if (!mounted || _isDisposed) return;
        setState(() => _isBannerLoaded = false);
        // Retry after 30 seconds
        Future.delayed(const Duration(seconds: 30), _loadBannerAd);
      },
    )..load();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isBannerLoaded && _bannerAd != null)
          Container(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            color: Colors.grey[100],
            child: AdWidget(ad: _bannerAd!),
          ),
        NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: widget.onDestinationSelected,
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: l10n.tabHome),
            NavigationDestination(
                icon: const Icon(Icons.kitchen_outlined),
                selectedIcon: const Icon(Icons.kitchen),
                label: l10n.tabKitchen),
            NavigationDestination(
                icon: const Icon(Icons.lightbulb_outline),
                selectedIcon: const Icon(Icons.lightbulb),
                label: l10n.tabSuggestions),
            NavigationDestination(
                icon: const Icon(Icons.insights_outlined),
                selectedIcon: const Icon(Icons.insights),
                label: l10n.tabInsights),
            NavigationDestination(
                icon: const Icon(Icons.person_outlined),
                selectedIcon: const Icon(Icons.person),
                label: l10n.tabProfile),
          ],
        ),
      ],
    );
  }
}
