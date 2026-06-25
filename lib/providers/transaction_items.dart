import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../backend-api/api_service.dart';
import '../backend-api/sync_service.dart';
import '../backend-api/dtos.dart';
import 'business.dart';
import 'inventory.dart';

class TransactionItemModel {
  final TransactionItemRes item;
  final String productName;

  TransactionItemModel({required this.item, required this.productName});
}

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

final transactionDetailsProvider = FutureProvider.family<List<TransactionItemModel>, String>((ref, id) async {
  // Intentar obtener de la lista global ya cargada (caché local reactiva)
  final allItems = await ref.watch(transactionItemsProvider.future);
  final productsAsync = ref.watch(productsProvider);
  
  var items = allItems.where((element) => element.transactionId == id || element.debtId == id).toList();
  
  // Si no hay nada en el provider global, intentar consultar directamente al API
  if (items.isEmpty) {
    try {
      // Intentar por Transaction ID
      var remoteItems = await ApiService.getTransactionItems(id, null);
      if (remoteItems.isEmpty) {
        // Intentar por Debt ID
        remoteItems = await ApiService.getTransactionItems(null, id);
      }
      
      if (remoteItems.isNotEmpty) {
        items = remoteItems;
      }
    } catch (_) {}
  }

  final products = productsAsync.value ?? [];
  return items.map((item) {
    final product = products.firstWhere((p) => p.id == item.productId, 
      orElse: () => ProductRes(id: '', businessId: 0, name: 'Producto desconocido', costPrice: 0, salePrice: 0, stock: 0, minStock: 0, createdAt: DateTime.now())
    );
    return TransactionItemModel(item: item, productName: product.name);
  }).toList();
});
