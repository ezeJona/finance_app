import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../backend-api/api_service.dart';
import '../backend-api/dtos.dart';

final healthcareFacilitiesProvider =
    StateNotifierProvider<
      HealthcareFacilitiesNotifier,
      List<HealthcareFacilityRes>?
    >((_) {
      return HealthcareFacilitiesNotifier();
    });

class HealthcareFacilitiesNotifier
    extends StateNotifier<List<HealthcareFacilityRes>?> {
  HealthcareFacilitiesNotifier() : super(null) {
    final facilities = Hive.box("general").get("healthcareFacilities");
    if (facilities != null) {
      final facilitiesJson = jsonDecode(facilities);
      try {
        state = List<HealthcareFacilityRes>.from(
          facilitiesJson.map(
            (facility) => HealthcareFacilityRes.fromJson(facility),
          ),
        );
      } catch (e) {
        fetch();
      }
    }
  }

  Future<List<HealthcareFacilityRes>?> fetch() async {
    return await ApiService.getHealthcareFacilities().then((res) {
      state = res;
      _persist();
      return res;
    });
  }

  void _persist() {
    if (state == null) {
      Hive.box("general").delete("healthcareFacilities");
    } else {
      Hive.box("general").put(
        "healthcareFacilities",
        jsonEncode(
          List<dynamic>.from(
            (state as List<HealthcareFacilityRes>).map(
              (facility) => facility.toJson(),
            ),
          ),
        ),
      );
    }
  }

  void destroy() {
    Hive.box("general").delete("healthcareFacilities");
    state = null;
  }
}
