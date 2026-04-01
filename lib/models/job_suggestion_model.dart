class JobSuggestionModel {
  final String title;
  final String company;
  final String location;
  final int matchScore;
  final String salary;
  final String type;
  final String level;
  final String aiExplanation;
  final List<String> requirements;
  bool isBookmarked;

  JobSuggestionModel({
    required this.title,
    required this.company,
    required this.location,
    required this.matchScore,
    required this.salary,
    required this.type,
    required this.level,
    required this.aiExplanation,
    required this.requirements,
    this.isBookmarked = false,
  });
}
