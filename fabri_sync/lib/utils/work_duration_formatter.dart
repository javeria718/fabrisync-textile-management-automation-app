String formatWorkDuration(num totalHours) {
  if (totalHours <= 0) return '0 hrs';

  final roundedHours = double.parse(totalHours.toStringAsFixed(1));
  final days = roundedHours ~/ 8;
  final remainingHours = double.parse(
    (roundedHours - (days * 8)).toStringAsFixed(1),
  );

  String formatNumber(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  if (days == 0) {
    return '${formatNumber(remainingHours)} '
        '${remainingHours == 1 ? 'hr' : 'hrs'}';
  }

  final dayText = '$days ${days == 1 ? 'day' : 'days'}';

  if (remainingHours <= 0) {
    return dayText;
  }

  final hourText = '${formatNumber(remainingHours)} '
      '${remainingHours == 1 ? 'hr' : 'hrs'}';
  return '$dayText $hourText';
}
