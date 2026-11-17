import 'package:shared_preferences/shared_preferences.dart';

import '../../Domain/model/Dream/dreams_model.dart';
import '../../Domain/model/Quiz/answer_model.dart';
import '../../Domain/model/Quiz/submission_model.dart';
import '../../Domain/model/User/user_model.dart';
import '../../main.dart' as globals;

/// The dev tools' data actions on the app's local storage.
abstract final class DevData {
  // The keys `SharedPreferencesStorage` and `QuestionRepository` use.
  static const _kUser = 'user';
  static const _kDreams = 'userDreams';
  static const _kSubmissions = 'submissions';

  /// A user (kept if there is one), a finished quiz leaning towards tech,
  /// and three dreams.
  static Future<void> seed() async {
    final user =
        await globals.userService.getUser() ?? User(name: 'Sokha');
    await globals.userService.saveUser(user);

    final options = await globals.questionService.getOptionsByQuestion();
    final answers = [
      for (final entry in options.entries)
        if (entry.value.isNotEmpty)
          Answer(
            questionId: entry.key,
            selectedOptionId: entry.value.first.id,
          ),
    ];
    await globals.questionService.saveSubmission(
      Submission(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id ?? '',
        answers: answers,
        completedAt: DateTime.now(),
      ),
    );

    await clearDreams();
    final now = DateTime.now();
    for (final (i, (title, majorId)) in const [
      ('Build apps for Cambodia', '1'),
      ('Become a doctor', '24'),
      ('Design brands', '15'),
    ].indexed) {
      await globals.dreamService.saveDream(
        Dream(
          id: 'dev-dream-$i',
          userId: user.id ?? '',
          majorId: majorId,
          title: title,
          createdAt: now.subtract(Duration(days: 3 * i + 1)),
        ),
      );
    }
  }

  static Future<void> clearDreams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDreams);
  }

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in const [_kUser, _kDreams, _kSubmissions]) {
      await prefs.remove(key);
    }
  }
}
