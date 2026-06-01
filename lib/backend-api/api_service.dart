import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dtos.dart';
import 'sync_service.dart';

// All API functions to make requests to the supabase backend go here
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
      final Map<String, dynamic> response = await _supabase
          .from('app_users')
          .insert(req.toJson())
          .select()
          .single();
      return AppUserRes.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create app user: $e');
    }
  }

  static Future<BusinessRes> createBusiness(CreateBusinessReq req) async {
    try {
      final Map<String, dynamic> response = await _supabase
          .from('businesses')
          .insert(req.toJson())
          .select()
          .single();
      return BusinessRes.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create business: $e');
    }
  }

  static Future<BusinessRes> updateBusiness(int id, CreateBusinessReq req) async {
    try {
      final Map<String, dynamic> response = await _supabase
          .from('businesses')
          .update(req.toJson())
          .eq('id', id)
          .select()
          .single();
      return BusinessRes.fromJson(response);
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
      final Map<String, dynamic>? response = await _supabase
          .from('app_users')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response != null) {
        return AppUserRes.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch app user: $e');
    }
  }

  static Future<List<MunicipalityRes>?> getMunicipalities() async {
    try {
      final List<dynamic> response = await _supabase
          .from('municipalities')
          .select();
      if (response.isNotEmpty) {
        return response.map((json) => MunicipalityRes.fromJson(json)).toList();
      }
      return [];
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
      // 1. Intentar obtener el que el usuario marcó como predeterminado
      final Map<String, dynamic>? defaultBus = await _supabase
          .from('businesses')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      if (defaultBus != null) {
        return BusinessRes.fromJson(defaultBus);
      }

      // 2. Si no hay predeterminado, traer el primero que se encuentre
      final List<dynamic> response = await _supabase
          .from('businesses')
          .select()
          .eq('user_id', userId)
          .limit(1);

      if (response.isNotEmpty) {
        return BusinessRes.fromJson(response.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch business: $e');
    }
  }

  static Future<void> setBusinessAsDefault(int businessId, String userId) async {
    try {
      // 1. Quitar el predeterminado a todos los negocios del usuario
      await _supabase
          .from('businesses')
          .update({'is_default': false})
          .eq('user_id', userId);
      
      // 2. Establecer el nuevo predeterminado
      await _supabase
          .from('businesses')
          .update({'is_default': true})
          .eq('id', businessId);
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
      final Map<String, dynamic> response = await _supabase
          .from('transactions')
          .insert(req.toJson())
          .select()
          .single();
      return TransactionRes.fromJson(response);
    } catch (e) {
      // Fallback a offline si hay error de red
      await SyncService.queueAction('create_transaction', req.toJson());
      rethrow;
    }
  }

  static Future<TransactionRes> updateTransaction(String id, CreateTransactionReq req) async {
    try {
      final Map<String, dynamic> response = await _supabase
          .from('transactions')
          .update(req.toJson())
          .eq('id', id)
          .select()
          .single();
      return TransactionRes.fromJson(response);
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

      if (type != null && type != 'all') {
        query = query.eq('type', type);
      }

      if (startDate != null) {
        query = query.gte('transaction_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('transaction_date', endDate.toIso8601String());
      }

      PostgrestTransformBuilder<List<Map<String, dynamic>>> finalQuery = 
          query.order('transaction_date', ascending: false);

      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

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
      throw Exception('Error al obtener deudas: $e');
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
      final Map<String, dynamic> response = await _supabase
          .from('debts')
          .insert(req.toJson())
          .select()
          .single();
      return DebtRes.fromJson(response);
    } catch (e) {
      await SyncService.queueAction('create_debt', req.toJson());
      rethrow;
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
      final Map<String, dynamic> response = await _supabase
          .from('debt_payments')
          .insert(req.toJson())
          .select()
          .single();
      return DebtPaymentRes.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      await SyncService.queueAction('create_debt_payment', req.toJson());
      rethrow;
    }
  }

  static Future<List<DebtPaymentRes>> fetchDebtPayments(String debtId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('debt_payments')
          .select()
          .eq('debt_id', debtId)
          .order('payment_date', ascending: false);
      return response.map((json) => DebtPaymentRes.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener abonos: $e');
    }
  }

  static Future<User> signInUser(String email, String password) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user!;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  static Future<void> signOutUser() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  static Future<void> signUpUser(String email, String password) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'https://hospired.github.io/hospired/',
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
