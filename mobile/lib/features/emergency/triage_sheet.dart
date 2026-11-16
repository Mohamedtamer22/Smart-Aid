import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import 'emergency_repository.dart';

class TriageSheet extends StatefulWidget {
  const TriageSheet({super.key});
  @override
  State<TriageSheet> createState() => _TriageSheetState();
}

class _TriageSheetState extends State<TriageSheet> {
  bool? conscious;
  bool? breathing;
  bool? bleeding;
  bool? chestPain;
  bool? fall;
  bool? traffic;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: ListView(
          shrinkWrap: true,
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
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.softRed,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: AppTheme.emergencyRed.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: AppTheme.emergencyRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.text('triage'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            QaCard(
              color: AppTheme.sky,
              borderColor: AppTheme.blue.withValues(alpha: 0.25),
              padding: const EdgeInsets.all(13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.text('triageIntro'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _question(
              l,
              l.text('triageConscious'),
              conscious,
              (v) => setState(() => conscious = v),
            ),
            _question(
              l,
              l.text('triageBreathing'),
              breathing,
              (v) => setState(() => breathing = v),
            ),
            _question(
              l,
              l.text('triageBleeding'),
              bleeding,
              (v) => setState(() => bleeding = v),
            ),
            _question(
              l,
              l.text('triageChestPain'),
              chestPain,
              (v) => setState(() => chestPain = v),
            ),
            _question(
              l,
              l.text('triageFall'),
              fall,
              (v) => setState(() => fall = v),
            ),
            _question(
              l,
              l.text('triageTrafficAccident'),
              traffic,
              (v) => setState(() => traffic = v),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                EmergencyTriage(
                  conscious: conscious,
                  breathing: breathing,
                  severeBleeding: bleeding,
                  chestPain: chestPain,
                  fallOccurred: fall,
                  trafficAccident: traffic,
                ),
              ),
              child: Text(l.text('triageContinue')),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(const EmergencyTriage()),
              child: Text(l.text('triageSkip')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _question(
    AppLocalizations l,
    String title,
    bool? value,
    ValueChanged<bool?> changed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: QaCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontSize: 15.5),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool?>(
              segments: [
                ButtonSegment(value: true, label: Text(l.text('yes'))),
                ButtonSegment(value: false, label: Text(l.text('no'))),
                ButtonSegment(value: null, label: Text(l.text('notSure'))),
              ],
              selected: {value},
              emptySelectionAllowed: false,
              onSelectionChanged: (values) => changed(values.first),
            ),
          ),
        ],
      ),
    ),
  );
}
