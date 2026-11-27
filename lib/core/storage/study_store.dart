import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../features/accounts/models.dart';
import '../../features/feed/models.dart';

class StudyStore {
  static late Box subjects;
  static late Box posts;
  static late Box settings;
  static const _uuid = Uuid();

  static Future<void> initialize() async {
    subjects = await Hive.openBox('subjects');
    posts = await Hive.openBox('posts');
    settings = await Hive.openBox('settings');
    if (subjects.isEmpty) {
      final physics = Subject.sample(id: 'physics', name: 'Physics', handle: '@physics_101', tint: 0xFF9B8CFF);
      final chemistry = Subject.sample(id: 'organic', name: 'Organic Chemistry', handle: '@organic.notes', tint: 0xFFFF86B5);
      await subjects.put(physics.id, physics.toMap());
      await subjects.put(chemistry.id, chemistry.toMap());
      await posts.put('sample-physics', StudyPost.samplePhysics().toMap());
      await posts.put('sample-chemistry', StudyPost.sampleChemistry().toMap());
    }
  }

  static List<Subject> get allSubjects => subjects.values.map((e) => Subject.fromMap(Map<String, dynamic>.from(e))).toList();
  static List<StudyPost> get allPosts => posts.values.map((e) => StudyPost.fromMap(Map<String, dynamic>.from(e))).toList();
  static List<StudyPost> postsFor(String subjectId) => allPosts.where((p) => p.subjectId == subjectId).toList()
    ..sort((a,b) => b.createdAt.compareTo(a.createdAt));

  static Future<void> saveSubject(Subject subject) => subjects.put(subject.id, subject.toMap());
  static Future<void> savePost(StudyPost post) => posts.put(post.id, post.toMap());
  static Future<void> toggleSaved(StudyPost post) => savePost(post.copyWith(saved: !post.saved));
  static Future<void> toggleMastered(StudyPost post) => savePost(post.copyWith(mastered: !post.mastered));
  static String newId() => _uuid.v4();
}
