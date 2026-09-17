import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/external_link_handler.dart';
import '../../../../core/utils/material_icon_map.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../clinic/domain/models/clinic_info.dart';
import '../../domain/models/patients_content.dart';
import '../providers/patients_providers.dart';

/// Patients hub redesign — account-style resource list.
class PatientTabScreen extends ConsumerWidget {
  const PatientTabScreen({super.key});

  static const _headerMuted = Color(0xFFD6EBEF);
  static const _pageBg = Color(0xFFF5F9F9);
  static const _avatarBg = Color(0xFFD6EBEF);
  static const _avatarText = Color(0xFF1F5F6C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsContentProvider);
    final clinic = ref.watch(patientClinicLinksProvider).asData?.value;
    final loggedIn = ref.watch(patientsLoggedInProvider);

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
                subtitle: patients.headerSubtitle,
                loggedIn: loggedIn,
                onAuthPressed: () {
                  ref.read(patientsLoggedInProvider.notifier).state = !loggedIn;
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
    required this.subtitle,
    required this.loggedIn,
    required this.onAuthPressed,
  });

  final String subtitle;
  final bool loggedIn;
  final VoidCallback onAuthPressed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.ochre,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patients',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: PatientTabScreen._headerMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (loggedIn)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const CircleAvatar(
                      radius: 15,
                      backgroundColor: PatientTabScreen._avatarBg,
                      child: Text(
                        'JD',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: PatientTabScreen._avatarText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onAuthPressed,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'Log out',
                          style: TextStyle(
                            fontSize: 12,
                            color: PatientTabScreen._headerMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                TextButton(
                  onPressed: onAuthPressed,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.ochre,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Log in',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, AppSpacing.xl),
      children: [
        for (var i = 0; i < patients.tiles.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final tile = patients.tiles[i];
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
        if (route == AppRoutes.faq || route == AppRoutes.contact) {
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
    'portal' || 'contact' => const _TileAccent(
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
        Color(0xFF17568F),
      ),
    'membership' => const _TileAccent(
        Color(0xFFE4E7E6),
        Color(0xFF6B7C7E),
      ),
    _ => const _TileAccent(
        Color(0xFFDCEFEE),
        Color(0xFF0E5A5F),
      ),
  };
}
