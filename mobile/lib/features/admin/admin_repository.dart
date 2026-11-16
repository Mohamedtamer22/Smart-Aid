import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class SystemOverview {
  const SystemOverview({
    required this.totalUsers,
    required this.totalVolunteers,
    required this.pendingVolunteerVerifications,
    required this.activeIncidents,
    required this.totalHospitals,
    required this.totalAmbulances,
    required this.totalAeds,
  });

  final int totalUsers;
  final int totalVolunteers;
  final int pendingVolunteerVerifications;
  final int activeIncidents;
  final int totalHospitals;
  final int totalAmbulances;
  final int totalAeds;

  factory SystemOverview.fromJson(Map<String, dynamic> json) => SystemOverview(
    totalUsers: json['totalUsers'] as int? ?? 0,
    totalVolunteers: json['totalVolunteers'] as int? ?? 0,
    pendingVolunteerVerifications:
        json['pendingVolunteerVerifications'] as int? ?? 0,
    activeIncidents: json['activeIncidents'] as int? ?? 0,
    totalHospitals: json['totalHospitals'] as int? ?? 0,
    totalAmbulances: json['totalAmbulances'] as int? ?? 0,
    totalAeds: json['totalAeds'] as int? ?? 0,
  );
}

class UserSummary {
  const UserSummary({
    required this.id,
    required this.email,
    required this.displayName,
    required this.enabled,
    required this.roles,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final bool enabled;
  final List<String> roles;
  final DateTime createdAt;

  factory UserSummary.fromJson(Map<String, dynamic> json) => UserSummary(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String? ?? '',
    enabled: json['enabled'] as bool? ?? true,
    roles: (json['roles'] as List<dynamic>? ?? []).cast<String>(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class VolunteerSummary {
  const VolunteerSummary({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.verified,
    required this.available,
    this.latitude,
    this.longitude,
    required this.updatedAt,
  });

  final String userId;
  final String email;
  final String displayName;
  final bool verified;
  final bool available;
  final double? latitude;
  final double? longitude;
  final DateTime updatedAt;

  factory VolunteerSummary.fromJson(Map<String, dynamic> json) =>
      VolunteerSummary(
        userId: json['userId'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String? ?? '',
        verified: json['verified'] as bool? ?? false,
        available: json['available'] as bool? ?? false,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    this.actorId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.traceId,
    required this.createdAt,
  });

  final String id;
  final String? actorId;
  final String action;
  final String entityType;
  final String? entityId;
  final String? traceId;
  final DateTime createdAt;

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
    id: json['id'] as String,
    actorId: json['actorId'] as String?,
    action: json['action'] as String,
    entityType: json['entityType'] as String,
    entityId: json['entityId'] as String?,
    traceId: json['traceId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class AdminRepository {
  AdminRepository(this._api);
  final ApiClient _api;

  static const _demoOverview = SystemOverview(
    totalUsers: 142,
    totalVolunteers: 28,
    pendingVolunteerVerifications: 2,
    activeIncidents: 3,
    totalHospitals: 8,
    totalAmbulances: 12,
    totalAeds: 24,
  );

  static final List<UserSummary> _demoUsers = [
    UserSummary(
      id: 'USR-001',
      email: 'admin@smartaid.local',
      displayName: 'مدير المنظومة (Admin)',
      enabled: true,
      roles: ['ADMIN', 'CITIZEN', 'VOLUNTEER', 'EMS'],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    UserSummary(
      id: 'USR-002',
      email: 'volunteer.cairo@smartaid.local',
      displayName: 'عمر خالد (Omar Khaled)',
      enabled: true,
      roles: ['VOLUNTEER', 'CITIZEN'],
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    UserSummary(
      id: 'USR-003',
      email: 'ems.central@smartaid.local',
      displayName: 'فريق الإسعاف المركزي (EMS Cairo)',
      enabled: true,
      roles: ['EMS'],
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    UserSummary(
      id: 'USR-004',
      email: 'citizen.salma@smartaid.local',
      displayName: 'سلمى إبراهيم (Salma Ibrahim)',
      enabled: true,
      roles: ['CITIZEN'],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static final List<VolunteerSummary> _demoVolunteers = [
    VolunteerSummary(
      userId: 'USR-002',
      email: 'volunteer.cairo@smartaid.local',
      displayName: 'عمر خالد (Omar Khaled)',
      verified: true,
      available: true,
      latitude: 30.0444,
      longitude: 31.2357,
      updatedAt: DateTime.now(),
    ),
    VolunteerSummary(
      userId: 'USR-005',
      email: 'volunteer.nour@smartaid.local',
      displayName: 'نور الدين حسن (Nour Hassan)',
      verified: true,
      available: false,
      latitude: 30.0500,
      longitude: 31.2400,
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    VolunteerSummary(
      userId: 'USR-006',
      email: 'volunteer.youssef@smartaid.local',
      displayName: 'يوسف مصطفى (Youssef Mostafa)',
      verified: false,
      available: true,
      latitude: 30.0350,
      longitude: 31.2200,
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];

  static final List<AuditLogEntry> _demoAuditLogs = [
    AuditLogEntry(
      id: 'AUD-001',
      actorId: 'USR-001',
      action: 'SYSTEM_BOOT',
      entityType: 'PLATFORM',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AuditLogEntry(
      id: 'AUD-002',
      actorId: 'USR-002',
      action: 'VOLUNTEER_AVAILABILITY_ON',
      entityType: 'VOLUNTEER',
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    AuditLogEntry(
      id: 'AUD-003',
      actorId: 'USR-003',
      action: 'AMBULANCE_DISPATCH',
      entityType: 'INCIDENT',
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
  ];

  Future<SystemOverview> getOverview() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/admin/overview',
      );
      if (response.data == null) return _demoOverview;
      return SystemOverview.fromJson(response.data!);
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return _demoOverview;
      }
      throw failure;
    }
  }

  Future<List<UserSummary>> listUsers() async {
    try {
      final response = await _api.get<List<dynamic>>('/api/admin/users');
      if (response.data == null) return const [];
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(UserSummary.fromJson)
          .toList();
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return _demoUsers;
      }
      throw failure;
    }
  }

  Future<UserSummary> updateUserRoles(String userId, List<String> roles) async {
    try {
      final response = await _api.patch<Map<String, dynamic>>(
        '/api/admin/users/$userId/roles',
        data: {'roles': roles},
      );
      return UserSummary.fromJson(response.data!);
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        final user = _demoUsers.firstWhere(
          (u) => u.id == userId,
          orElse: () => _demoUsers.first,
        );
        return UserSummary(
          id: user.id,
          email: user.email,
          displayName: user.displayName,
          enabled: user.enabled,
          roles: roles,
          createdAt: user.createdAt,
        );
      }
      throw failure;
    }
  }

  Future<UserSummary> updateUserStatus(String userId, bool enabled) async {
    try {
      final response = await _api.patch<Map<String, dynamic>>(
        '/api/admin/users/$userId/status',
        data: {'enabled': enabled},
      );
      return UserSummary.fromJson(response.data!);
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        final user = _demoUsers.firstWhere(
          (u) => u.id == userId,
          orElse: () => _demoUsers.first,
        );
        return UserSummary(
          id: user.id,
          email: user.email,
          displayName: user.displayName,
          enabled: enabled,
          roles: user.roles,
          createdAt: user.createdAt,
        );
      }
      throw failure;
    }
  }

  Future<List<VolunteerSummary>> listVolunteers() async {
    try {
      final response = await _api.get<List<dynamic>>('/api/admin/volunteers');
      if (response.data == null) return const [];
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(VolunteerSummary.fromJson)
          .toList();
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return _demoVolunteers;
      }
      throw failure;
    }
  }

  Future<void> verifyVolunteer(String userId) async {
    try {
      await _api.post<dynamic>('/api/admin/volunteers/$userId/verify');
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        final index = _demoVolunteers.indexWhere((v) => v.userId == userId);
        if (index >= 0) {
          final v = _demoVolunteers[index];
          _demoVolunteers[index] = VolunteerSummary(
            userId: v.userId,
            email: v.email,
            displayName: v.displayName,
            verified: true,
            available: v.available,
            latitude: v.latitude,
            longitude: v.longitude,
            updatedAt: DateTime.now(),
          );
        }
        return;
      }
      throw failure;
    }
  }

  Future<List<AuditLogEntry>> listAuditLogs() async {
    try {
      final response = await _api.get<List<dynamic>>('/api/admin/audit-logs');
      if (response.data == null) return const [];
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(AuditLogEntry.fromJson)
          .toList();
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return _demoAuditLogs;
      }
      throw failure;
    }
  }
}
