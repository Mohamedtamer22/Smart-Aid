import 'package:flutter_test/flutter_test.dart';
import 'package:smartaid_mobile/features/resources/resource_repository.dart';

void main() {
  test('parses verified hospital directory data from the API contract', () {
    final hospital = HospitalResource.fromJson({
      'id': 'd2ee4795-f5ad-468e-b0ea-b80656497c4d',
      'name': 'Verified Hospital',
      'latitude': 30.0444,
      'longitude': 31.2357,
      'updatedAt': '2026-10-09T12:00:00Z',
    });

    expect(hospital.name, 'Verified Hospital');
    expect(hospital.latitude, 30.0444);
    expect(hospital.updatedAt, DateTime.parse('2026-10-09T12:00:00Z'));
  });
}
