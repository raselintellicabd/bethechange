import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/presentation/screens/about_menu_screen.dart';
import '../../features/about/presentation/screens/about_slug_screen.dart';
import '../../features/appointment/domain/models/source_context.dart';
import '../../features/appointment/presentation/screens/appointment_screen.dart';
import '../../features/blog/presentation/screens/blog_detail_screen.dart';
import '../../features/blog/presentation/screens/blog_list_screen.dart';
import '../../features/chatbot/presentation/screens/chatbot_screen.dart';
import '../../features/conditions/presentation/screens/condition_detail_screen.dart';
import '../../features/contact/presentation/screens/contact_screen.dart';
import '../../features/explore/presentation/screens/explore_screen.dart';
import '../../features/faq/presentation/screens/faq_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/patient/presentation/screens/patient_tab_screen.dart';
import '../../features/services/presentation/screens/service_detail_screen.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import 'app_routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final path = state.uri.path;

      if (path == AppRoutes.patient) return AppRoutes.patients;
      if (path == AppRoutes.conditions) return AppRoutes.exploreConditions;
      if (path == AppRoutes.services) return AppRoutes.exploreServices;
      if (path == AppRoutes.explore) return AppRoutes.exploreConditions;

      if (path.startsWith('${AppRoutes.conditions}/')) {
        final id = path.substring(AppRoutes.conditions.length + 1);
        if (id.isNotEmpty) return AppRoutes.conditionDetailPath(id);
      }
      if (path.startsWith('${AppRoutes.services}/')) {
        final id = path.substring(AppRoutes.services.length + 1);
        if (id.isNotEmpty) return AppRoutes.serviceDetailPath(id);
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellWidget(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.explore,
                name: 'explore',
                redirect: (context, state) {
                  if (state.uri.path == AppRoutes.explore) {
                    return AppRoutes.exploreConditions;
                  }
                  return null;
                },
                routes: [
                  GoRoute(
                    path: 'conditions',
                    name: 'exploreConditions',
                    builder: (context, state) =>
                        const ExploreScreen(initialSegment: 0),
                    routes: [
                      GoRoute(
                        path: ':conditionId',
                        name: 'conditionDetail',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final id = state.pathParameters['conditionId']!;
                          return ConditionDetailScreen(conditionId: id);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'services',
                    name: 'exploreServices',
                    builder: (context, state) =>
                        const ExploreScreen(initialSegment: 1),
                    routes: [
                      GoRoute(
                        path: ':serviceId',
                        name: 'serviceDetail',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final id = state.pathParameters['serviceId']!;
                          return ServiceDetailScreen(serviceId: id);
                        },
                      ),
                    ],
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
                builder: (context, state) => const BlogListScreen(),
                routes: [
                  GoRoute(
                    path: ':articleId',
                    name: 'blogDetail',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['articleId']!;
                      return BlogDetailScreen(articleId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.patients,
                name: 'patients',
                builder: (context, state) => const PatientTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.contact,
                name: 'contact',
                builder: (context, state) => const ContactScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.about,
        name: 'about',
        builder: (context, state) => const AboutMenuScreen(),
        routes: [
          GoRoute(
            path: ':sectionId',
            name: 'aboutSection',
            builder: (context, state) {
              final id = state.pathParameters['sectionId']!;
              return AboutSlugScreen(slug: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.appointment,
        name: 'appointment',
        redirect: (context, state) {
          final raw =
              state.uri.queryParameters[AppConstants.sourceContextQueryParam];
          if (SourceContext.tryParse(raw) == null) {
            return AppRoutes.home;
          }
          return null;
        },
        builder: (context, state) {
          final raw =
              state.uri.queryParameters[AppConstants.sourceContextQueryParam];
          final sourceContext = SourceContext.tryParse(raw)!;
          return AppointmentScreen(sourceContext: sourceContext);
        },
      ),
      GoRoute(
        path: AppRoutes.faq,
        name: 'faq',
        builder: (context, state) => const FaqScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatbot,
        name: 'chatbot',
        builder: (context, state) => const ChatbotScreen(),
      ),
    ],
  );
}

class MainShellWidget extends StatelessWidget {
  const MainShellWidget({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = <_TabDestination>[
    _TabDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _TabDestination(
      label: 'Explore',
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
    ),
    _TabDestination(
      label: 'Blog',
      icon: Icons.article_outlined,
      selectedIcon: Icons.article,
    ),
    _TabDestination(
      label: 'Patients',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
    ),
    _TabDestination(
      label: 'Contact',
      icon: Icons.mail_outline,
      selectedIcon: Icons.mail,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final shellIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shellIndex,
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.sageLight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == shellIndex,
          );
        },
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon, color: AppColors.inkMuted),
              selectedIcon:
                  Icon(destination.selectedIcon, color: AppColors.forest),
              label: destination.label,
              tooltip: destination.label,
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
