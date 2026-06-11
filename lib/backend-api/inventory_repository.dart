import 'package:uuid/uuid.dart';
import 'api_service.dart';
import 'dtos.dart';
import 'sync_service.dart';

class InventoryRepository {
  static Future<List<ProductCategoryRes>> getCategories(int businessId) async {
    final cached = SyncService.getCachedCategories(businessId);
    _fetchAndCacheCategories(businessId);
    return cached;
  }

  static Future<void> _fetchAndCacheCategories(int businessId) async {
    try {
      if (await SyncService.isOnline()) {
        final remote = await ApiService.getProductCategoriesByBusiness(businessId);
        await SyncService.cacheCategories(businessId, remote);
      }
    } catch (_) {}
  }

  static Future<ProductCategoryRes> createCategory(int businessId, String name) async {
    final req = CreateCategoryReq(businessId: businessId, name: name);
    final isOnline = await SyncService.isOnline();
    ProductCategoryRes res;

    if (isOnline) {
      res = await ApiService.createProductCategory(req);
    } else {
      res = ProductCategoryRes(
        id: -1, // Temporary ID for local use
        businessId: businessId,
        name: name,
        createdAt: DateTime.now(),
      );
      await SyncService.queueAction('create_category', req.toJson());
    }
    
    final current = SyncService.getCachedCategories(businessId);
    await SyncService.cacheCategories(businessId, [...current, res]);
    
    return res;
  }

  static Future<List<ProductRes>> getProducts(int businessId) async {
    final cached = SyncService.getCachedProducts(businessId);
    _fetchAndCacheProducts(businessId);
    return cached.where((p) => p.deletedAt == null).toList();
  }

  static Future<void> _fetchAndCacheProducts(int businessId) async {
    try {
      if (await SyncService.isOnline()) {
        final remote = await ApiService.getProductsByBusiness(businessId);
        await SyncService.cacheProducts(businessId, remote);
      }
    } catch (_) {}
  }

  static Future<ProductRes> createProduct(CreateProductReq req) async {
    final isOnline = await SyncService.isOnline();
    ProductRes res;

    if (isOnline) {
      res = await ApiService.createProduct(req);
    } else {
      res = ProductRes(
        id: const Uuid().v4(),
        businessId: req.businessId,
        categoryId: req.categoryId,
        name: req.name,
        description: req.description,
        costPrice: req.costPrice,
        salePrice: req.salePrice,
        stock: req.stock,
        minStock: req.minStock,
        imageUrl: req.imageUrl,
        createdAt: DateTime.now(),
      );
      await SyncService.queueAction('create_product', req.toJson());
    }
    
    final current = SyncService.getCachedProducts(req.businessId);
    await SyncService.cacheProducts(req.businessId, [res, ...current]);
    
    return res;
  }

  static Future<ProductRes> updateProduct(String productId, CreateProductReq req) async {
    final isOnline = await SyncService.isOnline();
    ProductRes res;

    if (isOnline) {
      res = await ApiService.updateProduct(productId, req);
    } else {
      res = ProductRes(
        id: productId,
        businessId: req.businessId,
        categoryId: req.categoryId,
        name: req.name,
        description: req.description,
        costPrice: req.costPrice,
        salePrice: req.salePrice,
        stock: req.stock,
        minStock: req.minStock,
        imageUrl: req.imageUrl,
        createdAt: DateTime.now(), // Fallback, would be better to keep original
      );
      var payload = req.toJson();
      payload['id'] = productId;
      await SyncService.queueAction('update_product', payload);
    }
    
    final current = SyncService.getCachedProducts(req.businessId);
    final index = current.indexWhere((p) => p.id == productId);
    if (index != -1) {
      current[index] = res;
      await SyncService.cacheProducts(req.businessId, current);
    }
    
    return res;
  }

  static Future<void> softDeleteProduct(int businessId, String productId) async {
    final isOnline = await SyncService.isOnline();
    if (isOnline) {
      await ApiService.softDeleteProduct(productId);
    } else {
      await SyncService.queueAction('soft_delete_product', {'id': productId});
    }
    
    final current = SyncService.getCachedProducts(businessId);
    final index = current.indexWhere((p) => p.id == productId);
    if (index != -1) {
      current[index] = ProductRes(
        id: current[index].id,
        businessId: current[index].businessId,
        categoryId: current[index].categoryId,
        name: current[index].name,
        description: current[index].description,
        costPrice: current[index].costPrice,
        salePrice: current[index].salePrice,
        stock: current[index].stock,
        minStock: current[index].minStock,
        imageUrl: current[index].imageUrl,
        createdAt: current[index].createdAt,
        deletedAt: DateTime.now(),
      );
      await SyncService.cacheProducts(businessId, current);
    }
  }
}
