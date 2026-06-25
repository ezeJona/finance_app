import 'package:uuid/uuid.dart';
import '../models/cart_item.dart';
import '../backend-api/api_service.dart';
import '../backend-api/sync_service.dart';
import '../backend-api/dtos.dart';

class InventoryService {
  static Future<void> processInventorySale({
    required int businessId,
    required List<CartItem> items,
    required String paymentMethod,
    required bool isDebt,
    String? debtContactName,
  }) async {
    final double totalVenta = items.fold(0, (sum, item) => sum + item.subtotal);
    final isOnline = await SyncService.isOnline();
    
    String? transactionId;
    String? debtId;

    // PASO 1: Registro Padre (Contado vs Crédito)
    if (!isDebt) {
      final req = CreateTransactionReq(
        businessId: businessId,
        type: 'income',
        amount: totalVenta,
        description: 'Venta de productos en inventario',
        paymentMethod: paymentMethod,
        contactName: debtContactName, // Reutilizamos el parámetro para el nombre del cliente
      );
      // ApiService.createTransaction handles offline by queuing and returning optimistic result
      final res = await ApiService.createTransaction(req);
      transactionId = res.id;

      // Update local cache for transactions for immediate UI reflection
      final currentTxs = SyncService.getCachedTransactions(businessId);
      await SyncService.cacheTransactions(businessId, [res, ...currentTxs]);
    } else {
      final req = CreateDebtReq(
        businessId: businessId,
        type: 'to_collect',
        contactName: debtContactName ?? 'Cliente General',
        totalAmount: totalVenta,
        description: 'Venta de productos en inventario',
      );
      // ApiService.createDebt handles offline by queuing and returning optimistic result
      final res = await ApiService.createDebt(req);
      debtId = res.id;

      // Update local cache for debts for immediate UI reflection
      final currentDebts = SyncService.getCachedDebts(businessId);
      await SyncService.cacheDebts(businessId, [res, ...currentDebts]);
    }

    // PASO 2: Inserción del Detalle Masivo (transaction_items)
    final List<Map<String, dynamic>> itemsJson = items.map((item) => {
      'id': const Uuid().v4(),
      'transaction_id': transactionId,
      'debt_id': debtId,
      'product_id': item.product.id,
      'quantity': item.quantity.toDouble(),
      'unit_cost': item.product.costPrice,
      'unit_price': item.product.salePrice,
      'subtotal': item.subtotal,
    }).toList();

    if (isOnline) {
      try {
        await ApiService.createTransactionItems(itemsJson);
      } catch (e) {
        await SyncService.queueAction('create_transaction_items', {'items': itemsJson});
      }
    } else {
      await SyncService.queueAction('create_transaction_items', {'items': itemsJson});
    }

    // Update local cache for transaction items
    final List<TransactionItemRes> itemsRes = itemsJson.map((json) => TransactionItemRes.fromJson(json)).toList();
    final currentItems = SyncService.getCachedTransactionItems(businessId);
    await SyncService.cacheTransactionItems(businessId, [...itemsRes, ...currentItems]);

    // PASO 3: Descuento de Stock en Caliente
    final currentProducts = SyncService.getCachedProducts(businessId);
    for (var item in items) {
      final index = currentProducts.indexWhere((p) => p.id == item.product.id);
      if (index != -1) {
        final product = currentProducts[index];
        final newStock = product.stock - item.quantity;
        
        final updatedProduct = product.copyWith(stock: newStock);
        currentProducts[index] = updatedProduct;

        final updateReq = CreateProductReq(
          businessId: businessId,
          name: product.name,
          costPrice: product.costPrice,
          salePrice: product.salePrice,
          stock: newStock,
          minStock: product.minStock,
        );

        if (isOnline) {
          try {
            await ApiService.updateProduct(product.id, updateReq);
          } catch (e) {
            await SyncService.queueAction('update_product_stock', {
              'id': product.id,
              ...updateReq.toJson(),
            });
          }
        } else {
          await SyncService.queueAction('update_product_stock', {
            'id': product.id,
            ...updateReq.toJson(),
          });
        }
      }
    }
    // Update local cache for products
    await SyncService.cacheProducts(businessId, currentProducts);
  }
}
