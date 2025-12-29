class MigrationConfig {
  final String dateField;
  final String dateLabel;
  final List<String> columns;
  final Map<String, String> columnLabels;

  MigrationConfig({
    required this.dateField,
    required this.dateLabel,
    required this.columns,
    required this.columnLabels,
  });
}
