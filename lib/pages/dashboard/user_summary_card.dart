import 'package:flutter/material.dart';

import '../../backend-api/dtos.dart';
import '../../text_styles.dart';

class UserSummaryCard extends StatelessWidget {
  const UserSummaryCard({
    super.key,
    required this.appUser,
    required this.patient,
  });

  final AppUserRes appUser;
  final PatientRes patient;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${appUser.firstName}${appUser.secondName != null ? ' ${appUser.secondName}' : ' '}${appUser.firstLastName}${appUser.secondLastName != null ? ' ${appUser.secondLastName}' : ' '}",
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Cédula", style: HospiredTextStyle.body2Bold),
                  const SizedBox(height: 2),
                  Text(patient.nationalId, style: HospiredTextStyle.body2),
                  const SizedBox(height: 12),
                  if (patient.inssId != null) ...[
                    Text("No INSS", style: HospiredTextStyle.body2Bold),
                    const SizedBox(height: 2),
                    Text("${patient.inssId}", style: HospiredTextStyle.body2),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
