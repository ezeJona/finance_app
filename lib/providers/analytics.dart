import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'transactions.dart';
import 'debts.dart';

enum InsightType { achievement, warning, alert }

class Insight {
  final String title;
  final String message;
  final InsightType type;

  Insight({required this.title, required this.message, required this.type});
}

class AnalyticsState {
  final List<Insight> insights;
  final double monthlyPrediction;
  final Map<String, double> expensesByCategory;
  final double totalIncomeMonth;
  final double totalExpenseMonth;

  AnalyticsState({
    required this.insights,
    required this.monthlyPrediction,
    required this.expensesByCategory,
    required this.totalIncomeMonth,
    required this.totalExpenseMonth,
  });
}

final analyticsProvider = Provider<AnalyticsState>((ref) {
  final transactionsAsync = ref.watch(historicTransactionsProvider);
  final debtsAsync = ref.watch(debtsProvider);
  
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

  return transactionsAsync.maybeWhen(
    data: (transactions) {
      // 1. Cálculos Base
      final monthTransactions = transactions.where((tx) => tx.transactionDate.isAfter(startOfMonth) || tx.transactionDate.isAtSameMomentAs(startOfMonth)).toList();
      
      double totalIncomeMonth = monthTransactions
          .where((tx) => tx.type == 'income')
          .fold(0.0, (sum, tx) => sum + tx.amount);
      
      // Añadir deudas a cobrar registradas este mes como ingresos proyectados/reales para el negocio
      debtsAsync.whenData((debts) {
        totalIncomeMonth += debts
            .where((d) => d.type == 'to_collect' && d.createdAt.isAfter(startOfMonth))
            .fold(0.0, (sum, d) => sum + d.totalAmount);
      });

      final totalExpenseMonth = monthTransactions
          .where((tx) => tx.type == 'expense')
          .fold(0.0, (sum, tx) => sum + tx.amount);

      // 2. Predicción del Mes
      final dayOfMonth = now.day;
      final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final monthlyPrediction = dayOfMonth > 0 ? (totalIncomeMonth / dayOfMonth) * totalDaysInMonth : 0.0;

      // 3. Insights
      final List<Insight> insights = [];

      // A) Mezcla de Gastos
      final personalExpenses = transactions.where((tx) => 
        tx.type == 'expense' && 
        ['Personal', 'Hogar', 'Comida propia'].contains(tx.category)
      );
      if (personalExpenses.isNotEmpty) {
        insights.add(Insight(
          title: "Gastos Mezclados",
          message: "💡 Tip: Evita pagar tus antojos o gastos personales directo de la caja del negocio. Asígnate un sueldo fijo.",
          type: InsightType.warning,
        ));
      }

      // B) Falta de Actividad
      final todayIncome = transactions.where((tx) => 
        tx.type == 'income' && 
        tx.transactionDate.year == now.year &&
        tx.transactionDate.month == now.month &&
        tx.transactionDate.day == now.day
      );
      if (todayIncome.isEmpty) {
        insights.add(Insight(
          title: "Sin Ventas Hoy",
          message: "⚠️ Alerta: No has registrado ventas el día de hoy. ¡Mantén el ritmo!",
          type: InsightType.alert,
        ));
      }

      // C) Punto de Mayor Gasto (Última Semana)
      final weekExpenses = transactions.where((tx) => 
        tx.type == 'expense' && 
        tx.transactionDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))
      ).toList();
      
      final totalWeekExpense = weekExpenses.fold(0.0, (sum, tx) => sum + tx.amount);
      
      final Map<String, double> expensesByCat = {};
      for (var tx in weekExpenses) {
        expensesByCat[tx.category] = (expensesByCat[tx.category] ?? 0.0) + tx.amount;
      }

      String? topCat;
      double topAmount = 0;
      expensesByCat.forEach((cat, amount) {
        if (amount > topAmount) {
          topAmount = amount;
          topCat = cat;
        }
      });

      if (topCat != null && totalWeekExpense > 0 && (topAmount / totalWeekExpense) > 0.4) {
        insights.add(Insight(
          title: "Análisis de Gastos",
          message: "📊 Análisis: Esta semana gastaste más en $topCat, representando más del 40% de tus egresos.",
          type: InsightType.achievement,
        ));
      }

      // 4. Gastos por Categoría (Para el gráfico de pastel - todo el tiempo o este mes?)
      // Usaremos los de este mes para que sea relevante
      final Map<String, double> monthExpensesByCat = {};
      for (var tx in monthTransactions.where((tx) => tx.type == 'expense')) {
        monthExpensesByCat[tx.category] = (monthExpensesByCat[tx.category] ?? 0.0) + tx.amount;
      }

      return AnalyticsState(
        insights: insights,
        monthlyPrediction: monthlyPrediction,
        expensesByCategory: monthExpensesByCat,
        totalIncomeMonth: totalIncomeMonth,
        totalExpenseMonth: totalExpenseMonth,
      );
    },
    orElse: () => AnalyticsState(
      insights: [],
      monthlyPrediction: 0.0,
      expensesByCategory: {},
      totalIncomeMonth: 0.0,
      totalExpenseMonth: 0.0,
    ),
  );
});
