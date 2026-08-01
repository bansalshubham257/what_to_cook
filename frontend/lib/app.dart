import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/constants/category_catalog.dart';
import 'presentation/providers/ads_provider.dart';
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
import 'presentation/screens/planner/meal_plan_screen.dart';
import 'presentation/screens/recipe/recipe_detail_screen.dart';
import 'presentation/screens/shopping_list/shopping_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) => ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/kitchen', builder: (_, __) => const KitchenScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/suggestions', builder: (_, __) => const SuggestionsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/insights', builder: (_, __) => const InsightsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '/recipe/:id',
        builder: (_, state) => RecipeDetailScreen(recipeId: state.pathParameters['id']!),
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
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = ref.read(adServiceProvider).createBannerAd(
      onLoaded: () {
        if (mounted) {
          setState(() => _isBannerLoaded = true);
        }
      },
      onFailed: (error) {
        if (mounted) {
          setState(() => _isBannerLoaded = false);
        }
      },
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isBannerLoaded && _bannerAd != null)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          NavigationBar(
            selectedIndex: widget.navigationShell.currentIndex,
            onDestinationSelected: (index) {
              widget.navigationShell.goBranch(index, initialLocation: index == widget.navigationShell.currentIndex);
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.kitchen_outlined), selectedIcon: Icon(Icons.kitchen), label: 'Kitchen'),
              NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu), label: 'Suggestions'),
              NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Insights'),
              NavigationDestination(icon: Icon(Icons.person_outlined), selectedIcon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ],
      ),
    );
  }
}