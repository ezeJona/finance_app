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
import 'analytics.dart';

final syncProvider = Provider<void>((ref) {
  final connectivity = ref.watch(connectivityStatusProvider);
  final business = ref.watch(businessProvider);

  // Usamos ref.listen para reaccionar a cambios de conectividad sin causar efectos secundarios en el build
  ref.listen(connectivityStatusProvider, (previous, next) {
    if (next == ConnectivityStatus.isConnected) {
      SyncService.processQueue().then((_) {
        _invalidateAll(ref);
      });
    }
  });

  // Reaccionar al cambio de negocio
  ref.listen(businessProvider, (previous, next) {
    if (next != null && connectivity == ConnectivityStatus.isConnected) {
      SyncService.fullSync(next.id).then((_) {
        _invalidateAll(ref);
      });
    }
  });
});

void _invalidateAll(Ref ref) {
  ref.invalidate(transactionsProvider);
  ref.invalidate(historicTransactionsProvider);
  ref.read(debtsProvider.notifier).fetchDebts();
  ref.invalidate(productCategoriesProvider);
  ref.invalidate(productsProvider);
  ref.invalidate(transactionItemsProvider);
  ref.invalidate(executiveFinancialsProvider);
  ref.invalidate(inventoryPerformanceProvider);
}

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
