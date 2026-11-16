import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';

class OfflineFirstAidGuide {
  const OfflineFirstAidGuide({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.stepsEn,
    required this.stepsAr,
  });

  final String id;
  final String titleEn;
  final String titleAr;
  final List<String> stepsEn;
  final List<String> stepsAr;
}

class QueuedOfflineIncident {
  const QueuedOfflineIncident({
    required this.idempotencyKey,
    required this.emergencyType,
    required this.latitude,
    required this.longitude,
    required this.notes,
    required this.createdAtIso,
    this.synced = false,
  });

  final String idempotencyKey;
  final String emergencyType;
  final double latitude;
  final double longitude;
  final String notes;
  final String createdAtIso;
  final bool synced;

  Map<String, dynamic> toJson() => {
    'idempotencyKey': idempotencyKey,
    'emergencyType': emergencyType,
    'latitude': latitude,
    'longitude': longitude,
    'notes': notes,
    'createdAtIso': createdAtIso,
    'synced': synced,
  };

  factory QueuedOfflineIncident.fromJson(Map<String, dynamic> json) =>
      QueuedOfflineIncident(
        idempotencyKey: json['idempotencyKey'] as String? ?? '',
        emergencyType: json['emergencyType'] as String? ?? 'MEDICAL',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 30.0444,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 31.2357,
        notes: json['notes'] as String? ?? '',
        createdAtIso:
            json['createdAtIso'] as String? ?? DateTime.now().toIso8601String(),
        synced: json['synced'] as bool? ?? false,
      );
}

class OfflineSyncResult {
  const OfflineSyncResult({required this.syncedCount, required this.failedCount});

  final int syncedCount;
  final int failedCount;
}

class OfflineEmergencyService {
  static const String queueStorageKey = 'smartaid_offline_sos_queue_v1';

  static const List<OfflineFirstAidGuide> cachedGuides = [
    OfflineFirstAidGuide(
      id: 'cpr',
      titleEn: 'Adult Hands-Only CPR (Cardiac Arrest)',
      titleAr: 'الإنعاش القلبي الرئوي للبالغين (توقف القلب)',
      stepsEn: [
        'Check scene safety and responsiveness. Call local emergency services immediately.',
        'Place the heel of one hand on the center of the chest, other hand on top.',
        'Push hard and fast: 100–120 compressions per minute, depth ~5 cm (2 inches).',
        'Allow full chest recoil between compressions. Continue until AED or EMS arrives.',
      ],
      stepsAr: [
        'تأكد من أمان المكان واستجابة المصاب، واتصل بالإسعاف المحلي فوراً.',
        'ضع كعب إحدى يديك في منتصف الصدر واليد الأخرى فوقها مع تشبيك الأصابع.',
        'اضغط بقوة وبسرعة بمعدل 100 إلى 120 ضغطة في الدقيقة وبعمق حوالي 5 سم.',
        'اترك الصدر يرتد بالكامل بين الضغطات واستمر حتى وصول جهاز الصدمات أو الإسعاف.',
      ],
    ),
    OfflineFirstAidGuide(
      id: 'bleeding',
      titleEn: 'Severe Bleeding Control',
      titleAr: 'السيطرة على النزيف الحاد',
      stepsEn: [
        'Apply firm, direct pressure on the wound using clean gauze or cloth.',
        'Do not remove soaked dressings; add additional layers on top and keep pressing.',
        'If life-threatening limb bleeding continues and a tourniquet is available, apply 5–7 cm above the wound.',
        'Keep the person warm and monitor breathing until professional EMS takes over.',
      ],
      stepsAr: [
        'اضغط مباشرة وبقوة على الجرح باستخدام شاش معقم أو قطعة قماش نظيفة.',
        'لا تنزع الضمادة المشبعة بالدم، بل أضف طبقات جديدة فوقها مع استمرار الضغط.',
        'في حال نزيف الأطراف المهدد للحياة وتوفر عاصبة (تورنيكيه)، اربطها أعلى الجرح بـ 5–7 سم.',
        'حافظ على دفء المصاب وراقب تنفسه حتى استلام فرق الإسعاف.',
      ],
    ),
    OfflineFirstAidGuide(
      id: 'choking',
      titleEn: 'Conscious Adult Choking Relief',
      titleAr: 'إسعاف الاختناق للبالغ الواعي',
      stepsEn: [
        'Ask "Are you choking?" If unable to speak or cough, intervene immediately.',
        'Deliver 5 firm back blows between the shoulder blades with the heel of your hand.',
        'If airway remains blocked, perform 5 abdominal thrusts (Heimlich maneuver) just above the navel.',
        'Alternate 5 back blows and 5 abdominal thrusts until object clears or EMS arrives.',
      ],
      stepsAr: [
        'اسأل المصاب هل تختنق؟ إذا عجز عن الكلام أو السعال فتدخل فوراً.',
        'وجّه 5 ضربات ثابتة بكعب اليد بين لوحي الكتف.',
        'إذا استمر الانسداد، نفّذ 5 ضغطات بطنية (مناورة هيمليك) أعلى السرة مباشرة.',
        'كرر التناوب بين 5 ضربات ظهرية و5 ضغطات بطنية حتى خروج الجسم أو وصول الإسعاف.',
      ],
    ),
  ];

  Future<List<QueuedOfflineIncident>> loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(queueStorageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => QueuedOfflineIncident.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<QueuedOfflineIncident> enqueueIncident({
    required String emergencyType,
    required double latitude,
    required double longitude,
    required String notes,
  }) async {
    final existing = await loadQueue();
    final now = DateTime.now().toUtc();
    final key = 'offline-${now.microsecondsSinceEpoch}-${existing.length}';
    final entry = QueuedOfflineIncident(
      idempotencyKey: key,
      emergencyType: emergencyType,
      latitude: latitude,
      longitude: longitude,
      notes: notes.trim(),
      createdAtIso: now.toIso8601String(),
    );
    final updated = [entry, ...existing];
    await _saveQueue(updated);
    return entry;
  }

  Future<OfflineSyncResult> syncPending(ApiClient api) async {
    final queue = await loadQueue();
    if (queue.isEmpty) {
      return const OfflineSyncResult(syncedCount: 0, failedCount: 0);
    }
    int synced = 0;
    int failed = 0;
    final remaining = <QueuedOfflineIncident>[];
    for (final item in queue) {
      if (item.synced) continue;
      try {
        await api.post<Map<String, dynamic>>(
          '/api/incidents',
          data: {
            'emergencyType': item.emergencyType,
            'location': {
              'latitude': item.latitude,
              'longitude': item.longitude,
            },
            'notes': item.notes.isEmpty
                ? '[Synced Offline Draft] Created ${item.createdAtIso}'
                : '[Synced Offline Draft] ${item.notes}',
          },
          options: Options(headers: {'Idempotency-Key': item.idempotencyKey}),
        );
        synced++;
      } catch (_) {
        failed++;
        remaining.add(item);
      }
    }
    await _saveQueue(remaining);
    return OfflineSyncResult(syncedCount: synced, failedCount: failed);
  }

  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(queueStorageKey);
  }

  Future<void> _saveQueue(List<QueuedOfflineIncident> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      queueStorageKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}

final offlineEmergencyServiceProvider = Provider<OfflineEmergencyService>(
  (_) => OfflineEmergencyService(),
);
