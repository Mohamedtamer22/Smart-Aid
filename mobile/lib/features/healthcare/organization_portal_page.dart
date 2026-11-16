import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/language_toggle_button.dart';
import '../../shared/widgets/quick_role_switcher.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';

/// Dedicated mobile operational portal for the 5 healthcare provider roles:
/// HOSPITAL, PHARMACIST, BLOOD_BANK_STAFF, LAB_STAFF, and DOCTOR.
/// Every action writes directly to the Spring Boot API and synchronizes live
/// with the Angular ECC Web Dashboard.
class OrganizationPortalPage extends ConsumerStatefulWidget {
  const OrganizationPortalPage({super.key, required this.session});

  final Session session;

  @override
  ConsumerState<OrganizationPortalPage> createState() =>
      _OrganizationPortalPageState();
}

class _OrganizationPortalPageState
    extends ConsumerState<OrganizationPortalPage> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _hospitals = const [];
  List<Map<String, dynamic>> _handovers = const [];
  List<Map<String, dynamic>> _orders = const [];
  List<Map<String, dynamic>> _deliveries = const [];
  List<Map<String, dynamic>> _bloodInventory = const [];
  List<Map<String, dynamic>> _bloodRequests = const [];
  List<Map<String, dynamic>> _labAppointments = const [];
  List<Map<String, dynamic>> _providerAppointments = const [];

  String get _primaryRole {
    final roles = widget.session.roles;
    if (roles.contains('HOSPITAL')) return 'HOSPITAL';
    if (roles.contains('PHARMACIST')) return 'PHARMACIST';
    if (roles.contains('BLOOD_BANK_STAFF')) return 'BLOOD_BANK_STAFF';
    if (roles.contains('LAB_STAFF')) return 'LAB_STAFF';
    if (roles.contains('DOCTOR')) return 'DOCTOR';
    return 'HOSPITAL';
  }

  Color get _roleColor => switch (_primaryRole) {
    'HOSPITAL' => AppTheme.blue,
    'PHARMACIST' => const Color(0xFF059669),
    'BLOOD_BANK_STAFF' => const Color(0xFFB91C1C),
    'LAB_STAFF' => const Color(0xFF6D28D9),
    'DOCTOR' => const Color(0xFF0F766E),
    _ => AppTheme.navy,
  };

  IconData get _roleIcon => switch (_primaryRole) {
    'HOSPITAL' => Icons.local_hospital_rounded,
    'PHARMACIST' => Icons.local_pharmacy_rounded,
    'BLOOD_BANK_STAFF' => Icons.bloodtype_rounded,
    'LAB_STAFF' => Icons.science_rounded,
    'DOCTOR' => Icons.medical_services_rounded,
    _ => Icons.verified_user_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get<List<dynamic>>(path);
    return (res.data ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      switch (_primaryRole) {
        case 'HOSPITAL':
          _hospitals = await _getList('/api/hospitals');
          _handovers = await _getList('/api/handovers/pending');
          break;
        case 'PHARMACIST':
          _orders = await _getList('/api/pharmacies/orders/pending');
          _deliveries = await _getList('/api/medical-deliveries');
          break;
        case 'BLOOD_BANK_STAFF':
          _bloodInventory = await _getList('/api/blood-banks/inventory');
          _bloodRequests = await _getList('/api/blood-requests');
          break;
        case 'LAB_STAFF':
          _labAppointments = await _getList('/api/lab-appointments');
          break;
        case 'DOCTOR':
          _providerAppointments = await _getList('/api/provider-appointments');
          _handovers = await _getList('/api/handovers/pending');
          break;
      }
    } catch (_) {
      _error = 'Could not sync live data from server.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _updateHospitalCapacity(String hospitalId, int pct) async {
    try {
      await ref
          .read(apiClientProvider)
          .patch<Map<String, dynamic>>(
            '/api/hospitals/$hospitalId/capacity',
            data: {
              'estimatedCongestion': pct,
              'sourceNote': 'Mobile Hospital App',
            },
          );
      _toast('Capacity updated to $pct% (synced to ECC)');
      await _loadData();
    } catch (_) {
      _toast('Failed to update hospital capacity.');
    }
  }

  Future<void> _acknowledgeHandover(String handoverId) async {
    try {
      await ref
          .read(apiClientProvider)
          .post<Map<String, dynamic>>(
            '/api/handovers/$handoverId/acknowledge',
            data: {'receivingStaffName': widget.session.displayName},
          );
      _toast('Handover acknowledged (synced to ECC)');
      await _loadData();
    } catch (_) {
      _toast('Failed to acknowledge handover.');
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await ref
          .read(apiClientProvider)
          .patch<Map<String, dynamic>>(
            '/api/pharmacies/orders/$orderId/status',
            data: {'status': status},
          );
      _toast('Order updated to $status');
      await _loadData();
    } catch (_) {
      _toast('Failed to update order status.');
    }
  }

  Future<void> _markDelivered(String trackingCode) async {
    try {
      await ref
          .read(apiClientProvider)
          .patch<Map<String, dynamic>>(
            '/api/medical-deliveries/${Uri.encodeComponent(trackingCode)}/status',
            data: {'status': 'DELIVERED'},
          );
      _toast('Delivery $trackingCode marked DELIVERED');
      await _loadData();
    } catch (_) {
      _toast('Failed to update delivery status.');
    }
  }

  Future<void> _fulfillBloodRequest(String reqId) async {
    try {
      await ref
          .read(apiClientProvider)
          .patch<Map<String, dynamic>>(
            '/api/blood-requests/$reqId/status',
            data: {'status': 'FULFILLED'},
          );
      _toast('Blood request FULFILLED (synced to ECC)');
      await _loadData();
    } catch (_) {
      _toast('Failed to fulfill blood request.');
    }
  }

  Future<void> _publishLabResult(String appId) async {
    try {
      await ref
          .read(apiClientProvider)
          .put<Map<String, dynamic>>(
            '/api/lab-appointments/$appId/result',
            data: {
              'resultSummary': 'Verified Lab Panel Complete — Normal Range',
            },
          );
      _toast('Lab result published (COMPLETED)');
      await _loadData();
    } catch (_) {
      _toast('Failed to publish lab result.');
    }
  }

  Future<void> _confirmAppointment(String appId) async {
    try {
      await ref
          .read(apiClientProvider)
          .patch<Map<String, dynamic>>(
            '/api/provider-appointments/$appId/status',
            data: {'status': 'CONFIRMED'},
          );
      _toast('Appointment CONFIRMED (synced to ECC)');
      await _loadData();
    } catch (_) {
      _toast('Failed to confirm appointment.');
    }
  }

  bool get _isSandbox =>
      widget.session.email.endsWith('.local') ||
      widget.session.email.startsWith('demo.');

  String _shortId(Object? raw) {
    final value = (raw ?? '').toString().trim();
    if (value.isEmpty) return '—';
    return value.length <= 8 ? value : value.substring(0, 8);
  }

  StatusPill _statusPill(Object? rawStatus, bool isAr) {
    final code = (rawStatus ?? 'UNKNOWN').toString().toUpperCase();
    final (String label, Color color) = switch (code) {
      'FULFILLED' => (isAr ? 'مكتمل' : 'FULFILLED', AppTheme.success),
      'COMPLETED' => (isAr ? 'مكتمل' : 'COMPLETED', AppTheme.success),
      'CONFIRMED' => (isAr ? 'مؤكد' : 'CONFIRMED', AppTheme.success),
      'DELIVERED' => (isAr ? 'تم التوصيل' : 'DELIVERED', AppTheme.success),
      'DISPATCHED' => (isAr ? 'تم الشحن' : 'DISPATCHED', AppTheme.blue),
      'IN_TRANSIT' => (isAr ? 'في الطريق' : 'IN_TRANSIT', AppTheme.blue),
      'SCHEDULED' => (isAr ? 'مجدول' : 'SCHEDULED', AppTheme.warning),
      'PENDING' => (isAr ? 'معلق' : 'PENDING', AppTheme.warning),
      'CANCELLED' => (isAr ? 'ملغي' : 'CANCELLED', AppTheme.emergencyRed),
      _ => (code, AppTheme.textMuted),
    };
    return StatusPill(label: label, color: color);
  }

  String _roleTitle(bool isAr) => switch (_primaryRole) {
    'HOSPITAL' => isAr ? 'بوابة طاقم المستشفى' : 'Hospital Staff Portal',
    'PHARMACIST' => isAr ? 'بوابة الصيدلي والتوصيل' : 'Pharmacist Portal',
    'BLOOD_BANK_STAFF' => isAr ? 'بوابة بنك الدم' : 'Blood Bank Portal',
    'LAB_STAFF' => isAr ? 'بوابة المعمل الطبي' : 'Laboratory Portal',
    'DOCTOR' => isAr ? 'بوابة الطبيب والاستشارات' : 'Doctor Portal',
    _ => 'Smart Aid Portal',
  };

  String _roleSubtitle(bool isAr) => switch (_primaryRole) {
    'HOSPITAL' =>
      isAr
          ? 'تحديث سعة الطوارئ واستلام حالات الإسعاف فورياً مع ECC'
          : 'Real-time ER congestion control and EMS handover reception',
    'PHARMACIST' =>
      isAr
          ? 'إدارة طلبات المستلزمات الطبية وتتبع التوصيل المباشر'
          : 'Manage emergency supply orders and active medical deliveries',
    'BLOOD_BANK_STAFF' =>
      isAr
          ? 'متابعة مخزون فصائل الدم وتلبية الطلبات العاجلة'
          : 'Monitor blood group stock levels and fulfill urgent requests',
    'LAB_STAFF' =>
      isAr
          ? 'إدارة حجوزات التحاليل المخبرية ونشر النتائج المعتمدة'
          : 'Manage diagnostic appointments and publish verified results',
    'DOCTOR' =>
      isAr
          ? 'تأكيد مواعيد المرضى والاستشارات الطبية والتسليمات'
          : 'Confirm patient consultations and review medical handovers',
    _ => 'Smart Aid Connected Healthcare Operations',
  };

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.of(context).isArabic;
    return Scaffold(
      appBar: AppBar(
        title: Text(_roleTitle(isAr)),
        actions: [
          const LanguageToggleButton(isCompact: true),
          IconButton(
            tooltip: isAr ? 'تبديل الدور' : 'Switch Role',
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () => QuickRoleSwitcher.show(context),
          ),
          IconButton(
            tooltip: isAr ? 'تحديث' : 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
          IconButton(
            tooltip: isAr ? 'تسجيل الخروج' : 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: QaPageFrame(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    QaHeroCard(
                      eyebrow:
                          '${_isSandbox ? 'DEMO • ' : ''}ECC LIVE SYNC • $_primaryRole',
                      title: widget.session.displayName.isEmpty
                          ? _roleTitle(isAr)
                          : widget.session.displayName,
                      message: _roleSubtitle(isAr),
                      icon: _roleIcon,
                      color: _roleColor,
                      footer: Row(
                        children: [
                          const Icon(
                            Icons.alternate_email_rounded,
                            size: 15,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.session.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: QaCard(
                          color: AppTheme.softRed,
                          borderColor: AppTheme.emergencyRed.withValues(
                            alpha: 0.35,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.cloud_off_rounded,
                                color: AppTheme.emergencyRed,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AppTheme.emergencyRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ...switch (_primaryRole) {
                      'HOSPITAL' => _buildHospitalBody(isAr),
                      'PHARMACIST' => _buildPharmacistBody(isAr),
                      'BLOOD_BANK_STAFF' => _buildBloodBankBody(isAr),
                      'LAB_STAFF' => _buildLabBody(isAr),
                      _ => _buildDoctorBody(isAr),
                    },
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _buildHospitalBody(bool isAr) => [
    Row(
      children: [
        Expanded(
          child: QaMetricCard(
            icon: Icons.local_hospital_rounded,
            label: isAr ? 'المستشفيات المسجلة' : 'Hospitals',
            value: '${_hospitals.length}',
            color: AppTheme.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: QaMetricCard(
            icon: Icons.medical_information_rounded,
            label: isAr ? 'تسليمات معلقة' : 'Pending Handovers',
            value: '${_handovers.length}',
            color: _handovers.isEmpty ? AppTheme.success : AppTheme.warning,
          ),
        ),
      ],
    ),
    const SizedBox(height: 20),
    SectionHeader(
      title: isAr
          ? 'تحديث سعة وازدحام المستشفيات (${_hospitals.length})'
          : 'Hospital Capacity Control (${_hospitals.length})',
    ),
    const SizedBox(height: 10),
    for (final h in _hospitals)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: QaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: AppTheme.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h['name']?.toString() ?? 'Hospital',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAr
                              ? 'تحديث فوري لنسبة الازدحام في Smart ER'
                              : 'Updates Smart ER congestion score live',
                          style: const TextStyle(
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      foregroundColor: AppTheme.success,
                      side: BorderSide(
                        color: AppTheme.success.withValues(alpha: 0.5),
                      ),
                    ),
                    onPressed: () =>
                        _updateHospitalCapacity(h['id'].toString(), 25),
                    child: Text(isAr ? 'منخفض 25%' : 'Low 25%'),
                  ),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: () =>
                        _updateHospitalCapacity(h['id'].toString(), 60),
                    child: Text(isAr ? 'متوسط 60%' : 'Moderate 60%'),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      foregroundColor: AppTheme.emergencyRed,
                      side: BorderSide(
                        color: AppTheme.emergencyRed.withValues(alpha: 0.45),
                      ),
                    ),
                    onPressed: () =>
                        _updateHospitalCapacity(h['id'].toString(), 85),
                    child: Text(isAr ? 'مرتفع 85%' : 'High 85%'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    const SizedBox(height: 16),
    SectionHeader(
      title: isAr
          ? 'التسليمات الطبية الواردة من الإسعاف (${_handovers.length})'
          : 'Incoming EMS Handovers (${_handovers.length})',
    ),
    const SizedBox(height: 10),
    if (_handovers.isEmpty)
      QaCard(
        child: EmptyState(
          icon: Icons.check_circle_outline_rounded,
          title: isAr ? 'لا توجد تسليمات معلقة' : 'No Pending Handovers',
          message: isAr
              ? 'جميع التسليمات الطبية الواردة من فرق الإسعاف تم استلامها.'
              : 'All incoming EMS handovers have been acknowledged.',
        ),
      ),
    for (final ho in _handovers)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: QaCard(
          borderColor: AppTheme.warning.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ho['triageSummary']?.toString() ?? 'EMS Handover',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  StatusPill(
                    label: isAr ? 'بانتظار الاستلام' : 'PENDING',
                    color: AppTheme.warning,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if ((ho['vitalSigns']?.toString() ?? '').isNotEmpty)
                Text(
                  ho['vitalSigns'].toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.charcoal,
                  ),
                ),
              if ((ho['interventionsAdministered']?.toString() ?? '')
                  .isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  ho['interventionsAdministered'].toString(),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _acknowledgeHandover(ho['id'].toString()),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(isAr ? 'تأكيد استلام الحالة' : 'Acknowledge Handover'),
              ),
            ],
          ),
        ),
      ),
  ];

  List<Widget> _buildPharmacistBody(bool isAr) => [
    Row(
      children: [
        Expanded(
          child: QaMetricCard(
            icon: Icons.inventory_2_outlined,
            label: isAr ? 'طلبات معلقة' : 'Pending Orders',
            value: '${_orders.length}',
            color: const Color(0xFF059669),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: QaMetricCard(
            icon: Icons.local_shipping_outlined,
            label: isAr ? 'توصيلات نشطة' : 'Deliveries',
            value: '${_deliveries.length}',
            color: AppTheme.blue,
          ),
        ),
      ],
    ),
    const SizedBox(height: 20),
    SectionHeader(
      title: isAr
          ? 'طلبات الصيدلية المعلقة (${_orders.length})'
          : 'Pending Pharmacy Orders (${_orders.length})',
    ),
    const SizedBox(height: 10),
    if (_orders.isEmpty)
      QaCard(
        child: EmptyState(
          icon: Icons.local_pharmacy_outlined,
          title: isAr ? 'لا توجد طلبات معلقة' : 'No Pending Orders',
          message: isAr
              ? 'ستظهر طلبات المستلزمات الطبية الجديدة من تطبيق المواطن هنا فورياً.'
              : 'New citizen emergency supply orders will appear here live.',
        ),
      ),
    for (final o in _orders)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: QaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.local_pharmacy_rounded,
                      color: Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${_shortId(o['id'])} • Qty ${o['quantity'] ?? 1}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${o['deliveryAddress'] ?? 'Pickup'}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  _statusPill(o['orderStatus'], isAr),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      backgroundColor: const Color(0xFF059669),
                    ),
                    onPressed: () =>
                        _updateOrderStatus(o['id'].toString(), 'DISPATCHED'),
                    child: Text(isAr ? 'شحن' : 'Dispatch'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    const SizedBox(height: 16),
    SectionHeader(
      title: isAr
          ? 'التوصيلات الطبية النشطة (${_deliveries.length})'
          : 'Active Medical Deliveries (${_deliveries.length})',
    ),
    const SizedBox(height: 10),
    for (final d in _deliveries)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: QaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.sky,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: AppTheme.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d['trackingCode']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'ETA ${d['etaMinutes'] ?? '—'} min',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _statusPill(d['deliveryStatus'], isAr),
                  if (d['deliveryStatus'] != 'DELIVERED')
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                      ),
                      onPressed: () =>
                          _markDelivered(d['trackingCode'].toString()),
                      child: Text(isAr ? 'تم التوصيل' : 'Deliver'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
  ];

  List<Widget> _buildBloodBankBody(bool isAr) => [
    SectionHeader(
      title: isAr ? 'مخزون فصائل الدم المتاح' : 'Blood Group Inventory',
    ),
    const SizedBox(height: 10),
    Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final inv in _bloodInventory)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 112, maxWidth: 136),
            child: QaCard(
              padding: const EdgeInsets.all(12),
              color: AppTheme.softRed,
              borderColor: AppTheme.emergencyRed.withValues(alpha: 0.28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            inv['bloodGroup']?.toString() ?? '?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.emergencyRed,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.bloodtype_rounded,
                        size: 18,
                        color: AppTheme.emergencyRed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${inv['unitsAvailable']} ${isAr ? 'وحدة' : 'units'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7F1D1D),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
    const SizedBox(height: 20),
    SectionHeader(
      title: isAr
          ? 'طلبات الدم العاجلة (${_bloodRequests.length})'
          : 'Urgent Blood Requests (${_bloodRequests.length})',
    ),
    const SizedBox(height: 10),
    for (final r in _bloodRequests)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: QaCard(
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
                      color: AppTheme.softRed,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: AppTheme.emergencyRed.withValues(alpha: 0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          r['bloodGroup']?.toString() ?? '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.emergencyRed,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r['bloodGroup']} • ${r['unitsRequested']} ${isAr ? 'وحدة' : 'units'} (${r['urgency']})',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _statusPill(r['status'], isAr),
                            if (r['status'] == 'PENDING')
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 38),
                                  backgroundColor: AppTheme.emergencyRed,
                                ),
                                onPressed: () =>
                                    _fulfillBloodRequest(r['id'].toString()),
                                child: Text(isAr ? 'تنفيذ' : 'Fulfill'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
  ];

  List<Widget> _buildLabBody(bool isAr) => [
    SectionHeader(
      title: isAr
          ? 'حجوزات التحاليل المخبرية (${_labAppointments.length})'
          : 'Laboratory Appointments (${_labAppointments.length})',
    ),
    const SizedBox(height: 10),
    if (_labAppointments.isEmpty)
      QaCard(
        child: EmptyState(
          icon: Icons.science_outlined,
          title: isAr ? 'لا توجد حجوزات تحاليل بعد' : 'No Lab Appointments Yet',
          message: isAr
              ? 'ستظهر حجوزات التحاليل الواردة من المرضى هنا للمعالجة.'
              : 'Diagnostic bookings submitted by citizens will appear here.',
        ),
      ),
    for (final a in _labAppointments)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: QaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6D28D9).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.science_rounded,
                      color: Color(0xFF6D28D9),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lab #${_shortId(a['id'])}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          a['resultSummary']?.toString() ??
                              (isAr ? 'بانتظار النتيجة' : 'Pending result'),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _statusPill(a['status'], isAr),
                  if (a['status'] != 'COMPLETED' && a['status'] != 'CANCELLED')
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        backgroundColor: const Color(0xFF6D28D9),
                      ),
                      onPressed: () => _publishLabResult(a['id'].toString()),
                      child: Text(isAr ? 'نشر النتيجة' : 'Publish'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
  ];

  List<Widget> _buildDoctorBody(bool isAr) => [
    SectionHeader(
      title: isAr
          ? 'مواعيد المرضى والاستشارات (${_providerAppointments.length})'
          : 'Patient & Telemedicine Appointments (${_providerAppointments.length})',
    ),
    const SizedBox(height: 10),
    if (_providerAppointments.isEmpty)
      QaCard(
        child: EmptyState(
          icon: Icons.medical_services_outlined,
          title: isAr ? 'لا توجد مواعيد حالياً' : 'No Appointments Scheduled',
          message: isAr
              ? 'ستظهر حجوزات الاستشارات والمتابعة الطبية هنا فور إنشائها.'
              : 'New patient and telemedicine bookings will appear here live.',
        ),
      ),
    for (final p in _providerAppointments)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: QaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p['appointmentType'] ?? 'CONSULTATION'}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p['chiefComplaint']?.toString() ?? 'Consultation',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _statusPill(p['status'], isAr),
                  if (p['status'] == 'SCHEDULED')
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        backgroundColor: const Color(0xFF0F766E),
                      ),
                      onPressed: () => _confirmAppointment(p['id'].toString()),
                      child: Text(isAr ? 'تأكيد' : 'Confirm'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
  ];
}
