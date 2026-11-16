import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../shared/widgets/app_widgets.dart';
import '../emergency/active_emergency_page.dart';
import '../emergency/emergency_presenter.dart';
import '../emergency/emergency_repository.dart';
import 'incidents_controller.dart';

class IncidentsPage extends ConsumerWidget {
  const IncidentsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final incidents = ref.watch(myIncidentsProvider);
    return incidents.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => PageFailure(
        title: l.text('incidentHistory'),
        message: l.text('networkError'),
        retryLabel: l.text('retry'),
        onRetry: () => ref.invalidate(myIncidentsProvider),
      ),
      data: (items) => items.isEmpty
          ? EmptyState(
              icon: Icons.history_toggle_off,
              title: l.text('incidentsEmptyTitle'),
              message: l.text('incidentsEmptyMessage'),
            )
          : QaPageFrame(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(myIncidentsProvider),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) =>
                      _IncidentCard(incident: items[index]),
                ),
              ),
            ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident});
  final EmergencyIncident incident;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(incident.createdAt.toLocal());
    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(incident.createdAt.toLocal()));
    return Semantics(
      button: true,
      label:
          '${emergencyTypeLabel(l, incident.emergencyType)} ${incidentStatusLabel(l, incident.status)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ActiveEmergencyPage(incident: incident),
          ),
        ),
        child: QaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      emergencyTypeLabel(l, incident.emergencyType),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusPill(
                    label: priorityLabel(l, incident.priority),
                    color: priorityColor(incident.priority),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.route_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(incidentStatusLabel(l, incident.status)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$date · $time',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
