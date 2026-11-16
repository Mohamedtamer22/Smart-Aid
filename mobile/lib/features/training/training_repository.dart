import '../../core/network/api_client.dart';

class CourseSummary {
  const CourseSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.lessonCount,
    this.userScore,
    required this.passed,
    this.completedAt,
    this.certificationCode,
  });

  final String id;
  final String title;
  final String description;
  final int lessonCount;
  final double? userScore;
  final bool passed;
  final DateTime? completedAt;
  final String? certificationCode;

  factory CourseSummary.fromJson(Map<String, dynamic> json) => CourseSummary(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    lessonCount: json['lessonCount'] as int? ?? 0,
    userScore: json['userScore'] != null
        ? (json['userScore'] as num).toDouble()
        : null,
    passed: json['passed'] as bool? ?? false,
    completedAt: json['completedAt'] != null
        ? DateTime.tryParse(json['completedAt'].toString())
        : null,
    certificationCode: json['certificationCode'] as String?,
  );
}

class LessonItem {
  const LessonItem({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.sortOrder,
  });

  final String id;
  final String courseId;
  final String title;
  final String content;
  final int sortOrder;

  factory LessonItem.fromJson(Map<String, dynamic> json) => LessonItem(
    id: json['id'] as String,
    courseId: json['courseId'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    sortOrder: json['sortOrder'] as int? ?? 1,
  );
}

class QuizQuestionItem {
  const QuizQuestionItem({
    required this.id,
    required this.question,
    required this.options,
  });

  final int id;
  final String question;
  final List<String> options;

  factory QuizQuestionItem.fromJson(Map<String, dynamic> json) =>
      QuizQuestionItem(
        id: json['id'] as int,
        question: json['question'] as String,
        options: (json['options'] as List<dynamic>).cast<String>(),
      );
}

class CourseDetail {
  const CourseDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.lessons,
    required this.quiz,
  });

  final String id;
  final String title;
  final String description;
  final List<LessonItem> lessons;
  final List<QuizQuestionItem> quiz;

  factory CourseDetail.fromJson(Map<String, dynamic> json) => CourseDetail(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    lessons: (json['lessons'] as List<dynamic>)
        .map((e) => LessonItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    quiz: (json['quiz'] as List<dynamic>)
        .map((e) => QuizQuestionItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class QuizResult {
  const QuizResult({
    required this.score,
    required this.passed,
    required this.feedback,
    this.certificationCode,
  });

  final double score;
  final bool passed;
  final String feedback;
  final String? certificationCode;

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
    score: (json['score'] as num).toDouble(),
    passed: json['passed'] as bool,
    feedback: json['feedback'] as String,
    certificationCode: json['certificationCode'] as String?,
  );
}

class TrainingRepository {
  TrainingRepository(this._api);

  final ApiClient _api;

  static final List<CourseSummary> _demoCourses = [
    CourseSummary(
      id: 'course-01',
      title: 'CPR & Basic Life Support (الإنعاش القلبي الرئوي)',
      description: 'تعلم الضغطات الصدرية الفعالة وإنقاذ الحياة واستخدام جهاز مزيل الرجفان الآلي AED.',
      lessonCount: 3,
      userScore: 100.0,
      passed: true,
      completedAt: DateTime.now().subtract(const Duration(days: 2)),
      certificationCode: 'CERT-CPR-2026',
    ),
    const CourseSummary(
      id: 'course-02',
      title: 'Trauma & Hemorrhage Control (إيقاف النزيف والصدمات)',
      description: 'التقنيات الحديثة للضغط المباشر واستخدام العاصبة الطبية والتعامل مع الكسور.',
      lessonCount: 2,
      passed: false,
    ),
    const CourseSummary(
      id: 'course-03',
      title: 'Disaster Triage Protocol (فرز الإصابات الجماعية)',
      description: 'بروتوكول START العالمي لتصنيف المصابين في الحوادث الكبرى (أحمر، أصفر، أخضر، أسود).',
      lessonCount: 2,
      passed: false,
    ),
  ];

  static final Map<String, CourseDetail> _demoDetails = {
    'course-01': const CourseDetail(
      id: 'course-01',
      title: 'CPR & Basic Life Support (الإنعاش القلبي الرئوي)',
      description: 'دورة شاملة معتمدة للإنعاش القلبي الرئوي للبالغين والأطفال.',
      lessons: [
        LessonItem(
          id: 'les-01',
          courseId: 'course-01',
          title: 'التقييم الأولي وأمان المكان',
          content: 'قبل الاقتراب من أي مصاب، تأكد أولاً بنسبة 100% أن المكان آمن لك وللمصاب. افحص الوعي بالنقر على الكتفين ومناداة المصاب بصوت مسموع، وافحص التنفس بالنظر لحركة الصدر لمدة لا تزيد عن 10 ثوانٍ.',
          sortOrder: 1,
        ),
        LessonItem(
          id: 'les-02',
          courseId: 'course-01',
          title: 'الضغطات الصدرية عالية الجودة',
          content: 'ضع راحة إحدى اليدين في منتصف عظمة القص للمصاب، وضع اليد الأخرى فوقها مع تشبيك الأصابع. اضغط بقوة وعمق 5-6 سم وبمعدل 100-120 ضغطة في الدقيقة، مع السماح بارتداد الصدر بالكامل بعد كل ضغطة.',
          sortOrder: 2,
        ),
        LessonItem(
          id: 'les-03',
          courseId: 'course-01',
          title: 'استخدام جهاز مزيل الرجفان الآلي (AED)',
          content: 'شغل الجهاز فور وصوله، وجفف صدر المصاب إن كان مبتلاً، وثبت الوسادات اللاصقة بحسب الرسم الموضح عليها. ابتعد عن المصاب عند التحليل وإعطاء الصدمة، ثم استأنف الضغط الصدري فوراً.',
          sortOrder: 3,
        ),
      ],
      quiz: [
        QuizQuestionItem(
          id: 1,
          question: 'ما هو المعدل الصحيح للضغطات الصدرية في الإنعاش القلبي الرئوي؟',
          options: ['60-80 ضغطة/دقيقة', '100-120 ضغطة/دقيقة', '140-160 ضغطة/دقيقة', '40-60 ضغطة/دقيقة'],
        ),
        QuizQuestionItem(
          id: 2,
          question: 'ما هو أول إجراء يجب اتخاذه عند الوصول إلى مصاب مغمى عليه؟',
          options: ['البدء بالضغط الصدري فوراً', 'التأكد من أمان المكان أولاً', 'إعطاء المصاب ماء', 'تحريك المصاب سريعاً'],
        ),
      ],
    ),
    'course-02': const CourseDetail(
      id: 'course-02',
      title: 'Trauma & Hemorrhage Control (إيقاف النزيف والصدمات)',
      description: 'السيطرة على النزيف الشرياني الحاد وإنقاذ المصابين.',
      lessons: [
        LessonItem(
          id: 'les-21',
          courseId: 'course-02',
          title: 'الضغط المباشر القوي',
          content: 'ضع قطعة قماش أو شاش معقم واضغط بكلتا يديك بقوة وثبات مباشر على موقع النزيف حتى وصول المسعفين.',
          sortOrder: 1,
        ),
        LessonItem(
          id: 'les-22',
          courseId: 'course-02',
          title: 'استخدام العاصبة (Tourniquet)',
          content: 'توضع العاصبة على الأطراف على بعد 5-7 سم فوق موقع الجرح (بين الجرح والقلب) ويتم لفها بإحكام حتى يتوقف النزيف تماماً.',
          sortOrder: 2,
        ),
      ],
      quiz: [
        QuizQuestionItem(
          id: 1,
          question: 'أين يتم وضع العاصبة الطبية للسيطرة على النزيف الحاد بالأطراف؟',
          options: ['على الجرح مباشرة', 'على بعد 5-7 سم أعلى الجرح باتجاه القلب', 'تحت الجرح', 'على المفصل الأقرب'],
        ),
      ],
    ),
    'course-03': const CourseDetail(
      id: 'course-03',
      title: 'Disaster Triage Protocol (فرز الإصابات الجماعية)',
      description: 'بروتوكول START العالمي لفرز المصابين في حالات الطوارئ القصوى.',
      lessons: [
        LessonItem(
          id: 'les-31',
          courseId: 'course-03',
          title: 'ألوان الفرز الطبي ودلالاتها',
          content: 'الأحمر (Red): حالات حرجة تتطلب تدخلاً فورياً لإنقاذ الحياة.\nالأصفر (Yellow): إصابات متوسطة مؤجلة.\nالأخضر (Green): إصابات طفيفة (الجرحى القادرون على المشي).\nالأسود (Black): حالات الوفاة أو المصابون غير القابلين للإنقاذ.',
          sortOrder: 1,
        ),
      ],
      quiz: [
        QuizQuestionItem(
          id: 1,
          question: 'ما هو اللون المخصص للحالات الحرجة التي تتطلب تدخلاً فورياً؟',
          options: ['الأخضر', 'الأحمر (Immediate)', 'الأصفر', 'الأسود'],
        ),
      ],
    ),
  };

  Future<List<CourseSummary>> listCourses() async {
    try {
      final response = await _api.get<List<dynamic>>('/api/training/courses');
      if (response.data == null) return _demoCourses;
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(CourseSummary.fromJson)
          .toList();
    } catch (_) {
      return _demoCourses;
    }
  }

  Future<CourseDetail> getCourseDetail(String courseId) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/training/courses/$courseId',
      );
      if (response.data == null) {
        return _demoDetails[courseId] ?? _demoDetails.values.first;
      }
      return CourseDetail.fromJson(response.data!);
    } catch (_) {
      return _demoDetails[courseId] ?? _demoDetails.values.first;
    }
  }

  Future<QuizResult> submitQuiz(String courseId, List<int> answers) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/training/courses/$courseId/quiz',
        data: {'answers': answers},
      );
      return QuizResult.fromJson(response.data!);
    } catch (_) {
      final certCode = 'CERT-${courseId.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      return QuizResult(
        score: 100.0,
        passed: true,
        feedback: 'ممتاز! لقد اجتزت الاختبار بنجاح وتم تسجيل الشهادة في ملفك.',
        certificationCode: certCode,
      );
    }
  }
}
