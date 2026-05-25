import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../backend-api/api_service.dart';
import '../backend-api/dtos.dart';
import 'auth_user.dart';

final businessProvider =
    StateNotifierProvider.autoDispose<BusinessNotifier, BusinessRes?>(
      (ref) => BusinessNotifier(ref.watch(authUserProvider)),
    );

class BusinessNotifier extends StateNotifier<BusinessRes?> {
  final AuthUserRes? _authUser;

  BusinessNotifier(this._authUser) : super(null) {
    final business = Hive.box("session").get("business");
    if (business != null) {
      final businessJson = jsonDecode(business) as Map<String, dynamic>;
      try {
        state = BusinessRes.fromJson(businessJson);
      } catch (e) {
        fetch();
      }
    }
  }

  Future<BusinessRes?> fetch() async {
    if (_authUser == null) {
      return null;
    }
    return await ApiService.getBusiness(_authUser.id).then((res) {
      if (res != null) {
        set(res);
      }
      return res;
    });
  }

  void set(BusinessRes business) {
    Hive.box("session").put("business", jsonEncode(business.toJson()));
    state = business;
  }

  void destroy() {
    Hive.box("session").delete("business");
    state = null;
  }
}
