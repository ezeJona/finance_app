import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../backend-api/api_service.dart';
import '../backend-api/dtos.dart';
import 'business.dart';

final debtsProvider = StateNotifierProvider<DebtsNotifier, AsyncValue<List<DebtRes>>>((ref) {
  final business = ref.watch(businessProvider);
  return DebtsNotifier(business?.id);
});

class DebtsNotifier extends StateNotifier<AsyncValue<List<DebtRes>>> {
  final int? businessId;

  DebtsNotifier(this.businessId) : super(const AsyncValue.loading()) {
    if (businessId != null) {
      fetchDebts();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> fetchDebts() async {
    if (businessId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final debts = await ApiService.fetchDebtsByBusiness(businessId!);
      state = AsyncValue.data(debts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addDebt(CreateDebtReq req) async {
    try {
      final newDebt = await ApiService.createDebt(req);
      final currentDebts = state.value ?? [];
      state = AsyncValue.data([newDebt, ...currentDebts]);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addPayment(CreateDebtPaymentReq req) async {
    try {
      await ApiService.createDebtPayment(req);
      // Refresh to get updated remaining_amount and status from DB
      await fetchDebts();
    } catch (e) {
      rethrow;
    }
  }
}

// Provider for debts summary
final debtsSummaryProvider = Provider<({double toCollect, double toPay, int debtors, int creditors})>((ref) {
  final debtsAsync = ref.watch(debtsProvider);
  
  return debtsAsync.maybeWhen(
    data: (debts) {
      double toCollect = 0;
      double toPay = 0;
      Set<String> debtors = {};
      Set<String> creditors = {};

      for (var debt in debts) {
        if (debt.status == 'pending') {
          if (debt.type == 'to_collect') {
            toCollect += debt.remainingAmount;
            debtors.add(debt.contactName);
          } else {
            toPay += debt.remainingAmount;
            creditors.add(debt.contactName);
          }
        }
      }

      return (
        toCollect: toCollect,
        toPay: toPay,
        debtors: debtors.length,
        creditors: creditors.length,
      );
    },
    orElse: () => (toCollect: 0.0, toPay: 0.0, debtors: 0, creditors: 0),
  );
});
