import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../backend-api/api_service.dart';
import '../backend-api/dtos.dart';
import 'auth_user.dart';

final patientProvider =
    StateNotifierProvider.autoDispose<PatientNotifier, PatientRes?>(
      (ref) => PatientNotifier(ref.watch(authUserProvider)),
    );

class PatientNotifier extends StateNotifier<PatientRes?> {
  final AuthUserRes? _authUser;

  PatientNotifier(this._authUser) : super(null) {
    final patient = Hive.box("session").get("patient");
    if (patient != null) {
      final patientJson = jsonDecode(patient) as Map<String, dynamic>;
      try {
        state = PatientRes.fromJson(patientJson);
      } catch (e) {
        fetch();
      }
    }
  }

  Future<PatientRes?> fetch() async {
    if (_authUser == null) {
      return null;
    }
    return await ApiService.getPatient(_authUser.id).then((res) {
      if (res != null) {
        set(res);
      }
      return res;
    });
  }

  void set(PatientRes patient) {
    Hive.box("session").put("patient", jsonEncode(patient.toJson()));
    state = patient;
  }

  void destroy() {
    Hive.box("session").delete("patient");
    state = null;
  }
}
