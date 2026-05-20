// destroySession is typically called on sign out to reset session related providers.

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'appointments.dart';
import 'app_user.dart';
import 'auth_user.dart';
import 'patient.dart';

void destroySession(WidgetRef ref) {
  ref.read(appointmentsProvider.notifier).destroy();
  ref.read(appUserProvider.notifier).destroy();
  ref.read(authUserProvider.notifier).destroy();
  ref.read(patientProvider.notifier).destroy();
}
