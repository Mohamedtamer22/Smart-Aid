import 'package:flutter_test/flutter_test.dart';
import 'package:smartaid_mobile/features/profile/profile_repository.dart';
import 'package:smartaid_mobile/features/notifications/notifications_repository.dart';

void main() {
  group('Profile and Notifications Models Test', () {
    test('MedicalProfileData serializes and deserializes correctly', () {
      final json = {
        'bloodType': 'O+',
        'allergies': 'Penicillin',
        'medications': 'Insulin',
        'emergencyNotes': 'Diabetic Type 1',
        'sharingConsent': true,
      };

      final data = MedicalProfileData.fromJson(json);
      expect(data.bloodType, 'O+');
      expect(data.allergies, 'Penicillin');
      expect(data.medications, 'Insulin');
      expect(data.emergencyNotes, 'Diabetic Type 1');
      expect(data.sharingConsent, isTrue);

      final outJson = data.toJson();
      expect(outJson['bloodType'], 'O+');
      expect(outJson['sharingConsent'], isTrue);
    });

    test('EmergencyContactData serializes and deserializes correctly', () {
      final json = {
        'id': 'contact-123',
        'fullName': 'Ahmed Mohamed',
        'relationship': 'Brother',
        'phone': '+201012345678',
        'primary': true,
      };

      final contact = EmergencyContactData.fromJson(json);
      expect(contact.id, 'contact-123');
      expect(contact.fullName, 'Ahmed Mohamed');
      expect(contact.relationship, 'Brother');
      expect(contact.phone, '+201012345678');
      expect(contact.primary, isTrue);

      final outJson = contact.toJson();
      expect(outJson['fullName'], 'Ahmed Mohamed');
      expect(outJson['primary'], isTrue);
    });

    test('AppNotification serializes and deserializes correctly', () {
      final now = DateTime.now().toUtc().toIso8601String();
      final json = {
        'id': 'notif-999',
        'type': 'EMERGENCY_ALERT',
        'read': false,
        'createdAt': now,
      };

      final notif = AppNotification.fromJson(json);
      expect(notif.id, 'notif-999');
      expect(notif.type, 'EMERGENCY_ALERT');
      expect(notif.read, isFalse);
    });
  });
}
