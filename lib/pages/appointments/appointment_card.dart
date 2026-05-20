import 'package:flutter/material.dart';

import '../../backend-api/dtos.dart';
import '../../text_styles.dart';
import 'appointment_tag.dart';

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onTap,
  });

  final AppointmentRes appointment;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onTap(),
        child: Container(
          height: 96,
          width: 144,
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    appointment.status == 'requested'
                        ? "# Solicitud:"
                        : "# Cita:",
                    style: HospiredTextStyle.body2Bold,
                  ),
                  const SizedBox(width: 8),
                  Text("${appointment.id}"),
                ],
              ),
              const Spacer(),
              Row(children: [AppointmentTag(status: appointment.status)]),
            ],
          ),
        ),
      ),
    );
  }
}
