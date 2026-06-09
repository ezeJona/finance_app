import 'api_service.dart';
import 'dtos.dart';
import 'sync_service.dart';

class InventoryRepository {
  static Future<List<ProductCategoryRes>> getCategories(int businessId) async {
    // 1. Get from cache first
    final cached = SyncService.getCachedCategories(businessId);
    
    // 2. Fetch from remote in background (or foreground if cache empty)
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
    final res = await ApiService.createProductCategory(req);
    
    // Refresh cache
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
    final res = await ApiService.createProduct(req);
    
    // Refresh cache
    final current = SyncService.getCachedProducts(req.businessId);
    await SyncService.cacheProducts(req.businessId, [...current, res]);
    
    return res;
  }

  static Future<ProductRes> updateProduct(String productId, CreateProductReq req) async {
    final res = await ApiService.updateProduct(productId, req);
    
    // Update cache
    final current = SyncService.getCachedProducts(req.businessId);
    final index = current.indexWhere((p) => p.id == productId);
    if (index != -1) {
      current[index] = res;
      await SyncService.cacheProducts(req.businessId, current);
    }
    
    return res;
  }

  static Future<void> softDeleteProduct(int businessId, String productId) async {
    await ApiService.softDeleteProduct(productId);
    
    // Update cache
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
