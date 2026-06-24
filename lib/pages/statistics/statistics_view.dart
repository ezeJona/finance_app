import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/analytics.dart';
import '../../providers/business.dart';
import '../../providers/transactions.dart';
import '../../providers/debts.dart';
import '../../providers/transaction_items.dart';
import '../../services/report_export_service.dart';

class StatisticsView extends HookConsumerWidget {
  const StatisticsView({super.key});

  static const Color primaryYellow = Color(0xFFF1C40F);
  static const Color darkNavy = Color(0xFF2C3E50);
  static const Color incomeGreen = Color(0xFF00A86B);
  static const Color expenseRed = Color(0xFFFF2D55);
  static const Color backgroundGray = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);
    final business = ref.watch(businessProvider);
    final filter = ref.watch(statisticsFilterProvider);
    final currencySymbol = business?.currencyCode == 'USD' ? '\$' : 'C\$';
    final formatter = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);

    return Scaffold(
      backgroundColor: backgroundGray,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const AppHeader(title: "Estadísticas y Análisis"),
          Expanded(
            child: RefreshIndicator(
              color: primaryYellow,
              onRefresh: () async {
                ref.invalidate(historicTransactionsProvider);
                ref.invalidate(debtsProvider);
                ref.invalidate(transactionItemsProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección 1: Selector de Rango
                    _buildFilterSelector(context, ref, filter),
                    const SizedBox(height: 20),

                    // Sección 2: El Versus de Impacto Financiero
                    _buildFinancialImpactCard(analytics, formatter),
                    const SizedBox(height: 24),

                    // Sección 2.5: Carga Operativa
                    _buildOperationalLoadCard(analytics, formatter),
                    const SizedBox(height: 24),

                    // Sección 3: Feed de Alertas e Insights
                    if (analytics.insights.isNotEmpty) ...[
                      const Text(
                        "Insights y Alertas",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkNavy),
                      ),
                      const SizedBox(height: 12),
                      ...analytics.insights.map((insight) => _buildInsightTile(insight)),
                      const SizedBox(height: 24),
                    ],

                    // Sección 3.5: Semáforo de Gastos y Balance Neto
                    const Text(
                      "Flujo de Caja y Gastos",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkNavy),
                    ),
                    const SizedBox(height: 12),
                    _buildExpenseSemaphore(analytics, formatter),
                    const SizedBox(height: 12),
                    _buildNetCashBalanceCard(analytics, formatter),
                    const SizedBox(height: 24),

                    // Sección 4: Panel de Predicción
                    _buildPredictionCard(analytics.monthlyPrediction, formatter),
                    const SizedBox(height: 24),

                    // Sección 5: Mesa de Control
                    const Text(
                      "Mesa de Control (Inventario)",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkNavy),
                    ),
                    const SizedBox(height: 12),
                    _buildControlTable(analytics, formatter),
                    const SizedBox(height: 30),

                    // Botón de Exportación
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: FilledButton.icon(
                        onPressed: () => ReportExportService.exportToExcel(
                          transactions: analytics.filteredTransactions,
                          debts: analytics.filteredDebts,
                          periodName: analytics.periodLabel,
                        ),
                        icon: const Icon(Icons.file_download_rounded),
                        label: const Text(
                          "EXPORTAR REPORTE A EXCEL",
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: darkNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSelector(BuildContext context, WidgetRef ref, StatisticsFilter currentFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(ref, "Hoy", StatisticsFilter.today, currentFilter),
          const SizedBox(width: 8),
          _buildFilterChip(ref, "Esta Semana", StatisticsFilter.thisWeek, currentFilter),
          const SizedBox(width: 8),
          _buildFilterChip(ref, "Este Mes", StatisticsFilter.thisMonth, currentFilter),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Icon(Icons.calendar_month, size: 20),
            selected: currentFilter == StatisticsFilter.custom,
            onSelected: (selected) async {
              if (selected) {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: primaryYellow,
                          onPrimary: Colors.white,
                          onSurface: darkNavy,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (range != null) {
                  ref.read(statisticsCustomRangeProvider.notifier).state = range;
                  ref.read(statisticsFilterProvider.notifier).state = StatisticsFilter.custom;
                }
              }
            },
            selectedColor: primaryYellow,
            labelStyle: TextStyle(color: currentFilter == StatisticsFilter.custom ? Colors.white : darkNavy),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(WidgetRef ref, String label, StatisticsFilter filter, StatisticsFilter currentFilter) {
    final isSelected = filter == currentFilter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) ref.read(statisticsFilterProvider.notifier).state = filter;
      },
      selectedColor: primaryYellow,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : darkNavy,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildFinancialImpactCard(AnalyticsState analytics, NumberFormat formatter) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Ventas Inventario", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(
                        formatter.format(analytics.totalSales),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkNavy),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 50, color: Colors.grey.shade200),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Margen Producto", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(
                        formatter.format(analytics.realProfit),
                        style: TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold, 
                          color: analytics.realProfit >= 0 ? incomeGreen : expenseRed
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundGray,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: incomeGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${analytics.profitMargin.toStringAsFixed(1)}%",
                      style: const TextStyle(color: incomeGreen, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Eficiencia de Ventas", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: darkNavy)),
                        Text(
                          "De cada C\$ 100 vendidos, C\$ ${analytics.profitMargin.toStringAsFixed(1)} son ganancia de inventario.",
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalLoadCard(AnalyticsState analytics, NumberFormat formatter) {
    final isHighLoad = analytics.operationalLoad > 40;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighLoad ? expenseRed.withValues(alpha: 0.05) : incomeGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isHighLoad ? expenseRed.withValues(alpha: 0.1) : incomeGreen.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: (analytics.operationalLoad / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  color: isHighLoad ? expenseRed : incomeGreen,
                  strokeWidth: 8,
                ),
              ),
              Text(
                "${analytics.operationalLoad.toInt()}%",
                style: TextStyle(fontWeight: FontWeight.bold, color: isHighLoad ? expenseRed : incomeGreen),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Carga Operativa", style: TextStyle(fontWeight: FontWeight.bold, color: darkNavy)),
                const SizedBox(height: 4),
                Text(
                  isHighLoad 
                    ? "Tus gastos consumen el ${analytics.operationalLoad.toStringAsFixed(0)}% de tus ganancias. Mantente debajo del 40%."
                    : "¡Excelente! Tus gastos están bajo control, consumiendo solo el ${analytics.operationalLoad.toStringAsFixed(0)}% de tus ganancias.",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseSemaphore(AnalyticsState analytics, NumberFormat formatter) {
    final sortedCategories = analytics.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Semáforo de Gastos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            if (sortedCategories.isEmpty)
              const Center(child: Text("No hay gastos registrados", style: TextStyle(fontSize: 12, color: Colors.grey)))
            else
              ...sortedCategories.take(3).map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, color: darkNavy, fontSize: 13)),
                        Text(formatter.format(entry.value), style: const TextStyle(fontWeight: FontWeight.bold, color: expenseRed, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: analytics.directExpenses > 0 ? entry.value / analytics.directExpenses : 0,
                      backgroundColor: backgroundGray,
                      color: darkNavy,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildNetCashBalanceCard(AnalyticsState analytics, NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkNavy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildCashRow("Ingresos de Caja Directos", analytics.directIncome, Colors.white, incomeGreen),
          const SizedBox(height: 12),
          _buildCashRow("Gastos Operativos", -analytics.directExpenses, Colors.white, expenseRed),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white24),
          ),
          _buildCashRow(
            "Resultado Neto de Caja", 
            analytics.netCashBalance, 
            primaryYellow, 
            analytics.netCashBalance >= 0 ? incomeGreen : expenseRed,
            isTotal: true
          ),
        ],
      ),
    );
  }

  Widget _buildCashRow(String label, double amount, Color labelColor, Color amountColor, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 14 : 12)),
        Text(
          (amount >= 0 ? "+" : "") + (isTotal ? "" : "") + NumberFormat.currency(symbol: '', decimalDigits: 2).format(amount), 
          style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: isTotal ? 16 : 13)
        ),
      ],
    );
  }

  Widget _buildInsightTile(Insight insight) {
    Color bgColor;
    IconData icon;
    Color iconColor;

    switch (insight.type) {
      case InsightType.achievement:
        bgColor = incomeGreen.withValues(alpha: 0.08);
        icon = Icons.check_circle_rounded;
        iconColor = incomeGreen;
        break;
      case InsightType.warning:
        bgColor = primaryYellow.withValues(alpha: 0.1);
        icon = Icons.lightbulb_rounded;
        iconColor = Colors.orange;
        break;
      case InsightType.alert:
        bgColor = expenseRed.withValues(alpha: 0.08);
        icon = Icons.warning_rounded;
        iconColor = expenseRed;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: iconColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: darkNavy, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(double prediction, NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkNavy, Color(0xFF34495E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: darkNavy.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.online_prediction_rounded, color: primaryYellow, size: 24),
              SizedBox(width: 12),
              Text(
                "PROYECCIÓN DEL MES",
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "Si mantienes este ritmo, cerrarás el mes con ventas estimadas de:",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(prediction),
            style: const TextStyle(color: primaryYellow, fontSize: 28, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildControlTable(AnalyticsState analytics, NumberFormat formatter) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTableRow("Ventas Brutas Productos", analytics.inventorySales, formatter),
            const Divider(),
            _buildTableRow("Inversión en Mercancía", -analytics.cogs, formatter, isNegative: true),
            const Divider(),
            _buildTableRow("Margen Neto de Ganancia", analytics.realProfit, formatter, isIncome: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(String label, double amount, NumberFormat formatter, {bool isNegative = false, bool isIncome = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(
            formatter.format(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: isNegative ? expenseRed : (isIncome ? incomeGreen : darkNavy),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
