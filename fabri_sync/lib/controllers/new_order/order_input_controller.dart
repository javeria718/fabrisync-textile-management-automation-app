import 'package:fabri_sync/Model/orderModel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class OrderInputController extends ChangeNotifier {
  final TextEditingController quantityCtrl = TextEditingController();
  final TextEditingController materialCostCtrl = TextEditingController();

  void initFromOrder(OrderModel? existingOrder) {
    if (existingOrder != null) {
      quantityCtrl.text = existingOrder.quantity.toString();
    }
  }

  bool validateInputs() {
    return quantityCtrl.text.isNotEmpty && materialCostCtrl.text.isNotEmpty;
  }

  @override
  void dispose() {
    quantityCtrl.dispose();
    materialCostCtrl.dispose();
    super.dispose();
  }
}
