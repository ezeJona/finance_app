import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../backend-api/api_service.dart';
import '../backend-api/dtos.dart';
import 'business.dart';

final transactionsProvider = FutureProvider.autoDispose<List<TransactionRes>>((ref) async {
  final business = ref.watch(businessProvider);
  if (business == null) return [];
  
  return await ApiService.getTransactionsByBusiness(business.id);
});
