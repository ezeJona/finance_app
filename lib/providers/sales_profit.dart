import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../backend-api/api_service.dart';

final saleProfitProvider = FutureProvider.family<double, String>((ref, targetId) async {
  // First try fetching as transaction items
  var items = await ApiService.getTransactionItems(targetId, null);
  
  // If no items found, try fetching as debt items
  if (items.isEmpty) {
    items = await ApiService.getTransactionItems(null, targetId);
  }

  if (items.isEmpty) return 0.0;

  double totalProfit = 0.0;
  for (final item in items) {
    totalProfit += (item.unitPrice - item.unitCost) * item.quantity;
  }
  return totalProfit;
});
