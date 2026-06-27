import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'transactions.dart';
import 'businesses.dart';
import 'inventory.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
  });
}

final achievementsProvider = Provider<List<Achievement>>((ref) {
  final transactionsAsync = ref.watch(historicTransactionsProvider);
  final businessesAsync = ref.watch(businessesProvider);
  final productsAsync = ref.watch(productsProvider);
  
  // Datos básicos para cálculos
  final transactions = transactionsAsync.maybeWhen(data: (d) => d, orElse: () => []);
  final businesses = businessesAsync.maybeWhen(data: (d) => d, orElse: () => []);
  final products = productsAsync.maybeWhen(data: (d) => d, orElse: () => []);

  // 1. Disciplina de Acero (7 días registrando transacciones de ingreso/ventas)
  final uniqueDays = transactions
      .where((tx) => tx.type == 'income')
      .map((tx) => DateTime(tx.transactionDate.year, tx.transactionDate.month, tx.transactionDate.day))
      .toSet();
  final hasSteelDiscipline = uniqueDays.length >= 7;

  // 2. Blindaje Financiero (Cualquier mes con balance neto positivo)
  final monthlyBalances = <String, double>{};
  for (var tx in transactions) {
    final key = "${tx.transactionDate.year}-${tx.transactionDate.month}";
    final amount = tx.type == 'income' ? tx.amount : -tx.amount;
    monthlyBalances[key] = (monthlyBalances[key] ?? 0) + amount;
  }
  final hasFinancialShield = monthlyBalances.values.any((balance) => balance > 0);

  // 3. Control Excelente (Registrado ventas y gastos)
  final hasIncome = transactions.any((tx) => tx.type == 'income');
  final hasExpense = transactions.any((tx) => tx.type == 'expense');
  final hasExcellentControl = hasIncome && hasExpense;

  // 4. Gran Expansionista (Más de 1 negocio)
  final isExpansionist = businesses.length > 1;

  // 5. Catálogo Dorado (10 o más productos en el negocio actual)
  final hasGoldenCatalog = products.length >= 10;

  // 6. Ventas Imparables (Ventas totales > 50,000)
  final totalSales = transactions
      .where((tx) => tx.type == 'income')
      .fold<double>(0, (sum, tx) => sum + tx.amount);
  final hasUnstoppableSales = totalSales >= 50000;

  return [
    Achievement(
      id: 'steel_discipline',
      title: 'Disciplina de Acero',
      description: 'Registra ventas por 7 días diferentes.',
      icon: Icons.emoji_events_outlined,
      isUnlocked: hasSteelDiscipline,
    ),
    Achievement(
      id: 'financial_shield',
      title: 'Blindaje Financiero',
      description: 'Logra un balance neto positivo en un mes.',
      icon: Icons.shield_outlined,
      isUnlocked: hasFinancialShield,
    ),
    Achievement(
      id: 'unstoppable_sales',
      title: 'Ventas Imparables',
      description: 'Supera los 50,000 en ingresos totales.',
      icon: Icons.trending_up_rounded,
      isUnlocked: hasUnstoppableSales,
    ),
    Achievement(
      id: 'excellent_control',
      title: 'Control Excelente',
      description: 'Registra tanto ingresos como gastos para un control total.',
      icon: Icons.verified_user_outlined,
      isUnlocked: hasExcellentControl,
    ),
    Achievement(
      id: 'expansionist',
      title: 'Gran Expansionista',
      description: 'Gestiona 2 o más negocios desde tu cuenta.',
      icon: Icons.add_business_rounded,
      isUnlocked: isExpansionist,
    ),
    Achievement(
      id: 'golden_catalog',
      title: 'Catálogo Dorado',
      description: 'Registra al menos 10 productos en tu catálogo.',
      icon: Icons.auto_awesome_rounded,
      isUnlocked: hasGoldenCatalog,
    ),
    Achievement(
      id: 'first_step',
      title: 'Primer Paso',
      description: 'Realiza tu primera transacción en la app.',
      icon: Icons.rocket_launch_outlined,
      isUnlocked: transactions.isNotEmpty,
    ),
  ];
});
