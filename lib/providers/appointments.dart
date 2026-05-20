import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../backend-api/api_service.dart';
import '../backend-api/dtos.dart';
import 'patient.dart';

final appointmentsProvider =
    StateNotifierProvider.autoDispose<
      AppointmentsNotifier,
      List<AppointmentRes>?
    >((ref) => AppointmentsNotifier(ref.watch(patientProvider)));

class AppointmentsNotifier extends StateNotifier<List<AppointmentRes>?> {
  final PatientRes? _patient;

  AppointmentsNotifier(this._patient) : super(null) {
    final appointments = Hive.box("session").get("appointments");
    if (appointments != null) {
      final appointmentsJson = jsonDecode(appointments);
      try {
        state = List<AppointmentRes>.from(
          appointmentsJson.map(
            (appointmentJson) => AppointmentRes.fromJson(appointmentJson),
          ),
        );
      } catch (e) {
        fetch();
      }
    }
  }

  Future<List<AppointmentRes>?> fetch() async {
    if (_patient == null) {
      return null;
    }
    return await ApiService.getAppointmentsByPatientId(_patient.id).then((res) {
      if (res != null) {
        state = res;
      }
      _persist();
      return res;
    });
  }

  void _persist() {
    if (state == null) {
      Hive.box("session").delete("appointments");
    } else {
      Hive.box("session").put(
        "appointments",
        jsonEncode(
          List<dynamic>.from(
            (state as List<AppointmentRes>).map(
              (appointment) => appointment.toJson(),
            ),
          ),
        ),
      );
    }
  }

  void destroy() {
    Hive.box("session").delete("appointments");
    state = null;
  }
}
