import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/analytics.dart';
import '../../providers/business.dart';

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
    final currencySymbol = business?.currencyCode == 'USD' ? '\$' : 'C\$';

    return Scaffold(
      backgroundColor: backgroundGray,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Estadísticas y Análisis",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkNavy),
                  ),
                  const SizedBox(height: 20),

                  // 1. Carrusel de Insights Inteligentes
                  if (analytics.insights.isNotEmpty) ...[
                    const Text(
                      "Insights Inteligentes",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: analytics.insights.length,
                        itemBuilder: (context, index) {
                          final insight = analytics.insights[index];
                          return _buildInsightCard(insight);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 2. Sección de Predicción del Mes
                  _buildPredictionCard(analytics.monthlyPrediction, currencySymbol),
                  const SizedBox(height: 24),

                  // 3. Reportes Gráficos
                  const Text(
                    "Gastos por Categoría",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  _buildExpensesPieChart(analytics.expensesByCategory),
                  const SizedBox(height: 32),

                  const Text(
                    "Ingresos vs Egresos (Mes Actual)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  _buildIncomeVsExpenseChart(analytics.totalIncomeMonth, analytics.totalExpenseMonth, currencySymbol),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(Insight insight) {
    Color bgColor;
    IconData icon;
    Color iconColor;

    switch (insight.type) {
      case InsightType.achievement:
        bgColor = incomeGreen.withOpacity(0.1);
        icon = Icons.insights_rounded;
        iconColor = incomeGreen;
        break;
      case InsightType.warning:
        bgColor = primaryYellow.withOpacity(0.15);
        icon = Icons.lightbulb_outline;
        iconColor = Colors.orange;
        break;
      case InsightType.alert:
        bgColor = expenseRed.withOpacity(0.1);
        icon = Icons.warning_amber_rounded;
        iconColor = expenseRed;
        break;
    }

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: darkNavy, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(double prediction, String symbol) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.online_prediction_rounded, color: primaryYellow, size: 32),
              const SizedBox(width: 12),
              const Text(
                "PREDICCIÓN INTELIGENTE",
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: darkNavy),
              ),
            ],
          ),
          const SizedBox(height: 20),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              children: [
                const TextSpan(text: "Si mantienes este ritmo, ganarás "),
                TextSpan(
                  text: formatter.format(prediction),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: incomeGreen),
                ),
                const TextSpan(text: " este mes."),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesPieChart(Map<String, double> data) {
    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text("No hay datos de gastos este mes", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final total = data.values.fold(0.0, (sum, val) => sum + val);
    final colors = [incomeGreen, primaryYellow, expenseRed, Colors.blue, Colors.purple, Colors.orange];

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: data.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final cat = entry.value.key;
            final value = entry.value.value;
            final percentage = (value / total * 100).toStringAsFixed(1);
            
            return PieChartSectionData(
              color: colors[index % colors.length],
              value: value,
              title: "$percentage%",
              radius: 50,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              badgeWidget: _buildBadge(cat, colors[index % colors.length]),
              badgePositionPercentageOffset: 1.4,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildIncomeVsExpenseChart(double income, double expense, String symbol) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (income > expense ? income : expense) * 1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(value == 0 ? 'Ingresos' : 'Egresos', style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: income,
                  color: incomeGreen,
                  width: 40,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true, 
                    toY: (income > expense ? income : expense) * 1.2, 
                    color: backgroundGray
                  ),
                ),
              ],
              showingTooltipIndicators: [0],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: expense,
                  color: expenseRed,
                  width: 40,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true, 
                    toY: (income > expense ? income : expense) * 1.2, 
                    color: backgroundGray
                  ),
                ),
              ],
              showingTooltipIndicators: [0],
            ),
          ],
        ),
      ),
    );
  }
}
