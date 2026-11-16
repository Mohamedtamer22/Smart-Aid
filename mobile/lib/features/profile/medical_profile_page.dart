import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import 'profile_controller.dart';
import 'profile_repository.dart';

class MedicalProfilePage extends ConsumerWidget {
  const MedicalProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final value = ref.watch(medicalProfileProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.text('medicalProfile'))),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => PageFailure(
          title: l.text('medicalProfile'),
          message: l.text('profileSaveFailed'),
          retryLabel: l.text('retry'),
          onRetry: () => ref.read(medicalProfileProvider.notifier).refresh(),
        ),
        data: (profile) => _MedicalProfileEditor(profile: profile),
      ),
    );
  }
}

class _MedicalProfileEditor extends ConsumerStatefulWidget {
  const _MedicalProfileEditor({required this.profile});
  final MedicalProfileData profile;

  @override
  ConsumerState<_MedicalProfileEditor> createState() =>
      _MedicalProfileEditorState();
}

class _MedicalProfileEditorState extends ConsumerState<_MedicalProfileEditor> {
  late final TextEditingController _allergies = TextEditingController(
    text: widget.profile.allergies ?? '',
  );
  late final TextEditingController _medications = TextEditingController(
    text: widget.profile.medications ?? '',
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.profile.emergencyNotes ?? '',
  );
  late String? _bloodType = widget.profile.bloodType;
  late bool _consent = widget.profile.sharingConsent;
  bool _saving = false;

  @override
  void dispose() {
    _allergies.dispose();
    _medications.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final l = AppLocalizations.of(context);
    try {
      final payload = MedicalProfileData(
        bloodType: _bloodType,
        allergies: _allergies.text,
        medications: _medications.text,
        emergencyNotes: _notes.text,
        sharingConsent: _consent,
      );
      await ref.read(medicalProfileProvider.notifier).save(payload);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.text('saved'))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.text('profileSaveFailed'))));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = l.isArabic;

    return QaPageFrame(
      child: ListView(
        children: [
          // Live Emergency Medical ID Preview Card
          QaHeroCard(
            eyebrow: isAr ? 'بطاقة الهوية الطبية للطوارئ' : 'EMERGENCY MEDICAL ID',
            title: _bloodType != null
                ? (isAr ? 'فصيلة الدم: $_bloodType' : 'Blood Group: $_bloodType')
                : l.text('medicalProfile'),
            message: l.text('medicalProfileExplain'),
            icon: Icons.medical_information_rounded,
            color: AppTheme.emergencyRed,
            footer: Row(
              children: [
                Icon(
                  _consent
                      ? Icons.verified_user_rounded
                      : Icons.lock_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _consent
                        ? (isAr
                              ? 'مشاركة بيانات الطوارئ مع المسعفين مفعّلة'
                              : 'EMS responder sharing enabled')
                        : (isAr
                              ? 'مشاركة بيانات الطوارئ متوقفة حالياً'
                              : 'EMS responder sharing paused'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          QaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _bloodType,
                  decoration: InputDecoration(
                    labelText: l.text('bloodType'),
                    prefixIcon: const Icon(
                      Icons.bloodtype_rounded,
                      color: AppTheme.emergencyRed,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'A+', child: Text('A+')),
                    DropdownMenuItem(value: 'A-', child: Text('A-')),
                    DropdownMenuItem(value: 'B+', child: Text('B+')),
                    DropdownMenuItem(value: 'B-', child: Text('B-')),
                    DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                    DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                    DropdownMenuItem(value: 'O+', child: Text('O+')),
                    DropdownMenuItem(value: 'O-', child: Text('O-')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _bloodType = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _allergies,
                  maxLines: 3,
                  maxLength: 2000,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: l.text('allergies'),
                    prefixIcon: const Icon(Icons.warning_amber_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _medications,
                  maxLines: 3,
                  maxLength: 2000,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: l.text('medications'),
                    prefixIcon: const Icon(Icons.medication_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  maxLines: 4,
                  maxLength: 2000,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: l.text('emergencyNotes'),
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          QaCard(
            padding: EdgeInsets.zero,
            borderColor: _consent
                ? AppTheme.success.withValues(alpha: 0.35)
                : AppTheme.border,
            child: SwitchListTile.adaptive(
              value: _consent,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _consent = value),
              title: Text(
                l.text('sharingConsent'),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.lock_outline_rounded),
            label: Text(l.text(_saving ? 'saving' : 'save')),
          ),
        ],
      ),
    );
  }
}
