import 'package:flutter/material.dart';

import '../colors.dart';
import '../text_styles.dart';

Future<void> warningDialog({
  required BuildContext context,
  required String title,
  required String infoText,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
        ),
        title: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Text(title, style: HospiredTextStyle.body4),
        ),
        surfaceTintColor: Colors.transparent,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: HospiredColors.danger,
                  size: 32,
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                infoText,
                style: HospiredTextStyle.body2,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Ok',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: HospiredColors.primary,
              ),
            ),
          ),
        ],
      );
    },
  );
}
