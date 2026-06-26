import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../backend-api/api_service.dart';
import '../backend-api/dtos.dart';
import 'auth_user.dart';

final businessesProvider = FutureProvider<List<BusinessRes>>((ref) async {
  final authUser = ref.watch(authUserProvider);
  if (authUser == null) return [];

  final box = Hive.box('businesses_cache');
  
  // 1. Cargar desde cache inmediatamente si existe
  final cachedData = box.get(authUser.id);
  List<BusinessRes> cachedList = [];
  if (cachedData != null) {
    cachedList = (cachedData as List).map((json) => BusinessRes.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  // 2. Intentar actualizar desde red
  try {
    final fresh = await ApiService.getBusinesses(authUser.id);
    await box.put(authUser.id, fresh.map((b) => b.toJson()).toList());
    return fresh;
  } catch (e) {
    // Si falla la red, devolver cache
    if (cachedList.isNotEmpty) return cachedList;
    rethrow;
  }
});
