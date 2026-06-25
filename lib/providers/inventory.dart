import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../backend-api/inventory_repository.dart';
import '../backend-api/api_service.dart';
import '../backend-api/sync_service.dart';
import '../backend-api/dtos.dart';
import '../models/cart_item.dart';
import 'business.dart';
import 'transactions.dart';
import 'debts.dart';
import 'analytics.dart';

final productCategoriesProvider =
    StateNotifierProvider<ProductCategoriesNotifier, AsyncValue<List<ProductCategoryRes>>>((ref) {
  final business = ref.watch(businessProvider);
  return ProductCategoriesNotifier(ref, business);
});

class ProductCategoriesNotifier extends StateNotifier<AsyncValue<List<ProductCategoryRes>>> {
  final Ref ref;
  final BusinessRes? business;

  ProductCategoriesNotifier(this.ref, this.business) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    if (business == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final categories = await InventoryRepository.getCategories(business!.id);
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCategory(String name) async {
    if (business == null) throw Exception('No hay negocio seleccionado');
    try {
      final newCategory = await InventoryRepository.createCategory(business!.id, name);
      state.whenData((list) {
        state = AsyncValue.data([...list, newCategory]);
      });
    } catch (e) {
      rethrow;
    }
  }
}

final productsProvider =
    StateNotifierProvider<ProductsNotifier, AsyncValue<List<ProductRes>>>((ref) {
  final business = ref.watch(businessProvider);
  return ProductsNotifier(ref, business);
});

class ProductsNotifier extends StateNotifier<AsyncValue<List<ProductRes>>> {
  final Ref ref;
  final BusinessRes? business;

  ProductsNotifier(this.ref, this.business) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    if (business == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final products = await InventoryRepository.getProducts(business!.id);
      state = AsyncValue.data(products);
      // Refrescar también el performance cuando cambian productos
      ref.invalidate(inventoryPerformanceProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addProduct(CreateProductReq req) async {
    try {
      final newProduct = await InventoryRepository.createProduct(req);
      state.whenData((list) {
        state = AsyncValue.data([newProduct, ...list]);
      });
      ref.invalidate(inventoryPerformanceProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProduct(String id, CreateProductReq req) async {
    try {
      final updatedProduct = await InventoryRepository.updateProduct(id, req);
      state.whenData((list) {
        state = AsyncValue.data(list.map((p) => p.id == id ? updatedProduct : p).toList());
      });
      ref.invalidate(inventoryPerformanceProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    if (business == null) return;
    try {
      await InventoryRepository.softDeleteProduct(business!.id, id);
      state.whenData((list) {
        state = AsyncValue.data(list.where((p) => p.id != id).toList());
      });
      ref.invalidate(inventoryPerformanceProvider);
    } catch (e) {
      rethrow;
    }
  }
}

final inventoryPerformanceProvider = FutureProvider<List<InventoryPerformanceRes>>((ref) async {
  final business = ref.watch(businessProvider);
  if (business == null) return [];

  final cached = SyncService.getCachedInventoryPerformance(business.id);

  try {
    final fresh = await ApiService.getInventoryPerformance(business.id);
    await SyncService.cacheInventoryPerformance(business.id, fresh);
    return fresh;
  } catch (e) {
    return cached;
  }
});

final inventoryMetricsProvider = Provider<({double totalArticles, double totalSales})>((ref) {
  final performanceAsync = ref.watch(inventoryPerformanceProvider);
  final financialsAsync = ref.watch(executiveFinancialsProvider);

  final totalArticles = performanceAsync.maybeWhen(
    data: (items) => items.fold<double>(0.0, (sum, item) => sum + item.stock),
    orElse: () => 0.0,
  );

  final totalSales = financialsAsync.maybeWhen(
    data: (financials) => financials.fold<double>(0.0, (sum, f) => sum + f.totalInventorySales),
    orElse: () => 0.0,
  );

  return (totalArticles: totalArticles, totalSales: totalSales);
});

final selectedCategoryIdProvider = StateProvider<int?>((ref) => null);

final filteredProductsProvider = Provider<List<ProductRes>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
  
  return productsAsync.maybeWhen(
    data: (products) {
      if (selectedCategoryId == null) return products;
      return products.where((p) => p.categoryId == selectedCategoryId).toList();
    },
    orElse: () => [],
  );
});

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(ProductRes product, {required Function(String) onStockError}) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      final currentQty = state[index].quantity;
      if (currentQty + 1 > product.stock) {
        onStockError("❌ Sin existencias: No tienes stock disponible de este producto. Si tienes mercancía en bodega, edita el artículo para alimentar el stock primero.");
        return;
      }
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            CartItem(product: state[i].product, quantity: state[i].quantity + 1)
          else
            state[i]
      ];
    } else {
      if (product.stock <= 0) {
        onStockError("❌ Sin existencias: No tienes stock disponible de este producto. Si tienes mercancía en bodega, edita el artículo para alimentar el stock primero.");
        return;
      }
      state = [...state, CartItem(product: product, quantity: 1)];
    }
  }

  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateQuantity(String productId, int quantity, {Function(String)? onStockError}) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    
    final itemIndex = state.indexWhere((item) => item.product.id == productId);
    if (itemIndex != -1) {
      final item = state[itemIndex];
      if (quantity > item.product.stock) {
        onStockError?.call("❌ Sin existencias: No tienes stock disponible de este producto. Si tienes mercancía en bodega, edita el artículo para alimentar el stock primero.");
        return;
      }
    }

    state = [
      for (final item in state)
        if (item.product.id == productId)
          CartItem(product: item.product, quantity: quantity)
        else
          item
    ];
  }

  void clear() {
    state = [];
  }
}
