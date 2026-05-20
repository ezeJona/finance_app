import 'package:flutter/material.dart';

import '../../colors.dart';

class NextAppointmentCard extends StatelessWidget {
  const NextAppointmentCard({super.key, required this.onTap});

  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onTap(),
        child: Container(
          height: 96,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: HospiredColors.gray, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(child: Text('No hay citas programadas.')),
        ),
      ),
    );
  }
}
