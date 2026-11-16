import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/location/location_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/language_toggle_button.dart';
import '../../shared/widgets/pulsing_sos_button.dart';
import '../auth/auth_repository.dart';
import '../emergency/active_emergency_page.dart';
import '../emergency/emergency_presenter.dart';
import '../emergency/sos_confirmation_sheet.dart';
import '../emergency/triage_sheet.dart';
import '../healthcare/connected_healthcare_page.dart';
import '../incidents/incidents_controller.dart';
import '../incidents/incidents_page.dart';
import '../notifications/notifications_page.dart';
import '../offline/offline_emergency_page.dart';
import '../profile/medical_profile_page.dart';
import '../profile/user_profile_page.dart';
import '../resources/nearby_resources_page.dart';
import '../resources/resource_controller.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, required this.session});
  final Session session;
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _index = 0;

  Future<void> _openSosFlow() async {
    final triage = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const TriageSheet(),
    );
    if (!mounted || triage == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SosConfirmationSheet(triage: triage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final titles = [
      l.text('home'),
      l.text('incidentHistory'),
      l.text('profileAndSettings'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_index == 0) ...[
              const AppLogo(size: 30, showGlow: false, borderRadius: 9),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                titles[_index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          const LanguageToggleButton(isCompact: true),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsPage(),
              ),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: l.text('notifications'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          _UserHomeTab(session: widget.session, onSos: _openSosFlow),
          const IncidentsPage(),
          UserProfilePage(session: widget.session),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: l.text('home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined),
              selectedIcon: const Icon(Icons.history_rounded),
              label: l.text('incidents'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: l.text('profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserHomeTab extends ConsumerWidget {
  const _UserHomeTab({required this.session, required this.onSos});
  final Session session;
  final VoidCallback onSos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final incidents = ref.watch(myIncidentsProvider);
    final active = incidents.when(
      data: (items) {
        for (final item in items) {
          if (item.status != 'RESOLVED' && item.status != 'CANCELLED') {
            return item;
          }
        }
        return null;
      },
      loading: () => null,
      error: (_, _) => null,
    );
    return QaPageFrame(
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myIncidentsProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            QaPageHeader(
              title: session.displayName.isEmpty
                  ? l.text('homeSafetyTitle')
                  : l.format('greetingName', {'name': session.displayName}),
              subtitle: l.text('homeSafetyMessage'),
            ),
            const SizedBox(height: 14),
            const _UserGpsStatusCard(),
            const SizedBox(height: 14),
            QaHeroCard(
              eyebrow: l.text('appName'),
              title: l.text('homeSafetyTitle'),
              message: l.text('sosHint'),
              icon: Icons.health_and_safety_outlined,
            ),
            const SizedBox(height: 18),
            // Dedicated SOS Stage Container
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.emergencyRed.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  radius: 0.72,
                ),
              ),
              child: Center(
                child: PulsingSosButton(
                  label: l.text('sendSos'),
                  onPressed: onSos,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(title: l.text('activeEmergencies')),
            const SizedBox(height: 10),
            active == null
                ? QaCard(
                    borderColor: AppTheme.success.withValues(alpha: 0.3),
                    color: AppTheme.softSuccess,
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: AppTheme.success,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l.text('noActiveIncident'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : QaCard(
                    padding: EdgeInsets.zero,
                    borderColor: priorityColor(
                      active.priority,
                    ).withValues(alpha: 0.45),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      onTap: () =>
                          _go(context, ActiveEmergencyPage(incident: active)),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 5,
                              color: priorityColor(active.priority),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: priorityColor(
                                          active.priority,
                                        ).withValues(alpha: .12),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Icon(
                                        Icons.emergency_rounded,
                                        color: priorityColor(active.priority),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            emergencyTypeLabel(
                                              l,
                                              active.emergencyType,
                                            ),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            incidentStatusLabel(
                                              l,
                                              active.status,
                                            ),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusPill(
                                      label: priorityLabel(l, active.priority),
                                      color: priorityColor(active.priority),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 22),
            SectionHeader(title: l.text('quickActions')),
            const SizedBox(height: 12),
            QaCard(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionItem(
                          icon: Icons.assignment_outlined,
                          label: l.text('incidents'),
                          color: AppTheme.navyBlue,
                          onTap: () => _go(context, const IncidentsPage()),
                        ),
                      ),
                      Expanded(
                        child: _QuickActionItem(
                          icon: Icons.local_hospital_outlined,
                          label: l.text('hospitals'),
                          color: AppTheme.emergencyRed,
                          onTap: () => _go(
                            context,
                            const NearbyResourcesPage(initialTab: 0),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _QuickActionItem(
                          icon: Icons.bolt_rounded,
                          label: l.text('aed'),
                          color: const Color(0xFFD97706),
                          onTap: () => _go(
                            context,
                            const NearbyResourcesPage(initialTab: 1),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _QuickActionItem(
                          icon: Icons.badge_outlined,
                          label: l.text('medicalProfile'),
                          color: AppTheme.blue,
                          onTap: () => _go(context, const MedicalProfilePage()),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    child: Divider(height: 1),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionItem(
                          icon: Icons.local_pharmacy_outlined,
                          label: l.isArabic ? 'الصيدليات' : 'Pharmacy',
                          color: AppTheme.success,
                          onTap: () => _go(
                            context,
                            const ConnectedHealthcarePage(initialTab: 0),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _QuickActionItem(
                          icon: Icons.bloodtype_outlined,
                          label: l.isArabic ? 'بنك الدم' : 'Blood Bank',
                          color: const Color(0xFFB91C1C),
                          onTap: () => _go(
                            context,
                            const ConnectedHealthcarePage(initialTab: 1),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _QuickActionItem(
                          icon: Icons.science_outlined,
                          label: l.isArabic ? 'المعامل' : 'Labs',
                          color: const Color(0xFF6D28D9),
                          onTap: () => _go(
                            context,
                            const ConnectedHealthcarePage(initialTab: 2),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _QuickActionItem(
                          icon: Icons.wifi_off_rounded,
                          label: l.isArabic ? 'دون إنترنت' : 'Offline Aid',
                          color: const Color(0xFFC2410C),
                          onTap: () =>
                              _go(context, const OfflineEmergencyPage()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SectionHeader(
              title: l.text('hospitals'),
              actionLabel: l.text('viewAll'),
              onAction: () =>
                  _go(context, const NearbyResourcesPage(initialTab: 0)),
            ),
            const SizedBox(height: 10),
            _NearbyHospitalsSummary(
              onViewAll: () =>
                  _go(context, const NearbyResourcesPage(initialTab: 0)),
            ),
            const SizedBox(height: 16),
            SectionHeader(title: l.text('nearbyResources')),
            const SizedBox(height: 8),
            QaCard(
              padding: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                onTap: () => _go(context, const NearbyResourcesPage()),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.sky,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.location_searching_outlined,
                          color: AppTheme.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l.text('resourceDataNotice'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.charcoal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.16),
                    color.withValues(alpha: 0.07),
                  ],
                ),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: color.withValues(alpha: 0.24),
                  width: 1.3,
                ),
              ),
              child: Icon(icon, color: color, size: 25),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.text,
                height: 1.18,
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyHospitalsSummary extends ConsumerWidget {
  const _NearbyHospitalsSummary({required this.onViewAll});
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final hospitalsAsync = ref.watch(verifiedHospitalsProvider);

    return hospitalsAsync.when(
      data: (hospitals) {
        if (hospitals.isEmpty) {
          return QaCard(
            child: Row(
              children: [
                const Icon(
                  Icons.local_hospital_outlined,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(l.text('resourceDataNotice'))),
              ],
            ),
          );
        }
        final topHospitals = hospitals.take(3).toList();
        return Column(
          children: topHospitals.map((hospital) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: QaCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  onTap: onViewAll,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.blue.withValues(alpha: 0.16),
                                AppTheme.blue.withValues(alpha: 0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.blue.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: AppTheme.blue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hospital.name,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.near_me_outlined,
                                    size: 13,
                                    color: AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      l.format('hospitalCoordinates', {
                                        'latitude': hospital.latitude
                                            .toStringAsFixed(2),
                                        'longitude': hospital.longitude
                                            .toStringAsFixed(2),
                                      }),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppTheme.textMuted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              StatusPill(
                                label: l.isArabic ? 'طوارئ 24/7' : '24/7 ER',
                                color: AppTheme.success,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => QaCard(
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.emergencyRed),
            const SizedBox(width: 12),
            Expanded(child: Text(l.text('resourceDataNotice'))),
          ],
        ),
      ),
    );
  }
}

class _UserGpsStatusCard extends ConsumerWidget {
  const _UserGpsStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locationAsync = ref.watch(userLocationProvider);

    return locationAsync.when(
      data: (pos) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: pos != null ? AppTheme.softSuccess : AppTheme.sky,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: pos != null
                ? AppTheme.success.withValues(alpha: 0.32)
                : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: (pos != null ? AppTheme.success : AppTheme.blue)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                pos != null
                    ? Icons.gps_fixed_rounded
                    : Icons.location_searching_rounded,
                color: pos != null ? AppTheme.success : AppTheme.blue,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pos != null
                        ? l.text('gpsLocked')
                        : l.text('gettingLocation'),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: pos != null ? AppTheme.success : AppTheme.charcoal,
                    ),
                  ),
                  if (pos != null)
                    Text(
                      '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)} • ${l.format('accuracyMeters', {'meters': pos.accuracy.toStringAsFixed(1)})}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              onPressed: () =>
                  ref.read(userLocationProvider.notifier).refreshLocation(),
              tooltip: l.text('refreshLocation'),
            ),
          ],
        ),
      ),
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.sky,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l.text('gettingLocation'),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoal,
                ),
              ),
            ),
          ],
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
