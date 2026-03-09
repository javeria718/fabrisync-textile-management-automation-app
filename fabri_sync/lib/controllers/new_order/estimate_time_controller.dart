import 'package:flutter/foundation.dart';
import 'package:fabri_sync/services/new_order_service.dart';

class EstimateTimeController extends ChangeNotifier {
  EstimateTimeController({NewOrderService? service})
      : _service = service ?? NewOrderService();

  final NewOrderService _service;

  double estimatedTime = 0;
  bool hasCalculated = false;
  bool isCardTapped = false;
  int totalDays = 0;
  double totalProjectHours = 0;
  Map<String, double> estimatedDeptHours = {};

  Future<bool> calculateTime(double qty) async {
    if (qty <= 0) return false;

    try {
      final response = await _service.fetchTimeConfig();
      if (response.isEmpty) {
        throw Exception('No time config found');
      }

      final Map<String, double> deptHours = {};
      double totalHours = 0;

      for (final row in response) {
        final dept = (row['department'] ?? 'UNKNOWN').toString();
        final num hoursNum =
            row['estimated_hours'] is num ? row['estimated_hours'] : 0;
        final hoursPerUnit = hoursNum.toDouble();
        final deptTotal = qty * hoursPerUnit;

        deptHours[dept] = deptTotal;
        totalHours += deptTotal;
      }

      final duration = calculateProjectDuration(totalHours);

      estimatedDeptHours = deptHours;
      totalProjectHours = totalHours;
      totalDays = duration['days'] as int;
      estimatedTime = totalHours;
      hasCalculated = true;
      isCardTapped = true;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> calculateProjectDuration(double totalHours) {
    const double workHoursPerDay = 8.0;

    final totalDays = (totalHours / workHoursPerDay).ceil();
    final remainingHours = totalHours % workHoursPerDay;

    return {
      'days': totalDays,
      'hours': totalHours,
      'remainingHours': remainingHours.round(),
    };
  }
}
