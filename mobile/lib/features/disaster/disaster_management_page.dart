import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import 'disaster_controller.dart';
import 'disaster_repository.dart';

class DisasterManagementPage extends ConsumerStatefulWidget {
  const DisasterManagementPage({super.key});

  @override
  ConsumerState<DisasterManagementPage> createState() =>
      _DisasterManagementPageState();
}

class _DisasterManagementPageState
    extends ConsumerState<DisasterManagementPage> {
  bool _working = false;

  Future<void> _refresh() async {
    ref.invalidate(disasterOverviewProvider);
    ref.invalidate(disasterStatusProvider);
  }

  Future<void> _toggleDisasterMode(bool currentlyActive) async {
    final l = AppLocalizations.of(context);
    if (currentlyActive) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.text('deactivateDisaster')),
          content: Text(l.text('cancelEmergencyBody')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.text('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l.text('deactivateDisaster')),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      setState(() => _working = true);
      try {
        await ref.read(disasterRepositoryProvider).deactivate();
        await _refresh();
      } finally {
        if (mounted) setState(() => _working = false);
      }
    } else {
      final typeCtrl = TextEditingController(text: 'EARTHQUAKE');
      final areaCtrl = TextEditingController(text: 'Downtown Sector A');

      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.text('activateDisaster')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: typeCtrl,
                decoration: InputDecoration(labelText: l.text('disasterType')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: areaCtrl,
                decoration: InputDecoration(labelText: l.text('affectedArea')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.text('cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.emergencyRed,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l.text('activateDisaster')),
            ),
          ],
        ),
      );

      if (result == true) {
        setState(() => _working = true);
        try {
          await ref
              .read(disasterRepositoryProvider)
              .activate(
                disasterType: typeCtrl.text.trim(),
                disasterLevel: 'LEVEL_3',
                affectedArea: areaCtrl.text.trim(),
              );
          await _refresh();
        } finally {
          if (mounted) setState(() => _working = false);
        }
      }
    }
  }

  Future<void> _updateTag(MassCasualtyIncident incident) async {
    final l = AppLocalizations.of(context);
    final tags = ['RED', 'YELLOW', 'GREEN', 'BLACK'];

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.text('updateTriage'),
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              ...tags.map((tag) {
                final color = _triageColor(tag);
                return ListTile(
                  leading: CircleAvatar(backgroundColor: color, radius: 10),
                  title: Text(_triageLabel(l, tag)),
                  onTap: () => Navigator.of(ctx).pop(tag),
                );
              }),
            ],
          ),
        ),
      ),
    );

    if (selected != null && selected != incident.triageTag) {
      setState(() => _working = true);
      try {
        await ref
            .read(disasterRepositoryProvider)
            .updateTriageTag(incident.id, selected);
        await _refresh();
      } finally {
        if (mounted) setState(() => _working = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final overviewAsync = ref.watch(disasterOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.text('disasterManagement')),
        actions: [
          IconButton(
            onPressed: _working ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: l.text('refresh'),
          ),
        ],
      ),
      body: overviewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => PageFailure(
          title: l.text('disasterManagement'),
          message: l.text('error'),
          retryLabel: l.text('retry'),
          onRetry: _refresh,
        ),
        data: (data) => QaPageFrame(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                QaPageHeader(
                  title: l.text('disasterManagement'),
                  subtitle: l.text('disasterOverview'),
                ),
                const SizedBox(height: 16),
                QaHeroCard(
                  eyebrow: data.status.active
                      ? l.text('disasterActive')
                      : l.text('disasterInactive'),
                  title: data.status.active
                      ? '${data.status.disasterType ?? 'EMERGENCY'} • ${data.status.affectedArea ?? ''}'
                      : l.text('disasterInactive'),
                  message: data.status.active
                      ? '${data.status.activeIncidentsCount} ${l.text('activeIncidents')}, ${data.status.respondersMobilizedCount} Responders'
                      : l.text('homeSafetyMessage'),
                  icon: Icons.warning_amber_rounded,
                  color: data.status.active
                      ? AppTheme.emergencyRed
                      : AppTheme.navy,
                  footer: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    onPressed: _working
                        ? null
                        : () => _toggleDisasterMode(data.status.active),
                    child: Text(
                      data.status.active
                          ? l.text('deactivateDisaster')
                          : l.text('activateDisaster'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SectionHeader(title: l.text('triageQueue')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: QaMetricCard(
                        icon: Icons.emergency,
                        label: l.text('triageRed'),
                        value: data.redCount.toString(),
                        color: AppTheme.emergencyRed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: QaMetricCard(
                        icon: Icons.warning_amber,
                        label: l.text('triageYellow'),
                        value: data.yellowCount.toString(),
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: QaMetricCard(
                        icon: Icons.check_circle_outline,
                        label: l.text('triageGreen'),
                        value: data.greenCount.toString(),
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: QaMetricCard(
                        icon: Icons.cancel_outlined,
                        label: l.text('triageBlack'),
                        value: data.blackCount.toString(),
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SectionHeader(title: l.text('activeEmergencies')),
                const SizedBox(height: 8),
                if (data.priorityQueue.isEmpty)
                  QaCard(
                    child: EmptyState(
                      icon: Icons.check_circle_outline,
                      title: l.text('noActiveEmergencies'),
                      message: l.text('disclaimer'),
                    ),
                  )
                else
                  ...data.priorityQueue.map(
                    (inc) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: QaCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _triageColor(
                                  inc.triageTag,
                                ).withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.person,
                                color: _triageColor(inc.triageTag),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inc.emergencyType,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    inc.notes.isEmpty
                                        ? '${inc.latitude.toStringAsFixed(3)}, ${inc.longitude.toStringAsFixed(3)}'
                                        : inc.notes,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: _working ? null : () => _updateTag(inc),
                              borderRadius: BorderRadius.circular(20),
                              child: StatusPill(
                                label: _triageLabel(l, inc.triageTag),
                                color: _triageColor(inc.triageTag),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _triageColor(String tag) => switch (tag.toUpperCase()) {
    'RED' => AppTheme.emergencyRed,
    'YELLOW' => AppTheme.warning,
    'GREEN' => AppTheme.success,
    _ => Colors.black87,
  };

  String _triageLabel(AppLocalizations l, String tag) =>
      switch (tag.toUpperCase()) {
        'RED' => l.text('triageRed'),
        'YELLOW' => l.text('triageYellow'),
        'GREEN' => l.text('triageGreen'),
        _ => l.text('triageBlack'),
      };
}
