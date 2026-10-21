// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/storage/isar_service.dart';
import 'core/theme/app_theme.dart';
import 'core/settings/app_settings.dart';
import 'core/localization/app_localizations.dart';
import 'features/home/presentation/pages/home_studio_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IsarService.initialize();

  runApp(
    const ProviderScope(
      child: BoltApp(),
    ),
  );
}

class BoltApp extends ConsumerWidget {
  const BoltApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).settings;

    return MaterialApp(
      title: 'Bolt API Client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        visualDensity: settings.compactDensity
            ? VisualDensity.compact
            : VisualDensity.standard,
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        visualDensity: settings.compactDensity
            ? VisualDensity.compact
            : VisualDensity.standard,
      ),
      themeMode: settings.themeMode,
      locale: settings.languageCode == 'en'
          ? const Locale('en')
          : const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('en'),
        Locale('pt', 'BR'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(settings.textScale),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const HomeStudioPage(),
    );
  }
}