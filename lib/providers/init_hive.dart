// Hive is used for the local storage that the providers use.
import 'package:hive_flutter/hive_flutter.dart';

Future<void> initHive() async {
  await Hive.initFlutter();
  await Hive.openBox("general");
  await Hive.openBox('session');
}
