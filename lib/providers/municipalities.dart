import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../backend-api/api_service.dart';
import '../backend-api/dtos.dart';

final municipalitiesProvider =
    StateNotifierProvider<MunicipalitiesNotifier, List<MunicipalityRes>?>((_) {
      return MunicipalitiesNotifier();
    });

class MunicipalitiesNotifier extends StateNotifier<List<MunicipalityRes>?> {
  MunicipalitiesNotifier() : super(null) {
    final municipalities = Hive.box("general").get("municipalities");
    if (municipalities != null) {
      final municipalitiesJson = jsonDecode(municipalities);
      try {
        state = List<MunicipalityRes>.from(
          municipalitiesJson.map(
            (municipality) => MunicipalityRes.fromJson(municipality),
          ),
        );
      } catch (e) {
        fetch();
      }
    }
  }

  Future<List<MunicipalityRes>?> fetch() async {
    return await ApiService.getMunicipalities().then((res) {
      if (res != null) {
        state = res;
      }
      _persist();
      return res;
    });
  }

  void _persist() {
    if (state == null) {
      Hive.box("general").delete("municipalities");
    } else {
      Hive.box("general").put(
        "municipalities",
        jsonEncode(
          List<dynamic>.from(
            (state as List<MunicipalityRes>).map(
              (municipality) => municipality.toJson(),
            ),
          ),
        ),
      );
    }
  }

  void destroy() {
    Hive.box("general").delete("municipalities");
    state = null;
  }
}
