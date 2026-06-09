import 'package:hive_flutter/hive_flutter.dart';

Future<void> initHive() async {
  await Hive.initFlutter();
  await Hive.openBox("general");
  await Hive.openBox('session');
  
  // Cajas para Offline-First
  await Hive.openBox('businesses_cache');
  await Hive.openBox('transactions_cache');
  await Hive.openBox('debts_cache');
  await Hive.openBox('categories_cache');
  await Hive.openBox('products_cache');
  await Hive.openBox('sync_queue');
}
