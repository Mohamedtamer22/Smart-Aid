import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import 'volunteer_controller.dart';
import 'volunteer_repository.dart';

class NearbyIncidentsPage extends ConsumerStatefulWidget {
  const NearbyIncidentsPage({super.key});

  @override
  ConsumerState<NearbyIncidentsPage> createState() =>
      _NearbyIncidentsPageState();
}

class _NearbyIncidentsPageState extends ConsumerState<NearbyIncidentsPage> {
  String? _acceptingId;

  Future<void> _accept(VolunteerIncident incident) async {
    setState(() => _acceptingId = incident.id);
    try {
      await ref.read(volunteerRepositoryProvider).accept(incident.id);
      ref.invalidate(volunteerDashboardProvider);
      ref.invalidate(nearbyVolunteerIncidentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).text('missionAccepted')),
          ),
        );
        Navigator.of(context).pop();
      }
    } on ApiFailure {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).text('volunteerActionFailed'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _acceptingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final incidents = ref.watch(nearbyVolunteerIncidentsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.text('nearbyEmergencies'))),
      body: incidents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FilledButton(
              onPressed: () => ref.invalidate(nearbyVolunteerIncidentsProvider),
              child: Text(l.text('retry')),
            ),
          ),
        ),
        data: (items) => items.isEmpty
            ? Center(child: Text(l.text('noNearbyEmergencies')))
            : QaPageFrame(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _IncidentCard(
                    incident: items[index],
                    accepting: _acceptingId == items[index].id,
                    onAccept: () => _accept(items[index]),
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
    required this.accepting,
    required this.onAccept,
  });
  final VolunteerIncident incident;
  final bool accepting;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final skills = incident.matchingSkills.isEmpty
        ? l.text('noSkillsRequired')
        : incident.matchingSkills.join(', ');
    return Semantics(
      label:
          '${l.text('nearbyEmergencies')}: ${_emergencyLabel(l, incident.emergencyType)}',
      child: QaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _emergencyLabel(l, incident.emergencyType),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _Item(label: l.text('priority'), value: incident.priority),
            _Item(
              label: l.text('distance'),
              value:
                  '${incident.distanceKm.toStringAsFixed(1)} ${l.text('kilometers')}',
            ),
            _Item(
              label: l.text('estimatedEta'),
              value: '${incident.etaMinutes} ${l.text('minutes')}',
            ),
            _Item(label: l.text('skillMatch'), value: skills),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: accepting ? null : onAccept,
              style: FilledButton.styleFrom(backgroundColor: AppTheme.blue),
              icon: accepting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.volunteer_activism),
              label: Text(l.text('acceptEmergency')),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

String _emergencyLabel(AppLocalizations l, String type) => switch (type) {
  'CARDIAC' => l.text('emergencyCardiac'),
  'TRAUMA' => l.text('emergencyTrauma'),
  'ACCIDENT' => l.text('emergencyAccident'),
  'MEDICAL' => l.text('emergencyMedical'),
  _ => l.text('emergencyOther'),
};
