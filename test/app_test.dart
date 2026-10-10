import 'package:adventure_journal/app/adventure_journal_app.dart';
import 'package:adventure_journal/app/router.dart';
import 'package:adventure_journal/models/journal.dart';
import 'package:adventure_journal/repositories/local_journal_repository.dart';
import 'package:adventure_journal/state/journal_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de');
    final font = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await font.load();
  });
  Future<ProviderContainer> launch(
    WidgetTester tester, {
    double width = 412,
  }) async {
    tester.view.physicalSize = Size(width, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = (await tester.runAsync(() async {
      final db = await databaseFactoryMemory.openDatabase(
        'widget-${DateTime.now().microsecondsSinceEpoch}',
      );
      final repo = LocalJournalRepository(db);
      await repo.initialize();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWith((ref) async => repo)],
      );
      addTearDown(container.dispose);
      await container.read(journalProvider.future);
      return container;
    }))!;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AdventureJournalApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  for (final width in [320.0, 412.0, 1024.0]) {
    testWidgets(
      'Dashboard and main screens fit a $width logical pixel viewport',
      (tester) async {
        final container = await launch(tester, width: width);
        expect(find.text('Deine Welt.\nDeine Geschichten.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        for (final route in ['/map', '/trips', '/stats', '/settings']) {
          container.read(routerProvider).go(route);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: route);
        }
        await tester.runAsync(
          () => container
              .read(journalProvider.notifier)
              .saveSettings(const JournalSettings(appearance: Appearance.dark)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Place form validates, saves and refreshes the journal', (
    tester,
  ) async {
    final container = await launch(tester);
    container.read(routerProvider).push('/place/new');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editor-save')));
    await tester.pumpAndSettle();
    expect(find.text('Bitte ausfüllen.'), findsWidgets);
    for (final entry in {
      'place-name': 'Test am See',
      'place-city': 'Potsdam',
      'place-country': 'Deutschland',
      'place-latitude': '52,4',
      'place-longitude': '13.0',
    }.entries) {
      final field = find.byKey(Key(entry.key));
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
      await tester.pump();
    }
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('editor-save')));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    expect(container.read(journalProvider).asData!.value.places.length, 15);
    expect(
      container.read(journalProvider).asData!.value.places.first.name,
      'Test am See',
    );
    expect(find.text('Änderungen verwerfen?'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Search and filter update results and can be reset', (
    tester,
  ) async {
    final container = await launch(tester);
    container.read(routerProvider).push('/search');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'Amsterdam');
    await tester.pumpAndSettle();
    expect(find.text('2 Erinnerungen'), findsOneWidget);
    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Nature'));
    await tester.tap(find.text('Erinnerungen anzeigen'));
    await tester.pumpAndSettle();
    expect(find.text('1 Erinnerung'), findsOneWidget);
    expect(find.text('Vondelpark'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
