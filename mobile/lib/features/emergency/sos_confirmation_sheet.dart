import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/location/location_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import 'active_emergency_page.dart';
import 'emergency_repository.dart';
import 'sos_controller.dart';

class SosConfirmationSheet extends ConsumerWidget {
  const SosConfirmationSheet({super.key, this.triage});
  final EmergencyTriage? triage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(sosControllerProvider);
    ref.listen<AsyncValue<EmergencyIncident?>>(
      sosControllerProvider,
      (previous, next) => next.when(
        data: (incident) {
          if (incident != null && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ActiveEmergencyPage(incident: incident),
              ),
            );
            ref.read(sosControllerProvider.notifier).reset();
          }
        },
        error: (_, _) {},
        loading: () {},
      ),
    );
    final error = state.error;
    final errorText =
        error is SosFailure && error.kind == SosFailureKind.permission
        ? l.text('permissionDenied')
        : error is SosFailure && error.kind == SosFailureKind.location
        ? l.text('locationUnavailable')
        : error != null
        ? l.text('networkError')
        : null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.heroGradient(AppTheme.emergencyRed),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.emergencyRed.withValues(alpha: 0.32),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.text('sendEmergencyTitle'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              l.text('sendEmergencyBody'),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, _) {
                final locAsync = ref.watch(userLocationProvider);
                return locAsync.when(
                  data: (pos) => pos != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.softSuccess,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.success.withValues(alpha: 0.32),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.gps_fixed_rounded,
                                color: AppTheme.success,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${l.text('gpsLocked')}: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                );
              },
            ),
            if (state.isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: QaCard(
                  color: AppTheme.sky,
                  child: Row(
                    children: [
                      const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l.text('gettingLocation'))),
                    ],
                  ),
                ),
              ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: QaCard(
                  color: AppTheme.softRed,
                  borderColor: AppTheme.emergencyRed.withValues(alpha: 0.35),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppTheme.emergencyRed,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          errorText,
                          style: const TextStyle(
                            color: AppTheme.emergencyRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(l.text('cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: state.isLoading
                        ? null
                        : () => ref
                              .read(sosControllerProvider.notifier)
                              .send(triage: triage),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.emergencyRed,
                    ),
                    child: Text(l.text('confirmSend')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
