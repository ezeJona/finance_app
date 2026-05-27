import 'package:supabase_flutter/supabase_flutter.dart';

import 'dtos.dart';

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
    try {
      final Map<String, dynamic> response = await _supabase
          .from('transactions')
          .insert(req.toJson())
          .select()
          .single();
      return TransactionRes.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
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
