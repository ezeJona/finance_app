import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dtos.dart';
import 'sync_service.dart';

class ApiService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static AuthUserRes? checkAndGetUserSession() {
    try {
      final User? authUser = _supabase.auth.currentUser;
      if (authUser != null) {
        return AuthUserRes(
          id: authUser.id,
          email: authUser.email ?? "${authUser.id}@hospired.com.ni",
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to check user session: $e');
    }
  }

  static Future<AppUserRes> createAppUser(CreateAppUserReq req) async {
    try {
      final List<dynamic> response = await _supabase
          .from('app_users')
          .insert(req.toJson())
          .select();
      
      if (response.isEmpty) throw Exception('No se pudo crear el usuario');
      return AppUserRes.fromJson(response.first);
    } catch (e) {
      throw Exception('Failed to create app user: $e');
    }
  }

  static Future<BusinessRes> createBusiness(CreateBusinessReq req) async {
    try {
      final List<dynamic> response = await _supabase
          .from('businesses')
          .insert(req.toJson())
          .select();
      
      if (response.isEmpty) throw Exception('No se pudo crear el negocio');
      return BusinessRes.fromJson(response.first);
    } catch (e) {
      throw Exception('Failed to create business: $e');
    }
  }

  static Future<BusinessRes> updateBusiness(int id, CreateBusinessReq req) async {
    try {
      final List<dynamic> response = await _supabase
          .from('businesses')
          .update(req.toJson())
          .eq('id', id)
          .select();
      
      if (response.isEmpty) throw Exception('No se encontró el negocio');
      return BusinessRes.fromJson(response.first);
    } catch (e) {
      throw Exception('Failed to update business: $e');
    }
  }

  static Future<void> deleteBusiness(int id) async {
    try {
      await _supabase.from('businesses').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete business: $e');
    }
  }

  static Future<AppUserRes?> getAppUser(String id) async {
    try {
      return await _supabase
          .from('app_users')
          .select()
          .eq('id', id)
          .maybeSingle()
          .then((res) => res != null ? AppUserRes.fromJson(res) : null);
    } catch (e) {
      throw Exception('Failed to fetch app user: $e');
    }
  }

  static Future<List<MunicipalityRes>?> getMunicipalities() async {
    try {
      final List<dynamic> response = await _supabase.from('municipalities').select();
      return response.map((json) => MunicipalityRes.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch municipalities: $e');
    }
  }

  static Future<List<BusinessRes>> getBusinesses(String userId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('businesses')
          .select()
          .eq('user_id', userId);
      return response.map((json) => BusinessRes.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch businesses: $e');
    }
  }

  static Future<BusinessRes?> getBusiness(String userId) async {
    try {
      final Map<String, dynamic>? defaultBus = await _supabase
          .from('businesses')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      if (defaultBus != null) return BusinessRes.fromJson(defaultBus);

      final List<dynamic> response = await _supabase
          .from('businesses')
          .select()
          .eq('user_id', userId)
          .limit(1);

      if (response.isNotEmpty) return BusinessRes.fromJson(response.first);
      return null;
    } catch (e) {
      throw Exception('Failed to fetch business: $e');
    }
  }

  static Future<void> setBusinessAsDefault(int businessId, String userId) async {
    try {
      await _supabase.from('businesses').update({'is_default': false}).eq('user_id', userId);
      await _supabase.from('businesses').update({'is_default': true}).eq('id', businessId);
    } catch (e) {
      throw Exception('Failed to set default business: $e');
    }
  }

  static Future<TransactionRes> createTransaction(CreateTransactionReq req) async {
    final online = await SyncService.isOnline();
    if (!online) {
      final tempId = const Uuid().v4();
      final optimisticTx = TransactionRes(
        id: tempId,
        businessId: req.businessId,
        type: req.type,
        amount: req.amount,
        description: req.description,
        paymentMethod: req.paymentMethod,
        contactName: req.contactName,
        category: req.category,
        transactionDate: req.transactionDate,
        createdAt: DateTime.now(),
      );
      await SyncService.queueAction('create_transaction', req.toJson());
      return optimisticTx;
    }

    try {
      final List<dynamic> response = await _supabase
          .from('transactions')
          .insert(req.toJson())
          .select();
      
      if (response.isEmpty) throw Exception('No se pudo crear la transacción');
      return TransactionRes.fromJson(response.first);
    } catch (e) {
      await SyncService.queueAction('create_transaction', req.toJson());
      rethrow;
    }
  }

  static Future<TransactionRes> updateTransaction(String id, CreateTransactionReq req) async {
    try {
      final List<dynamic> response = await _supabase
          .from('transactions')
          .update(req.toJson())
          .eq('id', id)
          .select();
      
      if (response.isEmpty) throw Exception('No se encontró la transacción');
      return TransactionRes.fromJson(response.first);
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  static Future<void> deleteTransaction(String id) async {
    final online = await SyncService.isOnline();
    if (!online) {
      await SyncService.queueAction('delete_transaction', {'id': id});
      return;
    }
    try {
      await _supabase.from('transactions').delete().eq('id', id);
    } catch (e) {
      await SyncService.queueAction('delete_transaction', {'id': id});
      rethrow;
    }
  }

  static Future<List<TransactionRes>> getTransactionsByBusiness(int businessId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('transactions')
          .select()
          .eq('business_id', businessId)
          .order('transaction_date', ascending: false);
      return response.map((json) => TransactionRes.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  static Future<List<TransactionRes>> getFilteredTransactions({
    required int businessId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      PostgrestFilterBuilder<List<Map<String, dynamic>>> query = 
          _supabase.from('transactions').select().eq('business_id', businessId);

      if (type != null && type != 'all') query = query.eq('type', type);
      if (startDate != null) query = query.gte('transaction_date', startDate.toIso8601String());
      if (endDate != null) query = query.lte('transaction_date', endDate.toIso8601String());

      PostgrestTransformBuilder<List<Map<String, dynamic>>> finalQuery = 
          query.order('transaction_date', ascending: false);

      if (limit != null) finalQuery = finalQuery.limit(limit);

      final List<dynamic> response = await finalQuery;
      return response.map((json) => TransactionRes.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch filtered transactions: $e');
    }
  }

  static Future<List<DebtRes>> fetchDebtsByBusiness(int businessId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('debts')
          .select()
          .eq('business_id', businessId)
          .order('created_at', ascending: false);
      return response.map((json) => DebtRes.fromJson(json)).toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<DebtRes> createDebt(CreateDebtReq req) async {
    final online = await SyncService.isOnline();
    if (!online) {
      final tempId = const Uuid().v4();
      final optimisticDebt = DebtRes(
        id: tempId,
        businessId: req.businessId,
        type: req.type,
        contactName: req.contactName,
        totalAmount: req.totalAmount,
        remainingAmount: req.totalAmount,
        status: 'pending',
        dueDate: req.dueDate,
        description: req.description,
        createdAt: DateTime.now(),
      );
      await SyncService.queueAction('create_debt', req.toJson());
      return optimisticDebt;
    }
    try {
      final List<dynamic> response = await _supabase
          .from('debts')
          .insert(req.toJson())
          .select();
      
      if (response.isEmpty) throw Exception('Error al insertar deuda: 0 filas devueltas');
      return DebtRes.fromJson(response.first);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception(e.toString());
      }
      await SyncService.queueAction('create_debt', req.toJson());
      rethrow;
    }
  }

  static Future<DebtRes> updateDebt(String id, CreateDebtReq req) async {
    try {
      final List<dynamic> response = await _supabase
          .from('debts')
          .update(req.toUpdateJson())
          .eq('id', id)
          .select();
      
      if (response.isEmpty) throw Exception('Error al actualizar deuda: 0 filas devueltas. ID: $id');
      return DebtRes.fromJson(response.first);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> deleteDebt(String id) async {
    try {
      await _supabase.from('debts').delete().eq('id', id);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<DebtPaymentRes> createDebtPayment(CreateDebtPaymentReq req) async {
    final online = await SyncService.isOnline();
    if (!online) {
      final tempId = const Uuid().v4();
      final optimisticPayment = DebtPaymentRes(
        id: tempId,
        debtId: req.debtId,
        amount: req.amount,
        paymentMethod: req.paymentMethod,
        paymentDate: req.paymentDate,
        createdAt: DateTime.now(),
      );
      await SyncService.queueAction('create_debt_payment', req.toJson());
      return optimisticPayment;
    }
    try {
      final List<dynamic> response = await _supabase
          .from('debt_payments')
          .insert(req.toJson())
          .select();
      
      if (response.isEmpty) throw Exception('Error al registrar abono: 0 filas devueltas');
      return DebtPaymentRes.fromJson(response.first);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception(e.toString());
      }
      await SyncService.queueAction('create_debt_payment', req.toJson());
      rethrow;
    }
  }

  static Future<DebtPaymentRes> updateDebtPayment(String id, CreateDebtPaymentReq req) async {
    try {
      final List<dynamic> response = await _supabase
          .from('debt_payments')
          .update(req.toUpdateJson())
          .eq('id', id)
          .select();
      
      if (response.isEmpty) throw Exception('Error al actualizar abono: 0 filas devueltas');
      return DebtPaymentRes.fromJson(response.first);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> deleteDebtPayment(String id) async {
    try {
      await _supabase.from('debt_payments').delete().eq('id', id);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<List<DebtPaymentRes>> fetchDebtPayments(String debtId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('debt_payments')
          .select()
          .eq('debt_id', debtId)
          .order('created_at', ascending: false); // Ordenamos por fecha de registro (el último creado arriba)
      return response.map((json) => DebtPaymentRes.fromJson(json)).toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- INVENTORY METHODS ---

  static Future<List<ProductCategoryRes>> getProductCategoriesByBusiness(int businessId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('product_categories')
          .select()
          .eq('business_id', businessId)
          .order('name', ascending: true);
      return response.map((json) => ProductCategoryRes.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch product categories: $e');
    }
  }

  static Future<ProductCategoryRes> createProductCategory(CreateCategoryReq req) async {
    try {
      final List<dynamic> response = await _supabase
          .from('product_categories')
          .insert(req.toJson())
          .select();
      if (response.isEmpty) throw Exception('No se pudo crear la categoría');
      return ProductCategoryRes.fromJson(response.first);
    } catch (e) {
      throw Exception('Failed to create product category: $e');
    }
  }

  static Future<List<ProductRes>> getProductsByBusiness(int businessId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('products')
          .select()
          .eq('business_id', businessId)
          .isFilter('deleted_at', null)
          .order('name', ascending: true);
      return response.map((json) => ProductRes.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  static Future<ProductRes> createProduct(CreateProductReq req) async {
    final online = await SyncService.isOnline();
    if (!online) {
      final tempId = const Uuid().v4();
      final optimisticProduct = ProductRes(
        id: tempId,
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
      return optimisticProduct;
    }
    try {
      final List<dynamic> response = await _supabase
          .from('products')
          .insert(req.toJson())
          .select();
      if (response.isEmpty) throw Exception('No se pudo crear el producto');
      return ProductRes.fromJson(response.first);
    } catch (e) {
      await SyncService.queueAction('create_product', req.toJson());
      rethrow;
    }
  }

  static Future<ProductRes> updateProduct(String id, CreateProductReq req) async {
    final online = await SyncService.isOnline();
    if (!online) {
      await SyncService.queueAction('update_product', {'id': id, ...req.toJson()});
      // This is slightly tricky for optimistic updates without a full local DB, 
      // but we'll follow the pattern.
      throw Exception('Update not supported offline yet in this simplified implementation');
    }
    try {
      final List<dynamic> response = await _supabase
          .from('products')
          .update(req.toJson())
          .eq('id', id)
          .select();
      if (response.isEmpty) throw Exception('No se pudo actualizar el producto');
      return ProductRes.fromJson(response.first);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  static Future<void> softDeleteProduct(String id) async {
    final online = await SyncService.isOnline();
    final deletedAt = DateTime.now().toIso8601String();
    if (!online) {
      await SyncService.queueAction('soft_delete_product', {'id': id, 'deleted_at': deletedAt});
      return;
    }
    try {
      await _supabase.from('products').update({'deleted_at': deletedAt}).eq('id', id);
    } catch (e) {
      await SyncService.queueAction('soft_delete_product', {'id': id, 'deleted_at': deletedAt});
      rethrow;
    }
  }

  // --- TRANSACTION ITEMS ---

  static Future<List<TransactionItemRes>> createTransactionItems(List<Map<String, dynamic>> items) async {
    try {
      final List<dynamic> response = await _supabase
          .from('transaction_items')
          .insert(items)
          .select();
      return response.map((json) => TransactionItemRes.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to create transaction items: $e');
    }
  }

  static Future<List<TransactionItemRes>> getTransactionItems(String? transactionId, String? debtId) async {
    try {
      var query = _supabase.from('transaction_items').select();
      if (transactionId != null) {
        query = query.eq('transaction_id', transactionId);
      } else if (debtId != null) {
        query = query.eq('debt_id', debtId);
      } else {
        return [];
      }
      final List<dynamic> response = await query;
      return response.map((json) => TransactionItemRes.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch transaction items: $e');
    }
  }

  static Future<List<TransactionItemRes>> getAllTransactionItemsByBusiness(int businessId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('transaction_items_view') // Assuming there is a view or we filter by business_id if column exists
          .select()
          .eq('business_id', businessId);
      return response.map((json) => TransactionItemRes.fromJson(json)).toList();
    } catch (e) {
      // Fallback: if business_id doesn't exist in items table, we might need a join or different approach.
      // For now, let's assume transaction_items has business_id or there's a view.
      throw Exception('Failed to fetch transaction items: $e');
    }
  }

  static Future<User> signInUser(String email, String password) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(email: email, password: password);
      return response.user!;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  static Future<void> signOutUser() async => await _supabase.auth.signOut();

  static Future<void> signUpUser(String email, String password) async {
    try {
      await _supabase.auth.signUp(email: email, password: password, emailRedirectTo: 'https://hospired.github.io/hospired/');
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
