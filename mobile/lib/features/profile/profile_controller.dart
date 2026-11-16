import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import 'profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.read(apiClientProvider)),
);

class MedicalProfileController extends AsyncNotifier<MedicalProfileData> {
  @override
  Future<MedicalProfileData> build() async {
    final repo = ref.read(profileRepositoryProvider);
    _syncSilently(repo);
    return repo.cachedOrFallbackMedicalProfile();
  }

  void _syncSilently(ProfileRepository repo) {
    repo
        .medicalProfile()
        .then((fresh) {
          state = AsyncData(fresh);
        })
        .catchError((_) {});
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).medicalProfile(),
    );
  }

  Future<void> save(MedicalProfileData data) async {
    final saved = await ref
        .read(profileRepositoryProvider)
        .saveMedicalProfile(data);
    state = AsyncData(saved);
  }
}

final medicalProfileProvider =
    AsyncNotifierProvider<MedicalProfileController, MedicalProfileData>(
      MedicalProfileController.new,
    );

class EmergencyContactsController
    extends AsyncNotifier<List<EmergencyContactData>> {
  @override
  Future<List<EmergencyContactData>> build() async {
    final repo = ref.read(profileRepositoryProvider);
    _syncSilently(repo);
    return repo.cachedOrFallbackContacts();
  }

  void _syncSilently(ProfileRepository repo) {
    repo
        .contacts()
        .then((fresh) {
          state = AsyncData(fresh);
        })
        .catchError((_) {});
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).contacts(),
    );
  }

  Future<void> saveContact(EmergencyContactData contact) async {
    final saved = await ref
        .read(profileRepositoryProvider)
        .saveContact(contact);
    final current = state.value ?? [];
    final index = current.indexWhere((c) => c.id == saved.id);
    List<EmergencyContactData> updated;
    if (index >= 0) {
      updated = [...current]..[index] = saved;
    } else {
      updated = [...current, saved];
    }
    if (saved.primary) {
      updated = updated
          .map(
            (c) => c.id == saved.id
                ? c
                : EmergencyContactData(
                    id: c.id,
                    fullName: c.fullName,
                    relationship: c.relationship,
                    phone: c.phone,
                    primary: false,
                  ),
          )
          .toList();
    }
    state = AsyncData(updated);
  }

  Future<void> deleteContact(String id) async {
    await ref.read(profileRepositoryProvider).deleteContact(id);
    final current = state.value ?? [];
    state = AsyncData(current.where((c) => c.id != id).toList());
  }
}

final emergencyContactsProvider =
    AsyncNotifierProvider<
      EmergencyContactsController,
      List<EmergencyContactData>
    >(EmergencyContactsController.new);
