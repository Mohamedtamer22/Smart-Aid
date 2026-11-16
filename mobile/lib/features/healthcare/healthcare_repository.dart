import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

class PharmacyItem {
  const PharmacyItem({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.openingHours,
    required this.emergencySuppliesAvailable,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final String openingHours;
  final bool emergencySuppliesAvailable;

  factory PharmacyItem.fromJson(Map<String, dynamic> json) => PharmacyItem(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String? ?? 'Pharmacy',
    address: json['address'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    openingHours: json['openingHours'] as String? ?? '24/7',
    emergencySuppliesAvailable:
        json['emergencySuppliesAvailable'] as bool? ?? true,
  );
}

class BloodBankItem {
  const BloodBankItem({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
  });

  final String id;
  final String name;
  final String address;
  final String phone;

  factory BloodBankItem.fromJson(Map<String, dynamic> json) => BloodBankItem(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String? ?? 'Blood Bank',
    address: json['address'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
  );
}

class LaboratoryItem {
  const LaboratoryItem({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
  });

  final String id;
  final String name;
  final String address;
  final String phone;

  factory LaboratoryItem.fromJson(Map<String, dynamic> json) => LaboratoryItem(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String? ?? 'Laboratory',
    address: json['address'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
  );
}

class MedicalProviderItem {
  const MedicalProviderItem({
    required this.id,
    required this.name,
    required this.providerType,
    required this.specialty,
    required this.address,
    required this.telemedicineEnabled,
  });

  final String id;
  final String name;
  final String providerType;
  final String specialty;
  final String address;
  final bool telemedicineEnabled;

  factory MedicalProviderItem.fromJson(Map<String, dynamic> json) =>
      MedicalProviderItem(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? 'Provider',
        providerType: json['providerType'] as String? ?? 'CLINIC',
        specialty: json['specialty'] as String? ?? 'General',
        address: json['address'] as String? ?? '',
        telemedicineEnabled: json['telemedicineEnabled'] as bool? ?? false,
      );
}

class HealthcareRepository {
  HealthcareRepository(this._api);
  final ApiClient _api;

  Future<List<PharmacyItem>> listPharmacies({
    bool emergencySuppliesOnly = false,
  }) async {
    final res = await _api.get<List<dynamic>>(
      '/api/pharmacies?emergencySuppliesOnly=$emergencySuppliesOnly',
    );
    return (res.data ?? const [])
        .map((e) => PharmacyItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<BloodBankItem>> listBloodBanks() async {
    final res = await _api.get<List<dynamic>>('/api/blood-banks');
    return (res.data ?? const [])
        .map((e) => BloodBankItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> createBloodRequest({
    required String bloodGroup,
    required int unitsRequested,
    String urgency = 'URGENT',
    String? bloodBankId,
  }) async {
    await _api.post<Map<String, dynamic>>(
      '/api/blood-requests',
      data: {
        'bloodGroup': bloodGroup,
        'unitsRequested': unitsRequested,
        'urgency': urgency,
        'bloodBankId': ?bloodBankId,
      },
    );
  }

  Future<List<LaboratoryItem>> listLaboratories() async {
    final res = await _api.get<List<dynamic>>('/api/laboratories');
    return (res.data ?? const [])
        .map(
          (e) => LaboratoryItem.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<List<MedicalProviderItem>> listMedicalProviders({String? type}) async {
    final path = type != null
        ? '/api/medical-providers?type=${Uri.encodeQueryComponent(type)}'
        : '/api/medical-providers';
    final res = await _api.get<List<dynamic>>(path);
    return (res.data ?? const [])
        .map(
          (e) =>
              MedicalProviderItem.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<Map<String, dynamic>> trackDelivery(String trackingCode) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/api/medical-deliveries/track/${Uri.encodeComponent(trackingCode)}',
    );
    return Map<String, dynamic>.from(res.data ?? const {});
  }

  Future<Map<String, dynamic>> orderEmergencySupply({
    required String pharmacyId,
    required String deliveryAddress,
  }) async {
    final invRes = await _api.get<List<dynamic>>(
      '/api/pharmacies/$pharmacyId/inventory',
    );
    final items = (invRes.data ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((e) => e['prescriptionRequired'] != true && ((e['stockQuantity'] as num?) ?? 0) > 0)
        .toList();
    if (items.isEmpty) {
      throw StateError('No non-prescription emergency supplies in stock.');
    }
    final first = items.first;
    final res = await _api.post<Map<String, dynamic>>(
      '/api/pharmacies/orders',
      data: {
        'pharmacyId': pharmacyId,
        'medicineId': first['medicineId'],
        'quantity': 1,
        'deliveryRequested': true,
        'deliveryAddress': deliveryAddress,
      },
    );
    return Map<String, dynamic>.from(res.data ?? const {});
  }

  Future<Map<String, dynamic>> bookFirstLabService(String labId) async {
    final svcRes = await _api.get<List<dynamic>>(
      '/api/laboratories/$labId/services',
    );
    final svcs = (svcRes.data ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    if (svcs.isEmpty) {
      throw StateError('No lab services available.');
    }
    final res = await _api.post<Map<String, dynamic>>(
      '/api/lab-appointments',
      data: {
        'laboratoryId': labId,
        'labServiceId': svcs.first['id'],
      },
    );
    return Map<String, dynamic>.from(res.data ?? const {});
  }

  Future<Map<String, dynamic>> bookProviderVisit({
    required String providerId,
    required String chiefComplaint,
    bool telemedicine = false,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/api/provider-appointments',
      data: {
        'providerId': providerId,
        'appointmentType': telemedicine ? 'TELEMEDICINE' : 'IN_PERSON',
        'chiefComplaint': chiefComplaint,
      },
    );
    return Map<String, dynamic>.from(res.data ?? const {});
  }
}

final healthcareRepositoryProvider = Provider<HealthcareRepository>(
  (ref) => HealthcareRepository(ref.read(apiClientProvider)),
);

final pharmaciesProvider = FutureProvider<List<PharmacyItem>>(
  (ref) => ref.read(healthcareRepositoryProvider).listPharmacies(),
);

final bloodBanksProvider = FutureProvider<List<BloodBankItem>>(
  (ref) => ref.read(healthcareRepositoryProvider).listBloodBanks(),
);

final laboratoriesProvider = FutureProvider<List<LaboratoryItem>>(
  (ref) => ref.read(healthcareRepositoryProvider).listLaboratories(),
);

final medicalProvidersProvider = FutureProvider<List<MedicalProviderItem>>(
  (ref) => ref.read(healthcareRepositoryProvider).listMedicalProviders(),
);
