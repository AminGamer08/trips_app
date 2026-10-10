import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journal.dart';
import '../state/journal_provider.dart';
import 'router.dart';
import 'theme.dart';

class AdventureJournalApp extends ConsumerWidget {
  const AdventureJournalApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(journalProvider).asData?.value.settings ??
        const JournalSettings();
    return DynamicColorBuilder(
      builder: (light, dark) => MaterialApp.router(
        title: 'Adventure Journal',
        debugShowCheckedModeBanner: false,
        routerConfig: ref.watch(routerProvider),
        locale: const Locale('de'),
        supportedLocales: const [Locale('de')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: JournalTheme.build(
          Brightness.light,
          settings.seed,
          dynamicScheme: settings.dynamicColors ? light : null,
        ),
        darkTheme: JournalTheme.build(
          Brightness.dark,
          settings.seed,
          dynamicScheme: settings.dynamicColors ? dark : null,
        ),
        themeMode: switch (settings.appearance) {
          Appearance.system => ThemeMode.system,
          Appearance.light => ThemeMode.light,
          Appearance.dark => ThemeMode.dark,
        },
        themeAnimationDuration: const Duration(milliseconds: 250),
      ),
    );
  }
}
