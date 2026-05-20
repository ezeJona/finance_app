import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../providers/healthcare_facilities.dart';

class MapPage extends HookConsumerWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthcareFacilities = ref.watch(healthcareFacilitiesProvider);
    final markers = useState<Set<Marker>>({});
    final mapController = useState<GoogleMapController?>(null);

    useEffect(() {
      ref.read(healthcareFacilitiesProvider.notifier).fetch();
      return;
    }, []);

    useEffect(() {
      Set<Marker> currentMarkers = {};
      for (var facility in (healthcareFacilities ?? [])) {
        currentMarkers.add(
          Marker(
            markerId: MarkerId(facility.id.toString()),
            position: LatLng(
              facility.latitude.toDouble(),
              facility.longitude.toDouble(),
            ),
            infoWindow: InfoWindow(
              title: facility.name,
              snippet: (facility.isPublicMinsa
                  ? "Público"
                  : (facility.servesInss ? "Privado / INSS" : "Privado")),
            ),
          ),
        );
      }
      markers.value = currentMarkers;
      return;
    }, [healthcareFacilities]);

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de hospitales')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: (healthcareFacilities ?? []).isNotEmpty
              ? LatLng(
                  healthcareFacilities!.first.latitude.toDouble(),
                  healthcareFacilities.first.longitude.toDouble(),
                )
              : const LatLng(12.13, -86.25), // fallback
          zoom: 12,
        ),
        markers: markers.value,
        onMapCreated: (controller) {
          mapController.value = controller;

          // Solo para web: habilitar controles
          if (kIsWeb) {
            controller.setMapStyle(
              null,
            ); // puedes personalizar el estilo si quieres
          }
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: !kIsWeb, // controles de zoom solo en móvil
      ),
    );
  }
}
