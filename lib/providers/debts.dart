import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../backend-api/api_service.dart';
import '../backend-api/dtos.dart';
import '../backend-api/sync_service.dart';
import 'business.dart';
import 'transactions.dart';
import 'inventory.dart';
import 'transaction_items.dart';
import 'analytics.dart';

final debtsProvider = StateNotifierProvider<DebtsNotifier, AsyncValue<List<DebtRes>>>((ref) {
  final business = ref.watch(businessProvider);
  return DebtsNotifier(ref, business?.id);
});

class DebtsNotifier extends StateNotifier<AsyncValue<List<DebtRes>>> {
  final Ref ref;
  final int? businessId;

  DebtsNotifier(this.ref, this.businessId) : super(const AsyncValue.loading()) {
    if (businessId != null) {
      _loadInitialData();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> _loadInitialData() async {
    // 1. Cargar desde cache instantáneamente
    final cached = SyncService.getCachedDebts(businessId!);
    if (cached.isNotEmpty) {
      state = AsyncValue.data(cached);
    }
    
    // 2. Sincronizar con red en segundo plano
    await fetchDebts();
  }

  Future<void> fetchDebts() async {
    if (businessId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    try {
      if (!await SyncService.isOnline()) return;
      
      final debts = await ApiService.fetchDebtsByBusiness(businessId!);
      SyncService.cacheDebts(businessId!, debts);
      state = AsyncValue.data(debts);
    } catch (e, st) {
      if (state.hasValue) {
         // Keep existing data on error
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> addDebt(CreateDebtReq req) async {
    try {
      final newDebt = await ApiService.createDebt(req);
      
      // Actualización optimista inmediata
      state.whenData((list) {
         state = AsyncValue.data([newDebt, ...list]);
         SyncService.cacheDebts(businessId!, state.value!);
      });
      
      await fetchDebts(); 
      _invalidateRelatedProviders();
    } catch (e) {
      fetchDebts();
      rethrow;
    }
  }

  Future<void> updateDebt(String id, CreateDebtReq req) async {
    try {
      final updatedDebt = await ApiService.updateDebt(id, req);
      
      state.whenData((list) {
        final newList = list.map((d) => d.id == id ? updatedDebt : d).toList();
        state = AsyncValue.data(newList);
        if (businessId != null) SyncService.cacheDebts(businessId!, newList);
      });

      await fetchDebts();
      _invalidateRelatedProviders();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDebt(String id) async {
    try {
      await ApiService.deleteDebt(id);
      
      state.whenData((list) {
        final newList = list.where((d) => d.id != id).toList();
        state = AsyncValue.data(newList);
        if (businessId != null) SyncService.cacheDebts(businessId!, newList);
      });

      await fetchDebts();
      _invalidateRelatedProviders();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addPayment(CreateDebtPaymentReq req) async {
    try {
      final newPayment = await ApiService.createDebtPayment(req);
      
      // 1. Actualización optimista del estado de la deuda (Saldo restante)
      state.whenData((debts) {
        final index = debts.indexWhere((d) => d.id == req.debtId);
        if (index != -1) {
          final debt = debts[index];
          final newRemaining = (debt.remainingAmount - req.amount).clamp(0.0, debt.totalAmount);
          final newStatus = newRemaining <= 0 ? 'paid' : 'pending';
          
          final updatedDebt = debt.copyWith(
            remainingAmount: newRemaining,
            status: newStatus,
          );
          
          final newList = List<DebtRes>.from(debts);
          newList[index] = updatedDebt;
          state = AsyncValue.data(newList);
          
          // Actualizar cache de deudas
          if (businessId != null) {
            SyncService.cacheDebts(businessId!, newList);
          }
        }
      });

      // 2. Actualizar cache de abonos para que el historial sea visible offline
      final currentPayments = SyncService.getCachedDebtPayments(req.debtId);
      await SyncService.cacheDebtPayments(req.debtId, [newPayment, ...currentPayments]);
      
      // 3. Notificar a otros proveedores
      ref.invalidate(debtPaymentsProvider(req.debtId));
      _invalidateRelatedProviders();
      
      // 4. Intentar refrescar desde la nube si hay internet
      await fetchDebts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePayment(String id, CreateDebtPaymentReq req) async {
    try {
      await ApiService.updateDebtPayment(id, req);
      
      // Actualizar historial local
      final currentPayments = SyncService.getCachedDebtPayments(req.debtId);
      final index = currentPayments.indexWhere((p) => p.id == id);
      if (index != -1) {
        // Nota: Tendríamos que convertir req a res, pero ApiService ya lo hace si está online.
        // Si no está online, ApiService devuelve algo optimista.
        // Por simplicidad, refrescamos el provider.
      }
      
      await fetchDebts();
      ref.invalidate(debtPaymentsProvider(req.debtId));
      _invalidateRelatedProviders();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePayment(String id) async {
    try {
      // Necesitamos el debtId antes de borrar para refrescar
      // En una implementación real, buscaríamos en el cache.
      await ApiService.deleteDebtPayment(id);
      await fetchDebts();
      _invalidateRelatedProviders();
    } catch (e) {
      rethrow;
    }
  }

  void _invalidateRelatedProviders() {
    ref.invalidate(transactionsProvider);
    ref.invalidate(historicTransactionsProvider);
    ref.invalidate(transactionItemsProvider);
    ref.invalidate(executiveFinancialsProvider);
  }
}

final debtPaymentsProvider = FutureProvider.family<List<DebtPaymentRes>, String>((ref, debtId) async {
  final cached = SyncService.getCachedDebtPayments(debtId);
  try {
    if (!await SyncService.isOnline()) return cached;
    
    final payments = await ApiService.fetchDebtPayments(debtId);
    SyncService.cacheDebtPayments(debtId, payments);
    return payments;
  } catch (e) {
    return cached;
  }
});

final debtsSummaryProvider = Provider<({double toCollect, double toPay, int debtors, int creditors})>((ref) {
  final debtsAsync = ref.watch(debtsProvider);
  
  return debtsAsync.maybeWhen(
    data: (debts) {
      double toCollect = 0;
      double toPay = 0;
      Set<String> debtorsSet = {};
      Set<String> creditorsSet = {};

      for (var debt in debts) {
        if (debt.status == 'pending') {
          if (debt.type == 'to_collect') {
            toCollect += debt.remainingAmount;
            debtorsSet.add(debt.contactName);
          } else {
            toPay += debt.remainingAmount;
            creditorsSet.add(debt.contactName);
          }
        }
      }

      return (
        toCollect: toCollect,
        toPay: toPay,
        debtors: debtorsSet.length,
        creditors: creditorsSet.length,
      );
    },
    orElse: () => (toCollect: 0.0, toPay: 0.0, debtors: 0, creditors: 0),
  );
});
