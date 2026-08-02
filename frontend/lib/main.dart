import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app.dart';
import 'core/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'presentation/providers/ads_provider.dart';
import 'presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await MobileAds.instance.initialize();
  runApp(
    const ProviderScope(
      child: WhatToCookApp(),
    ),
  );
}

class WhatToCookApp extends ConsumerWidget {
  const WhatToCookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize ad service
    ref.watch(adServiceProvider).initialize();
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: 'What to Cook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
