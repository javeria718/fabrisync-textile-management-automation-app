import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/services/order_calculation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DraftExpiryService {
  DraftExpiryService({
    SupabaseClient? client,
    OrderCalculationService? calculationService,
  }) : supabase = client ?? Supabase.instance.client,
       _calculationService =
           calculationService ?? OrderCalculationService(client: client);

  final SupabaseClient supabase;
  final OrderCalculationService _calculationService;

  bool isDraftCandidate(OrderModel order) {
    return order.status.toLowerCase() == 'draft';
  }

  bool isDraftExpired(OrderModel order) {
    if (!isDraftCandidate(order)) return false;
    if (order.isDraftExpired) return true;
    final expiresAt = order.draftExpiresAt;
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt);
  }

  Duration timeUntilExpiry(OrderModel order) {
    final expiresAt = order.draftExpiresAt;
    if (expiresAt == null) return Duration.zero;
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String draftStatusLabel(OrderModel order) {
    if (!isDraftCandidate(order)) return order.status;
    if (isDraftExpired(order)) return '🔴 Expired';

    final remaining = timeUntilExpiry(order);
    if (remaining <= const Duration(hours: 12)) {
      return '🟠 Draft • expires in ${_formatDuration(remaining)}';
    }

    if (remaining.inDays == 0) {
      return '🟡 Draft • expires today';
    }

    return '🟡 Draft • ${remaining.inDays} day${remaining.inDays > 1 ? 's' : ''} left';
  }

  bool isDraftEditable(OrderModel order) {
    return isDraftCandidate(order) && !isDraftExpired(order);
  }

  Future<bool> validateDraftExpiry(OrderModel order) async {
    if (!isDraftCandidate(order)) return false;
    if (!isDraftExpired(order)) return false;

    await supabase
        .from('ordersmain')
        .update({'is_draft_expired': true})
        .eq('order_id', order.orderId)
        .eq('status', 'draft');

    return true;
  }

  Future<void> refreshExpiredDrafts() async {
    await supabase
        .from('ordersmain')
        .update({'is_draft_expired': true})
        .lt('draft_expires_at', DateTime.now().toIso8601String())
        .eq('status', 'draft')
        .eq('is_draft_expired', false);
  }

  Future<OrderCalculationResult> refreshLatestEstimate(
    OrderDraftInput input,
  ) async {
    return _calculationService.calculateOrderEstimate(input);
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays >= 1) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    }
    if (duration.inHours >= 1) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    }
    if (duration.inMinutes >= 1) {
      return '${duration.inMinutes} min${duration.inMinutes > 1 ? 's' : ''}';
    }
    return 'less than a minute';
  }
}
