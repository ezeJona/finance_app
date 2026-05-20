import 'package:flutter/material.dart';

import '../../colors.dart';
import '../../backend-api/enum_maps.dart';

Color tagColor(String status) {
  switch (status) {
    case 'requested':
      return HospiredColors.confirmedBgColor;
    case 'scheduled':
      return HospiredColors.confirmedForegroundColor;
    case 'completed':
      return HospiredColors.deliveredForegroundColor;
    case 'canceled':
      return HospiredColors.danger;
    case 'no-show':
      return HospiredColors.gray;
    default:
      return Colors.grey;
  }
}

class AppointmentTag extends StatelessWidget {
  const AppointmentTag({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: tagColor(status)),
        color: tagColor(status).withAlpha(70),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          appointmentStatus[status] ?? '',
          style: TextStyle(
            color: tagColor(status),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
