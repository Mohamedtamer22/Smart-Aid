import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class HospitalResource {
  const HospitalResource({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final DateTime? updatedAt;

  factory HospitalResource.fromJson(Map<String, dynamic> json) =>
      HospitalResource(
        id: json['id'] as String,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        updatedAt: json['updatedAt'] == null
            ? null
            : DateTime.parse(json['updatedAt'] as String),
      );
}

class AedResource {
  const AedResource({
    required this.id,
    required this.label,
    required this.resourceType,
    required this.latitude,
    required this.longitude,
    required this.availabilityStatus,
    required this.verified,
  });

  final String id;
  final String label;
  final String resourceType;
  final double latitude;
  final double longitude;
  final String availabilityStatus;
  final bool verified;

  factory AedResource.fromJson(Map<String, dynamic> json) => AedResource(
    id: json['id'] as String,
    label: json['label'] as String,
    resourceType: json['resourceType'] as String? ?? 'AED',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    availabilityStatus: json['availabilityStatus'] as String? ?? 'AVAILABLE',
    verified: json['verified'] as bool? ?? true,
  );
}

class ResourceRepository {
  ResourceRepository(this._api);

  final ApiClient _api;

  static List<HospitalResource>? _memoryHospitals;
  static List<AedResource>? _memoryAeds;
  static List<AmbulanceResource>? _memoryAmbulances;

  List<HospitalResource> cachedOrFallbackHospitals() =>
      _memoryHospitals ?? _fallbackHospitals;

  List<AedResource> cachedOrFallbackAeds() => _memoryAeds ?? _fallbackAeds;

  List<AmbulanceResource> cachedOrFallbackAmbulances() =>
      _memoryAmbulances ?? _fallbackAmbulances;

  Future<List<HospitalResource>> verifiedHospitals() async {
    try {
      final response = await _api.get<List<dynamic>>('/api/hospitals');
      final list = response.data!
          .cast<Map<String, dynamic>>()
          .map(HospitalResource.fromJson)
          .toList();
      _memoryHospitals = list;
      return list;
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return cachedOrFallbackHospitals();
      }
      throw failure;
    }
  }

  Future<List<AedResource>> verifiedAeds() async {
    try {
      final response = await _api.get<List<dynamic>>('/api/aed-devices');
      final list = response.data!
          .cast<Map<String, dynamic>>()
          .map(AedResource.fromJson)
          .toList();
      _memoryAeds = list;
      return list;
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return cachedOrFallbackAeds();
      }
      throw failure;
    }
  }

  Future<List<AmbulanceResource>> ambulances() async {
    try {
      final response = await _api.get<List<dynamic>>('/api/ambulances');
      final list = response.data!
          .cast<Map<String, dynamic>>()
          .map(AmbulanceResource.fromJson)
          .toList();
      _memoryAmbulances = list;
      return list;
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return cachedOrFallbackAmbulances();
      }
      throw failure;
    }
  }

  static final List<HospitalResource> _fallbackHospitals = [
    HospitalResource(
      id: 'hosp-01',
      name: 'Cairo Emergency Hospital (قصر العيني للطوارئ)',
      latitude: 30.0305,
      longitude: 31.2285,
      updatedAt: DateTime.now(),
    ),
    HospitalResource(
      id: 'hosp-02',
      name: 'Al-Salam International Hospital (مستشفى السلام الدولي)',
      latitude: 29.9824,
      longitude: 31.2782,
      updatedAt: DateTime.now(),
    ),
    HospitalResource(
      id: 'hosp-03',
      name: 'Dar Al Fouad Hospital (مستشفى دار الفؤاد)',
      latitude: 30.0074,
      longitude: 30.9733,
      updatedAt: DateTime.now(),
    ),
  ];

  static final List<AedResource> _fallbackAeds = [
    const AedResource(
      id: 'aed-01',
      label: 'Tahrir Metro Station AED (محطة مترو التحرير)',
      resourceType: 'AED',
      latitude: 30.0444,
      longitude: 31.2357,
      availabilityStatus: 'AVAILABLE',
      verified: true,
    ),
    const AedResource(
      id: 'aed-02',
      label: 'Cairo International Airport Terminal 3 AED',
      resourceType: 'AED',
      latitude: 30.1114,
      longitude: 31.4011,
      availabilityStatus: 'AVAILABLE',
      verified: true,
    ),
    const AedResource(
      id: 'aed-03',
      label: 'City Center Hub Public AED (مركز المدينة)',
      resourceType: 'AED',
      latitude: 30.0510,
      longitude: 31.2410,
      availabilityStatus: 'AVAILABLE',
      verified: true,
    ),
  ];

  static final List<AmbulanceResource> _fallbackAmbulances = [
    AmbulanceResource(
      id: 'amb-01',
      callSign: 'Ambulance Alpha-101 (إسعاف 101)',
      status: 'AVAILABLE',
      latitude: 30.0450,
      longitude: 31.2360,
      updatedAt: DateTime.now(),
    ),
    AmbulanceResource(
      id: 'amb-02',
      callSign: 'Ambulance Beta-204 (إسعاف 204)',
      status: 'DISPATCHED',
      latitude: 30.0410,
      longitude: 31.2390,
      updatedAt: DateTime.now(),
    ),
  ];
}

class AmbulanceResource {
  const AmbulanceResource({
    required this.id,
    required this.callSign,
    required this.status,
    this.latitude,
    this.longitude,
    this.updatedAt,
  });

  final String id;
  final String callSign;
  final String status;
  final double? latitude;
  final double? longitude;
  final DateTime? updatedAt;

  factory AmbulanceResource.fromJson(Map<String, dynamic> json) =>
      AmbulanceResource(
        id: json['id'] as String,
        callSign: json['callSign'] as String,
        status: json['status'] as String? ?? 'AVAILABLE',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        updatedAt: json['updatedAt'] == null
            ? null
            : DateTime.parse(json['updatedAt'] as String),
      );
}
