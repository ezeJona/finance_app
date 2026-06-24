import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../backend-api/api_service.dart';
import '../backend-api/sync_service.dart';
import '../backend-api/dtos.dart';
import 'business.dart';

final transactionItemsProvider = FutureProvider<List<TransactionItemRes>>((ref) async {
  final business = ref.watch(businessProvider);
  if (business == null) return [];
  
  final cached = SyncService.getCachedTransactionItems(business.id);
  
  try {
    if (await SyncService.isOnline()) {
      final remote = await ApiService.getAllTransactionItemsByBusiness(business.id);
      await SyncService.cacheTransactionItems(business.id, remote);
      return remote;
    }
  } catch (_) {}
  
  return cached;
});
