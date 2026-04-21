class HelpContent {
  const HelpContent({
    required this.title,
    required this.summary,
    required this.steps,
    this.tips = const <String>[],
    this.warnings = const <String>[],
  });

  final String title;
  final String summary;
  final List<String> steps;
  final List<String> tips;
  final List<String> warnings;
}
