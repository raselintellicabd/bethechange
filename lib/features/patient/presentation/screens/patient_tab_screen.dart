import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/external_link_handler.dart';
import '../../../../core/utils/material_icon_map.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../clinic/domain/models/clinic_info.dart';
import '../../../clinic/presentation/providers/clinic_providers.dart';
import '../../domain/models/patients_content.dart';
import '../providers/patients_providers.dart';

/// Patients hub. Membership is intentionally omitted.
class PatientTabScreen extends ConsumerWidget {
  const PatientTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsContentProvider);
    final clinicAsync = ref.watch(clinicInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        centerTitle: false,
      ),
      body: patientsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading…'),
        error: (error, _) => ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () {
            ref.invalidate(patientsContentProvider);
            ref.invalidate(clinicInfoProvider);
          },
        ),
        data: (patients) {
          return clinicAsync.when(
            loading: () => const LoadingIndicator(message: 'Loading…'),
            error: (error, _) => ErrorStateWidget(
              message: error.toString().replaceFirst('Exception: ', ''),
              onRetry: () => ref.invalidate(clinicInfoProvider),
            ),
            data: (clinic) => _PatientsBody(
              patients: patients,
              clinic: clinic,
            ),
          );
        },
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
  final ClinicInfo clinic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        SectionTitle(patients.sectionTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(
          patients.sectionSubtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.92,
          children: [
            for (final tile in patients.tiles)
              PatientTile(
                title: tile.title,
                subtitle: tile.subtitle,
                icon: materialIconFromName(tile.icon),
                onTap: () => _onTileTap(context, ref, tile),
              ),
          ],
        ),
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
        if (route == '/faq') {
          context.push(route);
        } else {
          context.go(route);
        }
      case PatientTileActionType.externalUrlKey:
        final url = clinic.urlForKey(tile.action.urlKey ?? '');
        if (url == null || url.isEmpty) return;
        await _openExternal(context, ref, url);
      case PatientTileActionType.externalUrl:
        final url = tile.action.url;
        if (url == null || url.isEmpty) return;
        await _openExternal(context, ref, url);
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
