import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../text_styles.dart';
import '../../breakpoints.dart';

class TreatmentPage extends HookConsumerWidget {
  const TreatmentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
        constraints: BoxConstraints(maxWidth: Breakpoint.md),
        child: Column(
          children: [
            Text('Tratamiento', style: HospiredTextStyle.sectionTitle),
            const Spacer(),
            Text(
              'Esta función está en desarrollo.',
              style: HospiredTextStyle.body3,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
