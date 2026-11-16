import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import 'healthcare_repository.dart';

class ConnectedHealthcarePage extends ConsumerStatefulWidget {
  const ConnectedHealthcarePage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<ConnectedHealthcarePage> createState() =>
      _ConnectedHealthcarePageState();
}

class _ConnectedHealthcarePageState
    extends ConsumerState<ConnectedHealthcarePage> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  Future<void> _showBloodRequestDialog(BloodBankItem bank) async {
    final isAr = AppLocalizations.of(context).isArabic;
    String bloodGroup = 'O-';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.softRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bloodtype_rounded,
                  color: AppTheme.emergencyRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr ? 'طلب دم عاجل' : 'Urgent Blood Request',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bank.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: bloodGroup,
                decoration: InputDecoration(
                  labelText: isAr ? 'فصيلة الدم' : 'Blood Group',
                ),
                items: const ['O-', 'O+', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => bloodGroup = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: AppTheme.emergencyRed,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isAr ? 'إرسال الطلب' : 'Submit Request'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(healthcareRepositoryProvider)
          .createBloodRequest(
            bloodGroup: bloodGroup,
            unitsRequested: 1,
            bloodBankId: bank.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'تم إرسال طلب فصيلة $bloodGroup إلى ${bank.name}.'
                : 'Blood request ($bloodGroup) submitted to ${bank.name}.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'تعذر إرسال الطلب؛ تحقق من الاتصال بالخادم.'
                : 'Could not submit request; verify backend connectivity.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.of(context).isArabic;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAr ? 'شبكة الرعاية الصحية المتصلة' : 'Connected Healthcare Network',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(pharmaciesProvider);
              ref.invalidate(bloodBanksProvider);
              ref.invalidate(laboratoriesProvider);
              ref.invalidate(medicalProvidersProvider);
            },
          ),
        ],
      ),
      body: QaPageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.sky,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.blue.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.blue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'تنبيه: الصيدليات ومقدمو الخدمات لا يغنيان عن الإسعاف في الحالات الحرجة. البيانات المعلّمة بـ DEMO بيانات تجريبية.'
                          : 'Notice: Pharmacies and healthcare directories do not replace emergency medical services. Records marked DEMO are local sandbox fixtures.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.navy,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _TabPill(
                    label: isAr ? 'الصيدليات' : 'Pharmacies',
                    icon: Icons.local_pharmacy_outlined,
                    accent: const Color(0xFF059669),
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  const SizedBox(width: 8),
                  _TabPill(
                    label: isAr ? 'بنوك الدم' : 'Blood Banks',
                    icon: Icons.bloodtype_outlined,
                    accent: AppTheme.emergencyRed,
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                  const SizedBox(width: 8),
                  _TabPill(
                    label: isAr ? 'المعامل' : 'Laboratories',
                    icon: Icons.science_outlined,
                    accent: const Color(0xFF6D28D9),
                    selected: _tab == 2,
                    onTap: () => setState(() => _tab = 2),
                  ),
                  const SizedBox(width: 8),
                  _TabPill(
                    label: isAr ? 'الخدمات الطبية' : 'Medical Services',
                    icon: Icons.medical_information_outlined,
                    accent: AppTheme.blue,
                    selected: _tab == 3,
                    onTap: () => setState(() => _tab = 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: switch (_tab) {
                0 => _buildPharmacies(isAr),
                1 => _buildBloodBanks(isAr),
                2 => _buildLabs(isAr),
                _ => _buildProviders(isAr),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacies(bool isAr) {
    final async = ref.watch(pharmaciesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: isAr ? 'تعذر تحميل الصيدليات' : 'Unable to load pharmacies',
        message: isAr
            ? 'تحقق من الاتصال بالخادم وأعد المحاولة.'
            : 'Verify server connectivity and try again.',
      ),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.local_pharmacy_outlined,
            title: isAr
                ? 'لا توجد صيدليات مسجلة حالياً'
                : 'No verified pharmacies yet',
            message: isAr
                ? 'ستظهر الصيدليات المعتمدة هنا فور توفرها.'
                : 'Verified partner pharmacies will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final p = items[i];
            return _HealthcareServiceCard(
              icon: Icons.local_pharmacy_rounded,
              accent: const Color(0xFF059669),
              title: p.name,
              subtitle: p.address,
              meta: '${p.openingHours} • ${p.phone}',
              badge: p.emergencySuppliesAvailable
                  ? (isAr ? 'مستلزمات طوارئ' : 'Emergency Kit')
                  : null,
              actionLabel: isAr ? 'اطلب' : 'Order',
              onAction: () async {
                try {
                  await ref
                      .read(healthcareRepositoryProvider)
                      .orderEmergencySupply(
                        pharmacyId: p.id,
                        deliveryAddress: 'Mobile Citizen Location',
                      );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'تم إرسال طلب مستلزمات طوارئ مع التوصيل إلى ${p.name}'
                            : 'Emergency supply order with delivery sent to ${p.name}',
                      ),
                    ),
                  );
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'تعذر إرسال الطلب؛ تحقق من الاتصال بالخادم.'
                            : 'Order failed; verify backend connectivity.',
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBloodBanks(bool isAr) {
    final async = ref.watch(bloodBanksProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: isAr ? 'تعذر تحميل بنوك الدم' : 'Unable to load blood banks',
        message: isAr
            ? 'تحقق من الاتصال بالخادم وأعد المحاولة.'
            : 'Verify server connectivity and try again.',
      ),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.bloodtype_outlined,
            title: isAr
                ? 'لا توجد بنوك دم مسجلة'
                : 'No verified blood banks yet',
            message: isAr
                ? 'ستظهر بنوك الدم المعتمدة هنا فور توفرها.'
                : 'Verified blood banks will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final b = items[i];
            return _HealthcareServiceCard(
              icon: Icons.bloodtype_rounded,
              accent: AppTheme.emergencyRed,
              title: b.name,
              subtitle: b.address,
              meta: b.phone,
              badge: isAr ? 'طلب دم عاجل' : 'Urgent Blood',
              actionLabel: isAr ? 'طلب دم' : 'Request',
              onAction: () => _showBloodRequestDialog(b),
            );
          },
        );
      },
    );
  }

  Widget _buildLabs(bool isAr) {
    final async = ref.watch(laboratoriesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: isAr ? 'تعذر تحميل المعامل' : 'Unable to load laboratories',
        message: isAr
            ? 'تحقق من الاتصال بالخادم وأعد المحاولة.'
            : 'Verify server connectivity and try again.',
      ),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.science_outlined,
            title: isAr
                ? 'لا توجد معامل مسجلة'
                : 'No verified laboratories yet',
            message: isAr
                ? 'ستظهر معامل التحاليل المعتمدة هنا فور توفرها.'
                : 'Verified diagnostic laboratories will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final lab = items[i];
            return _HealthcareServiceCard(
              icon: Icons.science_rounded,
              accent: const Color(0xFF6D28D9),
              title: lab.name,
              subtitle: lab.address,
              meta: lab.phone,
              badge: isAr ? 'تحاليل معتمدة' : 'Diagnostics',
              actionLabel: isAr ? 'حجز' : 'Book',
              onAction: () async {
                try {
                  await ref
                      .read(healthcareRepositoryProvider)
                      .bookFirstLabService(lab.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'تم حجز تحليل مخبري لدى ${lab.name}'
                            : 'Lab test appointment booked at ${lab.name}',
                      ),
                    ),
                  );
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr ? 'تعذر حجز التحليل.' : 'Lab booking failed.',
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildProviders(bool isAr) {
    final async = ref.watch(medicalProvidersProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: isAr
            ? 'تعذر تحميل مقدمي الخدمات'
            : 'Unable to load medical providers',
        message: isAr
            ? 'تحقق من الاتصال بالخادم وأعد المحاولة.'
            : 'Verify server connectivity and try again.',
      ),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.medical_services_outlined,
            title: isAr
                ? 'لا يوجد مقدمو خدمات حالياً'
                : 'No verified providers yet',
            message: isAr
                ? 'سيظهر الأطباء والعيادات المعتمدة هنا فور توفرهم.'
                : 'Verified doctors and clinics will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final prov = items[i];
            return _HealthcareServiceCard(
              icon: Icons.medical_services_rounded,
              accent: AppTheme.blue,
              title: prov.name,
              subtitle: '${prov.providerType} • ${prov.specialty}',
              meta: prov.address,
              badge: prov.telemedicineEnabled
                  ? (isAr ? 'استشارة عن بُعد' : 'Telemedicine')
                  : null,
              actionLabel: isAr ? 'حجز' : 'Book',
              onAction: () async {
                try {
                  await ref
                      .read(healthcareRepositoryProvider)
                      .bookProviderVisit(
                        providerId: prov.id,
                        chiefComplaint: 'Mobile App Consultation Request',
                        telemedicine: prov.telemedicineEnabled,
                      );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'تم حجز موعد لدى ${prov.name}'
                            : 'Appointment booked with ${prov.name}',
                      ),
                    ),
                  );
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr ? 'تعذر حجز الموعد.' : 'Booking failed.',
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : AppTheme.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: selected ? Colors.white : accent),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.text,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthcareServiceCard extends StatelessWidget {
  const _HealthcareServiceCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.actionLabel,
    required this.onAction,
    this.badge,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String meta;
  final String? badge;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return QaCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (badge != null) StatusPill(label: badge!, color: accent),
              const Spacer(),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  backgroundColor: accent.withValues(alpha: 0.12),
                  foregroundColor: accent,
                ),
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
