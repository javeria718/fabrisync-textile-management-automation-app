import 'package:flutter/foundation.dart';
import 'package:fabri_sync/services/new_order_service.dart';

class EstimateCostController extends ChangeNotifier {
  EstimateCostController({NewOrderService? service})
      : _service = service ?? NewOrderService();

  final NewOrderService _service;

  double estimatedCost = 0;
  double hourlyRate = 0;
  bool isLoadingRate = true;

  bool hasCalculated = false;
  bool isCardTapped = false;

  Future<bool> fetchHourlyRate() async {
    isLoadingRate = true;
    notifyListeners();

    final rate = await _service.fetchHourlyRate();
    if (rate == null) {
      isLoadingRate = true;
      notifyListeners();
      return false;
    }

    hourlyRate = rate;
    isLoadingRate = false;
    notifyListeners();
    return true;
  }

  void calculateCost({
    required double estimatedTime,
    required double qty,
    required double materialCost,
  }) {
    if (isLoadingRate) return;

    estimatedCost = (estimatedTime * hourlyRate) + (qty * materialCost);
    hasCalculated = true;
    isCardTapped = true;
    notifyListeners();
  }
}
