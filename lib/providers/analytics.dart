import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'transactions.dart';
import 'debts.dart';
import 'business.dart';
import 'inventory.dart';
import '../backend-api/sync_service.dart';
import '../backend-api/api_service.dart';
import '../backend-api/dtos.dart';

enum InsightType { achievement, warning, alert }

class Insight {
  final String title;
  final String message;
  final InsightType type;

  Insight({required this.title, required this.message, required this.type});
}

class AnalyticsState {
  final List<Insight> insights;
  final double totalSales; // Brutas (Inventario)
  final double realProfit; // Margen Producto (Ventas - COGS)
  final double profitMargin; // %
  final double monthlyPrediction;
  final String periodLabel;
  final List<TransactionRes> filteredTransactions;
  final List<DebtRes> filteredDebts;
  
  // Desglose
  final double directIncome;
  final double directExpenses;
  final double inventorySales;
  final double cogs;
  
  // Nuevas métricas
  final double operationalLoad; // % de ganancia que se va en gastos
  final double netCashBalance; // Direct Income - Direct Expenses
  final Map<String, double> expensesByCategory;

  AnalyticsState({
    required this.insights,
    required this.totalSales,
    required this.realProfit,
    required this.profitMargin,
    required this.monthlyPrediction,
    required this.periodLabel,
    required this.filteredTransactions,
    required this.filteredDebts,
    required this.directIncome,
    required this.directExpenses,
    required this.inventorySales,
    required this.cogs,
    required this.operationalLoad,
    required this.netCashBalance,
    required this.expensesByCategory,
  });
}

enum StatisticsFilter { today, thisWeek, thisMonth, custom }

final statisticsFilterProvider = StateProvider<StatisticsFilter>((ref) => StatisticsFilter.thisMonth);
final statisticsCustomRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final transactionItemsProvider = FutureProvider<List<TransactionItemRes>>((ref) async {
  final business = ref.watch(businessProvider);
  if (business == null) return [];
  
  final cached = SyncService.getCachedTransactionItems(business.id);
  
  try {
    if (await SyncService.isOnline()) {
      final remote = await ApiService.getAllTransactionItemsByBusiness(business.id);
      await SyncService.cacheTransactionItems(business.id, remote);
      return remote;
    }
  } catch (_) {}
  
  return cached;
});

final analyticsProvider = Provider<AnalyticsState>((ref) {
  final transactionsAsync = ref.watch(historicTransactionsProvider);
  final debtsAsync = ref.watch(debtsProvider);
  final transactionItemsAsync = ref.watch(transactionItemsProvider);
  final filter = ref.watch(statisticsFilterProvider);
  final customRange = ref.watch(statisticsCustomRangeProvider);

  final transactionItems = transactionItemsAsync.maybeWhen(
    data: (items) => items,
    orElse: () => <TransactionItemRes>[],
  );

  final now = DateTime.now();
  DateTime startDate;
  DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  String periodLabel = "";

  switch (filter) {
    case StatisticsFilter.today:
      startDate = DateTime(now.year, now.month, now.day);
      periodLabel = "Hoy";
      break;
    case StatisticsFilter.thisWeek:
      startDate = now.subtract(Duration(days: now.weekday - 1));
      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      periodLabel = "Esta Semana";
      break;
    case StatisticsFilter.thisMonth:
      startDate = DateTime(now.year, now.month, 1);
      periodLabel = "Este Mes";
      break;
    case StatisticsFilter.custom:
      if (customRange != null) {
        startDate = customRange.start;
        endDate = customRange.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        periodLabel = "Personalizado";
      } else {
        startDate = DateTime(now.year, now.month, 1);
        periodLabel = "Este Mes";
      }
      break;
  }

  return transactionsAsync.maybeWhen(
    data: (transactions) {
      final filteredTxs = transactions.where((tx) => 
        tx.transactionDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
        tx.transactionDate.isBefore(endDate.add(const Duration(seconds: 1)))
      ).toList();

      final filteredDebts = debtsAsync.maybeWhen(
        data: (debts) => debts.where((d) => 
          d.createdAt.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          d.createdAt.isBefore(endDate.add(const Duration(seconds: 1)))
        ).toList(),
        orElse: () => <DebtRes>[],
      );

      // 1. Ventas Totales (Brutas del Periodo - SOLO INVENTARIO)
      final filteredTxIds = filteredTxs.map((tx) => tx.id).toSet();
      final filteredDebtIds = filteredDebts.map((d) => d.id).toSet();

      final periodItems = transactionItems.where((item) => 
        (item.transactionId != null && filteredTxIds.contains(item.transactionId)) ||
        (item.debtId != null && filteredDebtIds.contains(item.debtId))
      ).toList();

      final inventorySales = periodItems.fold(0.0, (sum, item) => sum + item.subtotal);
      final totalSales = inventorySales; // ÚNICAMENTE sumando subtotal de transaction_items

      // 2. Ganancia Real (Margen de Producto)
      final cogs = periodItems.fold(0.0, (sum, item) => sum + (item.unitCost * item.quantity));
      final realProfit = totalSales - cogs;

      // 3. Margen de Producto (%)
      final profitMargin = totalSales > 0 ? (realProfit / totalSales) * 100 : 0.0;

      // 4. Gastos e Ingresos Directos (Flujo de Caja)
      final directIncome = filteredTxs
          .where((tx) => tx.type == 'income' && tx.description != 'Venta de productos en inventario')
          .fold(0.0, (sum, tx) => sum + tx.amount);

      final directExpenses = filteredTxs
          .where((tx) => tx.type == 'expense')
          .fold(0.0, (sum, tx) => sum + tx.amount);

      final netCashBalance = directIncome - directExpenses;

      // 5. Carga Operativa
      final operationalLoad = realProfit > 0 ? (directExpenses / realProfit) * 100 : 0.0;

      // 6. Gastos por Categoría (Semáforo)
      final Map<String, double> expensesByCategory = {};
      for (var tx in filteredTxs.where((tx) => tx.type == 'expense')) {
        expensesByCategory[tx.category] = (expensesByCategory[tx.category] ?? 0) + tx.amount;
      }

      // 7. Insights
      final List<Insight> insights = [];

      // Insight de Carga Operativa
      if (operationalLoad > 40) {
        insights.add(Insight(
          title: "Alta Carga Operativa",
          message: "⚠️ Tus gastos operativos consumen el ${operationalLoad.toStringAsFixed(1)}% de tus ganancias. Intenta mantenerlo por debajo del 40%.",
          type: InsightType.alert,
        ));
      }

      // Mezcla de Gastos
      final personalExpenses = filteredTxs.where((tx) => 
        tx.type == 'expense' && 
        ['Personal', 'Hogar', 'Comida propia', 'Salud Personal'].contains(tx.category)
      );
      if (personalExpenses.isNotEmpty) {
        insights.add(Insight(
          title: "Mezcla de Gastos",
          message: "💡 Tip: Evita pagar antojos o gastos personales directo de la caja del negocio. Asígnate un sueldo fijo.",
          type: InsightType.warning,
        ));
      }

      // Semáforo de Riesgo por Fiado
      final expiredDebts = debtsAsync.maybeWhen(
        data: (debts) => debts.where((d) => 
          d.type == 'to_collect' && 
          d.status == 'pending' && 
          d.dueDate != null && 
          d.dueDate!.isBefore(now)
        ).toList(),
        orElse: () => <DebtRes>[],
      );

      if (expiredDebts.isNotEmpty) {
        final totalExpired = expiredDebts.fold(0.0, (sum, d) => sum + d.remainingAmount);
        insights.add(Insight(
          title: "Semáforo de Riesgo",
          message: "⚠️ Alerta: Tienes C\$ ${totalExpired.toStringAsFixed(2)} en deudas vencidas. Prioriza la cobranza para no perder liquidez.",
          type: InsightType.alert,
        ));
      }

      // Alerta de Inactividad
      if (filter == StatisticsFilter.today && totalSales == 0) {
        insights.add(Insight(
          title: "Inactividad",
          message: "📉 Movimiento: No has registrado ventas el día de hoy. ¡Mantén el ritmo!",
          type: InsightType.alert,
        ));
      }

      // 5. Predicción
      // Basada en ingresos acumulados del mes actual (no solo del filtro si el filtro es hoy/semana)
      // Pero el prompt dice "basándote en el promedio diario transaccionado hasta el día de hoy del calendario"
      // Entiendo que es la proyección del CIERRE DEL MES.
      final startOfMonth = DateTime(now.year, now.month, 1);
      final monthIncome = transactions
          .where((tx) => tx.type == 'income' && tx.transactionDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1))))
          .fold(0.0, (sum, tx) => sum + tx.amount);
      
      final dayOfMonth = now.day;
      final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final monthlyPrediction = dayOfMonth > 0 ? (monthIncome / dayOfMonth) * totalDaysInMonth : 0.0;

      return AnalyticsState(
        insights: insights,
        totalSales: totalSales,
        realProfit: realProfit,
        profitMargin: profitMargin,
        monthlyPrediction: monthlyPrediction,
        periodLabel: periodLabel,
        filteredTransactions: filteredTxs,
        filteredDebts: filteredDebts,
        directIncome: directIncome,
        inventorySales: inventorySales,
        directExpenses: directExpenses,
        cogs: cogs,
        operationalLoad: operationalLoad,
        netCashBalance: netCashBalance,
        expensesByCategory: expensesByCategory,
      );
    },
    orElse: () => AnalyticsState(
      insights: [],
      totalSales: 0,
      realProfit: 0,
      profitMargin: 0,
      monthlyPrediction: 0,
      periodLabel: periodLabel,
      filteredTransactions: [],
      filteredDebts: [],
      directIncome: 0,
      inventorySales: 0,
      directExpenses: 0,
      cogs: 0,
      operationalLoad: 0,
      netCashBalance: 0,
      expensesByCategory: {},
    ),
  );
});
