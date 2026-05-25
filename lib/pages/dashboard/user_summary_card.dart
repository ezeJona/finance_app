import 'package:flutter/material.dart';

import '../../backend-api/dtos.dart';
import '../../text_styles.dart';

class UserSummaryCard extends StatelessWidget {
  const UserSummaryCard({
    super.key,
    required this.appUser,
    required this.business,
  });

  final AppUserRes appUser;
  final BusinessRes business;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
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
                   const Text(
                    "Usuario",
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${appUser.firstName}${appUser.secondName != null ? ' ${appUser.secondName}' : ' '}${appUser.firstLastName}${appUser.secondLastName != null ? ' ${appUser.secondLastName}' : ' '}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Negocio",
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    business.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00A86B)),
                    textAlign: TextAlign.end,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${business.businessType} • ${business.currencyCode}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
