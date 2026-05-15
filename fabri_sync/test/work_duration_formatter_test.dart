import 'package:fabri_sync/utils/work_duration_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatWorkDuration', () {
    test('formats hours under one working day', () {
      expect(formatWorkDuration(0), '0 hrs');
      expect(formatWorkDuration(5.2), '5.2 hrs');
      expect(formatWorkDuration(7.8), '7.8 hrs');
    });

    test('formats exact working days', () {
      expect(formatWorkDuration(8), '1 day');
      expect(formatWorkDuration(16), '2 days');
      expect(formatWorkDuration(24), '3 days');
    });

    test('formats working days with remaining hours', () {
      expect(formatWorkDuration(10.1), '1 day 2.1 hrs');
      expect(formatWorkDuration(14.3), '1 day 6.3 hrs');
      expect(formatWorkDuration(18.1), '2 days 2.1 hrs');
    });

    test('uses singular hour label', () {
      expect(formatWorkDuration(1), '1 hr');
      expect(formatWorkDuration(9), '1 day 1 hr');
    });
  });
}
