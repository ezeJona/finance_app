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

  static Future<AppointmentRes> createAppointment(
      CreateAppointmentReq req,
      ) async {
    try {
      final Map<String, dynamic> response = await _supabase
          .from('appointments')
          .insert(req.toJson())
          .select()
          .single();
      return AppointmentRes.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
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

  static Future<PatientRes> createPatient(CreatePatientReq req) async {
    try {
      final Map<String, dynamic> response = await _supabase
          .from('patients')
          .insert(req.toJson())
          .select()
          .single();
      return PatientRes.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create patient: $e');
    }
  }

  static Future<List<AppointmentRes>?> getAppointmentsByPatientId(
      int patientId,
      ) async {
    try {
      final List<dynamic> response = await _supabase
          .from('appointments')
          .select()
          .eq('patient_id', patientId);
      if (response.isNotEmpty) {
        return response
            .map(
              (json) => AppointmentRes.fromJson(json as Map<String, dynamic>),
        )
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch apppointments by patient id: $e');
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

  static Future<List<HealthcareFacilityRes>> getHealthcareFacilities() async {
    try {
      final List<dynamic> response =
      await _supabase.from('healthcare_facilities').select();

      return response
          .map((json) => HealthcareFacilityRes.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch healthcare facilities: $e');
    }
  }

  static Future<HealthcareFacilityRes?> getHealthcareFacility(int id) async {
    try {
      final Map<String, dynamic>? response = await _supabase
          .from('healthcare_facilities')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return HealthcareFacilityRes.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch healthcare facility: $e');
    }
  }

  static Future<FacilityUnitRes?> getFacilityUnit(int id) async {
    try {
      final Map<String, dynamic>? response = await _supabase
          .from('facility_units')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return FacilityUnitRes.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch facility unit: $e');
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

  static Future<PatientRes?> getPatient(String appUserId) async {
    try {
      final Map<String, dynamic>? response = await _supabase
          .from('patients')
          .select()
          .eq('app_user_id', appUserId)
          .maybeSingle();
      if (response != null) {
        return PatientRes.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch patient: $e');
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