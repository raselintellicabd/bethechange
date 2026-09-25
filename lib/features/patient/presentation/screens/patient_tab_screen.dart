import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/external_link_handler.dart';
import '../../../../core/utils/material_icon_map.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../auth/domain/models/patient_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../clinic/domain/models/clinic_info.dart';
import '../../domain/models/patients_content.dart';
import '../providers/patients_providers.dart';

/// Patients hub — account-style resource list with sectioned tiles.
class PatientTabScreen extends ConsumerWidget {
  const PatientTabScreen({super.key});

  static const _headerMuted = Color(0xFFD6EBEF);
  static const _pageBg = Color(0xFFF5F9F9);
  static const _avatarBg = Color(0xFFFFFFFF);
  static const _avatarText = Color(0xFF1F5F6C);
  static const _profileCard = Color(0xFF267A8C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsContentProvider);
    final clinic = ref.watch(patientClinicLinksProvider).asData?.value;
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final loggedIn = auth.isLoggedIn;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.ochre,
      ),
      child: Scaffold(
        backgroundColor: _pageBg,
        body: patientsAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading…'),
          error: (error, _) => ErrorStateWidget(
            message: error.toString().replaceFirst('Exception: ', ''),
            onRetry: () => ref.invalidate(patientsContentProvider),
          ),
          data: (patients) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PatientsHeader(
                headerSubtitle: patients.headerSubtitle,
                loggedIn: loggedIn,
                user: user,
                onLoginPressed: () {
                  context.push(
                    AppRoutes.loginPath(returnTo: AppRoutes.patients),
                  );
                },
                onSignupPressed: () {
                  context.push(
                    AppRoutes.signupPath(returnTo: AppRoutes.patients),
                  );
                },
                onLogoutPressed: () {
                  ref.read(authControllerProvider.notifier).logout();
                },
              ),
              Expanded(
                child: _PatientsBody(
                  patients: patients,
                  clinic: clinic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientsHeader extends StatelessWidget {
  const _PatientsHeader({
    required this.headerSubtitle,
    required this.loggedIn,
    required this.onLoginPressed,
    required this.onSignupPressed,
    required this.onLogoutPressed,
    this.user,
  });

  final String headerSubtitle;
  final bool loggedIn;
  final PatientUser? user;
  final VoidCallback onLoginPressed;
  final VoidCallback onSignupPressed;
  final VoidCallback onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.ochre,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Patients',
                style: GoogleFonts.workSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                headerSubtitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: PatientTabScreen._headerMuted,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              if (loggedIn && user != null)
                _LoggedInProfileCard(
                  user: user!,
                  onLogoutPressed: onLogoutPressed,
                )
              else
                _LoggedOutActions(
                  onLoginPressed: onLoginPressed,
                  onSignupPressed: onSignupPressed,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoggedInProfileCard extends StatelessWidget {
  const _LoggedInProfileCard({
    required this.user,
    required this.onLogoutPressed,
  });

  final PatientUser user;
  final VoidCallback onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    final membershipLabel = user.membershipActive
        ? '${user.tierTitle} member'
        : user.tierTitle;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: PatientTabScreen._profileCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: PatientTabScreen._avatarBg,
            child: Text(
              user.initials,
              style: GoogleFonts.workSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: PatientTabScreen._avatarText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.workSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  membershipLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: PatientTabScreen._headerMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onLogoutPressed,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.ochre,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              'Log out',
              style: GoogleFonts.workSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoggedOutActions extends StatelessWidget {
  const _LoggedOutActions({
    required this.onLoginPressed,
    required this.onSignupPressed,
  });

  final VoidCallback onLoginPressed;
  final VoidCallback onSignupPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: onLoginPressed,
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.ochre,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            'Log in',
            style: GoogleFonts.workSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onSignupPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Sign up',
            style: GoogleFonts.workSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PatientsBody extends ConsumerWidget {
  const _PatientsBody({
    required this.patients,
    required this.clinic,
  });

  final PatientsContent patients;
  final ClinicInfo? clinic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = patients.sections.isNotEmpty
        ? patients.sections
        : [
            PatientSection(
              id: 'all',
              title: '',
              tiles: patients.tiles,
            ),
          ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, AppSpacing.xl),
      children: [
        for (var s = 0; s < sections.length; s++) ...[
          if (s > 0) const SizedBox(height: 18),
          if (sections[s].title.isNotEmpty) ...[
            Text(
              sections[s].title.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: const Color(0xFF5A6A6C),
              ),
            ),
            const SizedBox(height: 10),
          ],
          for (var i = 0; i < sections[s].tiles.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Builder(
              builder: (context) {
                final tile = sections[s].tiles[i];
                final style = _tileStyle(tile.id);
                final comingSoon =
                    tile.action.type == PatientTileActionType.none;
                return PatientTile(
                  title: tile.title,
                  subtitle: tile.subtitle,
                  icon: materialIconFromName(tile.icon),
                  iconBackground: style.background,
                  iconColor: style.foreground,
                  comingSoon: comingSoon,
                  onTap: comingSoon
                      ? null
                      : () => _onTileTap(context, ref, tile),
                );
              },
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _onTileTap(
    BuildContext context,
    WidgetRef ref,
    PatientTileItem tile,
  ) async {
    switch (tile.action.type) {
      case PatientTileActionType.route:
        final route = tile.action.route;
        if (route == null || route.isEmpty) return;
        if (route == AppRoutes.faq ||
            route == AppRoutes.contact ||
            route == AppRoutes.membership ||
            route == AppRoutes.packages ||
            route == AppRoutes.patientProfile ||
            route == AppRoutes.appointmentHistory) {
          context.push(route);
        } else {
          context.go(route);
        }
      case PatientTileActionType.externalUrlKey:
        final links =
            clinic ?? await ref.read(patientClinicLinksProvider.future);
        if (links == null) return;
        final url = links.urlForKey(tile.action.urlKey ?? '');
        if (url == null || url.isEmpty) return;
        await _openExternal(context, ref, url);
      case PatientTileActionType.externalUrl:
        final url = tile.action.url;
        if (url == null || url.isEmpty) return;
        await _openExternal(context, ref, url);
      case PatientTileActionType.none:
        return;
    }
  }

  Future<void> _openExternal(
    BuildContext context,
    WidgetRef ref,
    String url,
  ) async {
    final opened =
        await ref.read(externalLinkHandlerProvider).openExternal(url);
    if (!context.mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the link. Please try again.'),
        ),
      );
    }
  }
}

class _TileAccent {
  const _TileAccent(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

_TileAccent _tileStyle(String id) {
  return switch (id) {
    'profile' => const _TileAccent(
        Color(0xFFE2ECFA),
        Color(0xFF17568F),
      ),
    'appointment-history' => const _TileAccent(
        Color(0xFFE8E4F5),
        Color(0xFF5B4B8A),
      ),
    'available-packages' => const _TileAccent(
        Color(0xFFE5F3EA),
        Color(0xFF1F6B3A),
      ),
    'membership' => const _TileAccent(
        Color(0xFFDCEFEE),
        Color(0xFF0E5A5F),
      ),
    'portal' => const _TileAccent(
        Color(0xFFDCEFEE),
        Color(0xFF0E5A5F),
      ),
    'book-service' => const _TileAccent(
        Color(0xFFFBE7DE),
        Color(0xFFA34A1F),
      ),
    'shop' => const _TileAccent(
        Color(0xFFFAEBD3),
        Color(0xFF8A5A0B),
      ),
    'faq' => const _TileAccent(
        Color(0xFFE2ECFA),
        Color(0xFFC62828),
      ),
    'contact' => const _TileAccent(
        Color(0xFFDCEFEE),
        Color(0xFF6B5B95),
      ),
    _ => const _TileAccent(
        Color(0xFFDCEFEE),
        Color(0xFF0E5A5F),
      ),
  };
}
