import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../widgets/placeholder_screen.dart';
import 'app_routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.about,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellWidget(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.about,
                name: 'about',
                builder: (context, state) => const PlaceholderScreen(
                  title: 'About',
                  details: 'About feature placeholder',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.conditions,
                name: 'conditions',
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Conditions',
                  details: 'Conditions list placeholder',
                ),
                routes: [
                  GoRoute(
                    path: ':conditionId',
                    name: 'conditionDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['conditionId']!;
                      return PlaceholderScreen(
                        title: 'Condition',
                        details: 'Condition detail placeholder ($id)',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.services,
                name: 'services',
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Services',
                  details: 'Services list placeholder',
                ),
                routes: [
                  GoRoute(
                    path: ':serviceId',
                    name: 'serviceDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['serviceId']!;
                      return PlaceholderScreen(
                        title: 'Service',
                        details: 'Service detail placeholder ($id)',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.blog,
                name: 'blog',
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Blog',
                  details: 'Blog list placeholder',
                ),
                routes: [
                  GoRoute(
                    path: ':articleId',
                    name: 'blogDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['articleId']!;
                      return PlaceholderScreen(
                        title: 'Article',
                        details: 'Blog article placeholder ($id)',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.patient,
                name: 'patient',
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Patient',
                  details: 'Patient area placeholder',
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.appointment,
        name: 'appointment',
        redirect: (context, state) {
          final sourceContext =
              state.uri.queryParameters[AppConstants.sourceContextQueryParam];
          // No direct/deep-link entry without required sourceContext.
          if (sourceContext == null || sourceContext.trim().isEmpty) {
            return AppRoutes.about;
          }
          return null;
        },
        builder: (context, state) {
          final sourceContext =
              state.uri.queryParameters[AppConstants.sourceContextQueryParam]!;
          return PlaceholderScreen(
            title: 'Appointment',
            details: 'Appointment placeholder (source: $sourceContext)',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.faq,
        name: 'faq',
        builder: (context, state) => const PlaceholderScreen(
          title: 'FAQ',
          details: 'FAQ placeholder',
        ),
      ),
      GoRoute(
        path: AppRoutes.contact,
        name: 'contact',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Contact',
          details: 'Contact placeholder',
        ),
      ),
    ],
  );
}

class MainShellWidget extends StatelessWidget {
  const MainShellWidget({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = <_TabDestination>[
    _TabDestination(
      label: 'About',
      icon: Icons.info_outline,
      selectedIcon: Icons.info,
    ),
    _TabDestination(
      label: 'Conditions',
      icon: Icons.health_and_safety_outlined,
      selectedIcon: Icons.health_and_safety,
    ),
    _TabDestination(
      label: 'Services',
      icon: Icons.medical_services_outlined,
      selectedIcon: Icons.medical_services,
    ),
    _TabDestination(
      label: 'Blog',
      icon: Icons.article_outlined,
      selectedIcon: Icons.article,
    ),
    _TabDestination(
      label: 'Patient',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.surfaceMuted,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

class _TabDestination {
  const _TabDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
