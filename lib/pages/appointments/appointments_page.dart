import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../colors.dart';
import '../../text_styles.dart';
import '../../breakpoints.dart';
import '../../providers/appointments.dart';
import 'appointment_card.dart';

class AppointmentsPage extends HookConsumerWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(appointmentsProvider);

    final requestedAppointments =
        appointments
            ?.where((appointment) => appointment.status == "requested")
            .toList() ??
        [];
    final upcomingAppointments =
        appointments
            ?.where((appointment) => appointment.status == "scheduled")
            .toList() ??
        [];
    final pastAppointments =
        appointments
            ?.where(
              (appointment) =>
                  appointment.status == "completed" ||
                  appointment.status == "canceled" ||
                  appointment.status == "no_show",
            )
            .toList() ??
        [];

    useEffect(() {
      ref.read(appointmentsProvider.notifier).fetch();
      return;
    }, []);

    return Center(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
        constraints: BoxConstraints(maxWidth: Breakpoint.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [Text('Citas', style: HospiredTextStyle.sectionTitle)],
            ),
            const SizedBox(height: 24),
            Text("Solicitudes", style: HospiredTextStyle.body3Bold),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: requestedAppointments.length + 1,
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(width: 8, height: 8);
                },
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/home/request-appointment',
                      ),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          HospiredColors.white,
                        ),
                        elevation: WidgetStateProperty.all(0),
                        fixedSize: WidgetStateProperty.all(const Size(160, 96)),
                      ),
                      child: Text(
                        '+ Solicitar cita',
                        style: HospiredTextStyle.body2Bold.copyWith(
                          color: HospiredColors.primary,
                        ),
                      ),
                    );
                  }
                  return AppointmentCard(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/home/appointment',
                      arguments: requestedAppointments[index - 1],
                    ),
                    appointment: requestedAppointments[index - 1],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text("Programadas", style: HospiredTextStyle.body3Bold),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: upcomingAppointments.isNotEmpty
                    ? upcomingAppointments.length
                    : 1,
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(width: 8, height: 8);
                },
                itemBuilder: (BuildContext context, int index) {
                  if (upcomingAppointments.isEmpty) {
                    return Container(
                      height: 96,
                      width: 160,
                      margin: const EdgeInsets.all(0),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: HospiredColors.gray,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'No hay citas programadas.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return AppointmentCard(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/home/appointment',
                      arguments: upcomingAppointments[index],
                    ),
                    appointment: upcomingAppointments[index],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text("Pasadas", style: HospiredTextStyle.body3Bold),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pastAppointments.isNotEmpty
                    ? pastAppointments.length
                    : 1,
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(width: 8, height: 8);
                },
                itemBuilder: (BuildContext context, int index) {
                  if (pastAppointments.isEmpty) {
                    return Container(
                      height: 96,
                      width: 160,
                      margin: const EdgeInsets.all(0),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: HospiredColors.gray,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'No hay citas pasadas.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return AppointmentCard(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/home/appointment',
                      arguments: pastAppointments[index],
                    ),
                    appointment: pastAppointments[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
