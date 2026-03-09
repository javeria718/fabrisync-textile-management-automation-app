import 'package:supabase_flutter/supabase_flutter.dart';

class NewOrderService {
  NewOrderService({SupabaseClient? client})
    : supabase = client ?? Supabase.instance.client;

  final SupabaseClient supabase;

  Future<double?> fetchHourlyRate() async {
    final response = await supabase
        .from('master_cost_config')
        .select('value')
        .eq('cost_type', 'hourly_rate')
        .maybeSingle();

    if (response == null) return null;
    final value = response['value'];
    if (value is num) return value.toDouble();
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchTimeConfig() async {
    final response = await supabase.from('master_time_config').select();
    return response;
  }

  Future<void> createOrder({
    required String orderId,
    required int quantity,
    required double estimatedTime,
    required double estimatedCost,
  }) async {
    await supabase.from('ordersmain').insert({
      'order_id': orderId,
      'quantity': quantity,
      'current_department': 'CUTTING',
      'status': 'pending',
      'estimated_total_time': estimatedTime,
      'estimated_total_cost': estimatedCost,
    });
  }

  Future<void> updateOrder({
    required String orderId,
    required int quantity,
    required double estimatedTime,
    required double estimatedCost,
  }) async {
    await supabase
        .from('ordersmain')
        .update({
          'quantity': quantity,
          'estimated_total_time': estimatedTime,
          'estimated_total_cost': estimatedCost,
        })
        .eq('order_id', orderId);
  }
}
