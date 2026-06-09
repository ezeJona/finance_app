import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../backend-api/inventory_repository.dart';
import '../backend-api/dtos.dart';
import 'business.dart';

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
    if (business == null) return;
    try {
      final newCategory = await InventoryRepository.createCategory(business!.id, name);
      state.whenData((list) {
        state = AsyncValue.data([...list, newCategory]);
      });
    } catch (e) {
      // Handle error
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
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateProduct(String id, CreateProductReq req) async {
    try {
      final updatedProduct = await InventoryRepository.updateProduct(id, req);
      state.whenData((list) {
        state = AsyncValue.data(list.map((p) => p.id == id ? updatedProduct : p).toList());
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteProduct(String id) async {
    if (business == null) return;
    try {
      await InventoryRepository.softDeleteProduct(business!.id, id);
      state.whenData((list) {
        state = AsyncValue.data(list.where((p) => p.id != id).toList());
      });
    } catch (e) {
      // Handle error
    }
  }
}
