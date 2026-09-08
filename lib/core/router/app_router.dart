import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/presentation/screens/about_screen.dart';
import '../../features/appointment/domain/models/source_context.dart';
import '../../features/appointment/presentation/screens/appointment_screen.dart';
import '../../features/blog/presentation/screens/blog_detail_screen.dart';
import '../../features/blog/presentation/screens/blog_list_screen.dart';
import '../../features/chatbot/presentation/screens/chatbot_screen.dart';
import '../../features/conditions/presentation/screens/condition_detail_screen.dart';
import '../../features/conditions/presentation/screens/conditions_list_screen.dart';
import '../../features/contact/presentation/screens/contact_screen.dart';
import '../../features/faq/presentation/screens/faq_screen.dart';
import '../../features/patient/presentation/screens/patient_tab_screen.dart';
import '../../features/services/presentation/screens/service_detail_screen.dart';
import '../../features/services/presentation/screens/services_list_screen.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
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
                builder: (context, state) => const AboutScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.conditions,
                name: 'conditions',
                builder: (context, state) => const ConditionsListScreen(),
                routes: [
                  GoRoute(
                    path: ':conditionId',
                    name: 'conditionDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['conditionId']!;
                      return ConditionDetailScreen(conditionId: id);
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
                builder: (context, state) => const ServicesListScreen(),
                routes: [
                  GoRoute(
                    path: ':serviceId',
                    name: 'serviceDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['serviceId']!;
                      return ServiceDetailScreen(serviceId: id);
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
                builder: (context, state) => const BlogListScreen(),
                routes: [
                  GoRoute(
                    path: ':articleId',
                    name: 'blogDetail',
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
                path: AppRoutes.patient,
                name: 'patient',
                builder: (context, state) => const PatientTabScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.appointment,
        name: 'appointment',
        redirect: (context, state) {
          final raw =
              state.uri.queryParameters[AppConstants.sourceContextQueryParam];
          // No direct/deep-link entry without a valid SourceContext.
          if (SourceContext.tryParse(raw) == null) {
            return AppRoutes.about;
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
      GoRoute(
        path: AppRoutes.contact,
        name: 'contact',
        builder: (context, state) => const ContactScreen(),
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
