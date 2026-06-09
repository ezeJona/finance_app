import 'package:flutter/material.dart';

class SideNavBar extends StatelessWidget {
  const SideNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final Function(int) onTap;

  // Colores de la UI de Balance para consistencia visual
  static const Color primaryYellow = Color(0xFFF1C40F);
  static const Color darkNavy = Color(0xFF2C3E50);
  static const Color textGray = Color(0xFF7F8C8D);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Colors.black.withOpacity(0.05), // Separación sutil vertical
            width: 1,
          ),
        ),
      ),
      child: NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => onTap(index),
        labelType: NavigationRailLabelType.all,
        backgroundColor: Colors.transparent, // Adopta el fondo del contenedor padre

        // Estilización Material 3 para combinar con Balance
        indicatorColor: primaryYellow.withOpacity(0.2), // Color de la píldora de selección
        selectedIconTheme: const IconThemeData(color: darkNavy, size: 26),
        unselectedIconTheme: IconThemeData(color: textGray.withOpacity(0.6), size: 24),
        selectedLabelTextStyle: const TextStyle(
          color: darkNavy,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: textGray.withOpacity(0.6),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),

        destinations: const [
          NavigationRailDestination(
            padding: EdgeInsets.symmetric(vertical: 12),
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: Text('Balance'),
          ),
          NavigationRailDestination(
            padding: EdgeInsets.symmetric(vertical: 12),
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: Text('Deudas'),
          ),
          NavigationRailDestination(
            padding: EdgeInsets.symmetric(vertical: 12),
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: Text('Inventario'),
          ),
          NavigationRailDestination(
            padding: EdgeInsets.symmetric(vertical: 12),
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: Text('Asistente'),
          ),
          NavigationRailDestination(
            padding: EdgeInsets.symmetric(vertical: 12),
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: Text('Perfil'),
          ),
        ],
      ),
    );
  }
}