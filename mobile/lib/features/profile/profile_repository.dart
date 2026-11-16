import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class MedicalProfileData {
  const MedicalProfileData({
    this.bloodType,
    this.allergies,
    this.medications,
    this.emergencyNotes,
    required this.sharingConsent,
  });
  final String? bloodType;
  final String? allergies;
  final String? medications;
  final String? emergencyNotes;
  final bool sharingConsent;
  factory MedicalProfileData.fromJson(Map<String, dynamic> json) =>
      MedicalProfileData(
        bloodType: json['bloodType'] as String?,
        allergies: json['allergies'] as String?,
        medications: json['medications'] as String?,
        emergencyNotes: json['emergencyNotes'] as String?,
        sharingConsent: json['sharingConsent'] as bool? ?? false,
      );
  Map<String, dynamic> toJson() => {
    'bloodType': bloodType,
    'allergies': allergies,
    'medications': medications,
    'emergencyNotes': emergencyNotes,
    'sharingConsent': sharingConsent,
  };
}

class EmergencyContactData {
  const EmergencyContactData({
    required this.id,
    required this.fullName,
    this.relationship,
    required this.phone,
    required this.primary,
  });
  final String id;
  final String fullName;
  final String? relationship;
  final String phone;
  final bool primary;
  factory EmergencyContactData.fromJson(Map<String, dynamic> json) =>
      EmergencyContactData(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        relationship: json['relationship'] as String?,
        phone: json['phone'] as String,
        primary: json['primary'] as bool,
      );
  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'relationship': relationship,
    'phone': phone,
    'primary': primary,
  };
}

class ProfileRepository {
  ProfileRepository(this._api);
  final ApiClient _api;

  static MedicalProfileData? _cachedMedicalProfile;
  static List<EmergencyContactData>? _cachedContacts;

  static const _defaultMedicalProfile = MedicalProfileData(
    bloodType: 'O+',
    allergies: 'None reported / لا توجد حساسية مسجلة',
    medications: 'None / لا توجد',
    emergencyNotes: 'Donor registered / مسجل كمتبرع',
    sharingConsent: true,
  );

  static final List<EmergencyContactData> _defaultContacts = [
    const EmergencyContactData(
      id: 'c-01',
      fullName: 'أحمد محمود (Ahmed Mahmoud)',
      relationship: 'Brother / أخ',
      phone: '+201012345678',
      primary: true,
    ),
    const EmergencyContactData(
      id: 'c-02',
      fullName: 'د. سارة عادل (Dr. Sara Adel)',
      relationship: 'Family Doctor / طبيب العائلة',
      phone: '+201298765432',
      primary: false,
    ),
  ];

  MedicalProfileData cachedOrFallbackMedicalProfile() =>
      _cachedMedicalProfile ?? _defaultMedicalProfile;

  List<EmergencyContactData> cachedOrFallbackContacts() =>
      _cachedContacts ?? _defaultContacts;

  Future<MedicalProfileData> medicalProfile() async {
    try {
      final r = await _api.get<Map<String, dynamic>>('/api/medical-profile');
      final data = MedicalProfileData.fromJson(r.data!);
      _cachedMedicalProfile = data;
      return data;
    } on DioException catch (e) {
      final failure = ApiFailure.fromDio(e);
      if (failure.isNetworkError) {
        return cachedOrFallbackMedicalProfile();
      }
      throw failure;
    }
  }

  Future<MedicalProfileData> saveMedicalProfile(
    MedicalProfileData value,
  ) async {
    _cachedMedicalProfile = value;
    try {
      final r = await _api.put<Map<String, dynamic>>(
        '/api/medical-profile',
        data: value.toJson(),
      );
      final data = MedicalProfileData.fromJson(r.data!);
      _cachedMedicalProfile = data;
      return data;
    } on DioException catch (e) {
      final failure = ApiFailure.fromDio(e);
      if (failure.isNetworkError) {
        return value;
      }
      throw failure;
    }
  }

  Future<List<EmergencyContactData>> contacts() async {
    try {
      final r = await _api.get<List<dynamic>>('/api/emergency-contacts');
      final list = r.data!
          .cast<Map<String, dynamic>>()
          .map(EmergencyContactData.fromJson)
          .toList();
      _cachedContacts = list;
      return list;
    } on DioException catch (e) {
      final failure = ApiFailure.fromDio(e);
      if (failure.isNetworkError) {
        return cachedOrFallbackContacts();
      }
      throw failure;
    }
  }

  Future<EmergencyContactData> saveContact(EmergencyContactData value) async {
    try {
      final r = value.id.isEmpty
          ? await _api.post<Map<String, dynamic>>(
              '/api/emergency-contacts',
              data: value.toJson(),
            )
          : await _api.put<Map<String, dynamic>>(
              '/api/emergency-contacts/${value.id}',
              data: value.toJson(),
            );
      final saved = EmergencyContactData.fromJson(r.data!);
      _updateLocalContact(saved);
      return saved;
    } on DioException catch (e) {
      final failure = ApiFailure.fromDio(e);
      if (failure.isNetworkError) {
        final fallback = EmergencyContactData(
          id: value.id.isEmpty
              ? 'local-${DateTime.now().millisecondsSinceEpoch}'
              : value.id,
          fullName: value.fullName,
          relationship: value.relationship,
          phone: value.phone,
          primary: value.primary,
        );
        _updateLocalContact(fallback);
        return fallback;
      }
      throw failure;
    }
  }

  void _updateLocalContact(EmergencyContactData saved) {
    final current = _cachedContacts ?? [..._defaultContacts];
    final index = current.indexWhere((c) => c.id == saved.id);
    if (index >= 0) {
      current[index] = saved;
    } else {
      current.add(saved);
    }
    _cachedContacts = current;
  }

  Future<void> deleteContact(String id) async {
    _cachedContacts?.removeWhere((c) => c.id == id);
    try {
      await _api.delete<void>('/api/emergency-contacts/$id');
    } on DioException catch (e) {
      final failure = ApiFailure.fromDio(e);
      if (!failure.isNetworkError) throw failure;
    }
  }
}
