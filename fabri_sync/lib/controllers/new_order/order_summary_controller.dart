import 'package:flutter/foundation.dart';
import 'package:fabri_sync/services/new_order_service.dart';

class OrderSummaryController extends ChangeNotifier {
  OrderSummaryController({NewOrderService? service})
      : _service = service ?? NewOrderService();

  final NewOrderService _service;

  Future<void> createOrder({
    required String orderId,
    required int quantity,
    required double estimatedTime,
    required double estimatedCost,
  }) async {
    await _service.createOrder(
      orderId: orderId,
      quantity: quantity,
      estimatedTime: estimatedTime,
      estimatedCost: estimatedCost,
    );
  }

  Future<void> updateOrder({
    required String orderId,
    required int quantity,
    required double estimatedTime,
    required double estimatedCost,
  }) async {
    await _service.updateOrder(
      orderId: orderId,
      quantity: quantity,
      estimatedTime: estimatedTime,
      estimatedCost: estimatedCost,
    );
  }
}
