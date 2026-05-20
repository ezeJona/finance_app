import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../backend-api/api_service.dart';
import '../../backend-api/dtos.dart';
import '../../breakpoints.dart';
import '../../colors.dart';
import '../../text_styles.dart';
import 'appointment_tag.dart';

class AppointmentPage extends HookConsumerWidget {
  const AppointmentPage({super.key, required this.appointment});

  final AppointmentRes appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fetching = useState<bool>(true);
    final facilityUnit = useState<FacilityUnitRes?>(null);
    final facility = useState<HealthcareFacilityRes?>(null);

    final fetchLocationAndPhysician = useCallback(() async {
      if (appointment.facilityUnitId == null) {
        fetching.value = false;
        return;
      }
      fetching.value = true;
      try {
        final facilityResponse = await ApiService.getFacilityUnit(
          appointment.facilityUnitId!,
        );
        if (facilityResponse != null) {
          facilityUnit.value = facilityResponse;
          final healthcareFacilityResponse =
              await ApiService.getHealthcareFacility(
                facilityResponse.facilityId,
              );
          facility.value = healthcareFacilityResponse;
        }
      } catch (e) {
        print(e);
      } finally {
        fetching.value = false;
      }
    }, []);

    final navigateBack = useCallback((BuildContext context) {
      facilityUnit.value = null;
      facility.value = null;
      Navigator.pop(context);
    }, []);

    useEffect(() {
      fetchLocationAndPhysician();
      return;
    }, []);

    if (fetching.value) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                "Cargando detalles de la cita...",
                style: HospiredTextStyle.body3.copyWith(
                  color: HospiredColors.confirmedForegroundColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => navigateBack(context),
        ),
        title: const Text('Detalles de Cita'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
          constraints: BoxConstraints(maxWidth: Breakpoint.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment.status == "requested"
                    ? "Solicitud # ${appointment.id}"
                    : "Cita # ${appointment.id}",
                style: HospiredTextStyle.sectionTitle,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text("Estado:", style: HospiredTextStyle.body2Bold),
                  const SizedBox(width: 8),
                  AppointmentTag(status: appointment.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text("Motivo:", style: HospiredTextStyle.body2Bold),
                  const SizedBox(width: 8),
                  Text(appointment.motive, style: HospiredTextStyle.body2),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text("Fecha:", style: HospiredTextStyle.body2Bold),
                  const SizedBox(width: 8),
                  Text(
                    appointment.start != null
                        ? DateFormat('dd/MM/yyyy').format(appointment.start!)
                        : "No se ha asignado la fecha",
                    style: HospiredTextStyle.body2,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text("Hora:", style: HospiredTextStyle.body2Bold),
                  const SizedBox(width: 8),
                  Text(
                    appointment.start != null && appointment.end != null
                        ? "${DateFormat('hh:mm a').format(appointment.start!)} - ${DateFormat('hh:mm a').format(appointment.end!)} "
                        : "No se ha asignado la hora",
                    style: HospiredTextStyle.body2,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Lugar de atención:",
                    style: HospiredTextStyle.body2Bold,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (facilityUnit.value == null &&
                          facility.value == null) ...[
                        Text(
                          "No se ha asignado el lugar de atención.",
                          style: HospiredTextStyle.body2,
                        ),
                      ] else ...[
                        if (facilityUnit.value != null) ...[
                          Text(
                            facilityUnit.value!.name,
                            style: HospiredTextStyle.body2,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            facilityUnit.value!.indications ?? '',
                            style: HospiredTextStyle.body2,
                          ),
                        ],
                        if (facility.value != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            facility.value!.name,
                            style: HospiredTextStyle.body2.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
              if (facility.value != null) ...[
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dirección:", style: HospiredTextStyle.body2Bold),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facility.value!.address,
                          style: HospiredTextStyle.body2,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          facility.value!.district,
                          style: HospiredTextStyle.body2,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (appointment.status != "canceled" &&
                      appointment.status != "completed" &&
                      appointment.status != "no-show")
                    ElevatedButton(
                      onPressed: () {},
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          HospiredColors.danger.withAlpha(120),
                        ),
                      ),
                      child: Text("Cancelar"),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => navigateBack(context),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        HospiredColors.primaryLight,
                      ),
                    ),
                    child: Text("Regresar"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
