import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/journal.dart';
import '../presentation/screens/detail_screens.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/map_screen.dart';
import '../presentation/screens/place_form_screen.dart';
import '../presentation/screens/search_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/stats_screen.dart';
import '../presentation/screens/trip_form_screen.dart';
import '../presentation/screens/trips_screen.dart';
import '../presentation/widgets/common.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/home'),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _NavigationShell(shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/map', builder: (_, _) => const MapScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/trips', builder: (_, _) => const TripsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/stats', builder: (_, _) => const StatsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      GoRoute(
        path: '/place/new',
        builder: (_, state) {
          final lat = double.tryParse(state.uri.queryParameters['lat'] ?? ''),
              lng = double.tryParse(state.uri.queryParameters['lng'] ?? '');
          final coordinates =
              lat != null && lng != null && Coordinates(lat, lng).isValid
              ? Coordinates(lat, lng)
              : null;
          return PlaceFormScreen(
            coordinates: coordinates,
            tripId: state.uri.queryParameters['trip'],
          );
        },
      ),
      GoRoute(
        path: '/place/:id',
        builder: (_, state) =>
            PlaceDetailScreen(id: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) =>
                PlaceFormScreen(id: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: '/trip/new', builder: (_, _) => const TripFormScreen()),
      GoRoute(
        path: '/trip/:id',
        builder: (_, state) =>
            TripDetailScreen(id: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) =>
                TripFormScreen(id: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: EmptyState(
        icon: Icons.explore_off_outlined,
        title: 'Hier geht es zurück zum Journal',
        message: 'Diese Seite konnte nicht gefunden werden.',
        action: 'Zum Journal',
        onAction: () => context.go('/home'),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});

class _NavigationShell extends StatelessWidget {
  const _NavigationShell(this.shell);
  final StatefulNavigationShell shell;
  static const _labels = [
    'Journal',
    'Karte',
    'Reisen',
    'Statistik',
    'Settings',
  ];
  static const _icons = [
    Icons.home_outlined,
    Icons.map_outlined,
    Icons.luggage_outlined,
    Icons.bar_chart_outlined,
    Icons.tune_rounded,
  ];
  static const _selectedIcons = [
    Icons.home_rounded,
    Icons.map_rounded,
    Icons.luggage_rounded,
    Icons.bar_chart_rounded,
    Icons.tune_rounded,
  ];
  void _select(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    return Scaffold(
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              minWidth: 104,
              groupAlignment: -.6,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 26),
                child: Icon(
                  Icons.explore_outlined,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              destinations: [
                for (var i = 0; i < _labels.length; i++)
                  NavigationRailDestination(
                    icon: Icon(_icons[i]),
                    selectedIcon: Icon(_selectedIcons[i]),
                    label: Text(_labels[i]),
                  ),
              ],
            ),
          if (wide)
            VerticalDivider(
              width: 1,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: .4),
            ),
          Expanded(child: shell),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _select,
              destinations: [
                for (var i = 0; i < _labels.length; i++)
                  NavigationDestination(
                    icon: Icon(_icons[i]),
                    selectedIcon: Icon(_selectedIcons[i]),
                    label: _labels[i],
                  ),
              ],
            ),
      floatingActionButton: shell.currentIndex == 0
          ? FloatingActionButton(
              tooltip: 'Neuen Ort hinzufügen',
              onPressed: () => context.push('/place/new'),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}
