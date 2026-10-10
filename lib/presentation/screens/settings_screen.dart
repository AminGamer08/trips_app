import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../models/journal.dart';
import '../../services/export_service.dart';
import '../../state/journal_provider.dart';
import '../../utilities/app_exception.dart';
import '../widgets/common.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;
  Future<void> _save({
    Appearance? appearance,
    DistanceUnit? unit,
    int? seed,
    bool? dynamicColors,
  }) async {
    try {
      await ref
          .read(journalProvider.notifier)
          .updateSettings(
            appearance: appearance,
            unit: unit,
            seed: seed,
            dynamicColors: dynamicColors,
          );
    } catch (e) {
      if (mounted) {
        showMessage(context, friendlyError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) => JournalAsync(
    builder: (data) {
      final settings = data.settings, scheme = Theme.of(context).colorScheme;
      return JournalPage(
        children: [
          const PageHeading(
            eyebrow: 'Ganz nach deinem Gefühl',
            title: 'Dein Journal. Dein Stil.',
            subtitle: 'Ein kleiner Platz für deine Vorlieben.',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: Space.smallRadius,
                    ),
                    child: Icon(
                      Icons.auto_stories_outlined,
                      color: scheme.onPrimaryContainer,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nur deine Geschichten',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Lokal gespeichert. Auch ohne Internet bei dir.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeading('So sieht dein Journal aus'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Erscheinungsbild',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<Appearance>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: Appearance.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto_outlined),
                        ),
                        ButtonSegment(
                          value: Appearance.light,
                          label: Text('Hell'),
                          icon: Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment(
                          value: Appearance.dark,
                          label: Text('Dunkel'),
                          icon: Icon(Icons.dark_mode_outlined),
                        ),
                      ],
                      selected: {settings.appearance},
                      onSelectionChanged: (values) =>
                          _save(appearance: values.first),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Deine Farbe',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 14,
                    runSpacing: 12,
                    children: [
                      for (final seed in JournalTheme.seeds.entries)
                        Tooltip(
                          message: seed.key,
                          child: Semantics(
                            label: seed.key,
                            selected: settings.seed == seed.value,
                            button: true,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () =>
                                  _save(seed: seed.value, dynamicColors: false),
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Color(seed.value),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color:
                                        settings.seed == seed.value &&
                                            !settings.dynamicColors
                                        ? scheme.onSurface
                                        : scheme.surface,
                                    width: 2,
                                  ),
                                ),
                                child:
                                    settings.seed == seed.value &&
                                        !settings.dynamicColors
                                    ? Icon(
                                        Icons.check_rounded,
                                        color: Theme.of(
                                          context,
                                        ).extension<JournalPalette>()!.onPhoto,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Gerätefarben verwenden'),
                    subtitle: const Text(
                      'Wenn unterstützt, passend zu deinem Hintergrundbild.',
                    ),
                    value: settings.dynamicColors,
                    onChanged: (value) => _save(dynamicColors: value),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeading('Unterwegs'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: DropdownButtonFormField<DistanceUnit>(
                initialValue: settings.unit,
                decoration: const InputDecoration(
                  labelText: 'Entfernungseinheit',
                ),
                items: const [
                  DropdownMenuItem(
                    value: DistanceUnit.kilometers,
                    child: Text('Kilometer (km)'),
                  ),
                  DropdownMenuItem(
                    value: DistanceUnit.miles,
                    child: Text('Meilen (mi)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _save(unit: value);
                  }
                },
              ),
            ),
          ),
          const SectionHeading('Deine Erinnerungen'),
          Card(
            child: Column(
              children: [
                Builder(
                  builder: (buttonContext) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    leading: const Icon(Icons.ios_share_rounded),
                    title: const Text('Daten exportieren'),
                    subtitle: const Text(
                      'Dein Journal mit Fotos als JSON-Datei',
                    ),
                    trailing: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    enabled: !_busy,
                    onTap: () async {
                      setState(() => _busy = true);
                      try {
                        final box =
                            buttonContext.findRenderObject() as RenderBox;
                        final origin =
                            box.localToGlobal(Offset.zero) & box.size;
                        final repository = await ref.read(
                          repositoryProvider.future,
                        );
                        await ExportService().share(repository, origin);
                      } catch (e) {
                        if (context.mounted) {
                          showMessage(context, friendlyError(e));
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _busy = false);
                        }
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: scheme.error,
                  ),
                  title: Text(
                    'Reisedaten löschen',
                    style: TextStyle(color: scheme.error),
                  ),
                  subtitle: const Text('Alle Reisen, Orte und Fotos entfernen'),
                  enabled: !_busy,
                  onTap: () async {
                    if (!await confirmAction(
                      context,
                      title: 'Dein Journal wirklich leeren?',
                      message:
                          'Alle ${data.places.length} Orte, ${data.trips.length} Reisen und ihre Fotos werden dauerhaft gelöscht. Deine Einstellungen bleiben erhalten. Exportiere vorher eine Kopie.',
                    )) {
                      return;
                    }
                    setState(() => _busy = true);
                    try {
                      await ref.read(journalProvider.notifier).clearData();
                      ref
                          .read(searchFilterProvider.notifier)
                          .update(const PlaceFilter());
                      if (context.mounted) {
                        showMessage(
                          context,
                          'Dein Journal ist jetzt leer. Platz für neue Abenteuer.',
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showMessage(context, friendlyError(e));
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _busy = false);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SectionHeading('Mit Liebe zum Unterwegssein'),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: const Icon(Icons.explore_outlined),
              title: const Text('Adventure Journal'),
              subtitle: const Text('Version 1.0.0'),
              trailing: const Icon(Icons.info_outline_rounded),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Adventure Journal',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.explore_outlined,
                  size: 42,
                  color: scheme.primary,
                ),
                children: [
                  const Text(
                    'Dein persönliches Reisetagebuch. Für die großen Reisen und die kleinen Momente dazwischen.',
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Karte: Natural Earth (Public Domain). Beispielfotos: Unsplash. Schrift: Manrope (SIL OFL).',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              'MADE FOR YOUR NEXT CHAPTER',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 2,
                color: scheme.outline,
              ),
            ),
          ),
        ],
      );
    },
  );
}
