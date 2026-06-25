import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'business.dart';
import 'transactions.dart';
import 'debts.dart';
import 'inventory.dart';
import '../backend-api/api_service.dart';
import '../backend-api/sync_service.dart';
import '../backend-api/dtos.dart';

enum InsightType { achievement, warning, alert }

class Insight {
  final String title;
  final String message;
  final InsightType type;

  Insight({required this.title, required this.message, required this.type});
}

enum StatisticsFilter { today, thisWeek, thisMonth, custom }

class AnalyticsState {
  final double totalSales;
  final double realProfit;
  final double profitMargin;
  final double operationalLoad;
  final double directIncome;
  final double directExpenses;
  final double netCashBalance;
  final double inventorySales;
  final double cogs;
  final double monthlyPrediction;
  final Map<String, double> expensesByCategory;
  final List<Insight> insights;
  final String periodLabel;
  final List<TransactionRes> filteredTransactions;
  final List<DebtRes> filteredDebts;

  AnalyticsState({
    required this.totalSales,
    required this.realProfit,
    required this.profitMargin,
    required this.operationalLoad,
    required this.directIncome,
    required this.directExpenses,
    required this.netCashBalance,
    required this.inventorySales,
    required this.cogs,
    required this.monthlyPrediction,
    required this.expensesByCategory,
    required this.insights,
    required this.periodLabel,
    required this.filteredTransactions,
    required this.filteredDebts,
  });
}

final statisticsFilterProvider = StateProvider<StatisticsFilter>((ref) => StatisticsFilter.thisMonth);
final statisticsCustomRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final executiveFinancialsProvider = FutureProvider<List<ExecutiveFinancialsRes>>((ref) async {
  final business = ref.watch(businessProvider);
  if (business == null) return [];
  
  final cached = SyncService.getCachedExecutiveFinancials(business.id);
  
  try {
    final now = DateTime.now();
    final start = DateTime(now.year - 1, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    final fresh = await ApiService.getExecutiveFinancials(business.id, start, end);
    await SyncService.cacheExecutiveFinancials(business.id, fresh);
    return fresh;
  } catch (e) {
    return cached.isNotEmpty ? cached : [];
  }
});

final analyticsProvider = Provider<AnalyticsState>((ref) {
  final financialsAsync = ref.watch(executiveFinancialsProvider);
  final performanceAsync = ref.watch(inventoryPerformanceProvider);
  final transactionsAsync = ref.watch(historicTransactionsProvider);
  final debtsAsync = ref.watch(debtsProvider);
  
  final filter = ref.watch(statisticsFilterProvider);
  final customRange = ref.watch(statisticsCustomRangeProvider);
  final business = ref.watch(businessProvider);

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

  // Initial empty state
  final emptyState = AnalyticsState(
    totalSales: 0,
    realProfit: 0,
    profitMargin: 0,
    operationalLoad: 0,
    directIncome: 0,
    directExpenses: 0,
    netCashBalance: 0,
    inventorySales: 0,
    cogs: 0,
    monthlyPrediction: 0,
    expensesByCategory: {},
    insights: [],
    periodLabel: periodLabel,
    filteredTransactions: [],
    filteredDebts: [],
  );

  if (business == null) return emptyState;

  final financials = financialsAsync.value ?? SyncService.getCachedExecutiveFinancials(business.id);
  final performance = performanceAsync.value ?? SyncService.getCachedInventoryPerformance(business.id);
  final allTransactions = transactionsAsync.value ?? SyncService.getCachedTransactions(business.id);
  final allDebts = debtsAsync.value ?? SyncService.getCachedDebts(business.id);

  // 1. Filtrado de Transacciones por Rango (Cálculos directos para reactividad)
  final filteredTransactions = allTransactions.where((tx) => 
    (tx.transactionDate.isAtSameMomentAs(startDate) || tx.transactionDate.isAfter(startDate)) &&
    (tx.transactionDate.isAtSameMomentAs(endDate) || tx.transactionDate.isBefore(endDate))
  ).toList();

  final directIncome = filteredTransactions
      .where((tx) => tx.type == 'income' && (tx.description == null || !tx.description!.startsWith('Venta')))
      .fold(0.0, (sum, tx) => sum + tx.amount);

  final inventorySales = filteredTransactions
      .where((tx) => tx.type == 'income' && (tx.description != null && tx.description!.startsWith('Venta')))
      .fold(0.0, (sum, tx) => sum + tx.amount);

  final directExpenses = filteredTransactions
      .where((tx) => tx.type == 'expense')
      .fold(0.0, (sum, tx) => sum + tx.amount);

  // El COGS y otros agregados siguen viniendo de financialsAsync
  final rangeFinancials = financials.where((f) => 
    (f.entryDate.isAtSameMomentAs(startDate) || f.entryDate.isAfter(startDate)) &&
    (f.entryDate.isAtSameMomentAs(endDate) || f.entryDate.isBefore(endDate))
  ).toList();
  
  final cogs = rangeFinancials.fold(0.0, (sum, f) => sum + f.totalCOGS);

  final totalSales = inventorySales;
  final realProfit = totalSales - cogs;
  final profitMargin = totalSales > 0 ? (realProfit / totalSales) * 100 : 0.0;
  
  // operationalLoad: (directExpenses / (directIncome + totalSales)) * 100
  final totalGrossIncome = directIncome + totalSales;
  final operationalLoad = totalGrossIncome > 0 ? (directExpenses / totalGrossIncome) * 100 : 0.0;
  
  final netCashBalance = directIncome - directExpenses;

  // 2. Predicción del Mes (promedio diario del periodo * 30)
  final daysInPeriod = endDate.difference(startDate).inDays + 1;
  final avgDailySales = daysInPeriod > 0 ? (directIncome + totalSales) / daysInPeriod : 0.0;
  final monthlyPrediction = avgDailySales * 30;

  // 3. Gastos por Categoría y Filtros de Detalle
  final Map<String, double> expensesByCategory = {};

  for (var tx in filteredTransactions.where((tx) => tx.type == 'expense')) {
    expensesByCategory[tx.category] = (expensesByCategory[tx.category] ?? 0.0) + tx.amount;
  }

  final filteredDebts = allDebts.where((d) => 
    (d.createdAt.isAtSameMomentAs(startDate) || d.createdAt.isAfter(startDate)) &&
    (d.createdAt.isAtSameMomentAs(endDate) || d.createdAt.isBefore(endDate))
  ).toList();

  // 4. Insights Inteligentes
  final List<Insight> insights = [];

  if (operationalLoad > 40) {
    insights.add(Insight(
      title: "Alta Carga Operativa",
      message: "Tus gastos operativos consumen el ${operationalLoad.toStringAsFixed(1)}% de tus ingresos. Mantente bajo el 40%.",
      type: InsightType.alert,
    ));
  }

  // Productos con stock bajo (Stock < 5)
  final lowStockProducts = performance.where((p) => p.stock < 5).toList();
  if (lowStockProducts.isNotEmpty) {
    insights.add(Insight(
      title: "Stock Crítico",
      message: "Tienes ${lowStockProducts.length} productos con menos de 5 unidades. ¡Revisa tu inventario!",
      type: InsightType.warning,
    ));
  }

  // Producto Estrella (Más vendido en los últimos 30 días)
  if (performance.isNotEmpty) {
    final topProduct = performance.reduce((a, b) => a.unitsSoldLast30Days > b.unitsSoldLast30Days ? a : b);
    if (topProduct.unitsSoldLast30Days > 0) {
      insights.add(Insight(
        title: "Producto Estrella",
        message: "${topProduct.productName} es tu líder en ventas con ${topProduct.unitsSoldLast30Days.toInt()} unidades este mes.",
        type: InsightType.achievement,
      ));
    }
  }

  return AnalyticsState(
    totalSales: totalSales,
    realProfit: realProfit,
    profitMargin: profitMargin,
    operationalLoad: operationalLoad,
    directIncome: directIncome,
    directExpenses: directExpenses,
    netCashBalance: netCashBalance,
    inventorySales: inventorySales,
    cogs: cogs,
    monthlyPrediction: monthlyPrediction,
    expensesByCategory: expensesByCategory,
    insights: insights,
    periodLabel: periodLabel,
    filteredTransactions: filteredTransactions,
    filteredDebts: filteredDebts,
  );
});
