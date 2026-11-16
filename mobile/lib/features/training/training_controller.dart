import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import 'training_repository.dart';

final trainingRepositoryProvider = Provider<TrainingRepository>(
  (ref) => TrainingRepository(ref.read(apiClientProvider)),
);

final coursesListProvider = FutureProvider<List<CourseSummary>>(
  (ref) => ref.read(trainingRepositoryProvider).listCourses(),
);

final courseDetailProvider = FutureProvider.family<CourseDetail, String>((
  ref,
  courseId,
) {
  return ref.read(trainingRepositoryProvider).getCourseDetail(courseId);
});
