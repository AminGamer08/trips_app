import 'dart:convert';
import 'package:adventure_journal/app/adventure_journal_app.dart';
import 'package:adventure_journal/app/router.dart';
import 'package:adventure_journal/models/journal.dart';
import 'package:adventure_journal/repositories/local_journal_repository.dart';
import 'package:adventure_journal/services/export_service.dart';
import 'package:adventure_journal/services/location_service.dart';
import 'package:adventure_journal/services/photo_service.dart';
import 'package:adventure_journal/state/journal_provider.dart';
import 'package:adventure_journal/utilities/app_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

class _DeniedLocation implements LocationService {
  @override
  Future<Coordinates> currentPosition() async => throw const AppException(
    'Standortfreigabe verweigert. Du kannst die Karte verwenden.',
  );
}

class _FixturePhoto extends PhotoService {
  @override
  Future<Map<String, Uint8List>> recoverLostPhotos() async => {};
  @override
  Future<Map<String, Uint8List>> pick({
    bool camera = false,
    int limit = 8,
  }) async {
    final data = await rootBundle.load('assets/images/cafe.jpg');
    return {
      'integration-photo': data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      ),
    };
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Offline journal: create with photo, search, edit, export, reopen and delete',
    (tester) async {
      await initializeDateFormatting('de');
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/integration-${DateTime.now().microsecondsSinceEpoch}.db';
      final db = await databaseFactoryIo.openDatabase(path);
      final repo = LocalJournalRepository(db);
      await repo.initialize();
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWith((ref) async => repo),
          locationServiceProvider.overrideWithValue(_DeniedLocation()),
          photoServiceProvider.overrideWithValue(_FixturePhoto()),
        ],
      );
      await container.read(journalProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AdventureJournalApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);
      router.push('/place/new');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Galerie'));
      await tester.pumpAndSettle();
      expect(find.text('1/8 Fotos'), findsOneWidget);
      await tester.ensureVisible(find.text('Mein Standort'));
      await tester.tap(find.text('Mein Standort'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Standortfreigabe verweigert'),
        findsOneWidget,
      );
      for (final entry in {
        'place-name': 'Ein Test am See',
        'place-city': 'Potsdam',
        'place-country': 'Deutschland',
        'place-latitude': '52.4',
        'place-longitude': '13.0',
      }.entries) {
        final field = find.byKey(Key(entry.key));
        await tester.ensureVisible(field);
        await tester.enterText(field, entry.value);
        await tester.pump();
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('editor-save')));
      await tester.pumpAndSettle();
      final created = container
          .read(journalProvider)
          .asData!
          .value
          .places
          .first;
      expect(created.name, 'Ein Test am See');
      expect(await repo.readPhoto('integration-photo'), isNotEmpty);
      router.push('/search');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(SearchBar), 'Potsdam');
      await tester.pumpAndSettle();
      expect(find.text('1 Erinnerung'), findsOneWidget);
      await tester.tap(find.text('Ein Test am See'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Bearbeiten'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('place-name')));
      await tester.enterText(
        find.byKey(const Key('place-name')),
        'Ein stiller See',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('editor-save')));
      await tester.pumpAndSettle();
      expect(find.text('Ein stiller See'), findsWidgets);
      final exported =
          jsonDecode(await ExportService().createJson(repo)) as Map;
      expect(
        (exported['photos'] as List).any((p) => p['id'] == 'integration-photo'),
        isTrue,
      );
      await tester.tap(find.byTooltip('Löschen'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
      await tester.pumpAndSettle();
      expect(
        container.read(journalProvider).asData!.value.place(created.id),
        isNull,
      );
      expect(await repo.readPhoto('integration-photo'), isNull);
      for (final route in [
        '/trips',
        '/trip/paris',
        '/map',
        '/stats',
        '/settings',
      ]) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: route);
      }
      await container
          .read(journalProvider.notifier)
          .updateSettings(
            appearance: Appearance.dark,
            unit: DistanceUnit.miles,
          );
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await db.close();
      final reopened = await databaseFactoryIo.openDatabase(path);
      final restored = LocalJournalRepository(reopened);
      expect((await restored.read()).place(created.id), isNull);
      expect((await restored.read()).settings.appearance, Appearance.dark);
      await reopened.close();
      await databaseFactoryIo.deleteDatabase(path);
    },
  );
}
