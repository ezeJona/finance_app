import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend-api/api_service.dart';
import '../backend-api/dtos.dart';
import '../backend-api/sync_service.dart';
import 'auth_user.dart';
import 'businesses.dart';

final businessProvider =
    StateNotifierProvider<BusinessNotifier, BusinessRes?>(
  (ref) {
    final authUser = ref.watch(authUserProvider);
    return BusinessNotifier(ref, authUser);
  },
);

class BusinessNotifier extends StateNotifier<BusinessRes?> {
  final Ref _ref;
  final AuthUserRes? _authUser;

  BusinessNotifier(this._ref, this._authUser) : super(null) {
    _initialize();
    
    // Escuchamos la lista de negocios para reaccionar ante cambios (ej: eliminación o creación)
    _ref.listen<AsyncValue<List<BusinessRes>>>(businessesProvider, (prev, next) {
      next.whenData((businesses) {
        if (businesses.isEmpty) {
          state = null;
          return;
        }

        // Si no hay nada seleccionado, o lo que estaba seleccionado ya no existe en la lista
        if (state == null || !businesses.any((b) => b.id == state!.id)) {
          _selectBestBusiness(businesses);
        } else {
          // Si el negocio seleccionado sigue existiendo, actualizamos sus datos por si cambiaron (nombre, etc)
          final updated = businesses.firstWhere((b) => b.id == state!.id);
          if (updated != state) {
            state = updated;
          }
        }
      });
    });
  }

  Future<void> _initialize() async {
    if (_authUser == null) return;

    // 1. Carga inmediata desde Hive (Cero clicks, UX instantánea)
    final cached = Hive.box("session").get("business");
    if (cached != null) {
      try {
        state = BusinessRes.fromJson(jsonDecode(cached));
      } catch (_) {}
    }

    // 2. Sincronización con la lista oficial del backend
    try {
      final businesses = await _ref.read(businessesProvider.future);
      if (businesses.isNotEmpty) {
        await _selectBestBusiness(businesses);
      }
    } catch (e) {
      // Si falla la red, mantenemos el estado de Hive
    }
  }

  Future<void> _selectBestBusiness(List<BusinessRes> businesses) async {
    if (businesses.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final lastBusinessId = prefs.getInt('last_active_business_id');

    BusinessRes? target;

    // Caso A: Historial local (Último usado)
    if (lastBusinessId != null) {
      for (final b in businesses) {
        if (b.id == lastBusinessId) {
          target = b;
          break;
        }
      }
    }

    // Caso B: Negocio marcado como predeterminado (is_default)
    if (target == null) {
      for (final b in businesses) {
        if (b.isDefault) {
          target = b;
          break;
        }
      }
    }

    // Caso C: El primer negocio de la lista
    target ??= businesses.first;

    if (target != null && target != state) {
      set(target);
    }
  }

  Future<BusinessRes?> fetch() async {
    if (_authUser == null) return null;
    try {
      final res = await ApiService.getBusiness(_authUser.id);
      if (res != null) set(res);
      return res;
    } catch (e) {
      return null;
    }
  }

  void set(BusinessRes business) async {
    state = business;
    
    // Guardamos en Hive para persistencia de objeto completo
    Hive.box("session").put("business", jsonEncode(business.toJson()));
    
    // Guardamos en SharedPreferences el ID para la lógica de "Último usado"
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_active_business_id', business.id);
  }

  void destroy() async {
    state = null;
    Hive.box("session").delete("business");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_active_business_id');
  }
}
