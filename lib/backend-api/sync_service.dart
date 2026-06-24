import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'api_service.dart';
import 'dtos.dart';

class SyncService {
  static final _syncBox = Hive.box('sync_queue');
  static final _txBox = Hive.box('transactions_cache');
  static final _debtsBox = Hive.box('debts_cache');
  static final _categoriesBox = Hive.box('categories_cache');
  static final _productsBox = Hive.box('products_cache');
  static final _itemsBox = Hive.box('transaction_items_cache');

  static Future<bool> isOnline() async {
    final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.isNotEmpty && !connectivityResult.contains(ConnectivityResult.none);
  }

  // --- GENERIC QUEUE ACTION ---

  static Future<void> queueAction(String type, Map<String, dynamic> payload) async {
    final id = const Uuid().v4();
    await _syncBox.put(id, {
      'id': id,
      'endpoint_type': type,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // --- SYNC ENGINE ---

  static Future<void> fullSync(int businessId) async {
    if (!await isOnline()) return;

    try {
      // Fetch everything in parallel for maximum speed
      final results = await Future.wait([
        ApiService.getTransactionsByBusiness(businessId),
        ApiService.fetchDebtsByBusiness(businessId),
        ApiService.getProductCategoriesByBusiness(businessId),
        ApiService.getProductsByBusiness(businessId),
        ApiService.getAllTransactionItemsByBusiness(businessId),
      ]);

      await cacheTransactions(businessId, results[0] as List<TransactionRes>);
      await cacheDebts(businessId, results[1] as List<DebtRes>);
      await cacheCategories(businessId, results[2] as List<ProductCategoryRes>);
      await cacheProducts(businessId, results[3] as List<ProductRes>);
      await cacheTransactionItems(businessId, results[4] as List<TransactionItemRes>);
    } catch (e) {
      print("Error during fullSync: $e");
    }
  }

  static Future<void> processQueue() async {
    if (!await isOnline()) return;

    final keys = _syncBox.keys.toList();
    if (keys.isEmpty) return;

    for (var key in keys) {
      final item = _syncBox.get(key);
      final type = item['endpoint_type'];
      final payload = jsonDecode(item['payload']);

      try {
        switch (type) {
          case 'create_transaction':
            await ApiService.createTransaction(CreateTransactionReq.fromJson(payload));
            break;
          case 'create_debt':
            await ApiService.createDebt(CreateDebtReq.fromJson(payload));
            break;
          case 'create_debt_payment':
            await ApiService.createDebtPayment(CreateDebtPaymentReq.fromJson(payload));
            break;
          case 'delete_transaction':
            await ApiService.deleteTransaction(payload['id']);
            break;
          case 'create_product':
            await ApiService.createProduct(CreateProductReq.fromJson(payload));
            break;
          case 'create_category':
            await ApiService.createProductCategory(CreateCategoryReq.fromJson(payload));
            break;
          case 'update_product':
            final id = payload['id'];
            final req = CreateProductReq.fromJson(payload);
            await ApiService.updateProduct(id, req);
            break;
          case 'create_transaction_items':
            final items = (payload['items'] as List).cast<Map<String, dynamic>>();
            await ApiService.createTransactionItems(items);
            break;
          case 'update_product_stock':
            final id = payload['id'];
            final stock = payload['stock'];
            await ApiService.updateProduct(payload['id'], CreateProductReq(
              businessId: payload['business_id'],
              name: payload['name'],
              costPrice: payload['cost_price'],
              salePrice: payload['sale_price'],
              stock: stock,
              minStock: payload['min_stock'],
            ));
            break;
          case 'soft_delete_product':
            await ApiService.softDeleteProduct(payload['id']);
            break;
        }
        await _syncBox.delete(key);
      } catch (e) {
        // En caso de error, lo dejamos en la cola para el próximo intento
      }
    }
  }

  // --- CACHE HELPERS ---

  static Future<void> cacheTransactions(int businessId, List<TransactionRes> transactions) async {
    final data = transactions.map((t) => t.toJson()).toList();
    await _txBox.put(businessId, data);
  }

  static List<TransactionRes> getCachedTransactions(int businessId) {
    final data = _txBox.get(businessId);
    if (data == null) return [];
    return (data as List).map((json) => TransactionRes.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  static Future<void> cacheDebts(int businessId, List<DebtRes> debts) async {
    final data = debts.map((d) => d.toJson()).toList();
    await _debtsBox.put(businessId, data);
  }

  static List<DebtRes> getCachedDebts(int businessId) {
    final data = _debtsBox.get(businessId);
    if (data == null) return [];
    return (data as List).map((json) => DebtRes.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  static Future<void> cacheCategories(int businessId, List<ProductCategoryRes> categories) async {
    final data = categories.map((c) => c.toJson()).toList();
    await _categoriesBox.put(businessId, data);
  }

  static List<ProductCategoryRes> getCachedCategories(int businessId) {
    final data = _categoriesBox.get(businessId);
    if (data == null) return [];
    return (data as List).map((json) => ProductCategoryRes.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  static Future<void> cacheProducts(int businessId, List<ProductRes> products) async {
    final data = products.map((p) => p.toJson()).toList();
    await _productsBox.put(businessId, data);
  }

  static List<ProductRes> getCachedProducts(int businessId) {
    final data = _productsBox.get(businessId);
    if (data == null) return [];
    return (data as List).map((json) => ProductRes.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  static Future<void> cacheTransactionItems(int businessId, List<TransactionItemRes> items) async {
    final data = items.map((i) => i.toJson()).toList();
    await _itemsBox.put(businessId, data);
  }

  static List<TransactionItemRes> getCachedTransactionItems(int businessId) {
    final data = _itemsBox.get(businessId);
    if (data == null) return [];
    return (data as List).map((json) => TransactionItemRes.fromJson(Map<String, dynamic>.from(json))).toList();
  }
}
