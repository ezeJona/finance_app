import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../backend-api/api_service.dart';
import '../backend-api/dtos.dart';
import 'auth_user.dart';

final appUserProvider =
    StateNotifierProvider.autoDispose<AppUserNotifier, AppUserRes?>(
      (ref) => AppUserNotifier(ref.watch(authUserProvider)),
    );

class AppUserNotifier extends StateNotifier<AppUserRes?> {
  final AuthUserRes? _authUser;

  AppUserNotifier(this._authUser) : super(null) {
    final appUser = Hive.box("session").get("appUser");
    if (appUser != null) {
      final appUserJson = jsonDecode(appUser) as Map<String, dynamic>;
      try {
        state = AppUserRes.fromJson(appUserJson);
      } catch (e) {
        fetch();
      }
    }
  }

  Future<AppUserRes?> fetch() async {
    if (_authUser == null) {
      return null;
    }
    return await ApiService.getAppUser(_authUser.id).then((res) {
      if (res != null) {
        set(res);
      }
      return res;
    });
  }

  void set(AppUserRes appUser) {
    Hive.box("session").put("appUser", jsonEncode(appUser.toJson()));
    state = appUser;
  }

  void destroy() {
    Hive.box("session").delete("appUser");
    state = null;
  }
}
