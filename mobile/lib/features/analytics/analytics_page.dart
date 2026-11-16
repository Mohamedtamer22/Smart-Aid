import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import '../emergency/emergency_presenter.dart';
import 'analytics_controller.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final dashboardAsync = ref.watch(analyticsDashboardProvider);
    final reportAsync = ref.watch(researchReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(l.text('analytics')),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(analyticsDashboardProvider);
              ref.invalidate(researchReportProvider);
            },
            icon: const Icon(Icons.refresh),
            tooltip: l.text('refresh'),
          ),
        ],
      ),
      body: QaPageFrame(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(analyticsDashboardProvider);
            ref.invalidate(researchReportProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              QaPageHeader(
                title: l.text('analytics'),
                subtitle: l.text('systemKpis'),
              ),
              const SizedBox(height: 16),
              dashboardAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, _) => PageFailure(
                  title: l.text('analytics'),
                  message: l.text('error'),
                  retryLabel: l.text('retry'),
                  onRetry: () => ref.invalidate(analyticsDashboardProvider),
                ),
                data: (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: QaMetricCard(
                            icon: Icons.timer_outlined,
                            label: l.text('avgResponseTime'),
                            value:
                                '${data.averageResponseTimeMinutes.toStringAsFixed(1)} ${l.text('minutes')}',
                            color: AppTheme.blue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: QaMetricCard(
                            icon: Icons.volunteer_activism_outlined,
                            label: l.text('volunteerAcceptance'),
                            value:
                                '${data.volunteerAcceptanceRatePercent.toStringAsFixed(0)}%',
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: QaMetricCard(
                            icon: Icons.emergency_outlined,
                            label: l.text('activeIncidents'),
                            value: data.activeIncidents.toString(),
                            color: AppTheme.warning,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: QaMetricCard(
                            icon: Icons.local_hospital_outlined,
                            label: l.text('totalHospitals'),
                            value: data.totalHospitals.toString(),
                            color: AppTheme.navy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SectionHeader(title: l.text('incidentsByType')),
                    const SizedBox(height: 8),
                    QaCard(
                      child: Column(
                        children: data.incidentsByType.entries.map((e) {
                          final total = data.totalIncidents > 0
                              ? data.totalIncidents
                              : 1;
                          final pct = (e.value / total) * 100;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: QaScoreBar(
                              label: '${e.key} (${e.value})',
                              score: pct,
                              color: AppTheme.blue,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SectionHeader(title: l.text('researchComparison')),
              const SizedBox(height: 6),
              Text(
                l.text('researchNotes'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              reportAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, _) => Text(l.text('unavailableData')),
                data: (report) => Column(
                  children: [
                    QaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.text('benchmarkTitle'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 14),
                          QaScoreBar(
                            label: l.text('smartErStrategy'),
                            score: report.smartErAverageScore,
                            color: AppTheme.success,
                          ),
                          const SizedBox(height: 10),
                          QaScoreBar(
                            label: l.text('nearestStrategy'),
                            score: report.nearestAverageScore,
                            color: AppTheme.blue,
                          ),
                          const SizedBox(height: 10),
                          QaScoreBar(
                            label: l.text('randomStrategy'),
                            score: report.randomAverageScore,
                            color: AppTheme.warning,
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.verified,
                                  color: AppTheme.success,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    report.summaryNotes,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...report.benchmarks.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: QaCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      emergencyTypeLabel(l, b.emergencyType),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusPill(
                                    label:
                                        '${l.text('smartScore')}: ${b.smartErRecommendation.compositeScore.toStringAsFixed(0)}',
                                    color: AppTheme.success,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• ${l.text('recommended')}: ${b.smartErRecommendation.hospitalName} (${b.smartErRecommendation.travelTimeEtaMinutes} ${l.text('minutes')})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '• ${b.nearestHospital.hospitalName} (${l.text('smartScore')}: ${b.nearestHospital.compositeScore.toStringAsFixed(0)})',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                b.conclusion,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.navy),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
