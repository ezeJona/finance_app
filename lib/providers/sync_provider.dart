import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../backend-api/sync_service.dart';
import 'connectivity.dart';
import 'business.dart';
import 'transactions.dart';
import 'debts.dart';
import 'inventory.dart';
import 'transaction_items.dart';

final syncProvider = Provider<void>((ref) {
  final connectivity = ref.watch(connectivityStatusProvider);
  final business = ref.watch(businessProvider);

  if (connectivity == ConnectivityStatus.isConnected) {
    // Cuando recuperamos conexión, procesamos la cola
    SyncService.processQueue().then((_) {
      // Invalidamos providers para refrescar datos desde la nube
      ref.invalidate(transactionsProvider);
      ref.invalidate(historicTransactionsProvider);
      ref.read(debtsProvider.notifier).fetchDebts();
      ref.invalidate(productCategoriesProvider);
      ref.invalidate(productsProvider);
      ref.invalidate(transactionItemsProvider);
    });
  }
  
  // Sincronización completa al cambiar de negocio o iniciar sesión
  if (business != null) {
    // Solo ejecutamos fullSync si estamos online
    if (connectivity == ConnectivityStatus.isConnected) {
      SyncService.fullSync(business.id).then((_) {
        ref.invalidate(transactionsProvider);
        ref.invalidate(historicTransactionsProvider);
        ref.read(debtsProvider.notifier).fetchDebts();
        ref.invalidate(productCategoriesProvider);
        ref.invalidate(productsProvider);
        ref.invalidate(transactionItemsProvider);
      });
    }
  }
});

final syncQueueCountProvider = StreamProvider<int>((ref) {
  final box = Hive.box('sync_queue');
  final controller = StreamController<int>();
  
  // Emitir valor inicial
  controller.add(box.length);
  
  // Escuchar cambios en la caja de Hive
  final listener = box.watch().listen((event) {
    if (!controller.isClosed) {
      controller.add(box.length);
    }
  });
  
  ref.onDispose(() {
    listener.cancel();
    controller.close();
  });
  
  return controller.stream;
});
