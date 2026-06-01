import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../backend-api/api_service.dart';
import '../backend-api/dtos.dart';
import '../backend-api/sync_service.dart';
import 'business.dart';
import 'transaction_filter.dart';

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, AsyncValue<List<TransactionRes>>>((ref) {
  final business = ref.watch(businessProvider);
  final filter = ref.watch(transactionFilterProvider);
  return TransactionsNotifier(ref, business, filter);
});

class TransactionsNotifier extends StateNotifier<AsyncValue<List<TransactionRes>>> {
  final Ref ref;
  final BusinessRes? business;
  final TransactionFilterState filter;

  TransactionsNotifier(this.ref, this.business, this.filter) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    if (business == null) {
      state = const AsyncValue.data([]);
      return;
    }

    // 1. Cargar desde Cache inmediatamente para que no haya parpadeo
    final cached = SyncService.getCachedTransactions(business!.id);
    if (cached.isNotEmpty && state is AsyncLoading) {
       state = AsyncValue.data(cached);
    }

    // 2. Determinar rangos de fecha para la petición
    DateTime? startDate;
    DateTime? endDate;
    int? limit;
    final now = DateTime.now();

    switch (filter.timeRange) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case 'last_5':
        limit = 5;
        break;
      case 'last_7':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'last_30':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'current_month':
        startDate = DateTime(filter.selectedMonthYear.year, filter.selectedMonthYear.month, 1);
        endDate = DateTime(filter.selectedMonthYear.year, filter.selectedMonthYear.month + 1, 0, 23, 59, 59);
        break;
      case 'custom_range':
        if (filter.customDateRange != null) {
          startDate = filter.customDateRange!.start;
          endDate = filter.customDateRange!.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        }
        break;
    }

    try {
      final fresh = await ApiService.getFilteredTransactions(
        businessId: business!.id,
        type: filter.flowType,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
      
      // Actualizamos cache local si es una vista general (sin filtros específicos de tipo o es la carga por defecto)
      if (filter.flowType == 'all' && (filter.timeRange == 'current_month' || filter.timeRange == 'last_30')) {
          SyncService.cacheTransactions(business!.id, fresh);
      }
      
      state = AsyncValue.data(fresh);
    } catch (e, st) {
      // Si falla la red pero tenemos cache, mantenemos el cache y mostramos error sutil si fuera necesario
      if (cached.isNotEmpty) {
        state = AsyncValue.data(cached);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  // Permite añadir una transacción localmente para UX instantánea
  void addOptimistic(TransactionRes tx) {
    state.whenData((list) {
      state = AsyncValue.data([tx, ...list]);
    });
    // También guardamos en cache para persistencia offline inmediata
    if (business != null) {
       final currentCache = SyncService.getCachedTransactions(business!.id);
       SyncService.cacheTransactions(business!.id, [tx, ...currentCache]);
    }
  }
}

// Mantenemos este para compatibilidad o simplificar, pero sin autoDispose
final historicTransactionsProvider = FutureProvider<List<TransactionRes>>((ref) async {
  final business = ref.watch(businessProvider);
  if (business == null) return [];
  
  final cached = SyncService.getCachedTransactions(business.id);
  
  try {
     final fresh = await ApiService.getTransactionsByBusiness(business.id);
     SyncService.cacheTransactions(business.id, fresh);
     return fresh;
  } catch (e) {
     return cached.isNotEmpty ? cached : [];
  }
});
