import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import 'admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.read(apiClientProvider)),
);

final adminOverviewProvider = FutureProvider<SystemOverview>(
  (ref) => ref.read(adminRepositoryProvider).getOverview(),
);

final adminUsersProvider = FutureProvider<List<UserSummary>>(
  (ref) => ref.read(adminRepositoryProvider).listUsers(),
);

final adminVolunteersProvider = FutureProvider<List<VolunteerSummary>>(
  (ref) => ref.read(adminRepositoryProvider).listVolunteers(),
);

final adminAuditLogsProvider = FutureProvider<List<AuditLogEntry>>(
  (ref) => ref.read(adminRepositoryProvider).listAuditLogs(),
);
