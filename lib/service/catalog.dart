import '../Domain/model/Career/career_major.dart';
import '../Domain/model/Career/career_model.dart';
import '../Domain/model/Category/category_model.dart';
import '../Domain/model/Major/major_model.dart';
import '../Domain/model/University/universityMajorDetail.dart';
import '../Domain/model/University/university_major.dart';
import '../Domain/model/University/university_model.dart';
import 'career_service.dart';
import 'major_service.dart';
import 'question_service.dart';
import 'university_service.dart';

/// Every piece of the app's static (bundled JSON) data, loaded once at
/// start-up through the services, with the lookups the screens need. Lets
/// a route open from just an ID (`/major/3`, `/career/8`), so deep links,
/// web refreshes and the dev tools' jumps all work.
class Catalog {
  Catalog._({
    required this.majors,
    required this.careers,
    required this.universities,
    required this.categories,
    required List<UniversityMajor> offerings,
    required List<CareerMajor> careerMajors,
    required Map<String, List<String>> related,
  }) : _offerings = offerings,
       _careerMajors = careerMajors,
       _related = related;

  static Future<Catalog> load({
    required MajorService majorService,
    required CareerService careerService,
    required UniversityService universityService,
    required QuestionService questionService,
  }) async {
    final results = await Future.wait([
      majorService.getMajorsData(),
      careerService.getCareersData(),
      universityService.getUniversitiesData(),
      questionService.getCategories(),
      universityService.getUniversityMajorsData(),
      careerService.getCareerMajorsData(),
      majorService.getMajorRelationships(),
    ]);
    return Catalog._(
      majors: results[0] as List<Major>,
      careers: results[1] as List<Career>,
      universities: results[2] as List<University>,
      categories: results[3] as List<Category>,
      offerings: results[4] as List<UniversityMajor>,
      careerMajors: results[5] as List<CareerMajor>,
      related: results[6] as Map<String, List<String>>,
    );
  }

  final List<Major> majors;
  final List<Career> careers;
  final List<University> universities;
  final List<Category> categories;
  final List<UniversityMajor> _offerings;
  final List<CareerMajor> _careerMajors;
  final Map<String, List<String>> _related;

  Major? major(String? id) => majors.where((m) => m.id == id).firstOrNull;
  Career? career(String? id) => careers.where((c) => c.id == id).firstOrNull;
  University? university(String? id) =>
      universities.where((u) => u.id == id).firstOrNull;
  Category? category(String? id) =>
      categories.where((c) => c.id == id).firstOrNull;

  List<Major> majorsIn(String categoryId) =>
      majors.where((m) => m.categoryId == categoryId).toList();

  List<Career> careersForMajor(String majorId) {
    final ids = {
      for (final cm in _careerMajors)
        if (cm.majorId == majorId) cm.careerId,
    };
    return careers.where((c) => ids.contains(c.id)).toList();
  }

  List<Major> majorsForCareer(String careerId) {
    final ids = {
      for (final cm in _careerMajors)
        if (cm.careerId == careerId) cm.majorId,
    };
    return majors.where((m) => ids.contains(m.id)).toList();
  }

  List<Major> relatedMajors(String majorId) {
    final ids = _related[majorId] ?? const [];
    return majors.where((m) => ids.contains(m.id)).toList();
  }

  /// Where [majorId] is taught: one entry per university, cheapest first.
  List<UniversityMajorDetail> offeringsOf(String majorId) => _details(
    _offerings.where((o) => o.majorId == majorId),
  )..sort((a, b) => a.universityMajor.pricePerYear.compareTo(
      b.universityMajor.pricePerYear,
    ));

  /// What [universityId] teaches, by major name.
  List<UniversityMajorDetail> offeringsAt(String universityId) => _details(
    _offerings.where((o) => o.universityId == universityId),
  )..sort((a, b) => a.major.name.compareTo(b.major.name));

  UniversityMajor? offering(String universityId, String majorId) => _offerings
      .where((o) => o.universityId == universityId && o.majorId == majorId)
      .firstOrNull;

  /// "$450 – $1,800 / yr", or null when nowhere teaches it.
  String? tuitionRange(String majorId) {
    final prices = [
      for (final o in _offerings)
        if (o.majorId == majorId) o.pricePerYear,
    ];
    if (prices.isEmpty) return null;
    prices.sort();
    final lo = formatUsd(prices.first);
    final hi = formatUsd(prices.last);
    return lo == hi ? '$lo / yr' : '$lo – $hi / yr';
  }

  int universityCount(String majorId) =>
      {for (final o in _offerings) if (o.majorId == majorId) o.universityId}
          .length;

  List<UniversityMajorDetail> _details(Iterable<UniversityMajor> offerings) => [
    for (final o in offerings)
      if ((university(o.universityId), major(o.majorId))
          case (final u?, final m?))
        UniversityMajorDetail(universityMajor: o, university: u, major: m),
  ];
}

/// "$1,250".
String formatUsd(num value) {
  final digits = value.round().toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return '\$$out';
}
