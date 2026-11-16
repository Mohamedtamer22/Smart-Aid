import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import 'admin_controller.dart';
import 'admin_repository.dart';

class AdminVolunteersPage extends ConsumerStatefulWidget {
  const AdminVolunteersPage({super.key});

  @override
  ConsumerState<AdminVolunteersPage> createState() =>
      _AdminVolunteersPageState();
}

class _AdminVolunteersPageState extends ConsumerState<AdminVolunteersPage> {
  String _query = '';
  String _filter = 'all'; // 'all', 'pending', 'verified'
  bool _working = false;

  Future<void> _verifyVolunteer(VolunteerSummary volunteer) async {
    final l = AppLocalizations.of(context);
    setState(() => _working = true);
    try {
      await ref.read(adminRepositoryProvider).verifyVolunteer(volunteer.userId);
      ref.invalidate(adminVolunteersProvider);
      ref.invalidate(adminOverviewProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.text('verifiedSuccess')),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.text('error')),
            backgroundColor: AppTheme.emergencyRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final volunteersAsync = ref.watch(adminVolunteersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.text('volunteerApprovals')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminVolunteersProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l.text('search'),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) =>
                      setState(() => _query = val.toLowerCase()),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(l.text('all')),
                        selected: _filter == 'all',
                        onSelected: (_) => setState(() => _filter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(l.text('pendingVerifications')),
                        selected: _filter == 'pending',
                        onSelected: (_) => setState(() => _filter = 'pending'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(l.text('verifiedSuccess')),
                        selected: _filter == 'verified',
                        onSelected: (_) => setState(() => _filter = 'verified'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_working) const LinearProgressIndicator(),

          // Volunteer list
          Expanded(
            child: volunteersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppTheme.emergencyRed,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.text('error'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(adminVolunteersProvider),
                        child: Text(l.text('retry')),
                      ),
                    ],
                  ),
                ),
              ),
              data: (volunteers) {
                final filtered = volunteers.where((v) {
                  final matchesQuery =
                      _query.isEmpty ||
                      v.displayName.toLowerCase().contains(_query) ||
                      v.email.toLowerCase().contains(_query);
                  final matchesFilter =
                      _filter == 'all' ||
                      (_filter == 'pending' && !v.verified) ||
                      (_filter == 'verified' && v.verified);
                  return matchesQuery && matchesFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_search,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l.text('noNotificationsTitle'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final volunteer = filtered[index];
                    return _VolunteerCard(
                      volunteer: volunteer,
                      onVerify: () => _verifyVolunteer(volunteer),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VolunteerCard extends StatelessWidget {
  const _VolunteerCard({required this.volunteer, required this.onVerify});

  final VolunteerSummary volunteer;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: volunteer.verified
                    ? AppTheme.success.withValues(alpha: 0.15)
                    : AppTheme.warning.withValues(alpha: 0.15),
                child: Icon(
                  volunteer.verified ? Icons.verified : Icons.pending_actions,
                  color: volunteer.verified
                      ? AppTheme.success
                      : AppTheme.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      volunteer.displayName.isNotEmpty
                          ? volunteer.displayName
                          : volunteer.email,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      volunteer.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Availability Chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: volunteer.available
                      ? AppTheme.success.withValues(alpha: 0.15)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: volunteer.available
                            ? AppTheme.success
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      volunteer.available
                          ? l.text('availableNow')
                          : l.text('standbyStatus'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: volunteer.available
                            ? AppTheme.success
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                volunteer.verified ? Icons.check_circle : Icons.warning_amber,
                size: 16,
                color: volunteer.verified ? AppTheme.success : AppTheme.warning,
              ),
              const SizedBox(width: 6),
              Text(
                volunteer.verified
                    ? l.text('verifiedSuccess')
                    : l.text('pendingVerifications'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: volunteer.verified
                      ? AppTheme.success
                      : AppTheme.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (!volunteer.verified)
                FilledButton.icon(
                  onPressed: onVerify,
                  icon: const Icon(Icons.shield_outlined, size: 16),
                  label: Text(l.text('verifyVolunteer')),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppTheme.oceanBlue,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
