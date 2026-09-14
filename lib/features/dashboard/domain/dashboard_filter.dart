class DashboardFilter {
  const DashboardFilter({
    this.period = 'today',
    this.startDate,
    this.endDate,
    this.userId,
  });

  final String period;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? userId;

  Map<String, dynamic> get queryParameters => {
    'period': period,
    if (period == 'custom' && startDate != null)
      'start_date': _date(startDate!),
    if (period == 'custom' && endDate != null) 'end_date': _date(endDate!),
    if (userId != null) 'user': userId,
  };

  static String _date(DateTime value) =>
      value.toIso8601String().substring(0, 10);
}
