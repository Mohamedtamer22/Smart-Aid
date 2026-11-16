import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import 'offline_emergency_service.dart';

class OfflineEmergencyPage extends ConsumerStatefulWidget {
  const OfflineEmergencyPage({super.key});

  @override
  ConsumerState<OfflineEmergencyPage> createState() =>
      _OfflineEmergencyPageState();
}

class _OfflineEmergencyPageState extends ConsumerState<OfflineEmergencyPage> {
  final TextEditingController _notesController = TextEditingController();
  String _selectedType = 'MEDICAL';
  List<QueuedOfflineIncident> _queue = const [];
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _reloadQueue();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _reloadQueue() async {
    final items = await ref.read(offlineEmergencyServiceProvider).loadQueue();
    if (!mounted) return;
    setState(() => _queue = items);
  }

  Future<void> _queueDraft() async {
    await ref
        .read(offlineEmergencyServiceProvider)
        .enqueueIncident(
          emergencyType: _selectedType,
          latitude: 30.0444,
          longitude: 31.2357,
          notes: _notesController.text,
        );
    _notesController.clear();
    await _reloadQueue();
    if (!mounted) return;
    final isAr = AppLocalizations.of(context).isArabic;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تم حفظ بلاغ الطوارئ محلياً في قائمة المزامنة الآمنة.'
              : 'Emergency draft saved locally in the idempotent sync queue.',
        ),
      ),
    );
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    try {
      final res = await ref
          .read(offlineEmergencyServiceProvider)
          .syncPending(ref.read(apiClientProvider));
      await _reloadQueue();
      if (!mounted) return;
      final isAr = AppLocalizations.of(context).isArabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'تمت مزامنة ${res.syncedCount} بلاغ(ات)، وتعذّر ${res.failedCount}.'
                : 'Synced ${res.syncedCount} draft(s); ${res.failedCount} still pending.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.of(context).isArabic;
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'وضع الطوارئ دون إنترنت' : 'Offline Emergency Mode'),
      ),
      body: QaPageFrame(
        child: ListView(
          children: [
            QaCard(
              color: const Color(0xFFFFF7ED),
              borderColor: const Color(0xFFFDBA74),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC2410C).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      color: Color(0xFFC2410C),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'ملاحظة أمان: وضع عدم الاتصال لا يضمن الإرسال الفوري لفرق الإسعاف أو التتبع المباشر. اتصل برقم الطوارئ المحلي عند توفر الشبكة الخلوية.'
                          : 'Safety Notice: Offline mode cannot guarantee live EMS dispatch or real-time tracking. Call local emergency services directly whenever cellular voice is available.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF9A3412),
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(
              title: isAr
                  ? 'أدلة الإسعافات الأولية المخزّنة محلياً'
                  : 'Cached Offline First-Aid Guides',
            ),
            const SizedBox(height: 10),
            for (final guide in OfflineEmergencyService.cachedGuides)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: QaCard(
                  padding: EdgeInsets.zero,
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.softRed,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.emergencyRed.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.medical_services_outlined,
                          color: AppTheme.emergencyRed,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        isAr ? guide.titleAr : guide.titleEn,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        14,
                      ),
                      children: [
                        for (int i = 0; i < guide.stepsEn.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  margin: const EdgeInsets.only(top: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.sky,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.navyBlue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isAr ? guide.stepsAr[i] : guide.stepsEn[i],
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            SectionHeader(
              title: isAr
                  ? 'حفظ بلاغ للمزامنة التلقائية لاحقاً'
                  : 'Queue Offline SOS Draft (Idempotent Sync)',
            ),
            const SizedBox(height: 10),
            QaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: ['MEDICAL', 'CARDIAC', 'TRAUMA', 'ACCIDENT']
                        .map(
                          (type) => ChoiceChip(
                            label: Text(type),
                            selected: _selectedType == type,
                            onSelected: (_) =>
                                setState(() => _selectedType = type),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: isAr
                          ? 'وصف الحالة أو الموقع التقريبي'
                          : 'Incident notes or landmark',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 46),
                        ),
                        onPressed: _queueDraft,
                        icon: const Icon(Icons.save_alt_rounded, size: 18),
                        label: Text(
                          isAr ? 'حفظ محلياً الآن' : 'Save Offline Draft',
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                        ),
                        onPressed: _syncing || _queue.isEmpty
                            ? null
                            : _syncNow,
                        icon: const Icon(Icons.sync_rounded, size: 18),
                        label: Text(
                          _syncing
                              ? (isAr ? 'جاري المزامنة...' : 'Syncing...')
                              : (isAr
                                    ? 'مزامنة (${_queue.length})'
                                    : 'Sync Pending (${_queue.length})'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_queue.isNotEmpty) ...[
              Text(
                isAr
                    ? 'البلاغات المحفوظة محلياً (لم تُؤكَّد من الخادم بعد)'
                    : 'Locally Queued Drafts (Not Yet Server-Confirmed)',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              for (final item in _queue)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: QaCard(
                    padding: const EdgeInsets.all(14),
                    borderColor: AppTheme.warning.withValues(alpha: 0.35),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.softWarning,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.schedule_send_rounded,
                            color: AppTheme.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.emergencyType,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  StatusPill(
                                    label: isAr ? 'محفوظ محلياً' : 'QUEUED',
                                    color: AppTheme.warning,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.notes.isEmpty
                                    ? 'Offline Draft'
                                    : item.notes,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Key: ${item.idempotencyKey}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
