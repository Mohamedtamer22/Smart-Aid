import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import 'resource_controller.dart';

class NearbyResourcesPage extends ConsumerStatefulWidget {
  const NearbyResourcesPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<NearbyResourcesPage> createState() =>
      _NearbyResourcesPageState();
}

class _NearbyResourcesPageState extends ConsumerState<NearbyResourcesPage> {
  late int _selectedTab;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = l.isArabic;

    final hospitalsAsync = ref.watch(verifiedHospitalsProvider);
    final aedsAsync = ref.watch(verifiedAedsProvider);
    final ambulancesAsync = ref.watch(ambulancesProvider);

    final hospitalsCount = hospitalsAsync.value?.length ?? 0;
    final aedsCount = aedsAsync.value?.length ?? 0;
    final ambulancesCount = ambulancesAsync.value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.text('resources')),
        actions: [
          IconButton(
            tooltip: l.text('refresh'),
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(verifiedHospitalsProvider.notifier).refresh();
              ref.read(verifiedAedsProvider.notifier).refresh();
              ref.read(ambulancesProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: QaPageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            // Custom Horizontal Pill Tabs (No awkward text wrapping)
            _ResourcePillTabs(
              selectedTab: _selectedTab,
              onTabChanged: (index) {
                setState(() {
                  _selectedTab = index;
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              hospitalsCount: hospitalsCount,
              aedsCount: aedsCount,
              ambulancesCount: ambulancesCount,
              l: l,
            ),
            const SizedBox(height: 12),
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppTheme.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: isAr
                            ? (_selectedTab == 0
                                  ? 'ابحث عن مستشفى أو قسم طوارئ...'
                                  : _selectedTab == 1
                                  ? 'ابحث عن موقع جهاز الصدمات...'
                                  : 'ابحث عن سيارة إسعاف...')
                            : (_selectedTab == 0
                                  ? 'Search hospitals or ER...'
                                  : _selectedTab == 1
                                  ? 'Search AED locations...'
                                  : 'Search ambulance fleet...'),
                        hintStyle: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.textMuted,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Verified Data Info Banner
            QaCard(
              color: AppTheme.sky,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: AppTheme.blue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.text('resourceDataNotice'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Active Tab Content
            Expanded(
              child: _selectedTab == 0
                  ? _HospitalsList(l: l, searchQuery: _searchQuery)
                  : _selectedTab == 1
                  ? _AedsList(l: l, searchQuery: _searchQuery)
                  : _AmbulancesList(l: l, searchQuery: _searchQuery),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourcePillTabs extends StatelessWidget {
  const _ResourcePillTabs({
    required this.selectedTab,
    required this.onTabChanged,
    required this.hospitalsCount,
    required this.aedsCount,
    required this.ambulancesCount,
    required this.l,
  });

  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final int hospitalsCount;
  final int aedsCount;
  final int ambulancesCount;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildPill(
            index: 0,
            icon: Icons.local_hospital_rounded,
            label: l.text('hospitals'),
            count: hospitalsCount,
          ),
          const SizedBox(width: 8),
          _buildPill(
            index: 1,
            icon: Icons.bolt_rounded,
            label: l.isArabic ? 'أجهزة الصدمات (AED)' : 'AED Devices',
            count: aedsCount,
          ),
          const SizedBox(width: 8),
          _buildPill(
            index: 2,
            icon: Icons.emergency_rounded,
            label: l.text('ambulances'),
            count: ambulancesCount,
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required int index,
    required IconData icon,
    required String label,
    required int count,
  }) {
    final isSelected = selectedTab == index;
    return InkWell(
      onTap: () => onTabChanged(index),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.blue : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.blue : AppTheme.border,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.blue.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.navy,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppTheme.sky,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class _HospitalsList extends ConsumerWidget {
  const _HospitalsList({required this.l, required this.searchQuery});
  final AppLocalizations l;
  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(verifiedHospitalsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => PageFailure(
            title: l.text('hospitals'),
            message: l.text('resourcesLoadFailed'),
            retryLabel: l.text('retry'),
            onRetry: () =>
                ref.read(verifiedHospitalsProvider.notifier).refresh(),
          ),
          data: (hospitals) {
            final filtered = searchQuery.isEmpty
                ? hospitals
                : hospitals
                      .where(
                        (h) => h.name.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();

            if (filtered.isEmpty) {
              return EmptyState(
                icon: Icons.location_searching_outlined,
                title: l.text('resourcesEmptyTitle'),
                message: searchQuery.isEmpty
                    ? l.text('resourcesEmptyMessage')
                    : (l.isArabic
                          ? 'لا توجد مستشفيات تطابق بحثك.'
                          : 'No hospitals match your search.'),
              );
            }

            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(verifiedHospitalsProvider.notifier).refresh(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final hospital = filtered[index];
                  final (headline, subtitle) = _parseBilingualName(
                    hospital.name,
                    l.isArabic,
                  );
                  final locationDesc = _getHospitalLocation(
                    hospital.id,
                    l.isArabic,
                  );

                  return _ResourceCard(
                    icon: Icons.local_hospital_rounded,
                    iconColor: AppTheme.blue,
                    title: headline,
                    subTitle: subtitle,
                    location: locationDesc,
                    coordinates: l.format('hospitalCoordinates', {
                      'latitude': hospital.latitude.toStringAsFixed(4),
                      'longitude': hospital.longitude.toStringAsFixed(4),
                    }),
                    statusBadge: l.text('verified'),
                    badgeColor: AppTheme.success,
                    extraTag: l.isArabic ? 'طوارئ 24/7' : '24/7 ER',
                    onCallPressed: () => _showEmergencyCallModal(
                      context: context,
                      title: headline,
                      number: '137',
                      serviceName: l.isArabic
                          ? 'طوارئ وزارة الصحة والرعاية العاجلة'
                          : 'MOH Emergency HotLine',
                      isArabic: l.isArabic,
                    ),
                    onDirectionsPressed: () => _showDirectionsModal(
                      context: context,
                      title: headline,
                      location: locationDesc,
                      latitude: hospital.latitude,
                      longitude: hospital.longitude,
                      isArabic: l.isArabic,
                    ),
                  );
                },
              ),
            );
          },
        );
  }

  String _getHospitalLocation(String id, bool isAr) {
    switch (id) {
      case 'hosp-01':
        return isAr
            ? 'وسط البلد - كورنيش النيل، القاهرة'
            : 'Downtown - Corniche, Cairo';
      case 'hosp-02':
        return isAr
            ? 'كورنيش النيل - المعادي، القاهرة'
            : 'Corniche El Nile - Maadi, Cairo';
      case 'hosp-03':
        return isAr
            ? 'مدينة 6 أكتوبر - محور 26 يوليو، الجيزة'
            : '6th of October City, Giza';
      default:
        return isAr ? 'محافظة القاهرة الكبرى' : 'Greater Cairo';
    }
  }
}

class _AedsList extends ConsumerWidget {
  const _AedsList({required this.l, required this.searchQuery});
  final AppLocalizations l;
  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(verifiedAedsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => PageFailure(
            title: l.text('aed'),
            message: l.text('resourcesLoadFailed'),
            retryLabel: l.text('retry'),
            onRetry: () => ref.read(verifiedAedsProvider.notifier).refresh(),
          ),
          data: (aeds) {
            final filtered = searchQuery.isEmpty
                ? aeds
                : aeds
                      .where(
                        (a) => a.label.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();

            if (filtered.isEmpty) {
              return EmptyState(
                icon: Icons.bolt_outlined,
                title: l.text('resourcesEmptyTitle'),
                message: searchQuery.isEmpty
                    ? l.text('resourcesEmptyMessage')
                    : (l.isArabic
                          ? 'لا توجد أجهزة تطابق بحثك.'
                          : 'No AED devices match your search.'),
              );
            }

            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(verifiedAedsProvider.notifier).refresh(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final aed = filtered[index];
                  final (headline, subtitle) = _parseBilingualName(
                    aed.label,
                    l.isArabic,
                  );
                  final isAvailable = aed.availabilityStatus == 'AVAILABLE';

                  return _ResourceCard(
                    icon: Icons.bolt_rounded,
                    iconColor: Colors.amber.shade800,
                    title: headline,
                    subTitle: subtitle,
                    location: l.isArabic
                        ? 'متاح في الأماكن العامة المعتمدة'
                        : 'Public Verified Access Hub',
                    coordinates: l.format('hospitalCoordinates', {
                      'latitude': aed.latitude.toStringAsFixed(4),
                      'longitude': aed.longitude.toStringAsFixed(4),
                    }),
                    statusBadge: isAvailable
                        ? (l.isArabic ? 'جاهز للاستخدام' : 'Available')
                        : aed.availabilityStatus,
                    badgeColor: isAvailable
                        ? AppTheme.success
                        : AppTheme.warning,
                    extraTag: 'AED Rapid Defib',
                    onCallPressed: () => _showEmergencyCallModal(
                      context: context,
                      title: headline,
                      number: '123',
                      serviceName: l.isArabic
                          ? 'طلب مساعدة طارئة من الإسعاف'
                          : 'Request Ambulance AED Support',
                      isArabic: l.isArabic,
                    ),
                    onDirectionsPressed: () => _showDirectionsModal(
                      context: context,
                      title: headline,
                      location: l.isArabic
                          ? 'موقع جهاز إزالة الرجفان'
                          : 'AED Location',
                      latitude: aed.latitude,
                      longitude: aed.longitude,
                      isArabic: l.isArabic,
                    ),
                  );
                },
              ),
            );
          },
        );
  }
}

class _AmbulancesList extends ConsumerWidget {
  const _AmbulancesList({required this.l, required this.searchQuery});
  final AppLocalizations l;
  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(ambulancesProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => PageFailure(
            title: l.text('ambulances'),
            message: l.text('resourcesLoadFailed'),
            retryLabel: l.text('retry'),
            onRetry: () => ref.read(ambulancesProvider.notifier).refresh(),
          ),
          data: (ambulances) {
            final filtered = searchQuery.isEmpty
                ? ambulances
                : ambulances
                      .where(
                        (amb) => amb.callSign.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();

            if (filtered.isEmpty) {
              return EmptyState(
                icon: Icons.airport_shuttle_outlined,
                title: l.text('resourcesEmptyTitle'),
                message: searchQuery.isEmpty
                    ? l.text('resourcesEmptyMessage')
                    : (l.isArabic
                          ? 'لا توجد مركبات تطابق بحثك.'
                          : 'No ambulances match your search.'),
              );
            }

            return RefreshIndicator(
              onRefresh: () => ref.read(ambulancesProvider.notifier).refresh(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final amb = filtered[index];
                  final isAvailable = amb.status == 'AVAILABLE';
                  final (headline, subtitle) = _parseBilingualName(
                    amb.callSign,
                    l.isArabic,
                  );

                  return _ResourceCard(
                    icon: Icons.emergency_rounded,
                    iconColor: isAvailable ? AppTheme.success : AppTheme.blue,
                    title: headline,
                    subTitle: subtitle,
                    location: amb.latitude != null && amb.longitude != null
                        ? (l.isArabic
                              ? 'نقطة تمركز نشطة بالقطاع'
                              : 'Active Sector Station')
                        : (l.isArabic
                              ? 'أسطول الإسعاف والتدخل السريع'
                              : 'Emergency Medical Fleet'),
                    coordinates: amb.latitude != null && amb.longitude != null
                        ? l.format('hospitalCoordinates', {
                            'latitude': amb.latitude!.toStringAsFixed(4),
                            'longitude': amb.longitude!.toStringAsFixed(4),
                          })
                        : 'GPS Monitored',
                    statusBadge: isAvailable
                        ? (l.isArabic ? 'متاحة للطلب' : 'Available')
                        : (amb.status == 'DISPATCHED' ||
                                  amb.status == 'EN_ROUTE'
                              ? (l.isArabic ? 'في مهمة' : 'En Route')
                              : amb.status),
                    badgeColor: isAvailable
                        ? AppTheme.success
                        : (amb.status == 'DISPATCHED' ||
                                  amb.status == 'EN_ROUTE'
                              ? AppTheme.warning
                              : AppTheme.blue),
                    extraTag: 'MOH Ambulance 123',
                    onCallPressed: () => _showEmergencyCallModal(
                      context: context,
                      title: headline,
                      number: '123',
                      serviceName: l.isArabic
                          ? 'هيئة الإسعاف المصرية (الخط الساخن)'
                          : 'Egyptian Ambulance Authority',
                      isArabic: l.isArabic,
                    ),
                    onDirectionsPressed: () => _showDirectionsModal(
                      context: context,
                      title: headline,
                      location: l.isArabic
                          ? 'نقطة تمركز الإسعاف'
                          : 'Ambulance Unit Location',
                      latitude: amb.latitude ?? 30.0450,
                      longitude: amb.longitude ?? 31.2360,
                      isArabic: l.isArabic,
                    ),
                  );
                },
              ),
            );
          },
        );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subTitle,
    required this.location,
    required this.coordinates,
    required this.statusBadge,
    required this.badgeColor,
    this.extraTag,
    required this.onCallPressed,
    required this.onDirectionsPressed,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subTitle;
  final String location;
  final String coordinates;
  final String statusBadge;
  final Color badgeColor;
  final String? extraTag;
  final VoidCallback onCallPressed;
  final VoidCallback onDirectionsPressed;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return QaCard(
      padding: const EdgeInsets.all(14),
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
                  color: iconColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (subTitle != null && subTitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subTitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: statusBadge, color: badgeColor),
            ],
          ),
          const SizedBox(height: 10),
          // Location & Coordinates Info
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppTheme.blue,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (extraTag != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.sky,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    extraTag!,
                    style: const TextStyle(
                      color: AppTheme.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              coordinates,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Quick Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDirectionsPressed,
                  icon: const Icon(Icons.navigation_outlined, size: 16),
                  label: Text(
                    isAr ? 'الاتجاهات' : 'Directions',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCallPressed,
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                  label: Text(
                    isAr ? 'اتصال طوارئ' : 'Emergency Call',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.blue,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Bilingual title parser: splits "Cairo Emergency Hospital (قصر العيني للطوارئ)"
(String headline, String? subtitle) _parseBilingualName(
  String raw,
  bool isArabic,
) {
  final match = RegExp(r'^(.*?)\s*\((.*?)\)$').firstMatch(raw.trim());
  if (match != null) {
    final part1 = match.group(1)!.trim();
    final part2 = match.group(2)!.trim();
    if (isArabic) {
      return (part2, part1);
    } else {
      return (part1, part2);
    }
  }
  return (raw, null);
}

void _showEmergencyCallModal({
  required BuildContext context,
  required String title,
  required String number,
  required String serviceName,
  required bool isArabic,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.sky,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.phone_in_talk_rounded,
                    color: AppTheme.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic
                            ? 'اتصال الطوارئ المباشر'
                            : 'Emergency Hotline Call',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.sky,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_rounded, color: AppTheme.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isArabic
                              ? 'الرقم الموحد للطوارئ:'
                              : 'Direct Hotline:',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isArabic
                          ? 'جاري بدء الاتصال برقم الطوارئ $number ($title)...'
                          : 'Initiating emergency call to $number ($title)...',
                    ),
                    backgroundColor: AppTheme.blue,
                  ),
                );
              },
              icon: const Icon(Icons.call_rounded),
              label: Text(
                isArabic ? 'اتصال الآن ($number)' : 'Call Now ($number)',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                isArabic ? 'إلغاء' : 'Cancel',
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showDirectionsModal({
  required BuildContext context,
  required String title,
  required String location,
  required double latitude,
  required double longitude,
  required bool isArabic,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.sky,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: AppTheme.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'الاتجاهات الملاحية' : 'Navigation & Route',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.sky,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        size: 18,
                        color: AppTheme.blue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'GPS: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isArabic
                          ? 'جاري إرسال الإحداثيات لخريطة الاستجابة السريعة...'
                          : 'Sending destination coordinates to response map...',
                    ),
                    backgroundColor: AppTheme.blue,
                  ),
                );
              },
              icon: const Icon(Icons.map_rounded),
              label: Text(
                isArabic ? 'بدء التوجيه الملاحي' : 'Start Navigation',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                isArabic ? 'إغلاق' : 'Close',
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
