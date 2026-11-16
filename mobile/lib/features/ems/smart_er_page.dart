import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import 'smart_er_controller.dart';
import 'smart_er_repository.dart';

class SmartErPage extends ConsumerWidget {
  const SmartErPage({
    super.key,
    required this.incidentId,
    required this.emergencyType,
  });
  final String incidentId;
  final String emergencyType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final recommendations = ref.watch(
      smartErRecommendationsProvider(incidentId),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.text('smartEr'))),
      body: recommendations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => PageFailure(
          title: l.text('smartEr'),
          message: l.text('networkError'),
          retryLabel: l.text('retry'),
          onRetry: () =>
              ref.invalidate(smartErRecommendationsProvider(incidentId)),
        ),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.local_hospital_outlined,
                title: l.text('noRecommendationsTitle'),
                message: l.text('noRecommendationsMessage'),
              )
            : _Recommendations(
                items: items,
                emergencyType: emergencyType,
                incidentId: incidentId,
              ),
      ),
    );
  }
}

class _Recommendations extends ConsumerStatefulWidget {
  const _Recommendations({
    required this.items,
    required this.emergencyType,
    required this.incidentId,
  });
  final List<HospitalRecommendation> items;
  final String emergencyType;
  final String incidentId;

  @override
  ConsumerState<_Recommendations> createState() => _RecommendationsState();
}

class _RecommendationsState extends ConsumerState<_Recommendations> {
  bool _confirming = false;

  Future<void> _confirm(HospitalRecommendation hospital) async {
    if (_confirming) return;
    setState(() => _confirming = true);
    final l = AppLocalizations.of(context);
    try {
      await ref
          .read(smartErRepositoryProvider)
          .confirmDestination(widget.incidentId, hospital.hospitalName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.success,
            content: Text(
              l.format('destinationConfirmed', {
                'hospital': hospital.hospitalName,
              }),
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.emergencyRed,
            content: Text(l.text('networkError')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final winner = widget.items.first;
    return QaPageFrame(
      child: ListView(
        children: [
          QaPageHeader(
            title: l.text('smartErSubtitle'),
            subtitle:
                '${widget.emergencyType} · ${l.text('smartErDecisionSupport')}',
          ),
          const SizedBox(height: 20),
          QaHeroCard(
            eyebrow: l.text('recommendedDestination'),
            title: winner.hospitalName,
            message: l.text('recommended'),
            icon: Icons.local_hospital_outlined,
            footer: Row(
              children: [
                Expanded(
                  child: _whiteMetric(
                    '${winner.score.toStringAsFixed(0)} / 100',
                    l.text('smartScore'),
                  ),
                ),
                Expanded(
                  child: _whiteMetric(
                    '${winner.etaMinutes} ${l.text('minutes')}',
                    l.text('estimatedEta'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _confirming ? null : () => _confirm(winner),
            icon: _confirming
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.navigation_rounded),
            label: Text(
              _confirming
                  ? l.text('confirmingDestination')
                  : l.text('confirmDestination'),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.emergencyRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(title: l.text('whyThisHospital')),
          const SizedBox(height: 8),
          QaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final reason in winner.reasons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.success,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_localizedReason(l, reason))),
                      ],
                    ),
                  ),
                Text(
                  l.text('estimatedNotLive'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(title: l.text('compareHospitals')),
          const SizedBox(height: 8),
          ...widget.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ComparisonCard(
                item: item,
                highlighted: item.hospitalId == winner.hospitalId,
                onSelect: _confirming ? null : () => _confirm(item),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l.text('disclaimer'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _whiteMetric(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: .85))),
    ],
  );
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.item,
    required this.highlighted,
    this.onSelect,
  });
  final HospitalRecommendation item;
  final bool highlighted;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return QaCard(
      color: highlighted ? AppTheme.blue.withValues(alpha: .06) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.hospitalName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: '${item.score.toStringAsFixed(0)} / 100',
                color: highlighted ? AppTheme.success : AppTheme.blue,
              ),
            ],
          ),
          const SizedBox(height: 14),
          QaScoreBar(
            label: l.text('travelTime'),
            score: item.travelTimeScore,
            color: AppTheme.blue,
          ),
          const SizedBox(height: 12),
          QaScoreBar(
            label: l.text('capability'),
            score: item.capabilityScore,
            color: AppTheme.success,
          ),
          const SizedBox(height: 12),
          QaScoreBar(
            label: l.text('specialtyMatch'),
            score: item.specialtyScore,
            color: AppTheme.navy,
          ),
          const SizedBox(height: 12),
          QaScoreBar(
            label: l.text('congestion'),
            score: item.congestionScore,
            color: AppTheme.warning,
          ),
          const SizedBox(height: 12),
          Text(
            '${item.etaMinutes} ${l.text('minutes')} · ${l.text('estimatedEta')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (!highlighted && onSelect != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSelect,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(l.text('selectHospital')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _localizedReason(AppLocalizations l, String reason) {
  if (reason == 'Verified specialty match') {
    return l.text('smartErReasonSpecialty');
  }
  if (reason == 'Required resources marked available') {
    return l.text('smartErReasonResources');
  }
  if (reason == 'ETA is an estimate based on straight-line distance') {
    return l.text('smartErReasonEta');
  }
  if (reason ==
      'Congestion data is unavailable and receives no positive score') {
    return l.text('smartErReasonMissingCongestion');
  }
  const prefix = 'Reported congestion: ';
  if (reason.startsWith(prefix)) {
    return l.format('smartErReasonReportedCongestion', {
      'value': reason.substring(prefix.length),
    });
  }
  return reason;
}
