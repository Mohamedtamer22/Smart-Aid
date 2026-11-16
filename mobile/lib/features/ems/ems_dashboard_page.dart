import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/language_toggle_button.dart';
import '../analytics/analytics_page.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import '../disaster/disaster_management_page.dart';
import '../resources/nearby_resources_page.dart';
import 'ems_controller.dart';
import 'ems_repository.dart';
import 'smart_er_page.dart';

class EmsDashboardPage extends ConsumerStatefulWidget {
  const EmsDashboardPage({super.key, required this.session});
  final Session session;

  @override
  ConsumerState<EmsDashboardPage> createState() => _EmsDashboardPageState();
}

class _EmsDashboardPageState extends ConsumerState<EmsDashboardPage> {
  String? _assigningIncident;

  Future<void> _refresh() async {
    ref.invalidate(emsDashboardProvider);
    await ref.read(emsDashboardProvider.future);
  }

  Future<void> _assign(EmsIncident incident) async {
    if (_assigningIncident != null) return;
    setState(() => _assigningIncident = incident.id);
    try {
      await ref.read(emsRepositoryProvider).assign(incident.id);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).text('emsAssigned')),
          ),
        );
      }
    } on ApiFailure {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).text('emsActionFailed')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _assigningIncident = null);
    }
  }

  Future<void> _openMultiResponderDispatch(EmsIncident incident) async {
    final dispatched = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MultiResponderDispatchSheet(
        incident: incident,
        onDispatch: (assignments) async {
          await ref.read(emsRepositoryProvider).assignResponders(
                incident.id,
                assignments,
              );
          await _refresh();
        },
      ),
    );
    if (dispatched == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).text('respondersDispatched'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dashboard = ref.watch(emsDashboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.text('emsDashboard')),
        actions: [
          const LanguageToggleButton(isCompact: true),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DisasterManagementPage(),
              ),
            ),
            icon: const Icon(Icons.emergency_outlined),
            tooltip: l.text('disasterManagement'),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AnalyticsPage()),
            ),
            icon: const Icon(Icons.analytics_outlined),
            tooltip: l.text('analytics'),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NearbyResourcesPage(),
              ),
            ),
            icon: const Icon(Icons.local_hospital_outlined),
            tooltip: l.text('resources'),
          ),
          IconButton(
            onPressed: _assigningIncident == null ? _refresh : null,
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
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: AppTheme.emergencyRed,
                ),
                const SizedBox(height: 16),
                Text(
                  l.text('networkError'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(l.text('retry')),
                ),
              ],
            ),
          ),
        ),
        data: (data) => QaPageFrame(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                QaPageHeader(
                  title: l.text('operationsCenter'),
                  subtitle: l.text('smartErDecisionSupport'),
                ),
                const SizedBox(height: 20),
                QaHeroCard(
                  eyebrow: l.text('emsDashboard'),
                  title:
                      '${data.activeIncidents} ${l.text('activeEmergencies')}',
                  message: data.criticalIncidents == 0
                      ? l.text('noActiveEmergencies')
                      : '${data.criticalIncidents} ${l.text('criticalIncidents')}',
                  icon: Icons.monitor_heart_outlined,
                  color: AppTheme.navy,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: QaMetricCard(
                        icon: Icons.emergency_outlined,
                        label: l.text('activeIncidents'),
                        value: data.activeIncidents.toString(),
                        color: AppTheme.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: QaMetricCard(
                        icon: Icons.priority_high,
                        label: l.text('criticalIncidents'),
                        value: data.criticalIncidents.toString(),
                        color: AppTheme.emergencyRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DisasterManagementPage(),
                          ),
                        ),
                        icon: const Icon(
                          Icons.emergency,
                          color: AppTheme.emergencyRed,
                          size: 18,
                        ),
                        label: Text(l.text('disasterManagement')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AnalyticsPage(),
                          ),
                        ),
                        icon: const Icon(
                          Icons.analytics,
                          color: Colors.deepPurple,
                          size: 18,
                        ),
                        label: Text(l.text('analytics')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SectionHeader(title: l.text('activeEmergencies')),
                const SizedBox(height: 10),
                if (data.incidents.isEmpty)
                  QaCard(
                    child: EmptyState(
                      icon: Icons.check_circle_outline,
                      title: l.text('noActiveEmergencies'),
                      message: l.text('disclaimer'),
                    ),
                  )
                else
                  ...data.incidents.map(
                    (incident) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _IncidentCard(
                        incident: incident,
                        assigning: _assigningIncident == incident.id,
                        onAssign: () => _assign(incident),
                        onMultiDispatch: () =>
                            _openMultiResponderDispatch(incident),
                        onOpenSmartEr: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SmartErPage(
                              incidentId: incident.id,
                              emergencyType: _emergencyLabel(
                                l,
                                incident.emergencyType,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
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

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    required this.incident,
    required this.assigning,
    required this.onAssign,
    required this.onMultiDispatch,
    required this.onOpenSmartEr,
  });
  final EmsIncident incident;
  final bool assigning;
  final VoidCallback onAssign;
  final VoidCallback onMultiDispatch;
  final VoidCallback onOpenSmartEr;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final actionable =
        incident.status == 'SEARCHING' ||
        incident.status == 'RESPONDER_ASSIGNED';
    final priorityColor = incident.priority == 'CRITICAL'
        ? AppTheme.emergencyRed
        : AppTheme.warning;
    return QaCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: priorityColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.emergency_outlined,
                            color: priorityColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _emergencyLabel(l, incident.emergencyType),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _statusLabel(l, incident.status),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusPill(
                          label: _priorityLabel(l, incident.priority),
                          color: priorityColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (actionable) ...[
                      FilledButton.icon(
                        onPressed: assigning ? null : onAssign,
                        icon: assigning
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.support_agent_rounded),
                        label: Text(l.text('startEmsCoordination')),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: onMultiDispatch,
                        icon: const Icon(
                          Icons.groups_rounded,
                          color: AppTheme.blue,
                        ),
                        label: Text(l.text('multiResponderDispatch')),
                      ),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton.icon(
                      onPressed: onOpenSmartEr,
                      icon: const Icon(
                        Icons.local_hospital_rounded,
                        color: AppTheme.mintTeal,
                      ),
                      label: Text(l.text('openSmartEr')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _emergencyLabel(AppLocalizations l, String type) => switch (type) {
  'CARDIAC' => l.text('emergencyCardiac'),
  'TRAUMA' => l.text('emergencyTrauma'),
  'ACCIDENT' => l.text('emergencyAccident'),
  'MEDICAL' => l.text('emergencyMedical'),
  _ => l.text('emergencyOther'),
};
String _statusLabel(AppLocalizations l, String status) => switch (status) {
  'SEARCHING' => l.text('statusSearching'),
  'RESPONDER_ASSIGNED' => l.text('statusResponderAssigned'),
  'EMS_ASSIGNED' => l.text('statusEmsAssigned'),
  'AMBULANCE_ASSIGNED' => l.text('statusAmbulanceAssigned'),
  'IN_TRANSIT' => l.text('statusInTransit'),
  'HOSPITAL_SELECTED' => l.text('statusHospitalSelected'),
  'AT_HOSPITAL' => l.text('statusAtHospital'),
  _ => l.text('unknown'),
};
String _priorityLabel(AppLocalizations l, String priority) =>
    switch (priority) {
      'CRITICAL' => l.text('priorityCritical'),
      'HIGH' => l.text('priorityHigh'),
      'STANDARD' => l.text('priorityStandard'),
      'LOW' => l.text('priorityLow'),
      _ => l.text('unknown'),
    };

class _MultiResponderDispatchSheet extends StatefulWidget {
  const _MultiResponderDispatchSheet({
    required this.incident,
    required this.onDispatch,
  });

  final EmsIncident incident;
  final Future<void> Function(List<Map<String, String>> assignments) onDispatch;

  @override
  State<_MultiResponderDispatchSheet> createState() =>
      _MultiResponderDispatchSheetState();
}

class _ResponderSlot {
  _ResponderSlot({
    required this.id,
    required this.name,
    required this.skills,
    required this.taskType,
    required this.etaMinutes,
    this.selected = true,
  });

  final String id;
  final String name;
  final String skills;
  String taskType;
  final int etaMinutes;
  bool selected;
}

class _MultiResponderDispatchSheetState
    extends State<_MultiResponderDispatchSheet> {
  bool _submitting = false;

  late final List<_ResponderSlot> _slots;

  @override
  void initState() {
    super.initState();
    _slots = [
      _ResponderSlot(
        id: 'VOL-001',
        name: 'Ahmed Hassan',
        skills: 'CPR / First Aid',
        taskType: 'PRIMARY_RESPONSE',
        etaMinutes: 4,
        selected: true,
      ),
      _ResponderSlot(
        id: 'VOL-002',
        name: 'Sarah Mansour',
        skills: 'BLS / Triage',
        taskType: 'TRIAGE_CPR_SUPPORT',
        etaMinutes: 6,
        selected: true,
      ),
      _ResponderSlot(
        id: 'VOL-003',
        name: 'Mahmoud Ali',
        skills: 'AED / Crowd Management',
        taskType: 'AED_CROWD_CONTROL',
        etaMinutes: 7,
        selected: true,
      ),
    ];
  }

  Future<void> _submit() async {
    final selectedSlots = _slots.where((s) => s.selected).toList();
    if (selectedSlots.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final assignments = selectedSlots
          .map((s) => {
                'volunteerId': s.id,
                'taskType': s.taskType,
              })
          .toList();
      await widget.onDispatch(assignments);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _taskName(AppLocalizations l, String taskType) => switch (taskType) {
        'PRIMARY_RESPONSE' => l.text('taskPrimaryResponse'),
        'TRIAGE_CPR_SUPPORT' => l.text('taskTriageCprSupport'),
        'AED_CROWD_CONTROL' => l.text('taskAedCrowdControl'),
        _ => taskType,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.86;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 16,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.group_add,
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
                        l.text('multiResponderDispatch'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'DEMO • ${widget.incident.id} • ${_emergencyLabel(l, widget.incident.emergencyType)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.text('assignedResponders'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._slots.map(
                      (slot) => Card(
                        elevation: 0,
                        color: slot.selected
                            ? AppTheme.blue.withValues(alpha: 0.05)
                            : Colors.grey.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: slot.selected
                                ? AppTheme.blue.withValues(alpha: 0.4)
                                : Colors.grey.shade200,
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: slot.selected,
                                onChanged: (val) {
                                  setState(() => slot.selected = val ?? false);
                                },
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      slot.name,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      '${slot.skills} • ETA ${slot.etaMinutes}m',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButton<String>(
                                      value: slot.taskType,
                                      isDense: true,
                                      isExpanded: true,
                                      underline: const SizedBox.shrink(),
                                      items: [
                                        DropdownMenuItem(
                                          value: 'PRIMARY_RESPONSE',
                                          child: Text(
                                            _taskName(l, 'PRIMARY_RESPONSE'),
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'TRIAGE_CPR_SUPPORT',
                                          child: Text(
                                            _taskName(l, 'TRIAGE_CPR_SUPPORT'),
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'AED_CROWD_CONTROL',
                                          child: Text(
                                            _taskName(l, 'AED_CROWD_CONTROL'),
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: slot.selected
                                          ? (newVal) {
                                              if (newVal != null) {
                                                setState(
                                                  () => slot.taskType = newVal,
                                                );
                                              }
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _submitting || _slots.every((s) => !s.selected)
                  ? null
                  : _submit,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(l.text('assignResponders')),
            ),
          ],
        ),
      ),
    );
  }
}
