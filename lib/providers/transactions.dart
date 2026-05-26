import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../backend-api/api_service.dart';
import '../backend-api/dtos.dart';
import 'business.dart';
import 'transaction_filter.dart';

final transactionsProvider = FutureProvider.autoDispose<List<TransactionRes>>((ref) async {
  final business = ref.watch(businessProvider);
  if (business == null) return [];

  final filter = ref.watch(transactionFilterProvider);
  
  DateTime? startDate;
  DateTime? endDate;
  int? limit;

  final now = DateTime.now();

  switch (filter.timeRange) {
    case 'today':
      startDate = DateTime(now.year, now.month, now.day);
      endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      break;
    case 'yesterday':
      final yesterday = now.subtract(const Duration(days: 1));
      startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
      endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
      break;
    case 'last_5':
      limit = 5;
      break;
    case 'last_7':
      startDate = now.subtract(const Duration(days: 7));
      break;
    case 'last_30':
      startDate = now.subtract(const Duration(days: 30));
      break;
    case 'current_month':
      startDate = DateTime(filter.selectedMonthYear.year, filter.selectedMonthYear.month, 1);
      endDate = DateTime(filter.selectedMonthYear.year, filter.selectedMonthYear.month + 1, 0, 23, 59, 59);
      break;
    case 'custom_range':
      if (filter.customDateRange != null) {
        startDate = filter.customDateRange!.start;
        endDate = filter.customDateRange!.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
      }
      break;
  }
  
  return await ApiService.getFilteredTransactions(
    businessId: business.id,
    type: filter.flowType,
    startDate: startDate,
    endDate: endDate,
    limit: limit,
  );
});
