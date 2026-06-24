import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../backend-api/inventory_repository.dart';
import '../backend-api/dtos.dart';
import '../models/cart_item.dart';
import 'business.dart';
import 'transactions.dart';
import 'debts.dart';

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
      rethrow;
    }
  }

  Future<void> updateProduct(String id, CreateProductReq req) async {
    try {
      final updatedProduct = await InventoryRepository.updateProduct(id, req);
      state.whenData((list) {
        state = AsyncValue.data(list.map((p) => p.id == id ? updatedProduct : p).toList());
      });
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
    } catch (e) {
      rethrow;
    }
  }
}

final inventoryMetricsProvider = Provider<({double totalArticles, double totalSales})>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final transactionsAsync = ref.watch(historicTransactionsProvider);
  final debtsAsync = ref.watch(debtsProvider);

  final totalArticles = productsAsync.maybeWhen(
    data: (products) => products.fold<double>(0.0, (sum, item) => sum + item.stock),
    orElse: () => 0.0,
  );

  double totalSales = 0.0;

  transactionsAsync.whenData((txs) {
    totalSales += txs
        .where((tx) => tx.type == 'income' && tx.description == 'Venta de productos en inventario')
        .fold(0.0, (sum, tx) => sum + tx.amount);
  });

  debtsAsync.whenData((debts) {
    totalSales += debts
        .where((d) => d.type == 'to_collect' && d.description == 'Venta de productos en inventario')
        .fold(0.0, (sum, d) => sum + d.totalAmount);
  });

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

  void addItem(ProductRes product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            CartItem(product: state[i].product, quantity: state[i].quantity + 1)
          else
            state[i]
      ];
    } else {
      state = [...state, CartItem(product: product, quantity: 1)];
    }
  }

  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
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
