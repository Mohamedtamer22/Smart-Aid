import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/location/location_service.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/language_toggle_button.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import '../training/training_courses_page.dart';
import 'nearby_incidents_page.dart';
import 'volunteer_controller.dart';
import 'volunteer_repository.dart';

class VolunteerDashboardPage extends ConsumerStatefulWidget {
  const VolunteerDashboardPage({super.key, required this.session});
  final Session session;

  @override
  ConsumerState<VolunteerDashboardPage> createState() =>
      _VolunteerDashboardPageState();
}

class _VolunteerDashboardPageState
    extends ConsumerState<VolunteerDashboardPage> {
  bool _working = false;

  Future<void> _refresh() async {
    ref.invalidate(volunteerDashboardProvider);
    await ref.read(volunteerDashboardProvider.future);
  }

  Future<void> _setAvailability(bool available) async {
    await _run(
      () => ref.read(volunteerRepositoryProvider).updateAvailability(available),
    );
  }

  Future<void> _shareLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const _VolunteerLocationFailure(false);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const _VolunteerLocationFailure(true);
      }
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getExactCurrentPosition(
        timeLimit: const Duration(seconds: 15),
      );
      if (position == null) {
        throw const _VolunteerLocationFailure(false);
      }
      await _run(
        () => ref
            .read(volunteerRepositoryProvider)
            .updateLocation(position.latitude, position.longitude),
      );
    } on _VolunteerLocationFailure catch (failure) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        _showMessage(
          failure.permissionDenied
              ? l.text('permissionDenied')
              : l.text('locationUnavailable'),
        );
      }
    } on TimeoutException {
      if (mounted) {
        _showMessage(AppLocalizations.of(context).text('locationUnavailable'));
      }
    }
  }

  Future<void> _updateMission(VolunteerMission mission, String status) async {
    await _run(
      () => ref
          .read(volunteerRepositoryProvider)
          .updateMission(mission.id, status),
    );
  }

  Future<void> _startOnboarding() async {
    await _run(() => ref.read(volunteerRepositoryProvider).startOnboarding());
  }

  Future<void> _run(Future<Object?> Function() action) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await action();
      await _refresh();
    } on ApiFailure {
      if (mounted) {
        _showMessage(
          AppLocalizations.of(context).text('volunteerActionFailed'),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dashboard = ref.watch(volunteerDashboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.text('volunteerDashboard')),
        actions: [
          const LanguageToggleButton(isCompact: true),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TrainingCoursesPage(),
              ),
            ),
            icon: const Icon(Icons.school_outlined),
            tooltip: l.text('training'),
          ),
          IconButton(
            onPressed: _working ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: l.text('refresh'),
          ),
          IconButton(
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            tooltip: l.text('signOut'),
          ),
        ],
      ),
      body: dashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _DashboardError(
          profileMissing: error is ApiFailure && error.status == 404,
          working: _working,
          onRetry: _refresh,
          onStartOnboarding: _startOnboarding,
          error: error,
        ),
        data: (data) => QaPageFrame(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                QaPageHeader(
                  title: widget.session.displayName.isEmpty
                      ? l.text('volunteerDashboard')
                      : '${l.text('welcome')} ${widget.session.displayName}',
                  subtitle: data.profile.dispatchEligible
                      ? l.text('dispatchReady')
                      : l.text('dispatchNotReady'),
                ),
                const SizedBox(height: 20),
                QaHeroCard(
                  eyebrow: l.text('availability'),
                  title: data.profile.available
                      ? l.text('available')
                      : l.text('unavailable'),
                  message: data.profile.dispatchEligible
                      ? l.text('dispatchReady')
                      : l.text('dispatchNotReady'),
                  icon: Icons.volunteer_activism_outlined,
                  color: data.profile.available
                      ? AppTheme.success
                      : AppTheme.navy,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: QaMetricCard(
                        icon: Icons.radar_outlined,
                        label: l.text('nearbyEmergencies'),
                        value: data.nearbyEligibleIncidents.toString(),
                        color: AppTheme.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: QaMetricCard(
                        icon: data.activeMission == null
                            ? Icons.verified_outlined
                            : Icons.directions_run_outlined,
                        label: l.text('activeMission'),
                        value: data.activeMission == null
                            ? l.text('available')
                            : l.text('statusAccepted'),
                        color: data.activeMission == null
                            ? AppTheme.success
                            : AppTheme.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ProfileCard(
                  profile: data.profile,
                  working: _working,
                  onAvailabilityChanged: _setAvailability,
                  onShareLocation: _shareLocation,
                ),
                const SizedBox(height: 16),
                if (data.activeMission != null)
                  _MissionCard(
                    mission: data.activeMission!,
                    working: _working,
                    onUpdate: _updateMission,
                  )
                else
                  _NearbyCard(
                    count: data.nearbyEligibleIncidents,
                    enabled: data.profile.dispatchEligible && !_working,
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NearbyIncidentsPage(),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _TrainingBannerCard(
                  onOpen: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TrainingCoursesPage(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l.text('disclaimer'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({
    required this.profileMissing,
    required this.working,
    required this.onRetry,
    required this.onStartOnboarding,
    this.error,
  });
  final bool profileMissing;
  final bool working;
  final VoidCallback onRetry;
  final VoidCallback onStartOnboarding;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              profileMissing
                  ? Icons.volunteer_activism_outlined
                  : Icons.error_outline,
              size: 48,
              color: AppTheme.blue,
            ),
            const SizedBox(height: 16),
            Text(
              profileMissing
                  ? l.text('profileSetupRequired')
                  : l.text('volunteerActionFailed'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            FilledButton(
              onPressed: working
                  ? null
                  : (profileMissing ? onStartOnboarding : onRetry),
              child: Text(
                profileMissing
                    ? l.text('startVolunteerProfile')
                    : l.text('retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.working,
    required this.onAvailabilityChanged,
    required this.onShareLocation,
  });
  final VolunteerProfile profile;
  final bool working;
  final ValueChanged<bool> onAvailabilityChanged;
  final VoidCallback onShareLocation;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.text('volunteerReadiness'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(l.text('availability')),
            subtitle: Text(
              profile.available ? l.text('available') : l.text('unavailable'),
            ),
            value: profile.available,
            onChanged: working ? null : onAvailabilityChanged,
          ),
          _ReadinessRow(
            label: l.text('verification'),
            value: profile.verified
                ? l.text('verified')
                : l.text('pendingVerification'),
            good: profile.verified,
          ),
          _ReadinessRow(
            label: l.text('certification'),
            value: profile.certificationValid
                ? l.text('valid')
                : l.text('missing'),
            good: profile.certificationValid,
          ),
          _ReadinessRow(
            label: l.text('location'),
            value: profile.latitude == null
                ? l.text('locationUnavailable')
                : l.text('locationShared'),
            good: profile.latitude != null,
          ),
          if (profile.latitude == null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: working ? null : onShareLocation,
              icon: const Icon(Icons.my_location),
              label: Text(l.text('shareLocation')),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            profile.dispatchEligible
                ? l.text('dispatchReady')
                : l.text('dispatchNotReady'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({
    required this.label,
    required this.value,
    required this.good,
  });
  final String label;
  final String value;
  final bool good;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: (good ? AppTheme.success : AppTheme.warning).withValues(
              alpha: 0.12,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            good ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: good ? AppTheme.success : AppTheme.warning,
            size: 17,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        StatusPill(
          label: value,
          color: good ? AppTheme.success : AppTheme.warning,
        ),
      ],
    ),
  );
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({
    required this.count,
    required this.enabled,
    required this.onOpen,
  });
  final int count;
  final bool enabled;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.text('nearbyEmergencies'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '$count ${l.text('eligibleIncidents')}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: enabled ? onOpen : null,
            icon: const Icon(Icons.list_alt),
            label: Text(l.text('viewEmergencies')),
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.mission,
    required this.working,
    required this.onUpdate,
  });
  final VolunteerMission mission;
  final bool working;
  final void Function(VolunteerMission mission, String status) onUpdate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final action = switch (mission.status) {
      'ACCEPTED' => ('ARRIVED', l.text('markArrived')),
      'ARRIVED' => ('COMPLETED', l.text('completeMission')),
      _ => null,
    };
    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.text('activeMission'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _MissionDetail(
            label: l.text('status'),
            value: _statusLabel(l, mission.status),
          ),
          _MissionDetail(
            label: l.text('emergencyType'),
            value: _emergencyLabel(l, mission.incident.emergencyType),
          ),
          _MissionDetail(
            label: l.text('priority'),
            value: mission.incident.priority,
          ),
          _MissionDetail(
            label: l.text('estimatedEta'),
            value: '${mission.etaMinutes} ${l.text('minutes')}',
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: working ? null : () => onUpdate(mission, action.$1),
              child: Text(action.$2),
            ),
          ],
        ],
      ),
    );
  }
}

class _MissionDetail extends StatelessWidget {
  const _MissionDetail({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 8),
        Text(value, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

String _statusLabel(AppLocalizations l, String status) => switch (status) {
  'ACCEPTED' => l.text('statusAccepted'),
  'ARRIVED' => l.text('statusArrived'),
  'COMPLETED' => l.text('statusCompleted'),
  'CANCELLED' => l.text('statusCancelled'),
  _ => l.text('unknown'),
};

String _emergencyLabel(AppLocalizations l, String type) => switch (type) {
  'CARDIAC' => l.text('emergencyCardiac'),
  'TRAUMA' => l.text('emergencyTrauma'),
  'ACCIDENT' => l.text('emergencyAccident'),
  'MEDICAL' => l.text('emergencyMedical'),
  _ => l.text('emergencyOther'),
};

class _VolunteerLocationFailure implements Exception {
  const _VolunteerLocationFailure(this.permissionDenied);
  final bool permissionDenied;
}

class _TrainingBannerCard extends StatelessWidget {
  const _TrainingBannerCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school, color: AppTheme.blue, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.text('training'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.text('trainingSubtitle'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.menu_book),
            label: Text(l.text('courses')),
          ),
        ],
      ),
    );
  }
}
