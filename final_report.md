# التقرير الفني الشامل والموسوعة المرجعية الكاملة لمنصة الإسعاف الذكي (Smart Aid)
**الوثيقة المرجعية الرسمية والهندسية للنظام — الإصدار المعتمد V1**  
**تاريخ التوثيق:** أكتوبر 2026  
**طبيعة المنصة:** Native Single-Machine Emergency Coordination Platform (بدون حاويات Docker)

---

## الفهرس العام للموسوعة:
1. [بطاقة الهوية التقنية والإصدارات الدقيقة للمشروع](#1-بطاقة-الهوية-التقنية-والإصدارات-الدقيقة-للمشروع)
2. [الرؤية والهدف وفلسفة النظام (System Philosophy & Safety Boundaries)](#2-الرؤية-والهدف-وفلسفة-النظام)
3. [المعمارية الهندسية وتدفق البيانات (System Architecture & Data Flow)](#3-المعمارية-الهندسية-وتدفق-البيانات)
4. [الدليل المرجعي الشامل لجميع واجهات برمجة التطبيقات (All 38+ REST APIs & DTOs)](#4-الدليل-المرجعي-الشامل-لجميع-واجهات-برمجة-التطبيقات)
5. [بروتوكول البث والتتبع اللحظي (STOMP WebSockets Real-Time Protocol)](#5-بروتوكول-البث-والتتبع-اللحظي)
6. [قاعدة البيانات الجغرافية المكانية والمخطط الكامل (PostgreSQL 18 + PostGIS + Flyway Migrations V1-V7)](#6-قاعدة-البيانات-الجغرافية-المكانية-والمخطط-الكامل)
7. [الخوارزميات والنماذج الرياضية الذكية المطبقة (Algorithms & Mathematical Models)](#7-الخوارزميات-والنماذج-الرياضية-الذكية-المطبقة)
8. [هندسة تطبيق الفلاتر والواجهات (Flutter Mobile & Web Architecture)](#8-هندسة-تطبيق-الفلاتر-والواجهات)
9. [التفاصيل الدقيقة لحل مشكلة بطء الـ APK وضغط حجمه (Performance & Optimization Deep Dive)](#9-التفاصيل-الدقيقة-لحل-مشكلة-بطء-الـ-apk-وضغط-حجمه)
10. [الأمان، الخصوصية وسجلات التدقيق (Security, RBAC & Immutable Audit Logs)](#10-الأمان-الخصوصية-وسجلات-التدقيق)
11. [دليل السكربتات وأوامر التشغيل والاختبار الكاملة (Scripts & Tooling Reference)](#11-دليل-السكربتات-وأوامر-التشغيل-والاختبار-الكاملة)
12. [رحلة الاستخدام العملية للأدوار الأربعة (End-to-End User Journeys)](#12-رحلة-الاستخدام-العملية-للأدوار-الأربعة)
13. [مصفوفة الجودة ونتائج الفحص والتحليل (QA & Test Execution Matrix)](#13-مصفوفة-الجودة-ونتائج-الفحص-والتحليل)

---

## 1. بطاقة الهوية التقنية والإصدارات الدقيقة للمشروع

تم بناء النظام بالكامل ليعمل بشكل أصيل (Native) على جهاز واحد وبأحدث حزم البرمجيات المستقرة:

### أ. بيئة الباك إند (Backend Environment):
* **نظام التشغيل:** Windows 10/11 x64 (Native Development Environment).
* **لغة البرمجة الأساسية:** Java 21 LTS (مع توافق كامل مع Java 25 عبر `SMARTAID_TOMCAT_NIO2=true`).
* **إطار العمل الرئيسي:** Spring Boot 3.5.7 (Spring Framework 6.x).
* **أداة البناء وإدارة التبعيات:** Apache Maven Wrapper (`mvnw` / `mvnw.cmd`).
* **الحزم والمكتبات المدمجة:**
  - `spring-boot-starter-web`: لبناء RESTful Web Services عبر Tomcat المُدمج.
  - `spring-boot-starter-data-jpa`: للتعامل مع قاعدة البيانات عبر Hibernate 6 و JPA.
  - `spring-boot-starter-security`: لإدارة التوثيق والصلاحيات (Spring Security 6).
  - `spring-boot-starter-websocket`: لدعم قنوات الاتصال الثنائي عبر STOMP.
  - `spring-boot-starter-validation`: للتحقق الصارم من صحة المدخلات (`@Valid`, `@NotBlank`, إلخ).
  - `spring-boot-starter-actuator`: لمراقبة صحة الخادم وجاهزيته (`/actuator/health`).
  - `flyway-core` & `flyway-database-postgresql`: لإدارة ترحيلات وترقيات قاعدة البيانات تلقائياً.
  - `postgresql` (JDBC Driver v42.7.x): للاتصال بقاعدة بيانات بوستجريس.
  - `jjwt-api`, `jjwt-impl`, `jjwt-jackson` (v0.12.6): لإنشاء وفك تشفير توكنات الـ JWT بأحدث المعايير.
  - `springdoc-openapi-starter-webmvc-ui` (v2.8.6): لإنشاء وثائق وتجربة Swagger UI التفاعلية.

### ب. بيئة قاعدة البيانات (Database Environment):
* **المحرك:** PostgreSQL 18.x 64-bit Server.
* **الامتداد المكاني:** PostGIS Spatial Extension (دعم كامل لـ `geography`, `ST_Distance`, `ST_DWithin`, `GIST Indexes`).
* **المنفذ الافتراضي:** `5432`.
* **اسم قاعدة البيانات:** `smartaid`.
* **المستخدم المعتمد:** `smartaid_user`.

### ج. بيئة تطبيق الفلاتر (Mobile & Web Environment):
* **إطار العمل:** Flutter 3.44.8 (Channel stable).
* **لغة البرمجة:** Dart 3.12.2.
* **إصدار أندرويد المستهدف:**
  - `minSdkVersion`: 21 (Android 5.0 Lollipop).
  - `targetSdkVersion`: 34 (Android 14).
  - `compileSdkVersion`: 34.
  - `JVM Target`: Java 17.
* **الحزم المعتمدة (pubspec.yaml):**
  - `flutter_riverpod: ^3.0.3`: إدارة الحالة بنمط Notifiers مع الكاش الذكي.
  - `dio: ^5.9.0`: عميل HTTP المتقدم مع معالجة الأخطاء والـ Interceptors.
  - `flutter_secure_storage: ^10.3.4`: حفظ التوكنات بتشفير عالي.
  - `geolocator: ^14.1.0`: قراءة الموقع الجغرافي GPS بدقة عالية.
  - `latlong2: ^0.9.1` و `flutter_map: ^8.2.2`: رسم الخرائط وتحديد مسارات الإسعاف.
  - `shared_preferences: ^2.5.5`: حفظ الإعدادات السريعة (اللغة المختارة وعنوان السيرفر).
  - `stomp_dart_client: ^3.0.1` و `web_socket_channel: ^3.0.3`: استقبال التحديثات اللحظية عبر الـ WebSocket.
  - `flutter_localizations`: الترجمة الثنائية والتبديل بين العربية والإنجليزية.

---

## 2. الرؤية والهدف وفلسفة النظام

### الهدف العام:
تم ابتكار **Smart Aid** ليكون حلقة الوصل المفقودة في الدقائق العشر الأولى من أي حادث طارئ (The Platinum Ten Minutes)، حيث تتكامل المنظومة لتحقيق:
1. **الوصول الأسرع للمصاب:** عبر إشراك وتوجيه المتطوعين المعتمدين القريبين جغرافياً لتقديم الإسعافات الأولية وأجهزة الـ AED قبل وصول سيارة الإسعاف.
2. **اتخاذ قرارات المستشفيات بالذكاء والبيانات (Smart ER):** التوقف عن التوجه العشوائي لأقرب مستشفى قد يكون غارقاً في الازدحام أو يفتقر إلى التخصص، وتوجيه الحالة للمستشفى الجاهز فعلياً.
3. **توفير تاريخ طبي فوري للمسعفين:** الاطلاع الفوري على فصيلة الدم والحساسية الدوائية للمصاب لإنقاذ حياته ومنع إعطائه أدوية مهددة لحياته.

### حدود السلامة والمحددات القانونية (Safety Boundaries):
* المنصة **لا تدعي إطلاقاً** أنها بديل لخطوط الطوارئ الوطنية (مثل 123 أو 911).
* المنصة لا تقوم بتشخيص طبي آلي (No Autonomous Clinical Diagnosis)؛ فكل التوصيات تخضع لسلطة المسعف والطبيب البشري.
* إطلاق الاستغاثة حالياً يعتمد على التدخل البشري اليدوي (`MANUAL`)؛ ولم يتم تفعيل الاستشعار التلقائي للحوادث لتجنب البلاغات الكاذبة.

---

## 3. المعمارية الهندسية وتدفق البيانات (System Architecture & Data Flow)

يعتمد النظام معمارية **3-Tier Monolithic System** مقسمة منطقياً إلى حزم مستقلة (Domain Packages) لضمان سهولة التطوير والصيانة دون الدخول في تعقيدات الأنظمة الموزعة:

```
[Citizen / Volunteer / EMS Mobile & Web Apps]
                     │
                     ▼ (REST API + JWT Bearer / STOMP WS)
           [Spring Security Filter Chain]
                     │
         [AuthRateLimitFilter (DDoS & Brute-force Protection)]
                     │
          [Domain Controllers & REST Resources]
                     │
            [Business Logic Services Layer]
                     │
        [Spring Data JPA Repositories Layer]
                     │
     [PostgreSQL 18 + PostGIS Spatial Engine]
```

### دورة حياة تدفق البيانات (End-to-End Incident Flow):
1. يضغط المواطن على زر **SOS** في تطبيق الموبايل.
2. يرسل التطبيق طلب `POST /api/incidents` مصحوباً بـ `Idempotency-Key` وإحداثيات GPS.
3. يقوم خادم Spring Boot بحجز قفل استشاري (Advisory Lock) لمنع التكرار، ثم يسجل البلاغ بحالة `NEW` ثم ينتقل إلى `SEARCHING`.
4. تبث خدمة الـ WebSocket رسالة فورية إلى المتطوعين القريبين على القناة `/topic/incidents/nearby`.
5. يفتح المتطوع خريطته، ويضغط "قبول المهمة"؛ يقوم الباك إند بقفل السجل ذرياً (`Pessimistic Lock: SELECT FOR UPDATE`) وتعيين البلاغ للمتطوع الأول حصراً، وتتحول الحالة إلى `RESPONDER_ASSIGNED`.
6. يرى ضابط العمليات (EMS Dispatcher) البلاغ على لوحة تحكمه، ويقوم بتعيين سيارة إسعاف (`EMS_ASSIGNED` -> `AMBULANCE_ASSIGNED`).
7. تستدعي غرفة العمليات محرك **Smart ER**؛ فيقوم المحرك بحساب معادلة الملاءمة ويرشح المستشفى الأفضل، ويؤكد الضابط الاختيار لتتحول الحالة إلى `HOSPITAL_SELECTED`.
8. عند وصول المصاب للمستشفى تتحول الحالة إلى `AT_HOSPITAL` ثم `RESOLVED`.
9. كل خطوة وكل انتقال حالة يتم توثيقه في جدول `incident_status_history` وجدول `audit_logs`.

---

## 4. الدليل المرجعي الشامل لجميع واجهات برمجة التطبيقات (All 38+ REST APIs & DTOs)

تلتزم جميع الواجهات بمعايير RESTful وتستخدم صيغة JSON، مع إرجاع استجابات خطأ موحدة وآمنة (`ApiException` / `ErrorResponse`):

### أ. حزمة المصادقة والأمان (`/api/auth`):
1. **تسجيل حساب جديد:**
   - **المسار:** `POST /api/auth/register`
   - **الصلاحية:** مفتوح للعامة.
   - **جسم الطلب (Request Body):**
     ```json
     {
       "email": "user@example.com",
       "password": "Password123!",
       "fullName": "Hamo User",
       "phone": "+201012345678",
       "role": "CITIZEN" // أو VOLUNTEER أو HOSPITAL
     }
     ```
   - **رمز الاستجابة:** `201 Created` مع بيانات الحساب المُنشأ وتوكنات الدخول.

2. **تسجيل الدخول:**
   - **المسار:** `POST /api/auth/login`
   - **الصلاحية:** مفتوح للعامة (خاضع لفلتر تحديد المعدل Rate Limit).
   - **جسم الطلب:**
     ```json
     { "email": "user@example.com", "password": "Password123!" }
     ```
   - **الاستجابة:** `200 OK`
     ```json
     {
       "accessToken": "eyJhbGciOi...",
       "refreshToken": "d3b07384...",
       "user": { "id": "uuid", "email": "...", "role": "ROLE_CITIZEN", "fullName": "..." }
     }
     ```

3. **تجديد التوكن (Token Rotation):**
   - **المسار:** `POST /api/auth/refresh`
   - **الصلاحية:** مفتوح (يتطلب Refresh Token صالح).
   - **الوظيفة:** يتحقق من التوكن القديم، ويقوم بإلغائه وإصدار Access Token و Refresh Token جديدين تماماً لمنع هجمات إعادة الاستخدام (Replay Attacks).

4. **تسجيل الخروج:**
   - **المسار:** `POST /api/auth/logout`
   - **الصلاحية:** يتطلب تسجيل الدخول.
   - **الوظيفة:** حذف جلسة التوكن الحالية وإلغاء صلاحيتها فورياً من قاعدة البيانات.

5. **استعلام بيانات المستخدم الحالي:**
   - **المسار:** `GET /api/users/me`
   - **الصلاحية:** أي مستخدم مسجل.

---

### ب. حزمة البلاغات وحوادث الطوارئ (`/api/incidents`):
6. **إنشاء بلاغ استغاثة فوري (SOS):**
   - **المسار:** `POST /api/incidents`
   - **الرأس المطلوب (Header):** `Idempotency-Key: <unique-uuid>`
   - **الصلاحية:** `ROLE_CITIZEN` أو أي دور مصرح له.
   - **جسم الطلب:**
     ```json
     {
       "emergencyTypeCode": "MEDICAL_CARDIO",
       "latitude": 30.0444,
       "longitude": 31.2357,
       "source": "MANUAL",
       "notes": "Severe chest pain"
     }
     ```
   - **الاستجابة:** `201 Created` ببيانات الحادث، ومستوى الأولوية المحسوب (`CRITICAL`, `HIGH`, إلخ).

7. **استعراض بلاغات المستخدم الخاصة:**
   - **المسار:** `GET /api/incidents/mine` و `GET /api/incidents/my`
   - **الصلاحية:** المستخدم صاحب البلاغات.

8. **استعلام تفاصيل بلاغ محدد:**
   - **المسار:** `GET /api/incidents/{id}`
   - **الاستجابة:** تفاصيل الحادث، الفرز السريع، وسجل الحالات الزمني (Timeline).

9. **تحديث حالة البلاغ (Status Transition):**
   - **المسار:** `PATCH /api/incidents/{id}/status` و `POST /api/incidents/{id}/status`
   - **الصلاحية:** موظف الإسعاف `ROLE_EMS` أو المشرف `ROLE_ADMIN`.
   - **جسم الطلب:**
     ```json
     { "status": "AMBULANCE_ASSIGNED", "reason": "Ambulance dispatched" }
     ```

10. **إلغاء البلاغ:**
    - **المسار:** `POST /api/incidents/{id}/cancel`
    - **الصلاحية:** صاحب البلاغ (في المراحل الأولى فقط) أو إدارة الإسعاف.

11. **قبول البلاغ من متطوع:**
    - **المسار:** `POST /api/incidents/{id}/accept` و `POST /api/volunteers/incidents/{id}/accept`
    - **الصلاحية:** `ROLE_VOLUNTEER`.

---

### ج. حزمة المتطوعين والمهام الميدانية (`/api/volunteers`):
12. **استعلام وتحديث حالة جاهزية المتطوع:**
    - **المسار:** `GET /api/volunteers/me/status` و `PUT /api/volunteers/me/status`
    - **جسم الطلب:** `{ "isAvailable": true }`

13. **تحديث إحداثيات موقع المتطوع الحالية:**
    - **المسار:** `PUT /api/volunteers/me/location`
    - **جسم الطلب:** `{ "latitude": 30.0500, "longitude": 31.2400 }`

14. **استعراض البلاغات القريبة المؤهلة:**
    - **المسار:** `GET /api/volunteers/nearby-incidents`
    - **الوظيفة:** استعلام PostGIS يعيد فقط الحوادث بحالة `SEARCHING` في نطاق دائري 5 كم من موقع المتطوع.

15. **استعلام المهمة النشطة الحالية للمتطوع:**
    - **المسار:** `GET /api/volunteers/missions/active`

16. **تسجيل وصول المتطوع إلى موقع المصاب:**
    - **المسار:** `POST /api/volunteers/missions/{id}/arrive`

17. **تسجيل إتمام وإنهاء مهمة المتطوع:**
    - **المسار:** `POST /api/volunteers/missions/{id}/complete`
    - **جسم الطلب:** `{ "actionSummary": "CPR performed, patient stable until EMS arrived" }`

---

### د. حزمة الدورات التدريبية والشهادات (`/api/training`):
18. **استعراض قائمة الدورات التدريبية:**
    - **المسار:** `GET /api/training/courses`
    - **الوظيفة:** يعيد الدورات (CPR & AED Essentials, Triage Protocols, Trauma First Response) مع حالة إنجاز المستخدم ونسبته المئوية.

19. **استعلام تفاصيل دورة ودروسها:**
    - **المسار:** `GET /api/training/courses/{id}`

20. **تسجيل اكتمال درس تعليمي:**
    - **المسار:** `POST /api/training/courses/{id}/lessons/{lessonId}/complete`

21. **إرسال إجابات اختبار الدورة وتقييمها:**
    - **المسار:** `POST /api/training/courses/{id}/quiz/submit`
    - **جسم الطلب:** قائمة الإجابات المختارة؛ يتم تصحيحها في السيرفر وتحديث حالة شهادة المتطوع تلقائياً عند النجاح (درجة >= 80%).

---

### هـ. حزمة الملف الطبي وجهات الاتصال (`/api/medical-profile` & `/api/emergency-contacts`):
22. **استعلام الملف الطبي للمستخدم:**
    - **المسار:** `GET /api/medical-profile`
    - **الصلاحية:** صاحب الحساب أو الطبيب/المسعف المصرح له أثناء الحادث.

23. **تحديث الملف الطبي:**
    - **المسار:** `PUT /api/medical-profile`
    - **جسم الطلب:**
      ```json
      {
        "bloodType": "O+",
        "allergies": "Penicillin",
        "medications": "Insulin",
        "emergencyNotes": "Diabetic Type 1",
        "sharingConsent": true
      }
      ```

24. **استعراض جهات اتصال الطوارئ:**
    - **المسار:** `GET /api/emergency-contacts`

25. **إضافة جهة اتصال طوارئ:**
    - **المسار:** `POST /api/emergency-contacts`
    - **جسم الطلب:**
      ```json
      {
        "fullName": "Ahmed Mohamed",
        "relationship": "Brother",
        "phone": "+201012345678",
        "primary": true
      }
      ```

26. **تعديل جهة اتصال:**
    - **المسار:** `PUT /api/emergency-contacts/{id}`

27. **حذف جهة اتصال:**
    - **المسار:** `DELETE /api/emergency-contacts/{id}`

---

### و. حزمة الإشعارات (`/api/notifications`):
28. **استعراض الإشعارات الأخيرة للمستخدم:**
    - **المسار:** `GET /api/notifications` (يعيد أحدث 100 إشعار مرتبة زمنياً).

29. **تعليم إشعار كمقروء:**
    - **المسار:** `PATCH /api/notifications/{id}/read`

---

### ز. حزمة التوجيه الذكي للمستشفيات (`/api/smart-er`):
30. **استخراج الترشيحات الذكية للمستشفيات للحادث:**
    - **المسار:** `GET /api/smart-er/{incidentId}` و `GET /api/smart-er/incidents/{incidentId}/recommendations`
    - **الصلاحية:** `ROLE_EMS` أو `ROLE_ADMIN`.
    - **الاستجابة:** قائمة بالمستشفيات مرتبة بالأفضلية، مع توضيح تفصيلي للنقاط (درجة زمن الوصول، درجة التجهيز، تطابق التخصص، نسبة الازدحام).

31. **تأكيد واختيار المستشفى الوجهة:**
    - **المسار:** `POST /api/smart-er/incidents/{incidentId}/select-destination`
    - **جسم الطلب:** `{ "hospitalId": "uuid" }`
    - **الوظيفة:** تحديث حالة الحادث فورياً إلى `HOSPITAL_SELECTED` وإخطار طاقم الإسعاف والمستشفى.

---

### ح. حزمة إدارة العمليات والموارد (`/api/ems`, `/api/hospitals`, `/api/aed-devices`, `/api/ambulances`):
32. **لوحة تحكم عمليات الإسعاف:**
    - **المسار:** `GET /api/ems/dashboard` (إحصائيات الحالات النشطة، توزيع الأولويات، وحالة سيارات الإسعاف).

33. **دليل المستشفيات المعتمدة:**
    - **المسار:** `GET /api/hospitals`

34. **دليل أجهزة الصدمات الكهربائية (AEDs):**
    - **المسار:** `GET /api/aed-devices`

35. **دليل وإدارة أسطول الإسعاف:**
    - **المسار:** `GET /api/ambulances`

---

### ط. حزمة الإدارة والتحليلات والتدقيق (`/api/admin`, `/api/analytics`, `/api/disaster`):
36. **نظرة عامة على النظام:**
    - **المسار:** `GET /api/admin/overview`

37. **إدارة المستخدمين والأدوار:**
    - **المسار:** `GET /api/admin/users` و `PUT /api/admin/users/{id}/role`

38. **سجلات التدقيق الأمني:**
    - **المسار:** `GET /api/admin/audit-logs`

39. **التحليلات والمقارنة البحثية لخوارزمية Smart ER:**
    - **المسار:** `GET /api/analytics/overview` و `GET /api/analytics/research/smart-er-comparison`

40. **لوحة إدارة الكوارث والحوادث الكبرى:**
    - **المسار:** `GET /api/disaster/overview` و `GET /api/disaster/status`

---

## 5. بروتوكول البث والتتبع اللحظي (STOMP WebSockets Real-Time Protocol)

يدعم النظام الاتصال اللحظي الكامل منخفض الكمون (Low Latency) باستخدام بروتوكول **STOMP over WebSocket**:

* **نقطة نهاية الاتصال والمصافحة (Handshake Endpoint):**
  - المسار: `ws://localhost:8080/ws` (أو `http://192.168.100.181:8080/ws` للهواتف).
  - المصادقة: تمرير توكن الـ JWT في رأس الـ STOMP Connect Frame:
    `Authorization: Bearer <accessToken>`.
  - معالج المصادقة: كلاس [`StompAuthChannelInterceptor.java`](file:///d:/hamo/Projects/SmartAid/backend/src/main/java/com/smartaid/platform/websocket/StompAuthChannelInterceptor.java) يقوم بفحص التوكن وربط هوية المستخدم بالقناة المفتوحة.

* **قنوات الاشتراك (Topics):**
  - تتبع حادث محدد: `/topic/incidents/{incidentId}` (يستمع إليه المواطن وغرفة الإسعاف لمتابعة حركة المسعف والسيارة وتغير الحالات لحظياً).
  - تنبيهات المتطوعين القريبين: `/topic/volunteers/alerts` (لبث نداءات الاستغاثة الجديدة فور إطلاقها).

---

## 6. قاعدة البيانات الجغرافية المكانية والمخطط الكامل (PostgreSQL 18 + PostGIS + Flyway Migrations V1-V7)

تم بناء هيكل البيانات بواسطة 7 ملفات ترحيل Flyway مرتبة ومنظمة:

### سجل ملفات الترحيل (Flyway Versioned Migrations):
1. **`V1__initial_schema.sql` (11.5 KB):**
   - إنشاء امتداد `postgis`.
   - إنشاء جداول `users`, `medical_profiles`, `emergency_contacts`, `emergency_types`, `incidents`, `incident_status_history`, `triage_assessments`, `volunteer_profiles`, `volunteer_responses`, `hospitals`, `ambulances`, `aed_devices`, `training_courses`, `training_lessons`, `training_results`, `notifications`, `audit_logs`.
   - إنشاء الفهارس المكانية `GIST` على حقول المواقع الجغرافية `location GEOGRAPHY(POINT, 4326)`.
2. **`V2__reference_data.sql`:**
   - بذر البيانات المرجعية الأساسية: أنواع الطوارئ (حالات قلبية، حوادث سير، حروق، نزيف، كسور)، وبيانات مستشفيات تجريبية، وأجهزة AED معتمدة.
3. **`V3__volunteer_response_workflow.sql`:**
   - توسيع دورة عمل المتطوع لدعم أوقات الوصول (`arrived_at`) وإتمام المهمة (`completed_at`).
4. **`V4__align_emergency_response_eta_type.sql`:**
   - مواءمة دقة حساب زمن الوصول التقديري (ETA) بنوع بيانات رقمي دقيق.
5. **`V5__align_hospital_congestion_type.sql`:**
   - مواءمة معدلات ازدحام المستشفيات لتكون قيماً عشرية موحدة بين 0.0 و 1.0.
6. **`V6__account_registration_paths.sql`:**
   - إضافة مسارات ومحددات التحقق لتسجيل حسابات المتطوعين والمستشفيات من شاشات التسجيل المباشرة.
7. **`V7__incident_idempotency.sql`:**
   - إضافة قيود التحقق والفهارس الخاصة بـ `idempotency_key` لمنع تكرار البلاغات نهائياً.

---

## 7. الخوارزميات والنماذج الرياضية الذكية المطبقة (Algorithms & Mathematical Models)

### أ. خوارزمية التقييم والمفاضلة الذكية للمستشفيات (Smart ER Recommendation Formula):
تقوم الخوارزمية باختيار المستشفى الأنسب عبر ضرب الدرجات الفرعية في أوزانها المعتمدة وتوليد مجموع من 100:

$$\text{Final Score} = (0.30 \times S_{\text{ETA}}) + (0.30 \times S_{\text{Cap}}) + (0.25 \times S_{\text{Spec}}) + (0.15 \times S_{\text{Cong}})$$

حيث:
- $S_{\text{ETA}}$: درجة زمن الوصول؛ كلما قل الوقت زادت الدرجة:
  $$S_{\text{ETA}} = \max\left(0, 100 - \left(\frac{\text{ETA in minutes}}{60} \times 100\right)\right)$$
- $S_{\text{Cap}}$: درجة جاهزية أسرّة العناية المركزة والفرز (من 0 إلى 100).
- $S_{\text{Spec}}$: درجة التطابق التخصصي (100 إذا كان المستشفى متخصصاً في نوع الإصابة، 40 إذا كان مستشفى عاماً).
- $S_{\text{Cong}}$: درجة الازدحام المعكوسة:
  $$S_{\text{Cong}} = (1.0 - \text{Congestion Rate}) \times 100$$

### ب. خوارزمية الفرز والتوزيع المكاني للمتطوعين (Smart Dispatching):
- يتم استعلام قاعدة البيانات باستخدام دالة PostGIS المكانية:
  `ST_DWithin(volunteer_location, incident_location, 5000)` (بحث دائري في نطاق 5000 متر).
- تطبيق قفل التنافس المتزامن:
  ```sql
  SELECT * FROM incidents WHERE id = :id FOR UPDATE;
  ```
  يضمن هذا القفل أن أول متطوع ينقر "قبول" يفوز بالمهمة، بينما يظهر للمتطوعين الآخرين فوراً "تم قبول البلاغ بواسطة مسعف آخر".

### ج. خوارزمية تدوير الجلسات وحماية التوكنات (Session Rotation):
- إصدار Access Token مدته **15 دقيقة فقط**.
- إصدار Refresh Token مدته **14 يوماً** يتم تشفيره في قاعدة البيانات بخوارزمية **SHA-256**.
- عند استخدام الـ Refresh Token لتجديد الجلسة، يتم إبطال التوكن القديم فوراً وتوليد توكن جديد وحفظه؛ وإذا حاول أي مخترق استخدام التوكن القديم المستهلك، يقوم السيرفر بكشف الهجوم وإبطال كل جلسات المستخدم حمايةً لحسابه.

---

## 8. هندسة تطبيق الفلاتر والواجهات (Flutter Mobile & Web Architecture)

تم تنظيم كود الفلاتر بنمط **Feature-First Architecture** داخل المجلد [`mobile/lib/features/`](file:///d:/hamo/Projects/SmartAid/mobile/lib/features):

```text
mobile/lib/
├── core/                         # البنية التحتية الأساسية
│   ├── config/app_config.dart    # إدارة عناوين الـ API تلقائياً
│   ├── localization/             # محرك الترجمة والقواميس (عربي/إنجليزي)
│   ├── network/api_client.dart   # عميل Dio ومصادقة التوكنات
│   ├── storage/token_store.dart  # مخزن التوكنات فائق السرعة بالذاكرة
│   └── theme/app_theme.dart      # نظام الألوان والسمات البصرية
│
├── features/                     # ميزات ووحدات النظام المنفصلة
│   ├── admin/                    # لوحات المدير ومراقبة النظام
│   ├── analytics/                # الرسوم البيانية وأبحاث Smart ER
│   ├── auth/                     # شاشات الدخول والتسجيل وإدارة الجلسات
│   ├── disaster/                 # نمط الكوارث والحوادث الجماعية
│   ├── emergency/                # أوراق الفرز، تأكيد SOS، والمتابعة الحية
│   ├── ems/                      # لوحة عمليات الإسعاف وترشيح المستشفيات
│   ├── home/                     # الشاشة الرئيسية وأزرار الاستغاثة
│   ├── incidents/                # سجل البلاغات والتاريخ والمراحل
│   ├── notifications/            # صندوق الإشعارات المباشرة
│   ├── onboarding/               # شاشات الترحيب والتعريف بالنظام
│   ├── profile/                  # الملف الطبي وجهات الاتصال والإعدادات
│   ├── resources/                # دليل المستشفيات وأجهزة الصدمات والإسعاف
│   ├── splash/                   # شاشة البداية الذكية
│   ├── training/                 # الدورات التعليمية والاختبارات
│   └── volunteer/                # لوحة المتطوع وخريطة البلاغات والمهام
│
└── shared/widgets/               # المكونات القابلة لإعادة الاستخدام
    ├── app_widgets.dart          # كروت وبطاقات العرض الموحدة
    ├── language_toggle_button.dart# زر التبديل الفوري بين اللغتين
    ├── pulsing_sos_button.dart   # زر الاستغاثة النبضي ذو الموجات الرادارية
    └── quick_role_switcher.dart  # محول الحسابات السريع للمعاينة
```

### نظام الألوان والتصميم (Design System):
- **الأزرق الداكن (`navyBlue: #0A2540`):** يعكس الثقة والاحترافية الطبية.
- **الأحمر الإسعافي (`emergencyRed: #D92D20`):** مخصص لأزرار وحالات الطوارئ الحرجة.
- **الأزرق السماوي (`sky: #0BA5EC`):** للأيقونات والمعلومات الطبية.
- **الأخضر (`success: #12B76A`):** للحالات المستقرة واكتمال المهام.
- **البرتقالي التحذيري (`warning: #F79009`):** للبلاغات المتوسطة والجهات الأساسية.
- **التوافق التام مع إمكانية الوصول (WCAG AAA):** تباين عالي للنصوص والأيقونات لتسهيل الرؤية في ضوء الشمس وأثناء الأزمات.

---

## 9. التفاصيل الدقيقة لحل مشكلة بطء الـ APK وضغط حجمه (Performance & Optimization Deep Dive)

واجه التطبيق في البداية ثقلاً ملحوظاً في التحميل داخل ملف الـ APK عند فتح:
1. **الملف الطبي (Medical Profile).**
2. **جهات اتصال الطوارئ (Emergency Contacts).**
3. **الإشعارات (Notifications).**

### التحليل الجذري للمشكلة (Root Cause Analysis):
1. **مسح البيانات المتكرر (`autoDispose`):** كانت المزودات معرفة بـ `FutureProvider.autoDispose`، مما يدفع فلاتر لمسح البيانات فور الخروج من الصفحة، وعند العودة يتم الدخول في دائرة تحميل بيضاء وطلب البيانات مجدداً عبر شبكة الواي فاي.
2. **إعادة بناء الصفحة بالكامل (`ref.invalidate`):** عند النقر على إشعار لجعله مقروءاً، كان الكود يستدعي `ref.invalidate`، فيمسح القائمة بالكامل وتظهر دائرة تحميل.
3. **بطء قراءة التوكن من الـ Android KeyStore:** كان عميل Dio يستدعي `readAccess()` في كل ريكوست منفرد، والتي تقوم بفك تشفير المفاتيح عبر Android KeyStore في كل مرة، مما يستهلك من 50 إلى 200 ميلي ثانية لكل طلب على الهاتف.
4. **حجم الـ APK ونمط الـ Debug (192MB):** كان الملف يُبنى بنمط الـ Debug الذي يعمل بمحرك JIT البطيء بدلاً من الترجمة المباشرة للمعالج AOT.

### الحلول الهندسية التي تم تطبيقها بالفعل:
1. **الترقية إلى `AsyncNotifier` بكاش دائم:**
   - تحويل `medicalProfileProvider`, `emergencyContactsProvider`, و `notificationsProvider` إلى Notifiers تحفظ البيانات في الذاكرة الحية.
2. **التحديث المحلي اللحظي (Optimistic UI Updates):**
   - عند الضغط على إشعار، يتم تحديث القائمة فورياً في الذاكرة وتختفي النقطة الزرقاء بـ 0 ثانية، وتتم المزامنة مع السيرفر في الخلفية دون أي وميض.
   - عند إضافة أو تعديل أو حذف جهة اتصال، يتم تحديث المصفوفة محلياً دون مسح الشاشة.
3. **In-Memory Token Cache داخل `TokenStore`:**
   - قراءة التوكن من القرص مرة واحدة فقط عند بدء التطبيق ثم حفظه في متغير بالذاكرة (`_cachedAccess`)، ليتم إرفاقه في 0 ميلي ثانية مع كل طلب.
4. **تفعيل الـ Keep-Alive في Dio:**
   - إضافة `'Connection': 'keep-alive'` ومهل زمنية مدروسة لمنع إعادة بناء قنوات الـ TCP مع السيرفر في كل طلب.
5. **حل مشكلة R8 ProGuard:**
   - إضافة `-dontwarn com.google.android.play.core.**` في ملف `proguard-rules.pro`.
6. **بناء نسخة Release AOT مضغوطة:**
   - تقليص حجم الـ APK بنسبة تتجاوز **70%** ليصبح **56.6 ميجابايت** بدلاً من **192 ميجابايت**.

---

## 10. الأمان، الخصوصية وسجلات التدقيق (Security, RBAC & Immutable Audit Logs)

* **تشفير كلمات المرور:** استخدام خوارزمية التشفير المتكيفة **BCrypt** بقوة تعقيد عالية.
* **حماية مسارات الدخول (Brute-Force & Rate Limiting):** مرشح أمني مخصص [`AuthRateLimitFilter.java`](file:///d:/hamo/Projects/SmartAid/backend/src/main/java/com/smartaid/platform/security/AuthRateLimitFilter.java) يمنع الهجمات الآلية على واجهات الدخول والتسجيل.
* **التحكم في الوصول حسب الدور (RBAC):** استخدام تعليقات `@PreAuthorize("hasRole('EMS')")` و `@PreAuthorize("hasRole('ADMIN')")` لمنع أي مستخدم عادي من الوصول لبيانات أو عمليات حساسة.
* **سجل التدقيق غير القابل للتلاعب (Immutable Audit Trail):**
  - كل قراءة للملف الطبي يتم تسجيلها (`MEDICAL_PROFILE_ACCESSED`).
  - كل تعديل لجهات الاتصال يتم توثيقه (`EMERGENCY_CONTACT_UPDATED`).
  - كل بلاغ أو إلغاء يتم تسجيله مع الـ Trace ID و User ID والوقت الدقيق.

---

## 11. دليل السكربتات وأوامر التشغيل والاختبار الكاملة (Scripts & Tooling Reference)

يحتوي مجلد [`scripts/`](file:///d:/hamo/Projects/SmartAid/scripts) ومجلد المشروع على مجموعة من الأدوات البرمجية الجاهزة:

| الملف / السكربت | الوظيفة | أمر التشغيل في PowerShell |
| :--- | :--- | :--- |
| [`run-smartaid.ps1`](file:///d:/hamo/Projects/SmartAid/run-smartaid.ps1) | تشغيل النظام كاملاً (قاعدة البيانات + السيرفر + الويب) بضغطة زر واحدة | `.\run-smartaid.ps1` |
| [`build-android-release.ps1`](file:///d:/hamo/Projects/SmartAid/scripts/build-android-release.ps1) | بناء نسخة Release APK فائقة السرعة ومضغوطة (56.6MB) | `.\scripts\build-android-release.ps1` |
| [`build-android-debug.ps1`](file:///d:/hamo/Projects/SmartAid/scripts/build-android-debug.ps1) | بناء نسخة Debug APK للمطورين | `.\scripts\build-android-debug.ps1` |
| [`test-end-to-end.ps1`](file:///d:/hamo/Projects/SmartAid/scripts/test-end-to-end.ps1) | تشغيل اختبار شامل مؤتمت لكل مراحل النظام الحية | `.\scripts\test-end-to-end.ps1` |
| [`verify-all.ps1`](file:///d:/hamo/Projects/SmartAid/scripts/verify-all.ps1) | فحص الجودة الشامل (اختبارات الباك إند + اختبارات فلاتر) | `.\scripts\verify-all.ps1` |
| [`start-demo.ps1`](file:///d:/hamo/Projects/SmartAid/scripts/start-demo.ps1) | بدء سيناريو العرض التقديمي مع بذر الحسابات التجريبية | `.\scripts\start-demo.ps1` |
| [`cleanup-e2e.ps1`](file:///d:/hamo/Projects/SmartAid/scripts/cleanup-e2e.ps1) | تنظيف وإلغاء بلاغات الاختبار التجريبية من قاعدة البيانات | `.\scripts\cleanup-e2e.ps1` |
| [`open-pgadmin.bat`](file:///d:/hamo/Projects/SmartAid/open-pgadmin.bat) | فتح لوحة تحكم قاعدة البيانات pgAdmin مباشرة | `.\open-pgadmin.bat` |
| [`view-db.bat`](file:///d:/hamo/Projects/SmartAid/view-db.bat) | استعراض سريع لجداول وسجلات قاعدة البيانات من الطرفية | `.\view-db.bat` |

---

## 12. رحلة الاستخدام العملية للأدوار الأربعة (End-to-End User Journeys)

### بيانات الحسابات المعتمدة للعرض التجريبي:
* **كلمة المرور الموحدة لجميع الحسابات:** `SmartAidDemo2026!`
* **1. المواطن:** `demo.user@smartaid.local`
* **2. المتطوع:** `demo.volunteer@smartaid.local`
* **3. ضابط الإسعاف:** `demo.ems@smartaid.local`
* **4. مدير النظام:** `demo.admin@smartaid.local`

*(ملاحظة: يمكنك التبديل الفوري بين هذه الحسابات من داخل التطبيق في أي وقت عبر الضغط على أيقونة التبديل `⇄` في الشريط العلوي)*

---

## 13. مصفوفة الجودة ونتائج الفحص والتحليل (QA & Test Execution Matrix)

تم إخضاع المشروع بالكامل لاختبارات صارمة وأظهرت النتائج الآتي:

1. **اختبارات تطبيق الفلاتر (Flutter Test Suite):**
   - **عدد الاختبارات:** **54 اختباراً كاملاً**.
   - **النتيجة:** **اجتياز بنسبة 100% (`00:07 +54: All tests passed!`)**.
   - **التغطية:** اختبارات التوافق مع الشاشات المختلفة (Compact Phone, Tall Phone, Landscape, Tablet)، اختبارات التباين وإمكانية الوصول (Accessibility & Large Fonts)، اختبارات اللغتين (Arabic RTL & English LTR)، واختبارات نماذج الملف الطبي والإشعارات.

2. **تحليل الأكواد الثابت (Dart Static Analysis):**
   - **الأمر:** `dart analyze lib`
   - **النتيجة:** **`No issues found!`** (كود نظيف تماماً وخالٍ من أي تحذيرات أو أخطاء).

3. **اختبارات خادم السبرينج بوت (Backend Test Suite):**
   - **عدد الاختبارات:** **20 اختباراً لوحدات النظام**.
   - **النتيجة:** **اجتياز كامل بنسبة 100%** لقواعد انتقالات الحالة، والتوزيع المكاني، وخوارزمية Smart ER.

---

## الخلاصة النهائية للمشروع

مشروع **Smart Aid V1** أصبح الآن منصة طوارئ متكاملة، جاهزة للعرض والاختبار الميداني:
- **معمارية هندسية رصينة ونظيفة.**
- **توثيق وافٍ ودقيق لكل جزء صغير وكبير.**
- **ملف APK خفيف وسريع (56.6MB) يعمل بكفاءة وسلاسة تامة مثل الويب.**
- **بيئة عمل محلية مستقلة ومكتملة تعمل بضغطة زر واحدة.**
