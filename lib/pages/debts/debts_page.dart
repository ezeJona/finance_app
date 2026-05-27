import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/app_user.dart';
import '../../providers/business.dart';
import '../../backend-api/dtos.dart';

class DebtsPage extends HookConsumerWidget {
  const DebtsPage({super.key});

  // paleta de colores de BalancePage
  static const Color primaryYellow = Color(0xFFF1C40F);
  static const Color backgroundColor = Color(0xFFF5F6F8);
  static const Color darkNavy = Color(0xFF2C3E50);
  static const Color incomeGreen = Color(0xFF00A86B);
  static const Color expenseRed = Color(0xFFFF2D55);
  static const Color textGray = Color(0xFF7F8C8D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(appUserProvider);
    final business = ref.watch(businessProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: const Drawer(),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context, appUser, business),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: _buildDebtsSummaryCard(business?.currencyCode ?? 'NIO'),
                ),
                Expanded(
                  child: _buildEmptyState(),
                ),
              ],
            ),
            _buildBottomActionButtons(),
          ],
        ),
      ),
    );
  }

  // 1. Header
  Widget _buildHeader(BuildContext context, AppUserRes? appUser, BusinessRes? business) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    String businessName = business?.name ?? "Cargando...";
    String subTitle = "";
    if (business != null) {
      subTitle = "${business.businessType} • ${appUser?.firstName ?? 'Usuario'}";
    } else if (appUser != null) {
      subTitle = "${appUser.firstName} ${appUser.firstLastName}";
    }

    return Container(
      padding: EdgeInsets.only(top: statusBarHeight + 16, left: 16, right: 16, bottom: 20),
      decoration: const BoxDecoration(
        color: primaryYellow,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      businessName,
                      style: const TextStyle(
                        fontSize: 19, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                        letterSpacing: 0.5
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subTitle,
                      style: TextStyle(
                        fontSize: 13, 
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.3),
                child: const Text('?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 2. Tarjeta de Resumen de Deudas (Métricas)
  Widget _buildDebtsSummaryCard(String currency) {
    final String symbol = currency == 'USD' ? '\$' : 'C\$';

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Lado Izquierdo: Por cobrar
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: incomeGreen.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet, color: incomeGreen, size: 14),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Por cobrar',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: darkNavy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$symbol 0',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const Text(
                      '0 deudores',
                      style: TextStyle(fontSize: 12, color: textGray),
                    ),
                  ],
                ),
              ),
              VerticalDivider(color: Colors.grey.withOpacity(0.3), thickness: 1),
              // Lado Derecho: Por pagar
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: expenseRed.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.payment, color: expenseRed, size: 14),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Por pagar',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: darkNavy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$symbol 0',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const Text(
                      '0 acreedores',
                      style: TextStyle(fontSize: 12, color: textGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Cuerpo de la Página (Estado Vacío)
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Aún no tienes deudas creadas empieza añadiendo una AQUÍ",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textGray,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            const Icon(
              Icons.south,
              size: 80,
              color: darkNavy,
            ),
          ],
        ),
      ),
    );
  }

  // 4. Botones de Acción Inferiores
  Widget _buildBottomActionButtons() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
        child: Row(
          children: [
            Expanded(
              child: _buildActionButton('NUEVO INGRESO', incomeGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton('NUEVO PAGO', expenseRed),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color color) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: () {}, // Estático por ahora
        style: FilledButton.styleFrom(
          backgroundColor: color,
          elevation: 4,
          shadowColor: color.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
