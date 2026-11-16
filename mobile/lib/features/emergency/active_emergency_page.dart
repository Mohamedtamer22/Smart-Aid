import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import '../incidents/incidents_controller.dart';
import 'emergency_presenter.dart';
import 'emergency_repository.dart';
import 'sos_controller.dart';

class ActiveEmergencyPage extends ConsumerStatefulWidget {
  const ActiveEmergencyPage({super.key, required this.incident});
  final EmergencyIncident incident;
  @override
  ConsumerState<ActiveEmergencyPage> createState() =>
      _ActiveEmergencyPageState();
}

class _ActiveEmergencyPageState extends ConsumerState<ActiveEmergencyPage> {
  bool _cancelling = false;
  bool get _canCancel =>
      widget.incident.status == 'NEW' || widget.incident.status == 'SEARCHING';
  Future<void> _cancel() async {
    final l = AppLocalizations.of(context);
    final approved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.text('confirmationNeeded')),
        content: Text(l.text('cancelEmergencyBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.emergencyRed,
            ),
            child: Text(l.text('cancelEmergency')),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await ref.read(emergencyRepositoryProvider).cancel(widget.incident.id);
      ref.invalidate(myIncidentsProvider);
      ref.invalidate(incidentDetailProvider(widget.incident.id));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.text('networkError'))));
      }
    } finally {
      if (mounted) {
        setState(() => _cancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final point = LatLng(widget.incident.latitude, widget.incident.longitude);
    final details = ref.watch(incidentDetailProvider(widget.incident.id));
    return Scaffold(
      appBar: AppBar(
        title: Text(l.text('emergencyActive')),
        actions: [
          IconButton(
            onPressed: () =>
                ref.invalidate(incidentDetailProvider(widget.incident.id)),
            icon: const Icon(Icons.refresh),
            tooltip: l.text('refresh'),
          ),
        ],
      ),
      body: QaPageFrame(
        child: ListView(
          children: [
            QaHeroCard(
              eyebrow: l.text('emergencyActive'),
              title: _headline(l, widget.incident.status),
              message: l.text('confirmed'),
              icon: Icons.verified_rounded,
              color: _headerColor(widget.incident.status),
            ),
            const SizedBox(height: 16),
            Container(
              height: 230,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.deepNavy.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.smartaid.mobile',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 52,
                          height: 52,
                          child: const Icon(
                            Icons.location_on,
                            color: AppTheme.emergencyRed,
                            size: 46,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            QaCard(
              child: Column(
                children: [
                  _detailWidget(
                    context,
                    l.text('status'),
                    StatusPill(
                      label: incidentStatusLabel(l, widget.incident.status),
                      color: _headerColor(widget.incident.status),
                    ),
                  ),
                  const Divider(height: 22),
                  _detailWidget(
                    context,
                    l.text('priority'),
                    StatusPill(
                      label: priorityLabel(l, widget.incident.priority),
                      color: priorityColor(widget.incident.priority),
                    ),
                  ),
                  const Divider(height: 22),
                  _detail(
                    context,
                    l.text('exactLocation'),
                    '${widget.incident.latitude.toStringAsFixed(5)}, ${widget.incident.longitude.toStringAsFixed(5)}',
                  ),
                  const Divider(height: 22),
                  _detail(context, l.text('incidentId'), widget.incident.id),
                ],
              ),
            ),
            const SizedBox(height: 22),
            details.when(
              loading: () => const QaCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, _) => QaCard(
                child: Text(
                  l.text('networkError'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              data: (detail) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (detail.responders.isNotEmpty) ...[
                    SectionHeader(title: l.text('assignedResponders')),
                    const SizedBox(height: 10),
                    QaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < detail.responders.length; i++) ...[
                            if (i > 0) const Divider(height: 20),
                            _ResponderTile(responder: detail.responders[i]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  SectionHeader(title: l.text('timeline')),
                  const SizedBox(height: 10),
                  QaCard(child: _Timeline(events: detail.timeline)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.text('disclaimer'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_canCancel) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _cancelling ? null : _cancel,
                icon: _cancelling
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.emergencyRed,
                ),
                label: Text(l.text('cancelEmergency')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _headerColor(String status) => status == 'RESOLVED'
      ? AppTheme.success
      : status == 'CANCELLED'
      ? Colors.grey
      : AppTheme.emergencyRed;
  String _headline(AppLocalizations l, String status) => status == 'RESOLVED'
      ? l.text('statusCompleted')
      : status == 'CANCELLED'
      ? l.text('statusCancelled')
      : l.text('helpArranged');
  Widget _detail(BuildContext context, String label, String value) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );

  Widget _detailWidget(BuildContext context, String label, Widget trailing) =>
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      );
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.events});
  final List<IncidentTimelineEvent> events;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (events.isEmpty) return Text(l.text('loading'));
    return Column(
      children: [
        for (var index = 0; index < events.length; index++)
          _event(context, l, events[index], index == events.length - 1),
      ],
    );
  }

  Widget _event(
    BuildContext context,
    AppLocalizations l,
    IncidentTimelineEvent event,
    bool last,
  ) {
    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(event.occurredAt.toLocal()));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
            if (!last)
              Container(
                height: 32,
                width: 2,
                color: AppTheme.success.withValues(alpha: .35),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incidentStatusLabel(l, event.status),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (event.reason != null)
                  Text(
                    event.reason!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text(time, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResponderTile extends StatelessWidget {
  const _ResponderTile({required this.responder});
  final EmergencyResponder responder;

  String _taskLabel(AppLocalizations l, String taskType) => switch (taskType) {
        'PRIMARY_RESPONSE' => l.text('taskPrimaryResponse'),
        'TRIAGE_CPR_SUPPORT' => l.text('taskTriageCprSupport'),
        'AED_CROWD_CONTROL' => l.text('taskAedCrowdControl'),
        _ => taskType,
      };

  Color _taskColor(String taskType) => switch (taskType) {
        'PRIMARY_RESPONSE' => AppTheme.emergencyRed,
        'TRIAGE_CPR_SUPPORT' => Colors.orange,
        'AED_CROWD_CONTROL' => Colors.blue,
        _ => Colors.teal,
      };

  IconData _taskIcon(String taskType) => switch (taskType) {
        'PRIMARY_RESPONSE' => Icons.health_and_safety,
        'TRIAGE_CPR_SUPPORT' => Icons.favorite,
        'AED_CROWD_CONTROL' => Icons.electric_bolt,
        _ => Icons.person_pin,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = _taskColor(responder.taskType);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_taskIcon(responder.taskType), color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                responder.volunteerName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _taskLabel(l, responder.taskType),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  Text(
                    responder.responseStatus,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: AppTheme.navy,
                ),
                const SizedBox(width: 3),
                Text(
                  '${responder.etaMinutes}m',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navy,
                      ),
                ),
              ],
            ),
            Text(
              'ETA',
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}
